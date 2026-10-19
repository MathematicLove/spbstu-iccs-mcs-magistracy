CREATE SCHEMA IF NOT EXISTS sport_and_cheerleaders;

CREATE TABLE sport_and_cheerleaders.country (
    country_id  SERIAL PRIMARY KEY,
    country     VARCHAR(60) UNIQUE NOT NULL
);
COMMENT ON TABLE sport_and_cheerleaders.country IS 'Справочник стран';

CREATE TABLE sport_and_cheerleaders.region (
    region_id          SERIAL PRIMARY KEY,
    region_name        VARCHAR(100) NOT NULL,
    region_ranking     INTEGER,
    sportsmans_count   INTEGER CHECK (sportsmans_count >= 0),
    country            INTEGER NOT NULL REFERENCES sport_and_cheerleaders.country(country_id),
    UNIQUE (country, region_name)
);
COMMENT ON TABLE sport_and_cheerleaders.region IS 'Регионы; N-1 к country';

CREATE TABLE sport_and_cheerleaders.club (
    club_id       SERIAL PRIMARY KEY,
    club_name     VARCHAR(100) NOT NULL,
    club_ranking  INTEGER,
    region_id     INTEGER NOT NULL REFERENCES sport_and_cheerleaders.region(region_id),
    birthdate     DATE,
    email         VARCHAR(100)
);
COMMENT ON TABLE  sport_and_cheerleaders.club           IS 'Клубы; N-1 к region';
COMMENT ON COLUMN sport_and_cheerleaders.club.birthdate IS 'Дата основания клуба';
CREATE INDEX idx_club_region ON sport_and_cheerleaders.club (region_id);

CREATE TABLE sport_and_cheerleaders.grade_type (
    grade_type_id  SMALLSERIAL PRIMARY KEY,
    grade_type     VARCHAR(60) UNIQUE NOT NULL
);
COMMENT ON TABLE sport_and_cheerleaders.grade_type IS 'Разряды и звания: юношеские, 1-3 разряд, КМС, МС, МСМК';

CREATE TABLE sport_and_cheerleaders.competition_type (
    competition_type_id  SMALLSERIAL PRIMARY KEY,
    competition_type     VARCHAR(60) UNIQUE NOT NULL
);
COMMENT ON TABLE sport_and_cheerleaders.competition_type IS 'Уровень соревнований: городские, региональные, всероссийские, международные';

CREATE TABLE sport_and_cheerleaders.grade (
    grade_id          SERIAL PRIMARY KEY,
    grade_type        SMALLINT NOT NULL REFERENCES sport_and_cheerleaders.grade_type(grade_type_id),
    date              DATE     NOT NULL,
    competition_type  SMALLINT NOT NULL REFERENCES sport_and_cheerleaders.competition_type(competition_type_id),
    verification      BOOLEAN  NOT NULL DEFAULT FALSE
);
COMMENT ON TABLE  sport_and_cheerleaders.grade              IS 'Приказ о присвоении разряда; N-1 к grade_type и competition_type';
COMMENT ON COLUMN sport_and_cheerleaders.grade.verification IS 'Подтверждён ли разряд федерацией';

CREATE TABLE sport_and_cheerleaders.sportsman (
    sportsman_id          SERIAL PRIMARY KEY,
    sportsman_name        VARCHAR(50) NOT NULL,
    sportsman_lastname    VARCHAR(50) NOT NULL,
    sportsman_middlename  VARCHAR(50),
    grade_id              INTEGER REFERENCES sport_and_cheerleaders.grade(grade_id),
    club_id               INTEGER NOT NULL REFERENCES sport_and_cheerleaders.club(club_id),
    sportsman_birthdate   DATE    NOT NULL
);
COMMENT ON TABLE  sport_and_cheerleaders.sportsman          IS 'Спортсмены; N-1 к club и grade (один приказ на нескольких спортсменов)';
COMMENT ON COLUMN sport_and_cheerleaders.sportsman.grade_id IS 'NULL - спортсмен без разряда';
CREATE INDEX idx_sportsman_club  ON sport_and_cheerleaders.sportsman (club_id);
CREATE INDEX idx_sportsman_grade ON sport_and_cheerleaders.sportsman (grade_id);

CREATE TABLE sport_and_cheerleaders.location (
    location_id  SERIAL PRIMARY KEY,
    location     VARCHAR(150) UNIQUE NOT NULL
);
COMMENT ON TABLE sport_and_cheerleaders.location IS 'Места проведения соревнований';

CREATE TABLE sport_and_cheerleaders.competition (
    competition_id    SERIAL PRIMARY KEY,
    competition_name  VARCHAR(150) NOT NULL,
    competition_date  DATE     NOT NULL,
    competition_type  SMALLINT NOT NULL REFERENCES sport_and_cheerleaders.competition_type(competition_type_id),
    location          INTEGER  NOT NULL REFERENCES sport_and_cheerleaders.location(location_id)
);
COMMENT ON TABLE sport_and_cheerleaders.competition IS 'Соревнования; N-1 к competition_type и location';
CREATE INDEX idx_competition_date ON sport_and_cheerleaders.competition (competition_date);

CREATE TABLE sport_and_cheerleaders.perfomance_type (
    perfomance_type_id  SMALLSERIAL PRIMARY KEY,
    perfomance_type      VARCHAR(60) UNIQUE NOT NULL
);
COMMENT ON TABLE sport_and_cheerleaders.perfomance_type IS 'Номинации: чир-данс, чир-микс, фристайл, группа, двойка, соло';

