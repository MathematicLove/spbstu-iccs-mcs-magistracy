import os
from contextlib import contextmanager

import psycopg2
import psycopg2.extras
import requests
from fastapi import FastAPI
from fastapi.responses import JSONResponse

DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ["DB_PORT"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

SOURCES = {
    "sales": {"internal_url": os.environ["SALES_URL"], "api_url": os.environ["SALES_API_URL"]},
    "crime": {"internal_url": os.environ["CRIME_URL"], "api_url": os.environ["CRIME_API_URL"]},
    "taxi":  {"internal_url": os.environ["TAXI_URL"],  "api_url": os.environ["TAXI_API_URL"]},
    "extra_for_students":     {"internal_url": os.environ["EXTRA_URL"],    "api_url": os.environ["EXTRA_API_URL"]},
    "mountain_sport":         {"internal_url": os.environ["MOUNTAIN_URL"], "api_url": os.environ["MOUNTAIN_API_URL"]},
    "sport_and_cheerleaders": {"internal_url": os.environ["SPORT_URL"],    "api_url": os.environ["SPORT_API_URL"]},
}

REQUEST_TIMEOUT = 8

app = FastAPI(title="meta-api")

COMPARE_FIELDS = ("ordinal_position", "data_type", "pk_key", "fk_key",
                   "ref_schema_name", "ref_table_name", "ref_column_name")

@contextmanager
def connect():
    conn = psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
        connect_timeout=5,
    )
    try:
        yield conn
    finally:
        conn.close()

def fetch_live_columns(source_id: str):
    cfg = SOURCES[source_id]
    resp = requests.get(f"{cfg['internal_url']}/metadata", timeout=REQUEST_TIMEOUT)
    resp.raise_for_status()
    live = {}
    for c in resp.json()["columns"]:
        key = (c["schema_name"], c["table_name"], c["column_name"])
        live[key] = c
    return live

def fetch_stored_columns(conn, source_id: str):
    with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
        cur.execute(
            "SELECT schema_name, table_name, column_name, ordinal_position, data_type, "
            "pk_key, fk_key, ref_schema_name, ref_table_name, ref_column_name "
            "FROM meta.catalog WHERE source_id = %s",
            (source_id,),
        )
        rows = cur.fetchall()
    return {(r["schema_name"], r["table_name"], r["column_name"]): r for r in rows}

def compute_diff(live: dict, stored: dict):
    added = sorted(live.keys() - stored.keys())
    removed = sorted(stored.keys() - live.keys())
    changed = []
    for key in sorted(live.keys() & stored.keys()):
        old, new = stored[key], live[key]
        if any(old[f] != new[f] for f in COMPARE_FIELDS):
            changed.append({
                "key": {"schema_name": key[0], "table_name": key[1], "column_name": key[2]},
                "old": {f: old[f] for f in COMPARE_FIELDS},
                "new": {f: new[f] for f in COMPARE_FIELDS},
            })
    return {
        "added": [{"schema_name": k[0], "table_name": k[1], "column_name": k[2], **live[k]} for k in added],
        "changed": changed,
        "removed": [{"schema_name": k[0], "table_name": k[1], "column_name": k[2]} for k in removed],
    }

def human_error(exc: Exception) -> str:
    if isinstance(exc, KeyError):
        return f"Unknown source_id {exc}. Expected one of: {', '.join(SOURCES)}."
    if isinstance(exc, (requests.exceptions.RequestException,)):
        return "Could not reach that source's agent."
    if isinstance(exc, psycopg2.OperationalError):
        return "The meta database is unreachable."
    return f"Request failed: {exc.__class__.__name__}."

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/catalog")
def get_catalog(source_id: str | None = None):
    try:
        with connect() as conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            if source_id:
                cur.execute("SELECT * FROM meta.catalog WHERE source_id = %s ORDER BY schema_name, table_name, ordinal_position", (source_id,))
            else:
                cur.execute("SELECT * FROM meta.catalog ORDER BY source_id, schema_name, table_name, ordinal_position")
            rows = cur.fetchall()
        return {"catalog": rows}
    except Exception as exc:
        return JSONResponse(status_code=502, content={"error": human_error(exc)})

@app.get("/diff")
def diff(source_id: str):
    try:
        if source_id not in SOURCES:
            raise KeyError(source_id)
        live = fetch_live_columns(source_id)
        with connect() as conn:
            stored = fetch_stored_columns(conn, source_id)
        d = compute_diff(live, stored)
        d["source_id"] = source_id
        d["up_to_date"] = not (d["added"] or d["changed"] or d["removed"])
        return d
    except Exception as exc:
        return JSONResponse(status_code=502, content={"error": human_error(exc)})

@app.post("/sync")
def sync(source_id: str):
    try:
        if source_id not in SOURCES:
            raise KeyError(source_id)
        live = fetch_live_columns(source_id)
        api_url = SOURCES[source_id]["api_url"]

        with connect() as conn:
            stored = fetch_stored_columns(conn, source_id)
            result = compute_diff(live, stored)

            with conn.cursor() as cur:
                for key in [(r["schema_name"], r["table_name"], r["column_name"]) for r in result["removed"]]:
                    cur.execute(
                        "DELETE FROM meta.catalog WHERE source_id=%s AND schema_name=%s AND table_name=%s AND column_name=%s",
                        (source_id, *key),
                    )
                for key, c in live.items():
                    cur.execute(
                        """
                        INSERT INTO meta.catalog
                            (source_id, schema_name, table_name, column_name, api_url,
                             ordinal_position, data_type, pk_key, fk_key,
                             ref_schema_name, ref_table_name, ref_column_name, synced_at)
                        VALUES (%(source_id)s, %(schema_name)s, %(table_name)s, %(column_name)s, %(api_url)s,
                                %(ordinal_position)s, %(data_type)s, %(pk_key)s, %(fk_key)s,
                                %(ref_schema_name)s, %(ref_table_name)s, %(ref_column_name)s, now())
                        ON CONFLICT (source_id, schema_name, table_name, column_name) DO UPDATE SET
                            api_url = EXCLUDED.api_url,
                            ordinal_position = EXCLUDED.ordinal_position,
                            data_type = EXCLUDED.data_type,
                            pk_key = EXCLUDED.pk_key,
                            fk_key = EXCLUDED.fk_key,
                            ref_schema_name = EXCLUDED.ref_schema_name,
                            ref_table_name = EXCLUDED.ref_table_name,
                            ref_column_name = EXCLUDED.ref_column_name,
                            synced_at = now()
                        """,
                        {
                            "source_id": source_id, "schema_name": key[0], "table_name": key[1],
                            "column_name": key[2], "api_url": api_url,
                            "ordinal_position": c["ordinal_position"], "data_type": c["data_type"],
                            "pk_key": c["pk_key"], "fk_key": c["fk_key"],
                            "ref_schema_name": c["ref_schema_name"], "ref_table_name": c["ref_table_name"],
                            "ref_column_name": c["ref_column_name"],
                        },
                    )
            conn.commit()

        result["source_id"] = source_id
        result["up_to_date"] = False
        return result
    except Exception as exc:
        return JSONResponse(status_code=502, content={"error": human_error(exc)})