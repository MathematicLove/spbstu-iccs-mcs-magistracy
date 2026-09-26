import sys
from pathlib import Path

import pandas as pd
import streamlit as st
import matplotlib.pyplot as plt
import seaborn as sns

sys.path.insert(0, str(Path(__file__).parent / "bi-elements"))
from backend import (
    all_sources, get_catalog, tables_for, columns_for, is_numeric,
    build_sql, build_detail_sql, run_query, BackendError, COMPARISON_OPS,
    list_templates, save_template, use_template, delete_template,
    get_diff, sync_diff, get_meta_catalog, compare_templates,
)

NO_OP = "--"
WHERE_OPS = [NO_OP] + COMPARISON_OPS

def _short_type_label(data_type):
    t = data_type.lower()
    if "char" in t or t == "text":
        return "VARCHAR"
    if "timestamp" in t:
        return "TIMESTAMP"
    if t == "date":
        return "DATE"
    if t == "boolean":
        return "BOOLEAN"
    if t in ("smallint", "integer", "bigint"):
        return "INTEGER"
    if t in ("numeric", "real", "double precision"):
        return "NUMERIC"
    return data_type.upper()

st.set_page_config(page_title="Mini-BI", layout="wide")

CHART_TYPES = ["barplot", "pieplot", "scatter", "heatmap"]
AGG_FUNCS = ["SUM", "AVG", "COUNT"]
PAGE_SIZE = 10
DEFAULT_ROW_LIMIT = 500

def parse_row_limit(raw):
    raw = raw.strip()
    if raw == "":
        return DEFAULT_ROW_LIMIT
    try:
        n = int(raw)
    except ValueError:
        return DEFAULT_ROW_LIMIT
    return n if n > 0 else None
MAX_LABELED_TICKS = 40
MAX_PIE_LABELS = 30
MAX_HEATMAP_ANNOT_CELLS = 80

