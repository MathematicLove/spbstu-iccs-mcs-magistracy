#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIDFILE="$ROOT/.interface.pid"

if [[ -f "$PIDFILE" ]]; then
  pid="$(cat "$PIDFILE")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null
    echo "==> Интерфейс (PID $pid) остановлен"
  fi
  rm -f "$PIDFILE"
fi

set -a; source "$ROOT/credentials.env" 2>/dev/null; set +a
port="${INTERFACE_PORT:-8501}"
leftover="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
[[ -n "$leftover" ]] && kill $leftover 2>/dev/null || true