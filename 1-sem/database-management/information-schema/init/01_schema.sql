CREATE SCHEMA IF NOT EXISTS meta;

CREATE TABLE meta.catalog (
    source_id VARCHAR(32) NOT NULL,
    schema_name VARCHAR(64) NOT NULL,
    table_name VARCHAR(64) NOT NULL,
    column_name VARCHAR(64) NOT NULL,

    api_url VARCHAR(200) NOT NULL,

    ordinal_position INTEGER NOT NULL,
    data_type VARCHAR(64)  NOT NULL,

    pk_key VARCHAR(8),
    fk_key VARCHAR(8),
    ref_schema_name VARCHAR(64),
    ref_table_name VARCHAR(64),
    ref_column_name VARCHAR(64),

    synced_at TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT pk_catalog
        PRIMARY KEY (source_id, schema_name, table_name, column_name),
    CONSTRAINT fk_catalog_ref
        FOREIGN KEY (source_id, ref_schema_name, ref_table_name, ref_column_name)
        REFERENCES meta.catalog (source_id, schema_name, table_name, column_name)
        ON DELETE CASCADE
        DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT ck_catalog_pk_key CHECK (pk_key ~ '^PK[0-9]*$'),
    CONSTRAINT ck_catalog_fk_key CHECK (fk_key ~ '^FK[0-9]+$'),
    CONSTRAINT ck_catalog_fk_ref CHECK (
        (fk_key IS NULL     AND ref_schema_name IS NULL     AND ref_table_name IS NULL     AND ref_column_name IS NULL) OR
        (fk_key IS NOT NULL AND ref_schema_name IS NOT NULL AND ref_table_name IS NOT NULL AND ref_column_name IS NOT NULL)
    )
);