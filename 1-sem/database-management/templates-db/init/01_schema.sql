CREATE SCHEMA IF NOT EXISTS tpl;

CREATE SEQUENCE tpl.template_name_seq;

CREATE TABLE tpl.form_templates (
    template_id    BIGSERIAL PRIMARY KEY,
    template_name  VARCHAR(120) NOT NULL UNIQUE,

    sql_text       TEXT NOT NULL,

    source_id      VARCHAR(32)  NOT NULL,
    schema_name    VARCHAR(64)  NOT NULL,
    table_name     VARCHAR(64)  NOT NULL,

    chart_type     VARCHAR(16)  NOT NULL,
    dimension_col  VARCHAR(64)  NOT NULL,
    measure_col    VARCHAR(64),
    second_dim_col VARCHAR(64),
    agg_func       VARCHAR(16),

    filter_summary VARCHAR(300),

    row_limit      INTEGER,

    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    used_count     INTEGER      NOT NULL DEFAULT 0,
    last_used_at   TIMESTAMPTZ,

    CONSTRAINT ck_tpl_chart CHECK (chart_type IN ('barplot', 'pieplot', 'scatter', 'heatmap')),
    CONSTRAINT ck_tpl_agg   CHECK (agg_func IS NULL OR agg_func IN ('SUM', 'AVG', 'COUNT')),
    CONSTRAINT ck_tpl_row_limit CHECK (row_limit IS NULL OR row_limit > 0),
    CONSTRAINT ck_tpl_select_only CHECK (upper(ltrim(sql_text)) LIKE 'SELECT%')
);

COMMENT ON TABLE  tpl.form_templates                IS 'Шаблоны форм BI-интерфейса: готовый SELECT + параметры формы';
COMMENT ON COLUMN tpl.form_templates.sql_text        IS 'Чистый SQL-запрос, выполняемый на стороне БД-источника; содержит фильтры и LIMIT';
COMMENT ON COLUMN tpl.form_templates.filter_summary  IS 'Читаемая сводка AND-фильтра по чекбоксам; сама фильтрация уже в sql_text';
COMMENT ON COLUMN tpl.form_templates.row_limit       IS 'NULL = без LIMIT — поле в форме можно оставить пустым';

CREATE INDEX idx_tpl_source ON tpl.form_templates (source_id);
CREATE INDEX idx_tpl_chart  ON tpl.form_templates (chart_type);

CREATE OR REPLACE FUNCTION tpl.set_default_template_name()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.template_name IS NULL OR btrim(NEW.template_name) = '' THEN
        NEW.template_name := 'template_' || nextval('tpl.template_name_seq');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_tpl_default_name
    BEFORE INSERT ON tpl.form_templates
    FOR EACH ROW
    EXECUTE FUNCTION tpl.set_default_template_name();