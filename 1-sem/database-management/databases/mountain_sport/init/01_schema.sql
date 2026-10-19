CREATE SCHEMA IF NOT EXISTS mountain_sport;

CREATE TABLE mountain_sport.team (
    team_id    SERIAL PRIMARY KEY,
    team_name  VARCHAR(100) UNIQUE NOT NULL
);
COMMENT ON TABLE mountain_sport.team IS 'Команды (сборные регионов, клубы)';

CREATE TABLE mountain_sport.athlete (
    athlete_id  SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    birth_date  DATE        NOT NULL,
    gender      CHAR(1)     NOT NULL CHECK (gender IN ('M', 'F')),
    team_id     INTEGER     NOT NULL REFERENCES mountain_sport.team(team_id)
);
COMMENT ON TABLE mountain_sport.athlete IS 'Спортсмены; N-1 к team';
CREATE INDEX idx_athlete_team ON mountain_sport.athlete (team_id);

CREATE TABLE mountain_sport.venue (
    venue_id                   SERIAL PRIMARY KEY,
    venue_name                 VARCHAR(100) UNIQUE NOT NULL,
    winter_weather_conditions  VARCHAR(100),
    spring_weather_conditions  VARCHAR(100)
);
COMMENT ON TABLE mountain_sport.venue IS 'Горнолыжные курорты и трассы';

CREATE TABLE mountain_sport.judge (
    judge_id    SERIAL PRIMARY KEY,
    last_name   VARCHAR(50) NOT NULL,
    first_name  VARCHAR(50) NOT NULL
);
COMMENT ON TABLE mountain_sport.judge IS 'Главные судьи соревнований';

CREATE TABLE mountain_sport.competition (
    competition_id    SERIAL PRIMARY KEY,
    competition_name  VARCHAR(150) NOT NULL,
    discipline        VARCHAR(50)  NOT NULL,
    competition_date  DATE         NOT NULL,
    attempt1_result   NUMERIC(7,2),
    attempt2_result   NUMERIC(7,2),
    venue_id          INTEGER NOT NULL REFERENCES mountain_sport.venue(venue_id),
    judge_id          INTEGER NOT NULL REFERENCES mountain_sport.judge(judge_id)
);
COMMENT ON TABLE  mountain_sport.competition                 IS 'Старты; N-1 к venue и judge';
COMMENT ON COLUMN mountain_sport.competition.discipline      IS 'Слалом, гигантский слалом, супергигант, скоростной спуск, комбинация';
COMMENT ON COLUMN mountain_sport.competition.attempt1_result IS 'Лучшее время первой попытки на старте, сек.';
COMMENT ON COLUMN mountain_sport.competition.attempt2_result IS 'Лучшее время второй попытки на старте, сек.';
CREATE INDEX idx_competition_venue ON mountain_sport.competition (venue_id);
CREATE INDEX idx_competition_judge ON mountain_sport.competition (judge_id);

CREATE TABLE mountain_sport.athlete_competition (
    athlete_competition_id  SERIAL PRIMARY KEY,
    athlete_id              INTEGER NOT NULL REFERENCES mountain_sport.athlete(athlete_id),
    competition_id          INTEGER NOT NULL REFERENCES mountain_sport.competition(competition_id) ON DELETE CASCADE,
    UNIQUE (athlete_id, competition_id)
);
COMMENT ON TABLE mountain_sport.athlete_competition IS 'N-M: заявка спортсмена на старт';
CREATE INDEX idx_athlete_competition_comp ON mountain_sport.athlete_competition (competition_id);

CREATE TABLE mountain_sport.attempt (
    attempt_id      SMALLSERIAL PRIMARY KEY,
    attempt_status  VARCHAR(30) UNIQUE NOT NULL
);
COMMENT ON TABLE mountain_sport.attempt IS 'Итог выступления: финишировал, не финишировал (DNF), дисквалифицирован (DSQ), не стартовал (DNS)';

CREATE TABLE mountain_sport.result (
    result_id        SERIAL PRIMARY KEY,
    athlete_id       INTEGER  NOT NULL REFERENCES mountain_sport.athlete(athlete_id),
    competition_id   INTEGER  NOT NULL REFERENCES mountain_sport.competition(competition_id) ON DELETE CASCADE,
    attempt1_result  NUMERIC(7,2),
    attempt2_result  NUMERIC(7,2),
    attempt_id       SMALLINT NOT NULL REFERENCES mountain_sport.attempt(attempt_id),
    UNIQUE (athlete_id, competition_id)
);
COMMENT ON TABLE  mountain_sport.result                 IS 'Результат спортсмена на старте; N-1 к athlete, competition, attempt';
COMMENT ON COLUMN mountain_sport.result.attempt1_result IS 'Время первой попытки, сек.; NULL если не финишировал';
COMMENT ON COLUMN mountain_sport.result.attempt2_result IS 'Время второй попытки, сек.; NULL если не финишировал или не прошёл во вторую';
CREATE INDEX idx_result_competition ON mountain_sport.result (competition_id);
CREATE INDEX idx_result_attempt     ON mountain_sport.result (attempt_id);