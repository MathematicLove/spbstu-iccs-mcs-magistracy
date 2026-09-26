import conn
import template
import to_numpy

def ask(question):
    return input(question).strip()

def ask_db():
    names = conn.databases()
    if not names:
        return None, None
    while True:
        dbname = ask("Which db ? ")
        if dbname not in names:
            print("no such db (((")
            continue
        return dbname, conn.catalog(dbname)

def ask_table(catalog):
    names = template.tables(catalog)
    while True:
        name = ask("Which table ? ")
        if name in names:
            return name
        print("no such table (((")

def ask_column(catalog, table, question, allow_empty=False):
    while True:
        name = ask(question)
        if allow_empty and name in ("", "no"):
            return None
        column = template.find_column(catalog, table, name)
        if column:
            return column
        print("no such column (((")

def ask_additional(catalog, table, used):
    answer = ask("Additional ? ")
    if answer in ("", "no"):
        return []
    extra = []
    for name in answer.split():
        column = template.find_column(catalog, table, name)
        if not column:
            print("no such column (((")
        elif column not in used and column not in extra:
            extra.append(column)
    return extra

def ask_agg():
    while True:
        agg_func = ask("Agg func ? ").upper()
        if agg_func in ("SUM", "COUNT"):
            return agg_func
        print("no such agg func (((")

def ask_plot():
    while True:
        kind = ask("Plot type ? ").lower()
        if kind in ("bar", "scatter", "no"):
            return kind
        print("no such plot type (((")

def main():
    dbname, catalog = ask_db()
    if not catalog:
        print("meta db is not running (((")
        return
    table = ask_table(catalog)
    print("Columns:")
    print(" ".join(template.column_names(catalog, table)))
    dim_col = ask_column(catalog, table, "Variable ? ")
    measure_col = ask_column(catalog, table, "Values ? ", True)
    dim_cols = [dim_col] + \
        ask_additional(catalog, table, [dim_col, measure_col])
    agg_func = ask_agg()
    kind = ask_plot()
    sql_text = template.build(catalog, table, dim_cols, measure_col, agg_func)
    print("")
    print(sql_text)
    print("")
    print("Tables:")
    print(table)
    print("")
    result, error = conn.run(dbname, sql_text)
    if error:
        print(error)
        return
    columns, rows = result
    if not rows:
        print("no rows (((")
        return
    to_numpy.show_table(columns, rows)
    if kind != "no":
        to_numpy.plot(rows, kind)