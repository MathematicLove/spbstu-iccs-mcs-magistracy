#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; source "$ROOT/credentials.env"; set +a

VENV="$ROOT/.venv"
PIDFILE="$ROOT/.interface.pid"
LOGFILE="$ROOT/.interface.log"

"$ROOT/scripts/stop_interface.sh" >/dev/null 2>&1 || true

if [[ ! -x "$VENV/bin/streamlit" ]]; then
  echo "==> Создаю .venv и ставлю зависимости интерфейса (один раз, минуту-другую)..."
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install --quiet --disable-pip-version-check -r "$ROOT/interface/requirements.txt"
else
  "$VENV/bin/pip" install --quiet --disable-pip-version-check -r "$ROOT/interface/requirements.txt"
fi

echo "==> Запускаю интерфейс на http://localhost:$INTERFACE_PORT ..."
nohup "$VENV/bin/streamlit" run "$ROOT/interface/app.py" \
  --server.port "$INTERFACE_PORT" --server.headless true \
  > "$LOGFILE" 2>&1 &
echo $! > "$PIDFILE"

for _ in $(seq 1 30); do
  if curl -sf -o /dev/null "http://localhost:$INTERFACE_PORT"; then
    echo "==> Интерфейс готов: http://localhost:$INTERFACE_PORT"
    exit 0
  fi
  sleep 1
done

echo "==> Интерфейс не ответил за 30с — смотри $LOGFILE"
exit 1