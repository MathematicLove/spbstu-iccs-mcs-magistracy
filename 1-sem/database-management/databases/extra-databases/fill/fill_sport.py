import random
from datetime import date

from common import copy_rows, person, rand_date

S = "sport_and_cheerleaders"

N_CLUBS = 1200
N_SPORTSMEN = 60000
N_COMPETITIONS = 1200
N_JUDGES = 2000
MIN_LINKS = 300000

COUNTRIES = {
    "Россия": (90, ["Москва", "Санкт-Петербург", "Московская область", "Ленинградская область",
                    "Краснодарский край", "Ростовская область", "Республика Татарстан", "Республика Башкортостан",
                    "Свердловская область", "Челябинская область", "Новосибирская область", "Красноярский край",
                    "Самарская область", "Нижегородская область", "Пермский край", "Воронежская область",
                    "Саратовская область", "Волгоградская область", "Тюменская область", "Омская область",
                    "Иркутская область", "Приморский край", "Хабаровский край", "Ярославская область",
                    "Тульская область", "Калининградская область", "Ставропольский край", "Удмуртская Республика",
                    "Оренбургская область", "Кемеровская область", "Алтайский край", "Томская область",
                    "Белгородская область", "Курская область", "Липецкая область", "Рязанская область",
                    "Тверская область", "Владимирская область", "Мурманская область", "Республика Крым"]),
    "Беларусь": (4, ["Минск", "Минская область", "Гомельская область", "Брестская область"]),
    "Казахстан": (3, ["Алматы", "Астана", "Карагандинская область", "Шымкент"]),
    "Армения": (1, ["Ереван", "Ширакская область"]),
    "Узбекистан": (1, ["Ташкент", "Самаркандская область"]),
    "Киргизия": (1, ["Бишкек", "Чуйская область"]),
}

CLUB_WORDS = ["Звезда", "Грация", "Феникс", "Пантеры", "Олимп", "Динамо", "Энергия", "Лидер", "Вектор",
              "Импульс", "Вершина", "Спарта", "Allegro", "Viva", "Черри", "Фортуна", "Прайд", "Ника",
              "Лайт", "Стрела", "Юность", "Смена", "Искра", "Галактика", "Буревестник", "Триумф", "Кредо",
              "Максимум", "Легенда", "Орион", "Метеор", "Сириус", "Жемчужина", "Барс", "Тигры", "Ангелы"]
CLUB_KINDS = ["Чир-клуб «{w}»", "СШ по черлидингу «{w}»", "ЧСК «{w}»", "Команда поддержки «{w}»",
              "Клуб черлидинга «{w}»"]
TRANSLIT = str.maketrans({"а": "a", "б": "b", "в": "v", "г": "g", "д": "d", "е": "e", "ё": "e", "ж": "zh",
                          "з": "z", "и": "i", "й": "y", "к": "k", "л": "l", "м": "m", "н": "n", "о": "o",
                          "п": "p", "р": "r", "с": "s", "т": "t", "у": "u", "ф": "f", "х": "h", "ц": "c",
                          "ч": "ch", "ш": "sh", "щ": "sch", "ы": "y", "э": "e", "ю": "yu", "я": "ya",
                          "ь": "", "ъ": ""})

# разряд, минимальный возраст, уровень соревнований (индекс в COMP_TYPES)
GRADE_TYPES = [("3 юношеский разряд", 7, 0), ("2 юношеский разряд", 8, 0), ("1 юношеский разряд", 9, 1),
               ("3 спортивный разряд", 10, 1), ("2 спортивный разряд", 11, 1), ("1 спортивный разряд", 12, 2),
               ("Кандидат в мастера спорта", 14, 2), ("Мастер спорта России", 15, 3),
               ("Мастер спорта международного класса", 16, 4)]
COMP_TYPES = [("Городские", 30), ("Региональные", 30), ("Всероссийские", 22),
              ("Чемпионат и первенство России", 10), ("Международные", 8)]

# номинация, (мин, макс) состав, вес
PERF_TYPES = [("Чир-данс соло", (1, 1), 12), ("Чир-данс двойка", (2, 2), 8), ("Чир-данс группа", (12, 20), 22),
              ("Чир-фристайл соло", (1, 1), 6), ("Чир-фристайл двойка", (2, 2), 4),
              ("Чир-фристайл группа", (12, 20), 12), ("Чир группа", (16, 20), 14), ("Чир-микс группа", (16, 24), 6),
              ("Групповой стант", (4, 5), 10), ("Партнёрский стант", (2, 2), 6)]
