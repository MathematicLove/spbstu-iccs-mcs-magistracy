#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a; source "$ROOT/credentials.env"; set +a
RAW="$ROOT/data/raw"
CHUNK=50000
mkdir -p "$RAW"

SALES_ROWS=${SALES_ROWS:-300000}
CRIME_ROWS=${CRIME_ROWS:-250000}
TAXI_ROWS=${TAXI_ROWS:-250000}

download() {
  local name="$1" base="$2" select="$3" order="$4" total="$5"
  local out="$RAW/$name.csv" stamp="$RAW/$name.rows"

  if [[ -f "$out" && "$(cat "$stamp" 2>/dev/null || echo 0)" == "$total" ]]; then
    echo "    $name.csv уже скачан ($total строк) — пропускаю"
    return
  fi

  : > "$out"
  local off=0 lim first=1
  while (( off < total )); do
    lim=$(( total - off < CHUNK ? total - off : CHUNK ))
    local url="${base}?\$select=${select}&\$order=${order}&\$limit=${lim}&\$offset=${off}"
    printf '    %s: строки %s..%s\n' "$name" "$off" "$(( off + lim ))"
    if (( first )); then
      curl -sS --fail --retry 6 --retry-all-errors --retry-delay 3 --max-time 600 "$url" >> "$out"
      first=0
    else
      curl -sS --fail --retry 6 --retry-all-errors --retry-delay 3 --max-time 600 "$url" | tail -n +2 >> "$out"
    fi
    off=$(( off + lim ))
  done
  echo "$total" > "$stamp"
}

psql_run() {
  local c="$1" u="$2" d="$3"; shift 3
  docker exec -i "$c" psql -v ON_ERROR_STOP=1 -q -U "$u" -d "$d" "$@"
}

WANT="${*:-sales crime taxi}"
want() { [[ " $WANT " == *" $1 "* ]]; }

if want sales; then
echo "==> [1/3] sales_db — Montgomery County Warehouse and Retail Sales"
download sales "https://data.montgomerycountymd.gov/resource/v76h-r7br.csv" \
  "calendar_year,cal_month_num,supplier,item_code,item_description,item_type,rtl_sales,rtl_transfers,whs_sales" \
  ":id" "$SALES_ROWS"

psql_run sales_db "$SALES_DB_USER" "$SALES_DB_NAME" <<'SQL'
TRUNCATE sales.sales_facts, sales.supplier_item_types, sales.supplier_profiles,
         sales.suppliers, sales.items, sales.item_types, sales.periods
    RESTART IDENTITY CASCADE;
DROP TABLE IF EXISTS stage_sales;
CREATE UNLOGGED TABLE stage_sales (
    calendar_year text, cal_month_num text, supplier text, item_code text,
    item_description text, item_type text, rtl_sales text, rtl_transfers text, whs_sales text
);
SQL

echo "    COPY -> stage_sales"
psql_run sales_db "$SALES_DB_USER" "$SALES_DB_NAME" \
  -c "\copy stage_sales FROM STDIN WITH (FORMAT csv, HEADER true)" < "$RAW/sales.csv"

