#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a; source "$ROOT/credentials.env"; set +a

echo "── Контейнеры ───────────────────────────────────────────────"
docker ps --filter "name=_db" --filter "name=_api" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

count() { docker exec -i "$1" psql -tAq -U "$2" -d "$3" -c "$4" 2>/dev/null || echo "нет связи"; }
row() { printf '%-32s %s\n' "$1" "$(count "$2" "$3" "$4" "SELECT count(*) FROM $5")"; }

echo
echo "── sales_db ─────────────────────────────────────────────────"
row sales.item_types           sales_db "$SALES_DB_USER" "$SALES_DB_NAME" sales.item_types
row sales.suppliers            sales_db "$SALES_DB_USER" "$SALES_DB_NAME" sales.suppliers
row sales.supplier_profiles    sales_db "$SALES_DB_USER" "$SALES_DB_NAME" sales.supplier_profiles
row sales.items                sales_db "$SALES_DB_USER" "$SALES_DB_NAME" sales.items
row sales.periods              sales_db "$SALES_DB_USER" "$SALES_DB_NAME" sales.periods
row sales.sales_facts          sales_db "$SALES_DB_USER" "$SALES_DB_NAME" sales.sales_facts
row sales.supplier_item_types  sales_db "$SALES_DB_USER" "$SALES_DB_NAME" sales.supplier_item_types

echo
echo "── crime_db ─────────────────────────────────────────────────"
row crime.districts       crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.districts
row crime.district_stats  crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.district_stats
row crime.beats           crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.beats
row crime.crime_types     crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.crime_types
row crime.location_types  crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.location_types
row crime.incidents       crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.incidents
row crime.incident_geo    crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.incident_geo
row crime.tags            crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.tags
row crime.incident_tags   crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" crime.incident_tags

echo
echo "── taxi_db ──────────────────────────────────────────────────"
row taxi.companies              taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" taxi.companies
row taxi.company_stats          taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" taxi.company_stats
row taxi.payment_types          taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" taxi.payment_types
row taxi.community_areas        taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" taxi.community_areas
row taxi.trips                  taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" taxi.trips
row taxi.trip_payments          taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" taxi.trip_payments
row taxi.company_payment_types  taxi_db "$TAXI_DB_USER" "$TAXI_DB_NAME" taxi.company_payment_types

echo
echo "── extra_db ─────────────────────────────────────────────────"
for t in $(docker exec -i extra_db psql -tAq -U "$EXTRA_DB_USER" -d "$EXTRA_DB_NAME" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'extra_for_students' ORDER BY tablename" 2>/dev/null); do
  row "extra_for_students.$t" extra_db "$EXTRA_DB_USER" "$EXTRA_DB_NAME" "extra_for_students.$t"
done

echo
echo "── mountain_db ─────────────────────────────────────────────────"
for t in $(docker exec -i mountain_db psql -tAq -U "$MOUNTAIN_DB_USER" -d "$MOUNTAIN_DB_NAME" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'mountain_sport' ORDER BY tablename" 2>/dev/null); do
  row "mountain_sport.$t" mountain_db "$MOUNTAIN_DB_USER" "$MOUNTAIN_DB_NAME" "mountain_sport.$t"
done

echo
echo "── sport_db ─────────────────────────────────────────────────"
for t in $(docker exec -i sport_db psql -tAq -U "$SPORT_DB_USER" -d "$SPORT_DB_NAME" -c "SELECT tablename FROM pg_tables WHERE schemaname = 'sport_and_cheerleaders' ORDER BY tablename" 2>/dev/null); do
  row "sport_and_cheerleaders.$t" sport_db "$SPORT_DB_USER" "$SPORT_DB_NAME" "sport_and_cheerleaders.$t"
done

echo
echo "── meta_db / templates_db ──────────────────────────────────────"
row meta.catalog        meta_db      "$META_DB_USER"      "$META_DB_NAME"      meta.catalog
row tpl.form_templates  templates_db "$TEMPLATES_DB_USER" "$TEMPLATES_DB_NAME" tpl.form_templates