#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a; source "$ROOT/credentials.env"; set +a

echo "==> Синхронизирую meta.catalog..."
for src in sales crime taxi extra_for_students mountain_sport sport_and_cheerleaders; do
  result="$(curl -sf -X POST "http://localhost:$META_API_PORT/sync?source_id=$src" 2>/dev/null)"
  if [[ -z "$result" ]]; then
    echo "    $src: meta-agent недоступен на localhost:$META_API_PORT"
    continue
  fi
  echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'error' in d:
    print('    $src: ERROR', d['error'])
else:
    print(f\"    $src: +{len(d['added'])} added, ~{len(d['changed'])} changed, -{len(d['removed'])} removed\")
"
done