CREATE TABLE sport_and_cheerleaders.age_category (
    age_category_id  SMALLSERIAL PRIMARY KEY,
    age_category     VARCHAR(60) UNIQUE NOT NULL
);
COMMENT ON TABLE sport_and_cheerleaders.age_category IS 'Возрастные категории';

CREATE TABLE sport_and_cheerleaders.judge_type (
    judge_type_id  SMALLSERIAL PRIMARY KEY,
    judge_type     VARCHAR(60) UNIQUE NOT NULL
);
COMMENT ON TABLE sport_and_cheerleaders.judge_type IS 'Роль судьи: главный судья, судья по технике, по артистизму, по сложности';

CREATE TABLE sport_and_cheerleaders.judge (
    judge_id          SERIAL PRIMARY KEY,
    judge_name        VARCHAR(50) NOT NULL,
    judge_lastname    VARCHAR(50) NOT NULL,
    judge_middlename  VARCHAR(50),
    judge_type        SMALLINT NOT NULL REFERENCES sport_and_cheerleaders.judge_type(judge_type_id),
    judge_score       INTEGER CHECK (judge_score BETWEEN 0 AND 100)
);
COMMENT ON TABLE  sport_and_cheerleaders.judge             IS 'Судьи; N-1 к judge_type';
COMMENT ON COLUMN sport_and_cheerleaders.judge.judge_score IS 'Квалификационный балл судьи';

CREATE TABLE sport_and_cheerleaders.judge_panel (
    judge_panel_id    SERIAL PRIMARY KEY,
    judge_count       SMALLINT NOT NULL CHECK (judge_count > 0),
    disqualification  BOOLEAN  NOT NULL DEFAULT FALSE,
    total_score       INTEGER,
    total_allowance   INTEGER
);
COMMENT ON TABLE  sport_and_cheerleaders.judge_panel                  IS 'Судейская бригада, оценивающая выступления';
COMMENT ON COLUMN sport_and_cheerleaders.judge_panel.disqualification IS 'Была ли бригадой вынесена хотя бы одна дисквалификация';
COMMENT ON COLUMN sport_and_cheerleaders.judge_panel.total_score      IS 'Сумма баллов, выставленных бригадой';
COMMENT ON COLUMN sport_and_cheerleaders.judge_panel.total_allowance  IS 'Сумма сбавок (штрафов), выставленных бригадой';

CREATE TABLE sport_and_cheerleaders.judge_panel_judge (
    judge_panel_judge_id  SERIAL PRIMARY KEY,
    judge_panel_id        INTEGER NOT NULL REFERENCES sport_and_cheerleaders.judge_panel(judge_panel_id) ON DELETE CASCADE,
    judge_id              INTEGER NOT NULL REFERENCES sport_and_cheerleaders.judge(judge_id),
    UNIQUE (judge_panel_id, judge_id)
);
COMMENT ON TABLE sport_and_cheerleaders.judge_panel_judge IS 'N-M: состав судейской бригады';
CREATE INDEX idx_judge_panel_judge_judge ON sport_and_cheerleaders.judge_panel_judge (judge_id);

CREATE TABLE sport_and_cheerleaders.perfomance (
    perfomance_id      SERIAL PRIMARY KEY,
    competition_id     INTEGER  NOT NULL REFERENCES sport_and_cheerleaders.competition(competition_id) ON DELETE CASCADE,
    perfomance_place   SMALLINT CHECK (perfomance_place > 0),
    perfomance_type    SMALLINT NOT NULL REFERENCES sport_and_cheerleaders.perfomance_type(perfomance_type_id),
    sportsman_count    SMALLINT NOT NULL CHECK (sportsman_count > 0),
    age_category       SMALLINT NOT NULL REFERENCES sport_and_cheerleaders.age_category(age_category_id),
    judge_panel        INTEGER  NOT NULL REFERENCES sport_and_cheerleaders.judge_panel(judge_panel_id)
);
COMMENT ON TABLE  sport_and_cheerleaders.perfomance                  IS 'Выступление; N-1 к competition, perfomance_type, age_category, judge_panel';
COMMENT ON COLUMN sport_and_cheerleaders.perfomance.perfomance_place IS 'Занятое место в номинации; NULL - дисквалификация';
CREATE INDEX idx_perfomance_competition ON sport_and_cheerleaders.perfomance (competition_id);
CREATE INDEX idx_perfomance_panel       ON sport_and_cheerleaders.perfomance (judge_panel);

CREATE TABLE sport_and_cheerleaders.sportsman_perfomance (
    perfomance_sportsman_id  SERIAL PRIMARY KEY,
    perfomance_id            INTEGER NOT NULL REFERENCES sport_and_cheerleaders.perfomance(perfomance_id) ON DELETE CASCADE,
    sportsman_id             INTEGER NOT NULL REFERENCES sport_and_cheerleaders.sportsman(sportsman_id),
    UNIQUE (perfomance_id, sportsman_id)
);
COMMENT ON TABLE sport_and_cheerleaders.sportsman_perfomance IS 'N-M: состав выступления';
CREATE INDEX idx_sportsman_perfomance_sportsman ON sport_and_cheerleaders.sportsman_perfomance (sportsman_id);
