import random
from datetime import date

from common import copy_rows, person, rand_date

S = "mountain_sport"

N_ATHLETES = 6000
N_JUDGES = 200
N_COMPETITIONS = 4500

REGIONS = ["Москвы", "Санкт-Петербурга", "Московской области", "Красноярского края", "Кемеровской области",
           "Мурманской области", "Свердловской области", "Челябинской области", "Республики Башкортостан",
           "Пермского края", "Новосибирской области", "Краснодарского края", "Кабардино-Балкарии",
           "Карачаево-Черкесии", "Сахалинской области", "Камчатского края", "Иркутской области",
           "Республики Бурятия", "Алтайского края", "Республики Алтай", "Хабаровского края", "Приморского края",
           "Ленинградской области", "Самарской области", "Нижегородской области", "Тюменской области",
           "Ханты-Мансийского АО", "Томской области", "Омской области", "Республики Татарстан",
           "Ярославской области", "Магаданской области", "Республики Карелия", "Вологодской области",
           "Архангельской области"]
CLUBS = ["СШОР «Юность Москвы»", "СШОР «Школа Олимпийского резерва по горнолыжному спорту»",
         "ГСК «Кировск»", "СШ «Бобровый лог»", "СШОР «Шерегеш»", "СК «Абзаково»", "СШ «Банное»",
         "СШОР «Горный воздух»", "СК «Роза Хутор»", "СК «Приэльбрусье»", "СШ «Домбай»", "СК «Губаха»",
         "СШ «Белокуриха»", "СК «Игора»", "СШ «Хвалынск»", "СК «Сорочаны»", "СШ «Волен»", "СК «Степаново»",
         "СШ «Жемчужина Урала»", "СШ «Гора Белая»", "СК «Мраткино»", "СШ «Холдоми»", "СК «Большой Вудъявр»",
         "СШОР «Динамо»", "ЦСКА", "СШ «Спартак»", "СК «Локомотив»", "СШ «Буревестник»", "СК «Зенит»",
         "СШ «Олимп»"]

# курорт, зимняя погода, весенняя погода
VENUES = [("Роза Хутор", "Мягко, -3..-8, натуральный снег", "Тепло, раскисший снег днём"),
          ("Газпром Лаура", "Мягко, -2..-7", "Оттепели, мокрый снег"),
          ("Красная Поляна (ГТЦ)", "Мягко, -3..-8", "Тепло, жёсткий фирн утром"),
          ("Шерегеш", "Морозно, -15..-25, много снега", "Стабильно, -5..0, пухляк"),
          ("Абзаково", "Морозно, -12..-20", "Переменчиво, оттепели"),
          ("Банное", "Морозно, -12..-20, искусственный снег", "Переменчиво, солнечно"),
          ("Большой Вудъявр (Кировск)", "Полярная ночь, -10..-20, ветер", "Солнечно, -5..0, хороший снег"),
          ("Бобровый лог", "Морозно, -15..-25", "Солнечно, оттепели днём"),
          ("Эльбрус (Азау)", "Высокогорье, -10..-20, ветер", "Солнечно, жёсткий снег"),
          ("Чегет", "Высокогорье, -8..-18", "Солнечно, лавиноопасно"),
          ("Домбай", "Мягко, -5..-12", "Оттепели, лавиноопасно"),
          ("Архыз", "Мягко, -5..-12, много снега", "Тепло, мокрый снег"),
          ("Губаха", "Морозно, -12..-22", "Переменно, -3..+2"),
          ("Белокуриха", "Морозно, -10..-18", "Солнечно, оттепели"),
          ("Манжерок", "Морозно, -10..-20", "Солнечно, оттепели"),
          ("Игора", "Влажно, -5..-12, искусственный снег", "Оттепели, мокрый снег"),
          ("Охта Парк", "Влажно, -5..-10", "Оттепели"),
          ("Сорочаны", "-8..-15, искусственный снег", "Оттепели, жёсткий снег"),
          ("Волен", "-8..-15, искусственный снег", "Оттепели"),
          ("Степаново", "-8..-15, искусственный снег", "Оттепели"),
          ("Хвалынск", "-8..-15, ветер", "Оттепели"),
          ("Гора Белая", "Морозно, -10..-20", "Переменно"),
          ("Хвоинка", "Морозно, -12..-20", "Переменно"),
          ("Холдоми", "Морозно, -20..-30", "Солнечно, -5..0"),
          ("Горный воздух", "Влажно, -5..-12, много снега", "Туманы, мокрый снег"),
          ("Спутник (Мурманск)", "Полярная ночь, -10..-18", "Солнечно, -3..0"),
          ("Мраткино", "Морозно, -15..-20", "Переменно"),
          ("Салманов Хутор", "Морозно, -15..-25", "Солнечно"),
          ("Красное Озеро", "Влажно, -5..-12", "Оттепели"),
          ("Пухтолова гора", "Влажно, -5..-12", "Оттепели")]

# дисциплина, число попыток, базовое время трассы, сек
DISCIPLINES = [("Слалом", 2, 52, 30), ("Гигантский слалом", 2, 68, 28), ("Супергигант", 1, 82, 16),
               ("Скоростной спуск", 1, 108, 10), ("Комбинация", 2, 60, 8), ("Параллельный слалом", 2, 27, 8)]

EVENTS = [("Кубок России, этап {n}", 30), ("Чемпионат России", 6), ("Первенство России", 8),
          ("Всероссийские соревнования «Приз ЗМС {z}»", 12), ("Первенство федерального округа", 14),
          ("Чемпионат региона", 20), ("Открытое первенство СШОР", 10)]