psql_run sales_db "$SALES_DB_USER" "$SALES_DB_NAME" <<'SQL'
INSERT INTO sales.item_types (type_name)
SELECT DISTINCT NULLIF(btrim(item_type), '') FROM stage_sales
WHERE NULLIF(btrim(item_type), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO sales.suppliers (supplier_name)
SELECT DISTINCT NULLIF(btrim(supplier), '') FROM stage_sales
WHERE NULLIF(btrim(supplier), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO sales.periods (calendar_year, cal_month_num)
SELECT DISTINCT NULLIF(calendar_year,'')::int, NULLIF(cal_month_num,'')::int
FROM stage_sales
WHERE NULLIF(calendar_year,'') IS NOT NULL AND NULLIF(cal_month_num,'') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO sales.items (item_code, item_description, item_type_id)
SELECT DISTINCT ON (s.item_code)
       s.item_code, s.item_description, it.item_type_id
FROM stage_sales s
JOIN sales.item_types it ON it.type_name = NULLIF(btrim(s.item_type), '')
WHERE NULLIF(s.item_code, '') IS NOT NULL
ORDER BY s.item_code
ON CONFLICT DO NOTHING;

INSERT INTO sales.sales_facts
    (period_id, supplier_id, item_id, retail_sales, retail_transfers, warehouse_sales)
SELECT p.period_id, sup.supplier_id, i.item_id,
       NULLIF(s.rtl_sales,'')::numeric,
       NULLIF(s.rtl_transfers,'')::numeric,
       NULLIF(s.whs_sales,'')::numeric
FROM stage_sales s
JOIN sales.periods   p   ON p.calendar_year = NULLIF(s.calendar_year,'')::int
                        AND p.cal_month_num = NULLIF(s.cal_month_num,'')::int
JOIN sales.suppliers sup ON sup.supplier_name = NULLIF(btrim(s.supplier), '')
JOIN sales.items     i   ON i.item_code = s.item_code;
DROP TABLE stage_sales;

INSERT INTO sales.supplier_profiles (supplier_id, items_count, total_retail, first_year, last_year)
SELECT sup.supplier_id, count(DISTINCT f.item_id), sum(f.retail_sales),
       min(p.calendar_year), max(p.calendar_year)
FROM sales.sales_facts f
JOIN sales.suppliers sup ON sup.supplier_id = f.supplier_id
JOIN sales.periods   p   ON p.period_id = f.period_id
GROUP BY sup.supplier_id;

INSERT INTO sales.supplier_item_types (supplier_id, item_type_id, positions_count)
SELECT f.supplier_id, i.item_type_id, count(DISTINCT f.item_id)
FROM sales.sales_facts f
JOIN sales.items i ON i.item_id = f.item_id
GROUP BY f.supplier_id, i.item_type_id;

ANALYZE sales.sales_facts;
SQL
fi

if want crime; then
echo "==> [2/3] crime_db — Chicago Crimes"
download crime "https://data.cityofchicago.org/resource/ijzp-q8t2.csv" \
  "id,case_number,date,block,iucr,primary_type,description,location_description,arrest,domestic,beat,district,ward,community_area,fbi_code,year,latitude,longitude" \
  "id" "$CRIME_ROWS"

psql_run crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" <<'SQL'
TRUNCATE crime.incident_tags, crime.tags, crime.incident_geo, crime.incidents,
         crime.location_types, crime.crime_types, crime.beats,
         crime.district_stats, crime.districts
    RESTART IDENTITY CASCADE;
DROP TABLE IF EXISTS stage_crime;
CREATE UNLOGGED TABLE stage_crime (
    id text, case_number text, date text, block text, iucr text, primary_type text,
    description text, location_description text, arrest text, domestic text, beat text,
    district text, ward text, community_area text, fbi_code text, year text,
    latitude text, longitude text
);
SQL

echo "    COPY -> stage_crime"
psql_run crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" \
  -c "\copy stage_crime FROM STDIN WITH (FORMAT csv, HEADER true)" < "$RAW/crime.csv"

psql_run crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" <<'SQL'
INSERT INTO crime.districts (district_code)
SELECT DISTINCT NULLIF(district, '') FROM stage_crime
WHERE NULLIF(district, '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO crime.beats (beat_code, district_id)
SELECT DISTINCT ON (s.beat) s.beat, d.district_id
FROM stage_crime s
JOIN crime.districts d ON d.district_code = s.district
WHERE NULLIF(s.beat, '') IS NOT NULL
ORDER BY s.beat
ON CONFLICT DO NOTHING;

INSERT INTO crime.crime_types (iucr, primary_type, description, fbi_code)
SELECT DISTINCT ON (iucr) iucr, btrim(primary_type), description, fbi_code
FROM stage_crime
WHERE NULLIF(iucr, '') IS NOT NULL
ORDER BY iucr
ON CONFLICT DO NOTHING;

INSERT INTO crime.location_types (location_name)
SELECT DISTINCT NULLIF(location_description, '') FROM stage_crime
WHERE NULLIF(location_description, '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO crime.incidents
    (source_id, case_number, occurred_at, block, crime_type_id, beat_id,
     location_type_id, arrest, domestic, ward, community_area, year)
SELECT NULLIF(s.id,'')::bigint,
       s.case_number,
       NULLIF(s.date,'')::timestamp,
       s.block,
       ct.crime_type_id,
       b.beat_id,
       lt.location_type_id,
       NULLIF(s.arrest,'')::boolean,
       NULLIF(s.domestic,'')::boolean,
       NULLIF(s.ward,'')::int,
       NULLIF(s.community_area,'')::int,
       NULLIF(s.year,'')::int
FROM stage_crime s
JOIN crime.crime_types ct ON ct.iucr = s.iucr
LEFT JOIN crime.beats b          ON b.beat_code = s.beat
LEFT JOIN crime.location_types lt ON lt.location_name = NULLIF(s.location_description, '');

INSERT INTO crime.incident_geo (incident_id, latitude, longitude)
SELECT i.incident_id, NULLIF(s.latitude,'')::numeric, NULLIF(s.longitude,'')::numeric
FROM stage_crime s
JOIN crime.incidents i ON i.source_id = NULLIF(s.id,'')::bigint
WHERE NULLIF(s.latitude,'') IS NOT NULL;
DROP TABLE stage_crime;

INSERT INTO crime.district_stats (district_id, incidents_count, arrest_rate, domestic_rate)
SELECT d.district_id, count(*),
       round(avg(CASE WHEN i.arrest   THEN 1 ELSE 0 END)::numeric, 3),
       round(avg(CASE WHEN i.domestic THEN 1 ELSE 0 END)::numeric, 3)
FROM crime.incidents i
JOIN crime.beats b     ON b.beat_id = i.beat_id
JOIN crime.districts d ON d.district_id = b.district_id
GROUP BY d.district_id;

INSERT INTO crime.tags (tag_name) VALUES ('ARREST'), ('DOMESTIC'), ('NIGHT'), ('WEEKEND')
ON CONFLICT DO NOTHING;

INSERT INTO crime.incident_tags (incident_id, tag_id)
SELECT i.incident_id, t.tag_id FROM crime.incidents i, crime.tags t
WHERE (t.tag_name = 'ARREST'   AND i.arrest)
   OR (t.tag_name = 'DOMESTIC' AND i.domestic)
   OR (t.tag_name = 'NIGHT'    AND extract(hour FROM i.occurred_at) NOT BETWEEN 7 AND 19)
   OR (t.tag_name = 'WEEKEND'  AND extract(isodow FROM i.occurred_at) IN (6,7));

ANALYZE crime.incidents;
SQL
fi

if want taxi; then
echo "==> [3/3] taxi_db — Chicago Taxi Trips"
download taxi "https://data.cityofchicago.org/resource/wrvz-psew.csv" \
  "trip_id,trip_start_timestamp,trip_end_timestamp,trip_seconds,trip_miles,pickup_community_area,dropoff_community_area,fare,tips,tolls,extras,trip_total,payment_type,company" \
  ":id" "$TAXI_ROWS"

psql_run taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" <<'SQL'
TRUNCATE taxi.company_payment_types, taxi.trip_payments, taxi.trips,
         taxi.community_areas, taxi.payment_types,
         taxi.company_stats, taxi.companies
    RESTART IDENTITY CASCADE;
DROP TABLE IF EXISTS stage_taxi;
CREATE UNLOGGED TABLE stage_taxi (
    trip_id text, trip_start_timestamp text, trip_end_timestamp text, trip_seconds text,
    trip_miles text, pickup_community_area text, dropoff_community_area text, fare text,
    tips text, tolls text, extras text, trip_total text, payment_type text, company text
);
SQL

echo "    COPY -> stage_taxi"
psql_run taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" \
  -c "\copy stage_taxi FROM STDIN WITH (FORMAT csv, HEADER true)" < "$RAW/taxi.csv"

psql_run taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" <<'SQL'
INSERT INTO taxi.companies (company_name)
SELECT DISTINCT NULLIF(btrim(company), '') FROM stage_taxi
WHERE NULLIF(btrim(company), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO taxi.payment_types (payment_name)
SELECT DISTINCT NULLIF(btrim(payment_type), '') FROM stage_taxi
WHERE NULLIF(btrim(payment_type), '') IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO taxi.community_areas (area_code)
SELECT DISTINCT area FROM (
    SELECT NULLIF(pickup_community_area,'')::numeric::int  AS area FROM stage_taxi
    UNION
    SELECT NULLIF(dropoff_community_area,'')::numeric::int AS area FROM stage_taxi
) x
WHERE area IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO taxi.trips
    (trip_id, trip_start, trip_end, trip_seconds, trip_miles,
     company_id, payment_type_id, pickup_area_id, dropoff_area_id)
SELECT s.trip_id,
       NULLIF(s.trip_start_timestamp,'')::timestamp,
       NULLIF(s.trip_end_timestamp,'')::timestamp,
       NULLIF(s.trip_seconds,'')::numeric::int,
       NULLIF(s.trip_miles,'')::numeric,
       c.company_id,
       pt.payment_type_id,
       pa.area_id,
       da.area_id
FROM stage_taxi s
LEFT JOIN taxi.companies      c  ON c.company_name  = NULLIF(btrim(s.company), '')
LEFT JOIN taxi.payment_types  pt ON pt.payment_name = NULLIF(btrim(s.payment_type), '')
LEFT JOIN taxi.community_areas pa ON pa.area_code = NULLIF(s.pickup_community_area,'')::numeric::int
LEFT JOIN taxi.community_areas da ON da.area_code = NULLIF(s.dropoff_community_area,'')::numeric::int;

INSERT INTO taxi.trip_payments (trip_pk, fare, tips, tolls, extras, trip_total)
SELECT t.trip_pk,
       NULLIF(s.fare,'')::numeric, NULLIF(s.tips,'')::numeric, NULLIF(s.tolls,'')::numeric,
       NULLIF(s.extras,'')::numeric, NULLIF(s.trip_total,'')::numeric
FROM stage_taxi s
JOIN taxi.trips t ON t.trip_id = s.trip_id;
DROP TABLE stage_taxi;

INSERT INTO taxi.company_stats (company_id, trips_count, avg_total, avg_miles)
SELECT t.company_id, count(*), round(avg(tp.trip_total), 2), round(avg(t.trip_miles), 2)
FROM taxi.trips t
JOIN taxi.trip_payments tp ON tp.trip_pk = t.trip_pk
WHERE t.company_id IS NOT NULL
GROUP BY t.company_id;

INSERT INTO taxi.company_payment_types (company_id, payment_type_id, trips_count)
SELECT company_id, payment_type_id, count(*)
FROM taxi.trips
WHERE company_id IS NOT NULL AND payment_type_id IS NOT NULL
GROUP BY company_id, payment_type_id;

ANALYZE taxi.trips;
SQL
fi

echo
echo "==> Итог:"
"$ROOT/scripts/status.sh"