AGE_CATS = [("Мини (6-8 лет)", 6, 8), ("Дети (9-11 лет)", 9, 11), ("Юниоры (12-15 лет)", 12, 15),
            ("Взрослые (16+ лет)", 16, 40)]
JUDGE_TYPES = ["Главный судья", "Судья по технике", "Судья по артистизму", "Судья по сложности",
               "Судья по безопасности", "Судья-секретарь"]
CITIES = ["Москва", "Санкт-Петербург", "Казань", "Екатеринбург", "Новосибирск", "Краснодар", "Сочи",
          "Ростов-на-Дону", "Самара", "Нижний Новгород", "Уфа", "Челябинск", "Воронеж", "Пермь", "Минск",
          "Алматы", "Тюмень", "Калининград", "Ярославль", "Красноярск"]
ARENAS = ["Дворец спорта «{c}»", "СК «Олимпийский»", "Ледовая арена «{c}»", "Дворец единоборств",
          "УСК «{c}-Арена»", "Спорткомплекс «Юность»", "ДС «Динамо»", "Дворец гимнастики"]

def age_at(birth, d):
    return d.year - birth.year - ((d.month, d.day) < (birth.month, birth.day))

def cat_of(age):
    for i, (_, lo, hi) in enumerate(AGE_CATS, 1):
        if lo <= age <= hi:
            return i
    return None