def render_controls(catalog):
    if st.button("Use template", width="stretch"):
        open_use_template_dialog()

    source_options = ["(all sources)"] + all_sources()
    default_idx = 1 if len(source_options) > 1 else 0
    source_choice = st.selectbox("Choose Database", source_options, index=default_idx, key="source_select")
    source_id = None if source_choice == "(all sources)" else source_choice

    table_name = None
    if source_id:
        tables = tables_for(source_id, catalog)
        if not tables:
            st.write(f"No tables found for {source_id}.")
            return None
        table_name = st.selectbox("Choose table", tables, index=0, key="table_select")

    chart_type = st.selectbox("Choose plot type", CHART_TYPES, index=0, key="chart_type_select")

    cols = columns_for(catalog, source_id, table_name)
    if not cols:
        st.write("No columns available for this selection.")
        return None

    def label_of(c):
        return c[3] if source_id else f"{c[3]} ({c[0]}.{c[2]})"

    labels = [label_of(c) for c in cols]

    def pick(label, key, default_label=None, default_idx=0, exclude=()):
        subset = [c for c in cols if c[3] not in exclude]
        sub_labels = [label_of(c) for c in subset]
        if not sub_labels:
            st.write(f"Not enough columns left in this table to pick {label}.")
            return None
        idx = sub_labels.index(default_label) if default_label in sub_labels else min(default_idx, len(sub_labels) - 1)
        type_of = {label_of(c): _short_type_label(c[4]) for c in subset}
        sel = st.selectbox(
            label, sub_labels, index=idx, key=key,
            format_func=lambda lbl: f"{lbl}  [{type_of[lbl]}]",
        )
        return subset[sub_labels.index(sel)]

    def default_dim_col():
        for c in cols:
            if not c[5] and not c[6]:
                return c[3]
        return cols[0][3]

    dim = pick("Choose column of variable", "dim_col", default_dim_col())
    if dim is None:
        return None

    def default_measure_col():
        def candidates(same_table_only, numeric_only):
            for c in cols:
                if c[3] == dim[3]:
                    continue
                if same_table_only and (c[0], c[2]) != (dim[0], dim[2]):
                    continue
                if numeric_only and not (is_numeric(c[4]) and not c[5] and not c[6]):
                    continue
                return c[3]
            return None

        for same_table_only in (True, False):
            for numeric_only in (True, False):
                name = candidates(same_table_only, numeric_only)
                if name is not None:
                    return name
        return None

    val = pick("Choose column of values", "measure_col", default_measure_col(), exclude=(dim[3],))
    if val is None:
        return None

    second_dim = None
    if chart_type == "heatmap":
        second_dim = pick("Second dimension (heatmap)", "second_dim_col", exclude=(dim[3], val[3]))
        if second_dim is None:
            return None

    agg_func = None
    if chart_type != "scatter":
        agg_func = st.selectbox("Aggregate", AGG_FUNCS, index=0, key="agg_func_select")

    row_limit_context = (source_id, table_name, dim[3], val[3])
    if st.session_state.get("_row_limit_context") != row_limit_context:
        st.session_state["_row_limit_context"] = row_limit_context
        st.session_state["row_limit_input"] = ""
    row_limit_raw = st.text_input(
        "Row limit", key="row_limit_input", placeholder=str(DEFAULT_ROW_LIMIT),
    )
    row_limit = parse_row_limit(row_limit_raw)

    where_filters = []
    with st.popover("WHERE filter", width="stretch"):
        for c in (dim, val):
            type_label = _short_type_label(c[4])
            if is_numeric(c[4]):
                name_col, type_col, op_col, val_col = st.columns([2, 1, 1, 2])
                name_col.write(c[3])
                type_col.caption(type_label)
                op = op_col.selectbox(
                    " ", WHERE_OPS, key=f"whereop_{c[0]}_{c[2]}_{c[3]}",
                    label_visibility="collapsed",
                )
                value = val_col.text_input(
                    " ", key=f"whereval_{c[0]}_{c[2]}_{c[3]}",
                    placeholder=type_label, label_visibility="collapsed",
                )
                if op != NO_OP and value.strip():
                    where_filters.append((c[3], op, value.strip()))
            else:
                name_col, type_col, val_col = st.columns([2, 1, 3])
                name_col.write(c[3])
                type_col.caption(type_label)
                value = val_col.text_input(
                    " ", key=f"whereval_{c[0]}_{c[2]}_{c[3]}",
                    placeholder=type_label, label_visibility="collapsed",
                )
                if value.strip():
                    where_filters.append((c[3], "LIKE", value.strip()))

    extra_cols = []
    with st.popover("Additional columns", width="stretch"):
        for c in cols:
            if c[3] in (dim[3], val[3]):
                continue
            box_col, type_col = st.columns([3, 1])
            if box_col.checkbox(c[3], key=f"extra_{c[0]}_{c[2]}_{c[3]}"):
                extra_cols.append(c[3])
            type_col.caption(_short_type_label(c[4]))

    effective_source, effective_schema, effective_table = dim[0], dim[1], dim[2]
    if source_id is None and (dim[0], dim[2]) != (val[0], val[2]):
        st.caption(
            f"Variable and Values are from different tables; "
            f"query runs against {effective_source}.{effective_table}."
        )

    return dict(
        source_id=effective_source, schema_name=effective_schema, table_name=effective_table,
        chart_type=chart_type, dim_col=dim[3], measure_col=val[3],
        second_dim_col=second_dim[3] if second_dim else None,
        agg_func=agg_func, filters=where_filters, extra_cols=extra_cols,
        row_limit=row_limit,
    )

