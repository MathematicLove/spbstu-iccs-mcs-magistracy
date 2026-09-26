#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a; source "$ROOT/credentials.env"; set +a
ok=0; fail=0
check() {
  if [[ "$2" == "$3" ]]; then printf '  ✅ %-46s %s\n' "$1" "$3"; ok=$((ok+1))
  else printf '  ❌ %-46s ожидалось %s, получено %s\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}
q() { docker exec -i "$1" psql -tAq -U "$2" -d "$3" -c "$4" 2>/dev/null | tr -d ' \n'; }

echo "══ 1. Colima и контейнеры ═════════════════════════════════════"
if colima status >/dev/null 2>&1; then echo "  ✅ Colima запущена"; else echo "  ❌ Colima не запущена"; fi
for c in sales_db crime_db taxi_db extra_db mountain_db sport_db meta_db templates_db; do
  check "контейнер $c" "healthy" "$(docker inspect -f '{{.State.Health.Status}}' "$c" 2>/dev/null || echo missing)"
done

echo
echo "══ 2. Изоляция: в каждой сети ровно один контейнер ════════════"
for n in sales_net crime_net taxi_net extra_net mountain_net sport_net meta_net templates_net; do
  printf '  %-14s -> %s\n' "$n" "$(docker network inspect "$n" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)"
done
docker exec sales_db getent hosts crime_db >/dev/null 2>&1 \
  && echo "  ❌ sales_db видит crime_db — изоляция нарушена" \
  || echo "  ✅ sales_db не видит crime_db (источники не общаются)"

echo
echo "══ 3. Объём данных ════════════════════════════════════════════"
check "sales.retail_sales"   "300000" "$(q sales_db "$SALES_DB_USER" "$SALES_DB_NAME" 'SELECT count(*) FROM sales.retail_sales')"
check "crime.incidents"      "250000" "$(q crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" 'SELECT count(*) FROM crime.incidents')"
check "taxi.trips"           "250000" "$(q taxi_db  "$TAXI_DB_USER"  "$TAXI_DB_NAME"  'SELECT count(*) FROM taxi.trips')"
check "sales.suppliers"      "395"    "$(q sales_db "$SALES_DB_USER" "$SALES_DB_NAME" 'SELECT count(*) FROM sales.suppliers')"
check "crime.districts"      "22"     "$(q crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" 'SELECT count(*) FROM crime.districts')"
check "taxi.companies"       "8"      "$(q taxi_db  "$TAXI_DB_USER"  "$TAXI_DB_NAME"  'SELECT count(*) FROM taxi.companies')"

echo
echo "══ 4. Главная БД и БД шаблонов: по одной таблице ══════════════"
check "таблиц в схеме meta" "1" "$(q meta_db "$META_DB_USER" "$META_DB_NAME" "SELECT count(*) FROM information_schema.tables WHERE table_schema='meta'")"
check "таблиц в схеме tpl" "1" "$(q templates_db "$TEMPLATES_DB_USER" "$TEMPLATES_DB_NAME" "SELECT count(*) FROM information_schema.tables WHERE table_schema='tpl'")"
check "колонок в meta.catalog" "13" "$(q meta_db "$META_DB_USER" "$META_DB_NAME" "SELECT count(*) FROM information_schema.columns WHERE table_schema='meta' AND table_name='catalog'")"
check "meta.catalog пока пуст (Этап 2)" "0" "$(q meta_db "$META_DB_USER" "$META_DB_NAME" 'SELECT count(*) FROM meta.catalog')"
check "tpl.form_templates существует" "0" "$(q templates_db "$TEMPLATES_DB_USER" "$TEMPLATES_DB_NAME" 'SELECT count(*) FROM tpl.form_templates')"

echo
echo "══ 5. Данные пригодны для графиков ════════════════════════════"
echo "  sales: категория × сумма продаж"
docker exec -i sales_db psql -U "$SALES_DB_USER" -d "$SALES_DB_NAME" -c \
  "SELECT item_type, count(*) AS n, round(sum(retail_sales),1) AS total FROM sales.retail_sales GROUP BY 1 ORDER BY 3 DESC NULLS LAST LIMIT 5"
echo "  crime: тип преступления × район (основа heatmap)"
docker exec -i crime_db psql -U "$CRIME_DB_USER" -d "$CRIME_DB_NAME" -c \
  "SELECT primary_type, count(DISTINCT district) AS districts, count(*) AS n FROM crime.incidents GROUP BY 1 ORDER BY 3 DESC LIMIT 5"
echo "  taxi: способ оплаты × средний чек"
docker exec -i taxi_db psql -U "$TAXI_DB_USER" -d "$TAXI_DB_NAME" -c \
  "SELECT payment_type, count(*) AS n, round(avg(trip_total),2) AS avg_total FROM taxi.trips GROUP BY 1 ORDER BY 2 DESC LIMIT 5"

echo
echo "══ Итог: успешно $ok, ошибок $fail ════════════════════════════"
[[ $fail -eq 0 ]]