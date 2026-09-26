CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE sales.item_types (
    item_type_id  SMALLSERIAL PRIMARY KEY,
    type_name     VARCHAR(50) UNIQUE NOT NULL
);
COMMENT ON TABLE sales.item_types IS 'Категории товара: WINE, BEER, LIQUOR, ...';

CREATE TABLE sales.suppliers (
    supplier_id    SERIAL PRIMARY KEY,
    supplier_name  VARCHAR(200) UNIQUE NOT NULL
);
COMMENT ON TABLE sales.suppliers IS 'Поставщики алкоголя';

CREATE TABLE sales.supplier_profiles (
    supplier_id   INTEGER PRIMARY KEY
                  REFERENCES sales.suppliers(supplier_id) ON DELETE CASCADE,
    items_count   INTEGER,
    total_retail  NUMERIC(16,2),
    first_year    INTEGER,
    last_year     INTEGER
);
COMMENT ON TABLE sales.supplier_profiles IS '1-1 к suppliers: агрегированная карточка поставщика';

CREATE TABLE sales.items (
    item_id           SERIAL PRIMARY KEY,
    item_code         VARCHAR(50) UNIQUE NOT NULL,
    item_description  VARCHAR(300),
    item_type_id      SMALLINT NOT NULL
                      REFERENCES sales.item_types(item_type_id)
);
COMMENT ON TABLE sales.items IS 'Номенклатура; N-1 к item_types';
CREATE INDEX idx_items_type ON sales.items (item_type_id);

CREATE TABLE sales.periods (
    period_id      SERIAL PRIMARY KEY,
    calendar_year  INTEGER NOT NULL,
    cal_month_num  INTEGER NOT NULL,
    UNIQUE (calendar_year, cal_month_num)
);
COMMENT ON TABLE sales.periods IS 'Календарные периоды отчётности';

CREATE TABLE sales.sales_facts (
    sale_id           BIGSERIAL PRIMARY KEY,
    period_id         INTEGER NOT NULL REFERENCES sales.periods(period_id),
    supplier_id       INTEGER NOT NULL REFERENCES sales.suppliers(supplier_id),
    item_id           INTEGER NOT NULL REFERENCES sales.items(item_id),
    retail_sales      NUMERIC(14,2),
    retail_transfers  NUMERIC(14,2),
    warehouse_sales   NUMERIC(14,2)
);
COMMENT ON TABLE  sales.sales_facts              IS 'Помесячные продажи; N-1 к periods, suppliers, items';
COMMENT ON COLUMN sales.sales_facts.retail_sales IS 'Розничные продажи, условные единицы';

CREATE INDEX idx_facts_period   ON sales.sales_facts (period_id);
CREATE INDEX idx_facts_supplier ON sales.sales_facts (supplier_id);
CREATE INDEX idx_facts_item     ON sales.sales_facts (item_id);

CREATE TABLE sales.supplier_item_types (
    supplier_id      INTEGER  NOT NULL REFERENCES sales.suppliers(supplier_id)  ON DELETE CASCADE,
    item_type_id     SMALLINT NOT NULL REFERENCES sales.item_types(item_type_id) ON DELETE CASCADE,
    positions_count  INTEGER,
    PRIMARY KEY (supplier_id, item_type_id)
);
COMMENT ON TABLE sales.supplier_item_types IS 'N-N: поставщики ↔ категории товара';