def render_chart(df, spec):
    chart_type = spec["chart_type"]
    dim, val = spec["dim_col"], spec["measure_col"]
    n = len(df)

    fig, ax = plt.subplots(figsize=(5.5, 4))
    try:
        if chart_type == "barplot":
            sns.barplot(data=df, x=dim, y=val, ax=ax, order=df[dim])
            step = max(1, n // MAX_LABELED_TICKS)
            shown = list(range(0, n, step))
            ax.set_xticks(shown)
            ax.set_xticklabels(df[dim].iloc[shown], rotation=45, ha="right",
                                fontsize=8 if n > 20 else 10)
        elif chart_type == "pieplot":
            show_labels = n <= MAX_PIE_LABELS
            ax.pie(df[val], labels=df[dim] if show_labels else None,
                   autopct="%1.0f%%" if show_labels else None,
                   textprops={"fontsize": 6 if n > 15 else 8})
        elif chart_type == "scatter":
            sns.scatterplot(data=df, x=dim, y=val, ax=ax)
            plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
        elif chart_type == "heatmap":
            pivot = df.pivot(index=dim, columns=spec["second_dim_col"], values=val)
            annot = pivot.size <= MAX_HEATMAP_ANNOT_CELLS
            sns.heatmap(pivot, annot=annot, fmt=".0f", ax=ax, cmap="Blues")
            plt.setp(ax.get_xticklabels(), rotation=45, ha="right")

        fig.tight_layout()
        st.pyplot(fig)
    finally:
        plt.close(fig)

def render_result_tables(tables):
    columns = st.columns(len(tables))
    for col, (title, df) in zip(columns, tables):
        with col:
            st.write(title)
            total_pages = max(1, (len(df) - 1) // PAGE_SIZE + 1)
            page_key = f"page_{title}"
            if page_key in st.session_state and st.session_state[page_key] > total_pages:
                st.session_state[page_key] = total_pages
            page = st.number_input(
                "Page", min_value=1, max_value=total_pages, step=1, key=page_key,
            )
            start = (page - 1) * PAGE_SIZE
            st.dataframe(df.iloc[start:start + PAGE_SIZE], width="stretch", height=320)
            st.caption(f"Rows {start + 1}-{min(start + PAGE_SIZE, len(df))} of {len(df)}, page {page}/{total_pages}")

@st.dialog("Save query as template")
def open_save_template_dialog():
    spec = st.session_state.get("last_spec")
    if not spec:
        st.write("Build a chart first.")
        if st.button("Exit"):
            st.rerun()
        return

    name = st.text_input("Template name", value="")
    st.caption("Leave blank for an automatic name (template_1, template_2, ...).")

    c1, c2 = st.columns(2)
    if c1.button("Save", width="stretch"):
        try:
            saved = save_template(spec, spec["sql_text"], template_name=name.strip() or None)
        except BackendError as exc:
            st.write(str(exc))
        else:
            st.write(f"Template {saved['template_name']} saved.")
            st.rerun()
    if c2.button("Cancel", width="stretch"):
        st.rerun()

@st.dialog("Use template")
def open_use_template_dialog():
    try:
        templates = list_templates()
    except BackendError as exc:
        st.write(str(exc))
        if st.button("Exit"):
            st.rerun()
        return

    if not templates:
        st.write("No templates yet. Save one first (Save query as template).")
        if st.button("Exit"):
            st.rerun()
        return

    compare_ids = []
    for t in templates:
        label = f"{t['template_name']} - {t['source_id']}.{t['table_name']}: {t['chart_type']}({t['dimension_col']}, {t['measure_col']})"
        use_col, cmp_col, del_col = st.columns([4, 1, 1])
        if del_col.button("Delete", key=f"del_{t['template_id']}", width="stretch"):
            try:
                delete_template(t["template_id"])
            except BackendError as exc:
                st.write(str(exc))
            else:
                st.rerun()
        if use_col.button(label, key=f"use_{t['template_id']}", width="stretch"):
            try:
                use_template(t["template_id"])
            except BackendError as exc:
                st.write(str(exc))
            else:
                st.session_state["source_select"] = t["source_id"]
                st.session_state["table_select"] = t["table_name"]
                st.session_state["chart_type_select"] = t["chart_type"]
                st.session_state["dim_col"] = t["dimension_col"]
                st.session_state["measure_col"] = t["measure_col"]
                if t.get("second_dim_col"):
                    st.session_state["second_dim_col"] = t["second_dim_col"]
                if t.get("agg_func"):
                    st.session_state["agg_func_select"] = t["agg_func"]
                st.session_state["row_limit_input"] = str(t["row_limit"] or 0)
                st.session_state["_row_limit_context"] = (
                    t["source_id"], t["table_name"], t["dimension_col"], t["measure_col"],
                )
                st.rerun()
        if cmp_col.checkbox("compare", key=f"cmp_{t['template_id']}"):
            compare_ids.append(t["template_id"])

    st.divider()
    if len(compare_ids) != 2:
        st.caption("Tick \"compare\" on exactly 2 templates to see a diff between them.")
        return

    t_a = next(t for t in templates if t["template_id"] == compare_ids[0])
    t_b = next(t for t in templates if t["template_id"] == compare_ids[1])
    try:
        meta_catalog = get_meta_catalog()
    except BackendError as exc:
        st.write(str(exc))
        return

    diff_result = compare_templates(t_a, t_b, meta_catalog)
    st.write(f"Diff: {t_a['template_name']} vs {t_b['template_name']}")

    rows = [dict(field=f, A=str(va), B=str(vb)) for f, va, vb, differs in diff_result["fields"] if differs]
    if rows:
        st.dataframe(pd.DataFrame(rows), width="stretch", hide_index=True)
    else:
        st.caption("All fields are identical.")

    if diff_result["columns"]:
        st.write("Column details:")
        col_rows = [dict(role=role,
                         A=f"{a[0]} - {a[1]}" if a else "-",
                         B=f"{b[0]} - {b[1]}" if b else "-")
                    for role, a, b in diff_result["columns"]]
        st.dataframe(pd.DataFrame(col_rows), width="stretch", hide_index=True)

    if diff_result["warnings"]:
        st.write("Warnings:")
        for w in diff_result["warnings"]:
            st.write(f"- {w}")

@st.dialog("Show diff")
def open_show_diff_dialog():
    if st.session_state.get("source_select") == "(all sources)":
        st.write("Choose a specific Database first — Show diff needs to know which source to check.")
        if st.button("Exit"):
            st.rerun()
        return

    spec = st.session_state.get("last_spec")
    if not spec:
        st.write("Build a chart first, so there is something to compare.")
        if st.button("Exit"):
            st.rerun()
        return

    source_id = spec["source_id"]
    try:
        d = get_diff(source_id)
    except BackendError as exc:
        st.write(str(exc))
        if st.button("Exit"):
            st.rerun()
        return

    if d["up_to_date"]:
        st.write("Already up to date")
        st.caption(f"meta.catalog matches the live schema of {source_id}.")
    else:
        st.write(f"{len(d['added'])} added, {len(d['changed'])} changed, {len(d['removed'])} removed")
        if d["added"]:
            st.write("Added:")
            st.dataframe(pd.DataFrame(d["added"])[["table_name", "column_name", "data_type"]],
                         width="stretch", hide_index=True)
        if d["changed"]:
            st.write("Changed:")
            rows = [dict(table_name=c["key"]["table_name"], column_name=c["key"]["column_name"],
                         old_data_type=c["old"]["data_type"], new_data_type=c["new"]["data_type"])
                    for c in d["changed"]]
            st.dataframe(pd.DataFrame(rows), width="stretch", hide_index=True)
        if d["removed"]:
            st.write("Removed:")
            st.dataframe(pd.DataFrame(d["removed"])[["table_name", "column_name"]],
                         width="stretch", hide_index=True)

    c1, c2 = st.columns(2)
    if c1.button("Update", width="stretch", disabled=d["up_to_date"]):
        try:
            sync_diff(source_id)
        except BackendError as exc:
            st.write(str(exc))
        else:
            st.rerun()
    if c2.button("Exit", width="stretch"):
        st.rerun()

catalog, catalog_errors = get_catalog()
for err in catalog_errors:
    st.write(err)

left, right = st.columns([1, 1])

with right:
    spec = render_controls(catalog)

with left:
    st.write("SQL Query:")
    df = None
    if spec:
        sql_text = build_sql(
            spec["schema_name"], spec["table_name"], spec["chart_type"],
            spec["dim_col"], spec["measure_col"], spec["second_dim_col"],
            spec["agg_func"], spec["filters"], spec["row_limit"],
        )
        st.code(sql_text, language=None)
        try:
            df = run_query(spec["source_id"], sql_text)
        except BackendError as exc:
            st.write(str(exc))
        else:
            st.session_state.last_spec = dict(spec, sql_text=sql_text)
            try:
                render_chart(df, spec)
            except Exception:
                st.write("Could not draw this chart for the selected columns.")
    else:
        st.code("-- select columns on the right --", language=None)

st.divider()

if df is not None:
    tables = [("Result", df)]
    if spec["extra_cols"]:
        detail_cols = [spec["dim_col"], spec["measure_col"]] + [
            c for c in spec["extra_cols"] if c not in (spec["dim_col"], spec["measure_col"])
        ]
        detail_sql = build_detail_sql(
            spec["schema_name"], spec["table_name"], detail_cols,
            spec["filters"], spec["row_limit"],
        )
        try:
            detail_df = run_query(spec["source_id"], detail_sql)
        except BackendError as exc:
            st.write(str(exc))
        else:
            tables.append(("Details", detail_df))
    render_result_tables(tables)

st.divider()

spacer, save_col, diff_col = st.columns([3, 1, 1])
with save_col:
    if st.button("Save query as template", width="stretch"):
        open_save_template_dialog()
with diff_col:
    if st.button("Show diff", width="stretch"):
        open_show_diff_dialog()