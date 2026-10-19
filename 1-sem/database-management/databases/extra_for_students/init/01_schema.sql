CREATE SCHEMA IF NOT EXISTS extra_for_students;

CREATE TABLE extra_for_students.gender (
    gender_id    SMALLSERIAL PRIMARY KEY,
    gender_name  VARCHAR(8) UNIQUE NOT NULL
);
COMMENT ON TABLE extra_for_students.gender IS 'Справочник полов';

CREATE TABLE extra_for_students.city (
    city_id    SERIAL PRIMARY KEY,
    city_name  VARCHAR(30) UNIQUE NOT NULL,
    timezone   VARCHAR(50) NOT NULL
);
COMMENT ON TABLE extra_for_students.city IS 'Справочник городов с часовым поясом';

CREATE TABLE extra_for_students.format (
    format_id    SMALLSERIAL PRIMARY KEY,
    format_name  VARCHAR(16) UNIQUE NOT NULL
);
COMMENT ON TABLE extra_for_students.format IS 'Формат занятия: очно, дистанционно, смешанный';

CREATE TABLE extra_for_students.subjects (
    subject_id    SERIAL PRIMARY KEY,
    subject_name  VARCHAR(25) UNIQUE NOT NULL
);
COMMENT ON TABLE extra_for_students.subjects IS 'Справочник школьных предметов';

CREATE TABLE extra_for_students.parent (
    parent_id    SERIAL PRIMARY KEY,
    last_name    VARCHAR(50) NOT NULL,
    first_name   VARCHAR(50) NOT NULL,
    middle_name  VARCHAR(50),
    contact      VARCHAR(50) NOT NULL
);
COMMENT ON TABLE extra_for_students.parent IS 'Родители учеников';

CREATE TABLE extra_for_students.tutors (
    tutor_id     SERIAL PRIMARY KEY,
    first_name   VARCHAR(50) NOT NULL,
    last_name    VARCHAR(50) NOT NULL,
    middle_name  VARCHAR(50),
    gender_id    SMALLINT NOT NULL REFERENCES extra_for_students.gender(gender_id),
    city_id      INTEGER  NOT NULL REFERENCES extra_for_students.city(city_id),
    age          SMALLINT NOT NULL CHECK (age BETWEEN 18 AND 80),
    experience   SMALLINT NOT NULL CHECK (experience >= 0),
    contact      VARCHAR(50) NOT NULL,
    CHECK (experience <= age - 16)
);
COMMENT ON TABLE extra_for_students.tutors IS 'Репетиторы; N-1 к gender и city';
CREATE INDEX idx_tutors_city ON extra_for_students.tutors (city_id);

CREATE TABLE extra_for_students.learner (
    learner_id   SERIAL PRIMARY KEY,
    parent_id    INTEGER  NOT NULL REFERENCES extra_for_students.parent(parent_id),
    city_id      INTEGER  NOT NULL REFERENCES extra_for_students.city(city_id),
    first_name   VARCHAR(50) NOT NULL,
    last_name    VARCHAR(50) NOT NULL,
    middle_name  VARCHAR(50),
    study_goal   VARCHAR(200),
    class        SMALLINT NOT NULL CHECK (class BETWEEN 1 AND 11)
);
COMMENT ON TABLE extra_for_students.learner IS 'Ученики; N-1 к parent (у родителя может быть несколько детей) и city';
CREATE INDEX idx_learner_parent ON extra_for_students.learner (parent_id);
CREATE INDEX idx_learner_city   ON extra_for_students.learner (city_id);

CREATE TABLE extra_for_students.tutor_subject (
    tutor_id    INTEGER NOT NULL REFERENCES extra_for_students.tutors(tutor_id) ON DELETE CASCADE,
    subject_id  INTEGER NOT NULL REFERENCES extra_for_students.subjects(subject_id),
    PRIMARY KEY (tutor_id, subject_id)
);
COMMENT ON TABLE extra_for_students.tutor_subject IS 'N-M: какие предметы преподаёт репетитор';
CREATE INDEX idx_tutor_subject_subject ON extra_for_students.tutor_subject (subject_id);

CREATE TABLE extra_for_students.learner_subjects (
    learner_id  INTEGER NOT NULL REFERENCES extra_for_students.learner(learner_id) ON DELETE CASCADE,
    subject_id  INTEGER NOT NULL REFERENCES extra_for_students.subjects(subject_id),
    PRIMARY KEY (learner_id, subject_id)
);
COMMENT ON TABLE extra_for_students.learner_subjects IS 'N-M: по каким предметам занимается ученик';
CREATE INDEX idx_learner_subjects_subject ON extra_for_students.learner_subjects (subject_id);

CREATE TABLE extra_for_students.lesson (
    lesson_id    BIGSERIAL PRIMARY KEY,
    subject_id   INTEGER  NOT NULL REFERENCES extra_for_students.subjects(subject_id),
    format_id    SMALLINT NOT NULL REFERENCES extra_for_students.format(format_id),
    learner_id   INTEGER  NOT NULL REFERENCES extra_for_students.learner(learner_id),
    tutor_id     INTEGER  NOT NULL REFERENCES extra_for_students.tutors(tutor_id),
    lesson_date  DATE     NOT NULL,
    cost         INTEGER  NOT NULL CHECK (cost > 0),
    duration     SMALLINT NOT NULL CHECK (duration > 0)
);
COMMENT ON TABLE  extra_for_students.lesson          IS 'Занятия; N-1 к subjects, format, learner, tutors';
COMMENT ON COLUMN extra_for_students.lesson.cost     IS 'Стоимость занятия, руб.';
COMMENT ON COLUMN extra_for_students.lesson.duration IS 'Длительность, мин.';
CREATE INDEX idx_lesson_learner ON extra_for_students.lesson (learner_id);
CREATE INDEX idx_lesson_tutor   ON extra_for_students.lesson (tutor_id);
CREATE INDEX idx_lesson_date    ON extra_for_students.lesson (lesson_date);

CREATE TABLE extra_for_students.review_of_tutor (
    review_id    SERIAL PRIMARY KEY,
    learner_id   INTEGER  NOT NULL REFERENCES extra_for_students.learner(learner_id),
    parent_id    INTEGER  NOT NULL REFERENCES extra_for_students.parent(parent_id),
    tutor_id     INTEGER  NOT NULL REFERENCES extra_for_students.tutors(tutor_id),
    review_date  DATE     NOT NULL,
    rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text  TEXT
);
COMMENT ON TABLE extra_for_students.review_of_tutor IS 'Отзыв родителя о репетиторе своего ребёнка';
CREATE INDEX idx_review_of_tutor_tutor ON extra_for_students.review_of_tutor (tutor_id);

CREATE TABLE extra_for_students.review_of_learner (
    review_id    SERIAL PRIMARY KEY,
    tutor_id     INTEGER  NOT NULL REFERENCES extra_for_students.tutors(tutor_id),
    learner_id   INTEGER  NOT NULL REFERENCES extra_for_students.learner(learner_id),
    review_date  DATE     NOT NULL,
    rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text  TEXT
);
COMMENT ON TABLE extra_for_students.review_of_learner IS 'Отзыв репетитора об ученике';
CREATE INDEX idx_review_of_learner_learner ON extra_for_students.review_of_learner (learner_id);
