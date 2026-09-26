WITH pk AS (
    SELECT kcu.table_schema, kcu.table_name, kcu.column_name,
           CASE WHEN count(*) OVER (PARTITION BY kcu.table_schema, kcu.table_name) = 1
                THEN 'PK'
                ELSE 'PK' || kcu.ordinal_position
           END AS pk_key
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage  kcu
      ON  kcu.constraint_schema = tc.constraint_schema
      AND kcu.constraint_name   = tc.constraint_name
      AND kcu.table_name        = tc.table_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
),
fk_cols AS (
    SELECT kcu.table_schema, kcu.table_name, kcu.column_name, kcu.constraint_name,
           c.ordinal_position AS column_position,
           ref.table_schema   AS ref_schema_name,
           ref.table_name     AS ref_table_name,
           ref.column_name    AS ref_column_name
    FROM information_schema.table_constraints       tc
    JOIN information_schema.key_column_usage        kcu
      ON  kcu.constraint_schema = tc.constraint_schema
      AND kcu.constraint_name   = tc.constraint_name
      AND kcu.table_name        = tc.table_name
    JOIN information_schema.referential_constraints rc
      ON  rc.constraint_schema  = tc.constraint_schema
      AND rc.constraint_name    = tc.constraint_name
    JOIN information_schema.key_column_usage        ref
      ON  ref.constraint_schema = rc.unique_constraint_schema
      AND ref.constraint_name   = rc.unique_constraint_name
      AND ref.ordinal_position  = kcu.position_in_unique_constraint
    JOIN information_schema.columns                 c
      ON  c.table_schema = kcu.table_schema
      AND c.table_name   = kcu.table_name
      AND c.column_name  = kcu.column_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
),
fk AS (
    SELECT f.table_schema, f.table_name, f.column_name,
           'FK' || dense_rank() OVER (PARTITION BY f.table_schema, f.table_name
                                      ORDER BY f.first_position, f.constraint_name) AS fk_key,
           f.ref_schema_name, f.ref_table_name, f.ref_column_name
    FROM (SELECT fk_cols.*,
                 min(column_position) OVER (PARTITION BY table_schema, table_name, constraint_name)
                     AS first_position
          FROM fk_cols) f
)
SELECT c.table_schema     AS schema_name,
       c.table_name,
       c.column_name,
       c.ordinal_position,
       c.data_type,
       pk.pk_key,
       fk.fk_key,
       fk.ref_schema_name,
       fk.ref_table_name,
       fk.ref_column_name
FROM information_schema.columns c
JOIN information_schema.tables  t
  ON  t.table_schema = c.table_schema
  AND t.table_name   = c.table_name
  AND t.table_type   = 'BASE TABLE'
LEFT JOIN pk
  ON  pk.table_schema = c.table_schema
  AND pk.table_name   = c.table_name
  AND pk.column_name  = c.column_name
LEFT JOIN fk
  ON  fk.table_schema = c.table_schema
  AND fk.table_name   = c.table_name
  AND fk.column_name  = c.column_name
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY c.table_schema, c.table_name, c.ordinal_position;