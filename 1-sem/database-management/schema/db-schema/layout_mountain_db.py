SQL = "../../databases/new/mountain_sport/init/01_schema.sql"
POS = {
    "team": (0, 0), "venue": (0, 330), "judge": (0, 560),
    "athlete": (480, 0), "competition": (480, 300),
    "athlete_competition": (960, 0), "result": (960, 230),
    "attempt": (1400, 230),
}
ROUTE = {
    ("athlete_competition", "athlete_id"): [(800, 75), (800, 45)],
    ("athlete_competition", "competition_id"): [(830, 105), (830, 345)],
    ("result", "athlete_id"): [(910, 305), (910, 45)],
}
