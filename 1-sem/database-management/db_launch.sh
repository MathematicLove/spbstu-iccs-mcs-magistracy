#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  up)
    "$ROOT/scripts/up_all.sh"
    "$ROOT/scripts/ensure_data.sh"
    "$ROOT/scripts/sync_meta.sh"
    "$ROOT/scripts/run_interface.sh"
    ;;
  load)   "$ROOT/scripts/load_data.sh" ;;
  sync)   "$ROOT/scripts/sync_meta.sh" ;;
  status) "$ROOT/scripts/status.sh" ;;
  down)
    "$ROOT/scripts/stop_interface.sh"
    "$ROOT/scripts/down_all.sh"
    ;;
  reset)
    "$ROOT/scripts/stop_interface.sh"
    "$ROOT/scripts/down_all.sh" --wipe
    ;;
  *)      echo "usage: $0 {up|load|sync|status|down|reset}"; exit 1 ;;
esac