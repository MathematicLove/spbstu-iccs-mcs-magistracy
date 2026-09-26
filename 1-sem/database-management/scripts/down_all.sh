#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
else
  COMPOSE=(docker-compose)
fi

WIPE=""
[[ "${1:-}" == "--wipe" ]] && WIPE="-v"

for stack in information-schema databases/sales-db databases/crime-db databases/taxi-db \
             databases/new/extra_for_students databases/new/mountain_sport databases/new/sport_and_cheerleaders \
             templates-db; do
  echo "==> compose down $WIPE: $stack"
  "${COMPOSE[@]}" --env-file "$ROOT/credentials.env" -f "$ROOT/$stack/docker-compose.yml" down $WIPE
done