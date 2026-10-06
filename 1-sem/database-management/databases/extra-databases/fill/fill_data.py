"""Заполнение extra_for_students, mountain_sport, sport_and_cheerleaders согласованными случайными данными.

Запуск: .venv/bin/python databases/new/fill/fill_data.py [extra|mountain|sport ...]
Подключение берётся из credentials.env (EXTRA_DB_*, MOUNTAIN_DB_*, SPORT_DB_*).
Повторный запуск очищает схему и заполняет заново (seed фиксирован, результат тот же).
"""
import sys
import time

import fill_extra
import fill_mountain
import fill_sport
from common import connect, reset_sequences, truncate_schema

TARGETS = {
    "extra": ("EXTRA", fill_extra),
    "mountain": ("MOUNTAIN", fill_mountain),
    "sport": ("SPORT", fill_sport),
}

def run(name):
    prefix, module = TARGETS[name]
    started = time.time()
    print(f"==> {module.S}")
    with connect(prefix) as conn, conn.cursor() as cur:
        truncate_schema(cur, module.S)
        module.fill(cur)
        reset_sequences(cur, module.S)
        conn.commit()
        cur.execute(f"""
            SELECT sum(cnt) FROM (
                {' UNION ALL '.join(f"SELECT count(*) AS cnt FROM {module.S}.{t}" for t in tables(cur, module.S))}
            ) x""")
        total = cur.fetchone()[0]
    print(f"    {'ИТОГО':<45} {total:>8}   ({time.time() - started:.0f} c)\n")

def tables(cur, schema):
    cur.execute("SELECT tablename FROM pg_tables WHERE schemaname = %s ORDER BY tablename", (schema,))
    return [t for (t,) in cur.fetchall()]

if __name__ == "__main__":
    names = sys.argv[1:] or list(TARGETS)
    for n in names:
        if n not in TARGETS:
            raise SystemExit(f"неизвестная БД {n}; допустимо: {', '.join(TARGETS)}")
    for n in names:
        run(n)
