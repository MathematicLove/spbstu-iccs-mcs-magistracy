import os
from contextlib import contextmanager
from typing import Optional

import psycopg2
import psycopg2.errors
import psycopg2.extras
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel

DB_HOST = os.environ["DB_HOST"]
DB_PORT = os.environ["DB_PORT"]
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

app = FastAPI(title="templates-api")

COLUMNS = (
    "template_id, template_name, sql_text, source_id, schema_name, table_name, "
    "chart_type, dimension_col, measure_col, second_dim_col, agg_func, "
    "filter_summary, row_limit, created_at, used_count, last_used_at"
)

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
    if isinstance(exc, psycopg2.errors.UniqueViolation):
        return "A template with that name already exists."
    if isinstance(exc, psycopg2.errors.CheckViolation):
        return "This template's data does not pass validation (see sql_text/chart_type/agg_func)."
    if isinstance(exc, psycopg2.errors.NotNullViolation):
        return "A required field is missing."
    if isinstance(exc, psycopg2.OperationalError):
        return "The templates database is unreachable."
    return f"Request failed: {exc.__class__.__name__}."

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/templates")
def list_templates():
    try:
        with connect() as conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(f"SELECT {COLUMNS} FROM tpl.form_templates ORDER BY template_id")
            rows = cur.fetchall()
        return {"templates": rows}
    except Exception as exc:
        return JSONResponse(status_code=502, content={"error": human_error(exc)})

class TemplateCreate(BaseModel):
    sql_text: str
    source_id: str
    schema_name: str
    table_name: str
    chart_type: str
    dimension_col: str
    measure_col: Optional[str] = None
    second_dim_col: Optional[str] = None
    agg_func: Optional[str] = None
    filter_summary: Optional[str] = None
    row_limit: Optional[int] = None
    template_name: Optional[str] = None

@app.post("/templates")
def create_template(t: TemplateCreate):
    try:
        with connect() as conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                f"""
                INSERT INTO tpl.form_templates
                    (template_name, sql_text, source_id, schema_name, table_name,
                     chart_type, dimension_col, measure_col, second_dim_col,
                     agg_func, filter_summary, row_limit)
                VALUES (%(template_name)s, %(sql_text)s, %(source_id)s, %(schema_name)s,
                        %(table_name)s, %(chart_type)s, %(dimension_col)s, %(measure_col)s,
                        %(second_dim_col)s, %(agg_func)s, %(filter_summary)s, %(row_limit)s)
                RETURNING {COLUMNS}
                """,
                t.model_dump(),
            )
            row = cur.fetchone()
            conn.commit()
        return row
    except Exception as exc:
        return JSONResponse(status_code=400, content={"error": human_error(exc)})

@app.post("/templates/{template_id}/use")
def use_template(template_id: int):
    try:
        with connect() as conn, conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                f"""
                UPDATE tpl.form_templates
                SET used_count = used_count + 1, last_used_at = now()
                WHERE template_id = %s
                RETURNING {COLUMNS}
                """,
                (template_id,),
            )
            row = cur.fetchone()
            conn.commit()
        if row is None:
            return JSONResponse(status_code=404, content={"error": "No such template."})
        return row
    except Exception as exc:
        return JSONResponse(status_code=400, content={"error": human_error(exc)})

@app.delete("/templates/{template_id}")
def delete_template(template_id: int):
    try:
        with connect() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM tpl.form_templates WHERE template_id = %s", (template_id,))
            deleted = cur.rowcount
            conn.commit()
        if not deleted:
            return JSONResponse(status_code=404, content={"error": "No such template."})
        return {"status": "ok", "template_id": template_id}
    except Exception as exc:
        return JSONResponse(status_code=400, content={"error": human_error(exc)})