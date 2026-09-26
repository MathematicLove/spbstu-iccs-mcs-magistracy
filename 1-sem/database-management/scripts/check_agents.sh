#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; source "$ROOT/credentials.env"; set +a

ok=0; fail=0
check() {
  if [[ "$2" == "1" ]]; then printf '  OK   %-55s\n' "$1"; ok=$((ok+1))
  else printf '  FAIL %-55s\n' "$1"; fail=$((fail+1)); fi
}

for src in SALES:8001:sales.sales_facts CRIME:8002:crime.incidents TAXI:8003:taxi.trips \
           EXTRA:8006:extra_for_students.lesson MOUNTAIN:8007:mountain_sport.result \
           SPORT:8008:sport_and_cheerleaders.perfomance; do
  NAME="${src%%:*}"; rest="${src#*:}"; PORT="${rest%%:*}"; TABLE="${rest#*:}"
  echo "== $NAME (localhost:$PORT) =========================================="

  check "$NAME /health отвечает" \
    "$([[ "$(curl -sf http://localhost:$PORT/health 2>/dev/null | grep -c '\"status\":\"ok\"')" == "1" ]] && echo 1 || echo 0)"

  n_cols="$(curl -sf http://localhost:$PORT/metadata 2>/dev/null | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["columns"]))' 2>/dev/null || echo 0)"
  check "$NAME /metadata отдаёт колонки (получено $n_cols)" \
    "$([[ "$n_cols" -gt 0 ]] && echo 1 || echo 0)"

  q_ok="$(curl -sf -X POST http://localhost:$PORT/query -H 'Content-Type: application/json' \
    -d "{\"sql_text\": \"SELECT count(*) FROM $TABLE\"}" 2>/dev/null | grep -c '\"rows\"')"
  check "$NAME /query выполняет SELECT" "$([[ "$q_ok" == "1" ]] && echo 1 || echo 0)"

  del_blocked="$(curl -s -X POST http://localhost:$PORT/query -H 'Content-Type: application/json' \
    -d "{\"sql_text\": \"DELETE FROM $TABLE\"}" 2>/dev/null | grep -c '\"error\"')"
  check "$NAME отклоняет не-SELECT" "$([[ "$del_blocked" == "1" ]] && echo 1 || echo 0)"

  inj_blocked="$(curl -s -X POST http://localhost:$PORT/query -H 'Content-Type: application/json' \
    -d '{"sql_text": "SELECT 1; SELECT 2;"}' 2>/dev/null | grep -c '\"error\"')"
  check "$NAME отклоняет составной запрос (;)" "$([[ "$inj_blocked" == "1" ]] && echo 1 || echo 0)"
  echo
done

echo "== TEMPLATES (localhost:$TEMPLATES_API_PORT) =================================="

check "TEMPLATES /health отвечает" \
  "$([[ "$(curl -sf http://localhost:$TEMPLATES_API_PORT/health 2>/dev/null | grep -c '\"status\":\"ok\"')" == "1" ]] && echo 1 || echo 0)"

created="$(curl -sf -X POST http://localhost:$TEMPLATES_API_PORT/templates -H 'Content-Type: application/json' -d \
  '{"sql_text":"SELECT payment_type_id, AVG(trip_miles) AS trip_miles FROM taxi.trips GROUP BY payment_type_id",
    "source_id":"taxi","schema_name":"taxi","table_name":"trips","chart_type":"barplot",
    "dimension_col":"payment_type_id","measure_col":"trip_miles","agg_func":"AVG"}' 2>/dev/null)"
tpl_id="$(echo "$created" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("template_id",""))' 2>/dev/null)"
tpl_name="$(echo "$created" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("template_name",""))' 2>/dev/null)"
check "TEMPLATES /templates создаёт с авто-именем (получено '$tpl_name')" \
  "$([[ -n "$tpl_id" && "$tpl_name" == template_* ]] && echo 1 || echo 0)"

listed="$(curl -sf http://localhost:$TEMPLATES_API_PORT/templates 2>/dev/null | grep -c "\"template_id\":$tpl_id")"
check "TEMPLATES /templates отдаёт созданный шаблон в списке" "$([[ "$listed" == "1" ]] && echo 1 || echo 0)"

