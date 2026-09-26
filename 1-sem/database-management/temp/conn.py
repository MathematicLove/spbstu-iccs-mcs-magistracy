import os
import psycopg
from psycopg.rows import dict_row
import template

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def env():
    values = {}
    with open(os.path.join(ROOT, "credentials.env")) as handle:
        for line in handle:
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                key, value = line.split("=", 1)
                values[key.strip()] = value.strip()
    return values

def sources():
    values = env()
    result = {}
    for key, value in values.items():
        if key.endswith("_DB_NAME"):
            prefix = key[: -len("_DB_NAME")]
            result[value] = {
                "host": values[prefix + "_DB_HOST"],
                "port": values[prefix + "_DB_PORT"],
                "dbname": value,
                "user": values[prefix + "_DB_USER"],
                "password": values[prefix + "_DB_PASSWORD"],
            }
    return result

def meta():
    return sources()[env()["META_DB_NAME"]]

def databases():
    try:
        with psycopg.connect(**meta()) as connection:
            with connection.cursor() as cursor:
                cursor.execute(template.SOURCES_SQL)
                return [row[0] for row in cursor.fetchall()]
    except psycopg.Error:
        return []

def catalog(source_id):
    with psycopg.connect(row_factory=dict_row, **meta()) as connection:
        with connection.cursor() as cursor:
            cursor.execute(template.CATALOG_SQL, (source_id,))
            return cursor.fetchall()

def run(dbname, sql_text):
    try:
        with psycopg.connect(**sources()[dbname]) as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql_text)
                return ([desc.name for desc in cursor.description], cursor.fetchall()), None
    except psycopg.Error as error:
        return None, str(error).strip()