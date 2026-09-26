import os
from pathlib import Path
from typing import Optional

import pandas as pd
import requests
import streamlit as st

NUMERIC_TYPES = {"smallint", "integer", "bigint", "numeric", "real", "double precision"}

MAIN_TABLE = {"sales": "sales_facts", "crime": "incidents", "taxi": "trips",
              "extra_for_students": "lesson", "mountain_sport": "result",
              "sport_and_cheerleaders": "perfomance"}

REQUEST_TIMEOUT = 8

class BackendError(Exception):
    pass

def _credentials_env_path():
    return Path(__file__).resolve().parents[2] / "credentials.env"

def _load_env_values(wanted):
    found = {}

    path = _credentials_env_path()
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.split("#", 1)[0].strip()
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            key, value = key.strip(), value.strip()
            if key in wanted:
                found[key] = value

    for key in wanted:
        if os.environ.get(key):
            found[key] = os.environ[key]

    missing = wanted - found.keys()
    if missing:
        raise BackendError(
            f"Missing value(s) in credentials.env: {', '.join(sorted(missing))}"
        )
    return found

SOURCE_ENV = {
    "sales": "SALES_API_URL",
    "crime": "CRIME_API_URL",
    "taxi": "TAXI_API_URL",
    "extra_for_students": "EXTRA_API_URL",
    "mountain_sport": "MOUNTAIN_API_URL",
    "sport_and_cheerleaders": "SPORT_API_URL",
}

def _load_api_urls():
    found = _load_env_values(set(SOURCE_ENV.values()))
    return {source_id: found[env] for source_id, env in SOURCE_ENV.items()}

API_URLS = _load_api_urls()
TEMPLATES_API_URL = _load_env_values({"TEMPLATES_API_URL"})["TEMPLATES_API_URL"]
META_API_URL = _load_env_values({"META_API_URL"})["META_API_URL"]

def all_sources():
    return list(API_URLS.keys())

