#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

render() {
  local dir="$1" name="$2" title="$3"
  local mmd="$ROOT/$dir/$name.mmd" html="$ROOT/$dir/$name.html"
  local diagram
  diagram="$(cat "$mmd")"

  {
    cat <<HTML
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<title>$title — ER-схема</title>
<style>
  body { font-family: system-ui, sans-serif; background: #0d1117; color: #e6edf3; margin: 0; padding: 24px; }
  h1 { font-size: 18px; font-weight: 600; margin: 0 0 16px; }
  .legend { font-size: 13px; color: #9da7b3; margin-bottom: 20px; line-height: 1.6; }
  .legend code { background: #161b22; padding: 1px 6px; border-radius: 4px; }
</style>
</head>
<body>
  <h1>$title — ER-схема (связи 1-N, N-1, 1-1, N-N)</h1>
  <div class="legend">
    <code>||--||</code> связь 1-1 &nbsp;·&nbsp;
    <code>||--o{</code> связь 1-N / N-1 &nbsp;·&nbsp;
    N-N показана как две связи 1-N через таблицу-справочник (junction table)
  </div>
  <pre class="mermaid" id="diagram">
HTML
    printf '%s\n' "$diagram"
    cat <<'HTML'
  </pre>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10.9.1/dist/mermaid.min.js"></script>
  <script>
    mermaid.initialize({ startOnLoad: true, theme: 'dark' });
  </script>
</body>
</html>
HTML
  } > "$html"
  echo "  ok: $dir/$name.html"
}

render sales-db sales-db "sales_db"
render crime-db crime-db "crime_db"
render taxi-db  taxi-db  "taxi_db"