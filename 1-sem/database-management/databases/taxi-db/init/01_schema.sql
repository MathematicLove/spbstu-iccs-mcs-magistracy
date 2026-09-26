CREATE SCHEMA IF NOT EXISTS taxi;

CREATE TABLE taxi.companies (
    company_id    SERIAL PRIMARY KEY,
    company_name  VARCHAR(120) UNIQUE NOT NULL
);
COMMENT ON TABLE taxi.companies IS 'Таксопарки и частные перевозчики';

CREATE TABLE taxi.company_stats (
    company_id   INTEGER PRIMARY KEY
                 REFERENCES taxi.companies(company_id) ON DELETE CASCADE,
    trips_count  INTEGER,
    avg_total    NUMERIC(12,2),
    avg_miles    NUMERIC(10,2)
);
COMMENT ON TABLE taxi.company_stats IS '1-1 к companies: средний чек и пробег';

CREATE TABLE taxi.payment_types (
    payment_type_id  SMALLSERIAL PRIMARY KEY,
    payment_name     VARCHAR(40) UNIQUE NOT NULL
);
COMMENT ON TABLE taxi.payment_types IS 'Cash, Credit Card, No Charge, ...';

CREATE TABLE taxi.community_areas (
    area_id    SMALLSERIAL PRIMARY KEY,
    area_code  SMALLINT UNIQUE NOT NULL
);
COMMENT ON TABLE taxi.community_areas IS 'Community areas Чикаго (1..77)';

CREATE TABLE taxi.trips (
    trip_pk          BIGSERIAL PRIMARY KEY,
    trip_id          VARCHAR(64),
    trip_start       TIMESTAMP,
    trip_end         TIMESTAMP,
    trip_seconds     INTEGER,
    trip_miles       NUMERIC(10,2),
    company_id       INTEGER  REFERENCES taxi.companies(company_id),
    payment_type_id  SMALLINT REFERENCES taxi.payment_types(payment_type_id),
    pickup_area_id   SMALLINT REFERENCES taxi.community_areas(area_id),
    dropoff_area_id  SMALLINT REFERENCES taxi.community_areas(area_id)
);
COMMENT ON TABLE  taxi.trips            IS 'Поездки; N-1 к companies, payment_types и дважды к community_areas';
COMMENT ON COLUMN taxi.trips.trip_miles IS 'Пробег поездки в милях';

CREATE INDEX idx_trips_company ON taxi.trips (company_id);
CREATE INDEX idx_trips_payment ON taxi.trips (payment_type_id);
CREATE INDEX idx_trips_pickup  ON taxi.trips (pickup_area_id);

CREATE TABLE taxi.trip_payments (
    trip_pk     BIGINT PRIMARY KEY
                REFERENCES taxi.trips(trip_pk) ON DELETE CASCADE,
    fare        NUMERIC(12,2),
    tips        NUMERIC(12,2),
    tolls       NUMERIC(12,2),
    extras      NUMERIC(12,2),
    trip_total  NUMERIC(12,2)
);
COMMENT ON TABLE  taxi.trip_payments            IS '1-1 к trips: тариф, чаевые, итог';
COMMENT ON COLUMN taxi.trip_payments.trip_total IS 'Итоговая стоимость поездки';

CREATE TABLE taxi.company_payment_types (
    company_id       INTEGER  NOT NULL REFERENCES taxi.companies(company_id)         ON DELETE CASCADE,
    payment_type_id  SMALLINT NOT NULL REFERENCES taxi.payment_types(payment_type_id) ON DELETE CASCADE,
    trips_count      INTEGER,
    PRIMARY KEY (company_id, payment_type_id)
);
COMMENT ON TABLE taxi.company_payment_types IS 'N-N: таксопарки ↔ способы оплаты';