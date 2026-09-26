CREATE SCHEMA IF NOT EXISTS crime;

CREATE TABLE crime.districts (
    district_id    SMALLSERIAL PRIMARY KEY,
    district_code  VARCHAR(10) UNIQUE NOT NULL
);
COMMENT ON TABLE crime.districts IS 'Полицейские районы Чикаго';

CREATE TABLE crime.district_stats (
    district_id      SMALLINT PRIMARY KEY
                     REFERENCES crime.districts(district_id) ON DELETE CASCADE,
    incidents_count  INTEGER,
    arrest_rate      NUMERIC(6,3),
    domestic_rate    NUMERIC(6,3)
);
COMMENT ON TABLE crime.district_stats IS '1-1 к districts: доля арестов и бытовых преступлений';

CREATE TABLE crime.beats (
    beat_id      SERIAL PRIMARY KEY,
    beat_code    VARCHAR(10) UNIQUE NOT NULL,
    district_id  SMALLINT NOT NULL REFERENCES crime.districts(district_id)
);
COMMENT ON TABLE crime.beats IS 'Участки; N-1 к districts';
CREATE INDEX idx_beats_district ON crime.beats (district_id);

CREATE TABLE crime.crime_types (
    crime_type_id  SERIAL PRIMARY KEY,
    iucr           VARCHAR(10) UNIQUE NOT NULL,
    primary_type   VARCHAR(60) NOT NULL,
    description    VARCHAR(200),
    fbi_code       VARCHAR(10)
);
COMMENT ON TABLE  crime.crime_types              IS 'Классификатор IUCR';
COMMENT ON COLUMN crime.crime_types.primary_type IS 'Тип преступления: THEFT, BATTERY, ...';

CREATE TABLE crime.location_types (
    location_type_id  SERIAL PRIMARY KEY,
    location_name     VARCHAR(120) UNIQUE NOT NULL
);
COMMENT ON TABLE crime.location_types IS 'Где произошло: STREET, RESIDENCE, ...';

CREATE TABLE crime.incidents (
    incident_id       BIGSERIAL PRIMARY KEY,
    source_id         BIGINT,
    case_number       VARCHAR(20),
    occurred_at       TIMESTAMP,
    block             VARCHAR(100),
    crime_type_id     INTEGER  NOT NULL REFERENCES crime.crime_types(crime_type_id),
    beat_id           INTEGER  REFERENCES crime.beats(beat_id),
    location_type_id  INTEGER  REFERENCES crime.location_types(location_type_id),
    arrest            BOOLEAN,
    domestic          BOOLEAN,
    ward              INTEGER,
    community_area    INTEGER,
    year              INTEGER
);
COMMENT ON TABLE  crime.incidents        IS 'Зарегистрированные преступления; N-1 к beats, crime_types, location_types';
COMMENT ON COLUMN crime.incidents.arrest IS 'Был ли произведён арест';

CREATE INDEX idx_incidents_type     ON crime.incidents (crime_type_id);
CREATE INDEX idx_incidents_beat     ON crime.incidents (beat_id);
CREATE INDEX idx_incidents_location ON crime.incidents (location_type_id);
CREATE INDEX idx_incidents_year     ON crime.incidents (year);

CREATE TABLE crime.incident_geo (
    incident_id  BIGINT PRIMARY KEY
                 REFERENCES crime.incidents(incident_id) ON DELETE CASCADE,
    latitude     NUMERIC(11,8),
    longitude    NUMERIC(11,8)
);
COMMENT ON TABLE crime.incident_geo IS '1-1 к incidents: географические координаты';

CREATE TABLE crime.tags (
    tag_id    SMALLSERIAL PRIMARY KEY,
    tag_name  VARCHAR(40) UNIQUE NOT NULL
);
COMMENT ON TABLE crime.tags IS 'Признаки: ARREST, DOMESTIC, NIGHT, WEEKEND';

CREATE TABLE crime.incident_tags (
    incident_id  BIGINT   NOT NULL REFERENCES crime.incidents(incident_id) ON DELETE CASCADE,
    tag_id       SMALLINT NOT NULL REFERENCES crime.tags(tag_id)           ON DELETE CASCADE,
    PRIMARY KEY (incident_id, tag_id)
);
COMMENT ON TABLE crime.incident_tags IS 'N-N: происшествия ↔ признаки';
CREATE INDEX idx_incident_tags_tag ON crime.incident_tags (tag_id);