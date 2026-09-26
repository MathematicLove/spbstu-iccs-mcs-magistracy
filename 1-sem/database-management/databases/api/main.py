import os
from pathlib import Path
from contextlib import contextmanager

import psycopg2
import psycopg2.errors
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel

SOURCE_ID = os.environ["SOURCE_ID"]
DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ["DB_PORT"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

MAX_ROWS_WITHOUT_LIMIT = 5000

METADATA_QUERY = (Path(__file__).parent / "metadata_query.sql").read_text(encoding="utf-8")

app = FastAPI(title=f"{SOURCE_ID}-api")

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

def human_error(exc: Exception) -> str:
    if isinstance(exc, psycopg2.errors.UndefinedTable):
        return "That table does not exist."
    if isinstance(exc, psycopg2.errors.UndefinedColumn):
        return "That column does not exist."
    if isinstance(exc, psycopg2.errors.SyntaxError):
        return "SQL syntax error in the query."
    if isinstance(exc, psycopg2.errors.InsufficientPrivilege):
        return "Not enough privileges to run this query."
    if isinstance(exc, psycopg2.OperationalError):
        return f"Source {SOURCE_ID} is unreachable: could not connect to the database."
    return f"Query failed: {exc.__class__.__name__}."

@app.get("/health")
def health():
    return {"status": "ok", "source_id": SOURCE_ID}

@app.get("/metadata")
def metadata():
    try:
        with connect() as conn, conn.cursor() as cur:
            cur.execute(METADATA_QUERY)
            cols = [d[0] for d in cur.description]
            rows = [dict(zip(cols, row)) for row in cur.fetchall()]
        return {"source_id": SOURCE_ID, "columns": rows}
    except Exception as exc:
        return JSONResponse(status_code=502, content={"error": human_error(exc)})

class QueryRequest(BaseModel):
    sql_text: str

def is_single_select(sql: str) -> bool:
    body = sql.strip()
    if body.endswith(";"):
        body = body[:-1].strip()
    if ";" in body:
        return False
    return body.upper().startswith("SELECT") or body.upper().startswith("WITH")

@app.post("/query")
def query(req: QueryRequest):
    sql = req.sql_text.strip()
    if not sql:
        return JSONResponse(status_code=400, content={"error": "Empty SQL query."})
    if not is_single_select(sql):
        return JSONResponse(
            status_code=400,
            content={"error": "Only a single SELECT statement is allowed, no extra statements."},
        )

    sql_to_run = sql[:-1] if sql.endswith(";") else sql
    if "limit" not in sql_to_run.lower():
        sql_to_run = f"{sql_to_run}\nLIMIT {MAX_ROWS_WITHOUT_LIMIT}"

    try:
        with connect() as conn, conn.cursor() as cur:
            cur.execute(sql_to_run)
            columns = [d[0] for d in cur.description]
            rows = cur.fetchall()
        return {"columns": columns, "rows": rows}
    except Exception as exc:
        return JSONResponse(status_code=400, content={"error": human_error(exc)})