@st.cache_data(ttl=60, show_spinner="Loading schema from source agents...")
def _fetch_metadata(source_id: str):
    url = f"{API_URLS[source_id]}/metadata"
    try:
        resp = requests.get(url, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Source {source_id} is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(f"Source {source_id} metadata request failed (HTTP {resp.status_code}).")
    return resp.json()["columns"]

def get_catalog():
    rows, errors = [], []
    for source_id in all_sources():
        try:
            for c in _fetch_metadata(source_id):
                rows.append((source_id, c["schema_name"], c["table_name"], c["column_name"],
                             c["data_type"], c["pk_key"], c["fk_key"]))
        except BackendError as exc:
            errors.append(str(exc))
    return rows, errors

def tables_for(source_id, catalog):
    names = sorted({r[2] for r in catalog if r[0] == source_id})
    main = MAIN_TABLE.get(source_id)
    if main in names:
        names.remove(main)
        names.insert(0, main)
    return names

def columns_for(catalog, source_id=None, table_name=None):
    rows = catalog
    if source_id:
        rows = [r for r in rows if r[0] == source_id]
        if table_name:
            rows = [r for r in rows if r[2] == table_name]
    return rows

def is_numeric(data_type):
    return data_type in NUMERIC_TYPES

COMPARISON_OPS = ["=", "<", ">", "<=", ">="]

def _filter_conditions(filters):
    conds = []
    for col, op, value in filters:
        if op == "LIKE":
            escaped = str(value).replace("'", "''")
            conds.append(f"{col} LIKE '%{escaped}%'")
        elif op in COMPARISON_OPS:
            conds.append(f"{col} {op} {value}")
        else:
            escaped = str(value).replace("'", "''")
            conds.append(f"{col} = '{escaped}'")
    return conds

def build_where(filters):
    conds = _filter_conditions(filters)
    return f"\nWHERE {' AND '.join(conds)}" if conds else ""

def build_sql(schema_name, table_name, chart_type, dim_col, measure_col, second_dim_col,
              agg_func, filters, row_limit):
    table = f"{schema_name}.{table_name}"

    if chart_type == "scatter":
        select, group_by = f"{dim_col}, {measure_col}", ""
    elif chart_type == "heatmap" and second_dim_col:
        select = f"{dim_col}, {second_dim_col}, {agg_func}({measure_col}) AS {measure_col}"
        group_by = f"\nGROUP BY {dim_col}, {second_dim_col}"
    elif agg_func == "COUNT" and not measure_col:
        select, group_by = f"{dim_col}, COUNT(*) AS count", f"\nGROUP BY {dim_col}"
    else:
        select = f"{dim_col}, {agg_func}({measure_col}) AS {measure_col}"
        group_by = f"\nGROUP BY {dim_col}"

    where = build_where(filters)
    limit = f"\nLIMIT {row_limit}" if row_limit else ""
    return f"SELECT {select}\nFROM {table}{where}{group_by}{limit}"

def build_detail_sql(schema_name, table_name, columns, filters, row_limit):
    table = f"{schema_name}.{table_name}"
    where = build_where(filters)
    limit = f"\nLIMIT {row_limit}" if row_limit else "\nLIMIT 200"
    return f"SELECT {', '.join(columns)}\nFROM {table}{where}{limit}"

def filter_summary(filters) -> Optional[str]:
    conds = _filter_conditions(filters)
    return " AND ".join(conds) if conds else None

def run_query(source_id, sql_text) -> pd.DataFrame:
    url = f"{API_URLS[source_id]}/query"
    try:
        resp = requests.post(url, json={"sql_text": sql_text}, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Source {source_id} is unreachable ({url}).")

    body = resp.json()
    if resp.status_code != 200:
        raise BackendError(body.get("error", f"Query failed (HTTP {resp.status_code})."))
    return pd.DataFrame(body["rows"], columns=body["columns"])

def list_templates():
    url = f"{TEMPLATES_API_URL}/templates"
    try:
        resp = requests.get(url, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Templates service is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(resp.json().get("error", f"Could not load templates (HTTP {resp.status_code})."))
    return resp.json()["templates"]

def save_template(spec, sql_text, template_name=None):
    body = dict(
        sql_text=sql_text,
        source_id=spec["source_id"], schema_name=spec["schema_name"], table_name=spec["table_name"],
        chart_type=spec["chart_type"], dimension_col=spec["dim_col"], measure_col=spec["measure_col"],
        second_dim_col=spec["second_dim_col"], agg_func=spec["agg_func"],
        filter_summary=filter_summary(spec["filters"]), row_limit=spec["row_limit"],
        template_name=template_name or None,
    )
    url = f"{TEMPLATES_API_URL}/templates"
    try:
        resp = requests.post(url, json=body, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Templates service is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(resp.json().get("error", f"Could not save template (HTTP {resp.status_code})."))
    return resp.json()

def use_template(template_id):
    url = f"{TEMPLATES_API_URL}/templates/{template_id}/use"
    try:
        resp = requests.post(url, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Templates service is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(resp.json().get("error", f"Could not use template (HTTP {resp.status_code})."))
    return resp.json()

def delete_template(template_id):
    url = f"{TEMPLATES_API_URL}/templates/{template_id}"
    try:
        resp = requests.delete(url, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Templates service is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(resp.json().get("error", f"Could not delete template (HTTP {resp.status_code})."))
    return resp.json()

def get_diff(source_id):
    url = f"{META_API_URL}/diff"
    try:
        resp = requests.get(url, params={"source_id": source_id}, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Meta service is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(resp.json().get("error", f"Could not compute diff (HTTP {resp.status_code})."))
    return resp.json()

def sync_diff(source_id):
    url = f"{META_API_URL}/sync"
    try:
        resp = requests.post(url, params={"source_id": source_id}, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Meta service is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(resp.json().get("error", f"Could not sync (HTTP {resp.status_code})."))
    return resp.json()

def get_meta_catalog(source_id=None):
    url = f"{META_API_URL}/catalog"
    params = {"source_id": source_id} if source_id else {}
    try:
        resp = requests.get(url, params=params, timeout=REQUEST_TIMEOUT)
    except requests.exceptions.RequestException:
        raise BackendError(f"Meta service is unreachable ({url}).")
    if resp.status_code != 200:
        raise BackendError(resp.json().get("error", f"Could not load meta.catalog (HTTP {resp.status_code})."))
    return resp.json()["catalog"]

TEMPLATE_COMPARE_FIELDS = ["source_id", "schema_name", "table_name", "chart_type",
                           "dimension_col", "measure_col", "second_dim_col", "agg_func",
                           "filter_summary", "row_limit", "sql_text"]

def _describe_column(t, role, catalog_by_key):
    col = t.get(role)
    if not col:
        return None
    key = (t["source_id"], t["schema_name"], t["table_name"], col)
    meta = catalog_by_key.get(key)
    if meta is None:
        return col, "column not found in meta.catalog (source schema changed)"
    if meta["fk_key"]:
        return col, f"{meta['data_type']}, {meta['fk_key']} -> {meta['ref_table_name']}.{meta['ref_column_name']}"
    if meta["pk_key"]:
        return col, f"{meta['data_type']}, {meta['pk_key']}"
    return col, meta["data_type"]

def compare_templates(t_a, t_b, catalog):
    catalog_by_key = {(r["source_id"], r["schema_name"], r["table_name"], r["column_name"]): r
                      for r in catalog}

    fields = [(f, t_a.get(f), t_b.get(f), t_a.get(f) != t_b.get(f)) for f in TEMPLATE_COMPARE_FIELDS]

    columns, warnings = [], []
    for role in ("dimension_col", "measure_col", "second_dim_col"):
        da = _describe_column(t_a, role, catalog_by_key)
        db = _describe_column(t_b, role, catalog_by_key)
        if da or db:
            columns.append((role, da, db))
        for label, t, d in (("A", t_a, da), ("B", t_b, db)):
            if d is None:
                continue
            col, desc = d
            if "not found" in desc:
                warnings.append(f"[{label}] {role}={col}: {desc}")
            elif role in ("dimension_col", "second_dim_col") and "FK" in desc:
                warnings.append(f"[{label}] {role}={col} is a foreign key ({desc}); "
                                 f"the chart will group by raw ids, not names")
            elif role == "measure_col" and desc.split(",")[0] not in NUMERIC_TYPES:
                warnings.append(f"[{label}] {role}={col} is {desc.split(',')[0]}, not numeric; "
                                 f"{t.get('agg_func')}({col}) will fail")

    return {"fields": fields, "columns": columns, "warnings": warnings}