#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; source "$ROOT/credentials.env"; set +a

count() { docker exec -i "$1" psql -tAq -U "$2" -d "$3" -c "$4" 2>/dev/null | tr -d ' \n'; }

sales_rows="$(count sales_db "$SALES_DB_USER" "$SALES_DB_NAME" 'SELECT count(*) FROM sales.sales_facts')"
crime_rows="$(count crime_db "$CRIME_DB_USER" "$CRIME_DB_NAME" 'SELECT count(*) FROM crime.incidents')"
taxi_rows="$(count taxi_db  "$TAXI_DB_USER"  "$TAXI_DB_NAME"  'SELECT count(*) FROM taxi.trips')"

if [[ "${sales_rows:-0}" -gt 0 && "${crime_rows:-0}" -gt 0 && "${taxi_rows:-0}" -gt 0 ]]; then
  echo "==> Данные источников уже загружены (sales=$sales_rows, crime=$crime_rows, taxi=$taxi_rows) — пропускаю load"
else
  echo "==> Данных нет или неполные (sales=${sales_rows:-0}, crime=${crime_rows:-0}, taxi=${taxi_rows:-0}) — запускаю load"
  "$ROOT/scripts/load_data.sh"
fi

# новые источники генерируются скриптом databases/new/fill (seed фиксирован)
extra_rows="$(count extra_db "$EXTRA_DB_USER" "$EXTRA_DB_NAME" 'SELECT count(*) FROM extra_for_students.lesson')"
mountain_rows="$(count mountain_db "$MOUNTAIN_DB_USER" "$MOUNTAIN_DB_NAME" 'SELECT count(*) FROM mountain_sport.result')"
sport_rows="$(count sport_db "$SPORT_DB_USER" "$SPORT_DB_NAME" 'SELECT count(*) FROM sport_and_cheerleaders.sportsman_perfomance')"

todo=()
[[ "${extra_rows:-0}" -gt 0 ]]    || todo+=(extra)
[[ "${mountain_rows:-0}" -gt 0 ]] || todo+=(mountain)
[[ "${sport_rows:-0}" -gt 0 ]]    || todo+=(sport)

if (( ${#todo[@]} == 0 )); then
  echo "==> Сгенерированные источники уже заполнены (extra=$extra_rows, mountain=$mountain_rows, sport=$sport_rows) — пропускаю"
else
  VENV="$ROOT/.venv"
  [[ -x "$VENV/bin/python" ]] || python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet --disable-pip-version-check "psycopg[binary]"
  echo "==> Заполняю: ${todo[*]}"
  "$VENV/bin/python" "$ROOT/databases/new/fill/fill_data.py" "${todo[@]}"
fi
