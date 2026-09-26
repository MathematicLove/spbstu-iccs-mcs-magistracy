SOURCES_SQL = """SELECT source_id
FROM meta.catalog
ORDER BY source_id"""

CATALOG_SQL = """SELECT schema_name,       
       table_name,
       column_name,
       data_type,                          
       pk_key,                             
       fk_key,                       
       ref_table_name,               
       ref_column_name               
FROM meta.catalog                    
WHERE source_id = %s                 
ORDER BY table_name, ordinal_position"""

QUERY_SQL = """SELECT {group_cols}, {agg_func}({agg_arg}) AS value
FROM {table}
GROUP BY {group_cols}
ORDER BY value DESC
LIMIT 20"""

def tables(catalog):
    return sorted({row["table_name"] for row in catalog})

def columns(catalog, table):
    return [row for row in catalog if row["table_name"] == table]

def column_names(catalog, table):
    return [row["column_name"] for row in columns(catalog, table)]

def full_name(catalog, table):
    return columns(catalog, table)[0]["schema_name"] + "." + table

def find_column(catalog, table, name):
    if name in column_names(catalog, table):
        return full_name(catalog, table) + "." + name
    return None

def build(catalog, table, dim_cols, measure_col, agg_func):
    return QUERY_SQL.format(
        group_cols=", ".join(dim_cols),
        agg_func=agg_func if measure_col else "COUNT",
        agg_arg=measure_col if measure_col else "*",
        table=full_name(catalog, table),
    )