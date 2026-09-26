SQL = "../../databases/new/extra_for_students/init/01_schema.sql"
POS = {
    "tutor_subject": (0, 0), "format": (0, 150), "tutors": (0, 280), "gender": (0, 620),
    "subjects": (440, 30), "lesson": (440, 170), "city": (440, 480), "review_of_learner": (440, 630),
    "learner_subjects": (880, 0), "learner": (880, 280),
    "parent": (1320, 560), "review_of_tutor": (1760, 280),
}
ROUTE = {
    ("tutor_subject", "tutor_id"): [(-30, 45), (-30, 325)],
    ("tutors", "gender_id"): [(-50, 415), (-50, 665)],
    ("lesson", "subject_id"): [(410, 245), (410, 75)],
    ("learner_subjects", "learner_id"): [(1330, 45), (1330, 325)],
    ("review_of_tutor", "tutor_id"): [(1730, 385), (1730, 860), (-70, 860), (-70, 325)],
    ("tutors", "city_id"): [(320, 475), (320, 525)],
    ("review_of_learner", "tutor_id"): [(385, 705), (385, 325)],
    ("lesson", "format_id"): [(355, 275), (355, 195)],
    ("learner", "city_id"): [(770, 385), (770, 525)],
    ("review_of_learner", "learner_id"): [(845, 735), (845, 325)],
}
SIDE = {("learner_subjects", "learner_id"): ("right", "right"),
        ("review_of_tutor", "tutor_id"): ("left", "left")}