ZMS = ["Л. Смирновой", "В. Зелениной", "А. Цыганова", "Н. Кузнецова", "В. Андреева", "С. Смирновой"]

ATTEMPTS = ["Финишировал", "Не финишировал (DNF)", "Дисквалифицирован (DSQ)", "Не стартовал (DNS)"]

def season_date():
    # горнолыжный сезон: ноябрь-апрель
    while True:
        d = rand_date(date(2012, 11, 1), date(2025, 12, 20))
        if d.month in (11, 12, 1, 2, 3, 4):
            return d

def age_at(birth, d):
    return d.year - birth.year - ((d.month, d.day) < (birth.month, birth.day))

def fill(cur):
    random.seed(2)
    teams = [f"Сборная {r}" for r in REGIONS] + CLUBS
    copy_rows(cur, f"{S}.team", ["team_id", "team_name"], list(enumerate(teams, 1)))

    athletes = []
    for aid in range(1, N_ATHLETES + 1):
        first, last, _, g = person(random.choices("MF", [55, 45])[0])
        birth = rand_date(date(1985, 1, 1), date(2010, 12, 31))
        athletes.append(dict(id=aid, first=first, last=last, birth=birth, g=g,
                             team=random.randint(1, len(teams)), skill=random.gauss(0, 1)))
    copy_rows(cur, f"{S}.athlete", ["athlete_id", "first_name", "last_name", "birth_date", "gender", "team_id"],
              ((a["id"], a["first"], a["last"], a["birth"], a["g"], a["team"]) for a in athletes))

    copy_rows(cur, f"{S}.venue", ["venue_id", "venue_name", "winter_weather_conditions",
                                  "spring_weather_conditions"], [(i, *v) for i, v in enumerate(VENUES, 1)])
    copy_rows(cur, f"{S}.judge", ["judge_id", "last_name", "first_name"],
              [(i, *person()[1::-1]) for i in range(1, N_JUDGES + 1)])
    copy_rows(cur, f"{S}.attempt", ["attempt_id", "attempt_status"], list(enumerate(ATTEMPTS, 1)))

    by_gender = {"M": [a for a in athletes if a["g"] == "M"], "F": [a for a in athletes if a["g"] == "F"]}

    competitions, entries, results = [], [], []
    for cid in range(1, N_COMPETITIONS + 1):
        d = season_date()
        disc, runs, base, _ = random.choices(DISCIPLINES, [x[3] for x in DISCIPLINES])[0]
        g = random.choice("MF")
        event = random.choices(EVENTS, [e[1] for e in EVENTS])[0][0]
        name = event.format(n=random.randint(1, 6), z=random.choice(ZMS))
        name = f"{name}, {disc.lower()}, {'мужчины' if g == 'M' else 'женщины'}"
        venue = random.randint(1, len(VENUES))
        spring_factor = 1.03 if d.month in (3, 4) else 1.0
        course = base * random.uniform(0.9, 1.12) * spring_factor

        # к старту допускаются спортсмены нужного пола в возрасте 15-36 лет
        pool = [a for a in random.sample(by_gender[g], 900) if 15 <= age_at(a["birth"], d) <= 36]
        field = random.sample(pool, min(len(pool), random.randint(25, 60)))

        run1, rows = [], []
        for a in field:
            status = random.choices([1, 2, 3, 4], [85, 9, 3, 3])[0]
            t1 = round(course * (1 + 0.035 * (-a["skill"]) + random.gauss(0, 0.015) + 0.02), 2) \
                if status in (1, 3) or (status == 2 and runs == 2 and random.random() < 0.3) else None
            if status == 3 and random.random() < 0.5:
                t1 = None
            rows.append([a["id"], t1, None, status, a])
            if status == 1 and t1:
                run1.append((t1, len(rows) - 1))

        if runs == 2:
            # во вторую попытку проходят 30 лучших по первой
            for _, idx in sorted(run1)[:30]:
                r = rows[idx]
                if random.random() < 0.05:
                    r[3] = 2  # сошёл во второй попытке
                    continue
                r[2] = round(course * 0.97 * (1 + 0.035 * (-r[4]["skill"]) + random.gauss(0, 0.018) + 0.02), 2)

        finished1 = [r[1] for r in rows if r[1] is not None and r[3] == 1]
        finished2 = [r[2] for r in rows if r[2] is not None]
        competitions.append((cid, name, disc, d, min(finished1) if finished1 else None,
                             min(finished2) if finished2 else None, venue, random.randint(1, N_JUDGES)))
        for r in rows:
            entries.append((r[0], cid))
            results.append((r[0], cid, r[1], r[2], r[3]))

    competitions.sort(key=lambda c: c[3])
    remap = {c[0]: i for i, c in enumerate(competitions, 1)}
    copy_rows(cur, f"{S}.competition", ["competition_id", "competition_name", "discipline", "competition_date",
                                        "attempt1_result", "attempt2_result", "venue_id", "judge_id"],
              ((remap[c[0]], *c[1:]) for c in competitions))
    copy_rows(cur, f"{S}.athlete_competition", ["athlete_competition_id", "athlete_id", "competition_id"],
              ((i, a, remap[c]) for i, (a, c) in enumerate(entries, 1)))
    copy_rows(cur, f"{S}.result", ["result_id", "athlete_id", "competition_id", "attempt1_result",
                                   "attempt2_result", "attempt_id"],
              ((i, a, remap[c], t1, t2, st) for i, (a, c, t1, t2, st) in enumerate(results, 1)))
