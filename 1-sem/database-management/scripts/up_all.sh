#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STACKS=(
  "databases/sales-db"
  "databases/crime-db"
  "databases/taxi-db"
  "databases/new/extra_for_students"
  "databases/new/mountain_sport"
  "databases/new/sport_and_cheerleaders"
  "information-schema"
  "templates-db"
)

CONTAINERS=(sales_db crime_db taxi_db extra_db mountain_db sport_db meta_db templates_db
            sales_api crime_api taxi_api extra_api mountain_api sport_api templates_api meta_api)

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
else
  COMPOSE=(docker-compose)
fi

if ! colima status >/dev/null 2>&1; then
  echo "==> Запускаю Colima..."
  colima start --cpu 4 --memory 6 --disk 60
else
  echo "==> Colima уже запущена"
fi

for stack in "${STACKS[@]}"; do
  echo "==> docker compose up: $stack"
  "${COMPOSE[@]}" --env-file "$ROOT/credentials.env" -f "$ROOT/$stack/docker-compose.yml" up -d --build
done

echo "==> Жду готовности контейнеров..."
for c in "${CONTAINERS[@]}"; do
  for _ in $(seq 1 60); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$c" 2>/dev/null || echo missing)"
    [[ "$status" == "healthy" ]] && break
    sleep 2
  done
  printf '    %-14s %s\n' "$c" "$(docker inspect -f '{{.State.Health.Status}}' "$c" 2>/dev/null || echo missing)"
done

echo
docker ps --filter "name=_db" --filter "name=_api" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'