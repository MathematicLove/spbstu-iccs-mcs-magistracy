SQL = "../../databases/new/sport_and_cheerleaders/init/01_schema.sql"
POS = {
    "country": (0, 0), "region": (0, 130), "club": (0, 360), "grade_type": (0, 640),
    "judge_type": (440, 0), "sportsman": (440, 280), "grade": (440, 600),
    "judge": (880, 0), "sportsman_perfomance": (880, 300), "competition_type": (880, 640),
    "judge_panel_judge": (1320, 0), "perfomance": (1320, 260), "competition": (1320, 580),
    "judge_panel": (1760, 0), "perfomance_type": (1760, 260), "age_category": (1760, 380), "location": (1760, 620),
}
ROUTE = {
    ("region", "country"): [(-30, 295), (-30, 45)],
    ("club", "region_id"): [(-50, 495), (-50, 175)],
    ("sportsman", "grade_id"): [(410, 445), (410, 645)],
    ("perfomance", "competition_id"): [(1295, 335), (1295, 625)],
    ("sportsman_perfomance", "perfomance_id"): [(1260, 375), (1260, 305)],
    ("perfomance", "judge_panel"): [(1725, 485), (1725, 45)],
    ("judge_panel_judge", "judge_panel_id"): [(1700, 75), (1700, 45)],
}