def fill(cur):
    random.seed(3)
    countries = list(COUNTRIES)
    copy_rows(cur, f"{S}.country", ["country_id", "country"], list(enumerate(countries, 1)))
    regions = []  # (id, name, country_id, country_weight)
    for cid, c in enumerate(countries, 1):
        for r in COUNTRIES[c][1]:
            # столицы и крупные регионы сильнее: вес убывает по порядку в списке
            rank = len(regions) - sum(1 for x in regions if x[2] != cid)
            regions.append((len(regions) + 1, r, cid, COUNTRIES[c][0] / len(COUNTRIES[c][1]) * 3 / (1 + rank * 0.12)))

    clubs = []
    for club_id in range(1, N_CLUBS + 1):
        region = random.choices(regions, [r[3] for r in regions])[0]
        word = random.choice(CLUB_WORDS)
        name = random.choice(CLUB_KINDS).format(w=word)
        email = f"{word.lower().translate(TRANSLIT)}{club_id}@cheer-{random.choice(['club', 'team', 'sport'])}.ru"
        clubs.append(dict(id=club_id, name=name, region=region[0], founded=rand_date(date(1998, 1, 1),
                                                                                   date(2019, 12, 31)),
                          email=email, level=random.gauss(0, 1), members=[]))

    # спортсмены и приказы о разрядах (1 приказ на 1-6 спортсменов одного клуба - N-1)
    sportsmen, grades = [], []
    for sid in range(1, N_SPORTSMEN + 1):
        club = random.choice(clubs)
        g = random.choices("FM", [85, 15])[0]
        first, last, middle, _ = person(g)
        s = dict(id=sid, first=first, last=last, middle=middle, club=club["id"], grade=None,
                 birth=rand_date(date(1996, 1, 1), date(2019, 6, 30)), skill=random.gauss(club["level"], 1))
        sportsmen.append(s)
        club["members"].append(s)

    for club in clubs:
        waiting = [s for s in club["members"] if age_at(s["birth"], date(2025, 12, 31)) >= 7
                   and random.random() < 0.75]
        random.shuffle(waiting)
        while waiting:
            batch = waiting[:random.randint(1, 6)]
            waiting = waiting[len(batch):]
            youngest = max(s["birth"] for s in batch)
            age_now = age_at(youngest, date(2025, 12, 31))
            skill = sum(s["skill"] for s in batch) / len(batch)
            fit = [i for i, gt in enumerate(GRADE_TYPES) if gt[1] <= age_now]
            gi = max(0, min(fit[-1], int(len(fit) * 0.5 + skill * 1.5 + random.gauss(0, 1))))
            min_date = date(youngest.year + GRADE_TYPES[gi][1], youngest.month, min(youngest.day, 28))
            gdate = rand_date(max(min_date, date(2012, 1, 1)), date(2025, 12, 31))
            ctype = min(len(COMP_TYPES), GRADE_TYPES[gi][2] + 1 + (random.random() < 0.2))
            grades.append((len(grades) + 1, gi + 1, gdate, ctype, random.random() < 0.9))
            for s in batch:
                s["grade"] = len(grades)

    copy_rows(cur, f"{S}.grade_type", ["grade_type_id", "grade_type"],
              [(i, g[0]) for i, g in enumerate(GRADE_TYPES, 1)])
    copy_rows(cur, f"{S}.competition_type", ["competition_type_id", "competition_type"],
              [(i, c[0]) for i, c in enumerate(COMP_TYPES, 1)])
    copy_rows(cur, f"{S}.grade", ["grade_id", "grade_type", "date", "competition_type", "verification"], grades)

    # места проведения и соревнования
    locations = sorted({f"{c}, " + random.choice(ARENAS).format(c=c) for c in CITIES for _ in range(4)})
    copy_rows(cur, f"{S}.location", ["location_id", "location"], list(enumerate(locations, 1)))
    competitions = []
    for _ in range(N_COMPETITIONS):
        ctype = random.choices(range(1, len(COMP_TYPES) + 1), [c[1] for c in COMP_TYPES])[0]
        d = rand_date(date(2016, 1, 15), date(2025, 12, 15))
        loc = random.randint(1, len(locations))
        city = locations[loc - 1].split(",")[0]
        name = {1: f"Открытый турнир г. {city} по черлидингу", 2: f"Чемпионат и первенство региона ({city})",
                3: f"Всероссийские соревнования «Кубок {random.choice(CLUB_WORDS)}»",
                4: "Чемпионат и первенство России по черлидингу",
                5: f"Международный турнир «{random.choice(['Cheer Cup', 'Open Cheer', 'Cheer Stars', 'Grand Prix'])}»"
                }[ctype]
        competitions.append([None, f"{name} {d.year}", d, ctype, loc])
    competitions.sort(key=lambda c: c[2])
    for i, c in enumerate(competitions, 1):
        c[0] = i

    copy_rows(cur, f"{S}.competition", ["competition_id", "competition_name", "competition_date",
                                        "competition_type", "location"], [tuple(c) for c in competitions])
    copy_rows(cur, f"{S}.perfomance_type", ["perfomance_type_id", "perfomance_type"],
              [(i, p[0]) for i, p in enumerate(PERF_TYPES, 1)])
    copy_rows(cur, f"{S}.age_category", ["age_category_id", "age_category"],
              [(i, a[0]) for i, a in enumerate(AGE_CATS, 1)])
    copy_rows(cur, f"{S}.judge_type", ["judge_type_id", "judge_type"], list(enumerate(JUDGE_TYPES, 1)))

    # судьи: главных мало, у главных выше квалификация
    judges = []
    for jid in range(1, N_JUDGES + 1):
        first, last, middle, _ = person(random.choices("MF", [30, 70])[0])
        jt = random.choices(range(1, len(JUDGE_TYPES) + 1), [8, 25, 25, 20, 15, 7])[0]
        score = max(40, min(100, int(random.gauss(85 if jt == 1 else 72, 8))))
        judges.append((jid, first, last, middle, jt, score))
    copy_rows(cur, f"{S}.judge", ["judge_id", "judge_name", "judge_lastname", "judge_middlename",
                                  "judge_type", "judge_score"], judges)
    chiefs = [j[0] for j in judges if j[4] == 1]
    others = [j[0] for j in judges if j[4] != 1]

    # бригады: 1-2 на соревнование, 1 главный судья + 4-6 судей (N-M через judge_panel_judge)
    panels, panel_judges, comp_panels = [], [], {}
    for c in competitions:
        for _ in range(random.choices([1, 2], [60, 40])[0]):
            pid = len(panels) + 1
            members = [random.choice(chiefs)] + random.sample(others, random.randint(4, 6))
            panels.append(dict(id=pid, count=len(members), score=0, allowance=0, dq=False))
            panel_judges += [(pid, j) for j in members]
            comp_panels.setdefault(c[0], []).append(pid)

    # выступления: состав из одного клуба и одной возрастной категории на дату соревнования
    # у каждого соревнования своя программа: 4-8 номинаций (вид x возрастная категория)
    program = {}
    for c in competitions:
        combos = set()
        while len(combos) < random.randint(4, 8):
            combos.add((random.choices(range(len(PERF_TYPES)), [p[2] for p in PERF_TYPES])[0],
                        random.choices(range(1, len(AGE_CATS) + 1), [15, 30, 35, 20])[0]))
        program[c[0]] = list(combos)
    perfs, links = [], []
    while len(links) < MIN_LINKS:
        c = random.choice(competitions)
        d = c[2]
        ti, cat = random.choice(program[c[0]])
        lo, hi = PERF_TYPES[ti][1]
        club = random.choice(clubs)
        members = [s for s in club["members"] if cat_of(age_at(s["birth"], d)) == cat]
        if len(members) < lo:
            continue
        by_cat = {cat: members}
        team = random.sample(by_cat[cat], min(len(by_cat[cat]), random.randint(lo, hi)))
        skill = sum(s["skill"] for s in team) / len(team)
        dq = random.random() < 0.03
        score = 0 if dq else max(10, int(random.gauss(70 + skill * 8, 6)))
        allowance = random.choices([0, 1, 2, 3, 5, 8], [45, 20, 12, 10, 8, 5])[0] + (10 if dq else 0)
        panel = random.choice(comp_panels[c[0]])
        perfs.append(dict(id=len(perfs) + 1, comp=c[0], type=ti + 1, cat=cat, count=len(team),
                          panel=panel, score=score - allowance, dq=dq))
        p = panels[panel - 1]
        p["score"] += score
        p["allowance"] += allowance
        p["dq"] = p["dq"] or dq
        links += [(perfs[-1]["id"], s["id"]) for s in team]

    # места внутри номинации: соревнование + номинация + возрастная категория
    groups = {}
    for p in perfs:
        groups.setdefault((p["comp"], p["type"], p["cat"]), []).append(p)
    medals = {}
    for group in groups.values():
        ranked = sorted((p for p in group if not p["dq"]), key=lambda p: -p["score"])
        for place, p in enumerate(ranked, 1):
            p["place"] = place
        for p in group:
            p.setdefault("place", None)

    copy_rows(cur, f"{S}.judge_panel", ["judge_panel_id", "judge_count", "disqualification", "total_score",
                                        "total_allowance"],
              [(p["id"], p["count"], p["dq"], p["score"], p["allowance"]) for p in panels])
    copy_rows(cur, f"{S}.judge_panel_judge", ["judge_panel_judge_id", "judge_panel_id", "judge_id"],
              [(i, pid, j) for i, (pid, j) in enumerate(panel_judges, 1)])

    # рейтинги: клуб - по числу призовых мест, регион - по числу спортсменов
    club_of_perf = {}
    for pid, sid in links:
        club_of_perf[pid] = sportsmen[sid - 1]["club"]
    for p in perfs:
        if p["place"] and p["place"] <= 3:
            medals[club_of_perf[p["id"]]] = medals.get(club_of_perf[p["id"]], 0) + 1
    club_rank = {cid: i for i, cid in enumerate(sorted((c["id"] for c in clubs),
                                                       key=lambda cid: -medals.get(cid, 0)), 1)}
    region_count = {}
    for s in sportsmen:
        r = clubs[s["club"] - 1]["region"]
        region_count[r] = region_count.get(r, 0) + 1
    region_rows = []
    for cid in range(1, len(countries) + 1):
        in_country = sorted((r for r in regions if r[2] == cid), key=lambda r: -region_count.get(r[0], 0))
        for rank, r in enumerate(in_country, 1):
            region_rows.append((r[0], r[1], rank, region_count.get(r[0], 0), cid))
    copy_rows(cur, f"{S}.region", ["region_id", "region_name", "region_ranking", "sportsmans_count", "country"],
              sorted(region_rows))
    copy_rows(cur, f"{S}.club", ["club_id", "club_name", "club_ranking", "region_id", "birthdate", "email"],
              [(c["id"], c["name"], club_rank[c["id"]], c["region"], c["founded"], c["email"]) for c in clubs])
    copy_rows(cur, f"{S}.sportsman", ["sportsman_id", "sportsman_name", "sportsman_lastname",
                                      "sportsman_middlename", "grade_id", "club_id", "sportsman_birthdate"],
              ((s["id"], s["first"], s["last"], s["middle"], s["grade"], s["club"], s["birth"])
               for s in sportsmen))
    copy_rows(cur, f"{S}.perfomance", ["perfomance_id", "competition_id", "perfomance_place", "perfomance_type",
                                       "sportsman_count", "age_category", "judge_panel"],
              ((p["id"], p["comp"], p["place"], p["type"], p["count"], p["cat"], p["panel"]) for p in perfs))
    copy_rows(cur, f"{S}.sportsman_perfomance", ["perfomance_sportsman_id", "perfomance_id", "sportsman_id"],
              ((i, pid, sid) for i, (pid, sid) in enumerate(links, 1)))