used="$(curl -sf -X POST http://localhost:$TEMPLATES_API_PORT/templates/$tpl_id/use 2>/dev/null | grep -c '\"used_count\":1')"
check "TEMPLATES /templates/{id}/use увеличивает used_count" "$([[ "$used" == "1" ]] && echo 1 || echo 0)"

bad="$(curl -s -X POST http://localhost:$TEMPLATES_API_PORT/templates -H 'Content-Type: application/json' -d \
  '{"sql_text":"DELETE FROM taxi.trips","source_id":"taxi","schema_name":"taxi","table_name":"trips",
    "chart_type":"barplot","dimension_col":"x"}' 2>/dev/null | grep -c '\"error\"')"
check "TEMPLATES отклоняет не-SELECT sql_text" "$([[ "$bad" == "1" ]] && echo 1 || echo 0)"

if [[ -n "$tpl_id" ]]; then
  docker exec templates_db psql -tA -U "$TEMPLATES_DB_USER" -d "$TEMPLATES_DB_NAME" \
    -c "DELETE FROM tpl.form_templates WHERE template_id=$tpl_id" >/dev/null 2>&1
fi

echo
echo "== META (localhost:$META_API_PORT) =================================="

check "META /health отвечает" \
  "$([[ "$(curl -sf http://localhost:$META_API_PORT/health 2>/dev/null | grep -c '\"status\":\"ok\"')" == "1" ]] && echo 1 || echo 0)"

n_cat="$(curl -sf http://localhost:$META_API_PORT/catalog 2>/dev/null | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["catalog"]))' 2>/dev/null || echo 0)"
check "META /catalog отдаёт строки (получено $n_cat)" "$([[ "$n_cat" -gt 0 ]] && echo 1 || echo 0)"

before="$(curl -sf "http://localhost:$META_API_PORT/diff?source_id=taxi" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["up_to_date"])' 2>/dev/null)"
check "META /diff?source_id=taxi: up to date до дрейфа (получено '$before')" "$([[ "$before" == "True" ]] && echo 1 || echo 0)"

docker exec taxi_db psql -U "$TAXI_DB_USER" -d "$TAXI_DB_NAME" -c "ALTER TABLE taxi.trips ADD COLUMN check_agents_drift INTEGER" >/dev/null 2>&1
after_add="$(curl -sf "http://localhost:$META_API_PORT/diff?source_id=taxi" 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d["added"]))' 2>/dev/null)"
check "META /diff видит добавленную колонку (added=$after_add)" "$([[ "$after_add" == "1" ]] && echo 1 || echo 0)"

sync_added="$(curl -sf -X POST "http://localhost:$META_API_PORT/sync?source_id=taxi" 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d["added"]))' 2>/dev/null)"
check "META /sync применяет добавление (added=$sync_added)" "$([[ "$sync_added" == "1" ]] && echo 1 || echo 0)"

after_sync="$(curl -sf "http://localhost:$META_API_PORT/diff?source_id=taxi" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["up_to_date"])' 2>/dev/null)"
check "META up to date после sync (получено '$after_sync')" "$([[ "$after_sync" == "True" ]] && echo 1 || echo 0)"

docker exec taxi_db psql -U "$TAXI_DB_USER" -d "$TAXI_DB_NAME" -c "ALTER TABLE taxi.trips DROP COLUMN check_agents_drift" >/dev/null 2>&1
curl -sf -X POST "http://localhost:$META_API_PORT/sync?source_id=taxi" >/dev/null 2>&1
final="$(curl -sf "http://localhost:$META_API_PORT/diff?source_id=taxi" 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["up_to_date"])' 2>/dev/null)"
check "META up to date после отката (получено '$final')" "$([[ "$final" == "True" ]] && echo 1 || echo 0)"

echo
echo "== Итог: успешно $ok, ошибок $fail =================================="
[[ $fail -eq 0 ]]