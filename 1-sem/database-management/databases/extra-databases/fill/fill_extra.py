import random
from datetime import date, timedelta

from common import copy_rows, female_last, person, phone, rand_date, TODAY, LAST_NAMES, PATRONYMICS, \
    MALE_FIRST, FEMALE_FIRST

S = "extra_for_students"

N_PARENTS = 40000
N_TUTORS = 4000
N_LESSONS = 300000
N_REVIEWS = 60000

# город, часовой пояс, вес (примерно по населению)
CITIES = [("Москва", "МСК", 130), ("Санкт-Петербург", "МСК", 55), ("Новосибирск", "МСК+4", 16),
          ("Екатеринбург", "МСК+2", 15), ("Казань", "МСК", 13), ("Нижний Новгород", "МСК", 12),
          ("Красноярск", "МСК+4", 11), ("Челябинск", "МСК+2", 11), ("Самара", "МСК+1", 11),
          ("Уфа", "МСК+2", 11), ("Ростов-на-Дону", "МСК", 11), ("Краснодар", "МСК", 11),
          ("Омск", "МСК+3", 11), ("Воронеж", "МСК", 10), ("Пермь", "МСК+2", 10), ("Волгоград", "МСК", 10),
          ("Саратов", "МСК+1", 8), ("Тюмень", "МСК+2", 8), ("Тольятти", "МСК+1", 7), ("Барнаул", "МСК+4", 6),
          ("Ижевск", "МСК+1", 6), ("Махачкала", "МСК", 6), ("Хабаровск", "МСК+7", 6), ("Ульяновск", "МСК+1", 6),
          ("Иркутск", "МСК+5", 6), ("Владивосток", "МСК+7", 6), ("Ярославль", "МСК", 6), ("Томск", "МСК+4", 5),
          ("Оренбург", "МСК+2", 5), ("Кемерово", "МСК+4", 5), ("Рязань", "МСК", 5), ("Набережные Челны", "МСК", 5),
          ("Астрахань", "МСК+1", 5), ("Пенза", "МСК", 5), ("Киров", "МСК", 5), ("Липецк", "МСК", 5),
          ("Калининград", "МСК-1", 5), ("Тула", "МСК", 5), ("Чебоксары", "МСК", 5), ("Курск", "МСК", 4),
          ("Сочи", "МСК", 4), ("Ставрополь", "МСК", 4), ("Тверь", "МСК", 4), ("Мурманск", "МСК", 3),
          ("Якутск", "МСК+6", 3), ("Архангельск", "МСК", 3), ("Петрозаводск", "МСК", 3),
          ("Петропавловск-Камчатский", "МСК+9", 2), ("Южно-Сахалинск", "МСК+8", 2), ("Великий Новгород", "МСК", 2)]

FORMATS = ["Очно", "Дистанционно", "Смешанный"]

# предмет, с какого класса, популярность, базовая цена за 60 мин
SUBJECTS = [("Математика", 1, 30, 1500), ("Русский язык", 1, 22, 1300), ("Английский язык", 1, 24, 1500),
            ("Физика", 7, 10, 1700), ("Химия", 8, 7, 1700), ("Биология", 5, 6, 1500),
            ("Информатика", 5, 7, 1800), ("Программирование", 5, 5, 2200), ("История", 5, 5, 1400),
            ("Обществознание", 6, 8, 1400), ("Литература", 5, 4, 1300), ("География", 5, 2, 1200),
            ("Немецкий язык", 2, 2, 1500), ("Французский язык", 2, 1, 1600), ("Китайский язык", 2, 2, 2000),
            ("Начальная школа", 1, 6, 1100), ("Подготовка к школе", 1, 2, 1000)]

# предметы, которые часто ведёт один репетитор
RELATED = [["Математика", "Физика", "Информатика"], ["Информатика", "Программирование", "Математика"],
           ["Русский язык", "Литература"], ["История", "Обществознание"], ["Химия", "Биология"],
           ["Английский язык", "Немецкий язык"], ["Английский язык", "Французский язык"],
           ["Начальная школа", "Подготовка к школе", "Русский язык", "Математика"], ["Биология", "География"],
           ["Английский язык"], ["Китайский язык"], ["Математика"], ["Русский язык"]]

GOALS = ["Подготовка к ЕГЭ", "Подготовка к ОГЭ", "Подтянуть оценки", "Подготовка к олимпиаде",
         "Подготовка к контрольным", "Углублённое изучение", "Разговорная практика", "Подготовка к ВПР",
         "Поступление в профильный класс", None]

TUTOR_REVIEWS = {5: ["Отличный преподаватель, ребёнок занимается с удовольствием", "Результат виден уже через месяц",
                     "Очень понятно объясняет, рекомендуем", "Сдали экзамен на отлично, спасибо!"],
                 4: ["Хороший репетитор, есть прогресс", "В целом довольны, иногда переносит занятия",
                     "Объясняет хорошо, но много домашних заданий"],
                 3: ["Средне, прогресс небольшой", "Нормально, но ожидали большего"],
                 2: ["Часто опаздывает на занятия", "Ребёнку не подошла манера объяснения"],
                 1: ["Не рекомендуем, занятия проходили формально", "Пропускал занятия без предупреждения"]}
LEARNER_REVIEWS = {5: ["Старательный ученик, всегда выполняет домашние задания", "Быстро схватывает материал"],
                   4: ["Хорошо занимается, иногда не делает домашнее задание", "Есть заметный прогресс"],
                   3: ["Занимается нестабильно", "Нужно больше самостоятельной работы"],
                   2: ["Часто не готов к занятию", "Отвлекается на уроке"],
                   1: ["Пропускает занятия", "Не выполняет задания"]}

def lesson_date():
    # учебный год нагружен сильнее, лето проседает
    while True:
        d = rand_date(date(2021, 9, 1), TODAY)
        if d.month not in (6, 7, 8) or random.random() < 0.3:
            return d

def rating(quality):
    return max(1, min(5, round(random.gauss(quality, 0.8))))

def fill(cur):
    random.seed(1)
    city_ids = list(range(1, len(CITIES) + 1))
    city_w = [c[2] for c in CITIES]
    subj_id = {s[0]: i for i, s in enumerate(SUBJECTS, 1)}

    copy_rows(cur, f"{S}.gender", ["gender_id", "gender_name"], [(1, "Мужской"), (2, "Женский")])
    copy_rows(cur, f"{S}.city", ["city_id", "city_name", "timezone"],
              [(i, c[0], c[1]) for i, c in enumerate(CITIES, 1)])
    copy_rows(cur, f"{S}.format", ["format_id", "format_name"], [(i, f) for i, f in enumerate(FORMATS, 1)])
    copy_rows(cur, f"{S}.subjects", ["subject_id", "subject_name"], [(i, s[0]) for i, s in enumerate(SUBJECTS, 1)])

    # родители; у каждого 1-3 ребёнка из того же города с той же фамилией (1-N)
    parents, learners = [], []
    for pid in range(1, N_PARENTS + 1):
        g = "F" if random.random() < 0.75 else "M"  # чаще на связи мама
        base_last = random.choice(LAST_NAMES)
        pm, pf = random.choice(PATRONYMICS)
        first = random.choice(FEMALE_FIRST if g == "F" else MALE_FIRST)
        last = female_last(base_last) if g == "F" else base_last
        parents.append((pid, last, first, pf if g == "F" else pm, phone()))
        city = random.choices(city_ids, city_w)[0]
        child_patr = random.choice(PATRONYMICS)
        for _ in range(random.choices([1, 2, 3], [60, 32, 8])[0]):
            cg = random.choice("MF")
            learners.append(dict(
                id=len(learners) + 1, parent=pid, city=city, g=cg,
                first=random.choice(MALE_FIRST if cg == "M" else FEMALE_FIRST),
                last=base_last if cg == "M" else female_last(base_last),
                middle=child_patr[0] if cg == "M" else child_patr[1],
                cls=random.choices(range(1, 12), [4, 5, 5, 6, 7, 8, 9, 10, 14, 12, 16])[0],
                goal=random.choice(GOALS), diligence=random.uniform(2.5, 5.0)))
    copy_rows(cur, f"{S}.parent", ["parent_id", "last_name", "first_name", "middle_name", "contact"], parents)
    for l in learners:
        if l["goal"] == "Подготовка к ЕГЭ" and l["cls"] < 10:
            l["goal"] = "Подготовка к ОГЭ" if l["cls"] >= 8 else "Подтянуть оценки"
    copy_rows(cur, f"{S}.learner", ["learner_id", "parent_id", "city_id", "first_name", "last_name",
                                    "middle_name", "study_goal", "class"],
              ((l["id"], l["parent"], l["city"], l["first"], l["last"], l["middle"], l["goal"], l["cls"])
               for l in learners))

    # репетиторы
    tutors = []
    for tid in range(1, N_TUTORS + 1):
        first, last, middle, g = person(random.choices("MF", [35, 65])[0])
        age = random.randint(19, 68)
        exp = min(age - 17, max(0, int(random.gauss((age - 20) * 0.5, 4))))
        tutors.append(dict(id=tid, first=first, last=last, middle=middle, g=1 if g == "M" else 2,
                           city=random.choices(city_ids, city_w)[0], age=age, exp=exp,
                           quality=random.uniform(3.0, 5.0)))
    copy_rows(cur, f"{S}.tutors", ["tutor_id", "first_name", "last_name", "middle_name", "gender_id", "city_id",
                                   "age", "experience", "contact"],
              ((t["id"], t["first"], t["last"], t["middle"], t["g"], t["city"], t["age"], t["exp"], phone())
               for t in tutors))

    # N-M: репетитор - предметы (связанные группы)
    tutor_subject = set()
    for t in tutors:
        group = random.choice(RELATED)
        for s in random.sample(group, random.randint(1, len(group))):
            tutor_subject.add((t["id"], subj_id[s]))
    copy_rows(cur, f"{S}.tutor_subject", ["tutor_id", "subject_id"], sorted(tutor_subject))
    by_subject = {}
    for tid, sid in tutor_subject:
        by_subject.setdefault(sid, []).append(tid)
    tutors_by_city_subject = {}
    for tid, sid in tutor_subject:
        tutors_by_city_subject.setdefault((tutors[tid - 1]["city"], sid), []).append(tid)

    # N-M: ученик - предметы, с учётом класса
    learner_subjects = []
    for l in learners:
        allowed = [(i, s[2]) for i, s in enumerate(SUBJECTS, 1) if s[1] <= l["cls"] and i in by_subject
                   and not (s[0] == "Подготовка к школе" and l["cls"] > 1)
                   and not (s[0] == "Начальная школа" and l["cls"] > 4)]
        k = random.choices([1, 2, 3], [55, 33, 12])[0]
        chosen = set()
        while len(chosen) < min(k, len(allowed)):
            chosen.add(random.choices([a[0] for a in allowed], [a[1] for a in allowed])[0])
        learner_subjects += [(l["id"], sid) for sid in sorted(chosen)]
    copy_rows(cur, f"{S}.learner_subjects", ["learner_id", "subject_id"], learner_subjects)

    # занятия: для каждой пары ученик-предмет постоянный репетитор, который ведёт этот предмет
    pair_tutor = {}
    for lid, sid in learner_subjects:
        local = tutors_by_city_subject.get((learners[lid - 1]["city"], sid))
        pair_tutor[(lid, sid)] = random.choice(local if local and random.random() < 0.7 else by_subject[sid])
    pairs = list(pair_tutor)
    counts = {p: 1 for p in pairs}
    for p in random.choices(pairs, k=N_LESSONS - len(pairs)):
        counts[p] += 1

    lessons, last_lesson = [], {}
    lesson_id = 0
    for (lid, sid), n in counts.items():
        tid = pair_tutor[(lid, sid)]
        t, l = tutors[tid - 1], learners[lid - 1]
        same_city = t["city"] == l["city"]
        fmt = random.choices([1, 2, 3], [55, 30, 15] if same_city else [0, 90, 10])[0]
        duration = random.choices([45, 60, 90], [25, 55, 20])[0]
        price = SUBJECTS[sid - 1][3] * (1 + t["exp"] * 0.025) * (1 + (l["cls"] >= 9) * 0.2) \
            * (0.85 if fmt == 2 else 1.0) * random.uniform(0.85, 1.15)
        cost = int(round(price * duration / 60 / 50) * 50)
        latest = max(date(2021, 9, 1), TODAY - timedelta(days=7 * n + 3))
        start = lesson_date()
        while start > latest:
            start = lesson_date()
        for i in range(n):
            lesson_id += 1
            d = min(TODAY, start + timedelta(days=7 * i + random.randint(-2, 2)))
            lessons.append((lesson_id, sid, fmt, lid, tid, d, cost, duration))
            last_lesson[(lid, tid)] = max(last_lesson.get((lid, tid), d), d)
    random.shuffle(lessons)
    copy_rows(cur, f"{S}.lesson", ["lesson_id", "subject_id", "format_id", "learner_id", "tutor_id",
                                   "lesson_date", "cost", "duration"], lessons)

    # отзывы только по реальным парам ученик-репетитор, после последнего занятия
    lt_pairs = list(last_lesson)
    def review_date(p):
        return min(TODAY, last_lesson[p] + timedelta(days=random.randint(0, 30)))

    rows = []
    for i, (lid, tid) in enumerate(random.sample(lt_pairs, min(N_REVIEWS, len(lt_pairs))), 1):
        r = rating(tutors[tid - 1]["quality"])
        rows.append((i, lid, learners[lid - 1]["parent"], tid, review_date((lid, tid)), r,
                     random.choice(TUTOR_REVIEWS[r]) if random.random() < 0.8 else None))
    copy_rows(cur, f"{S}.review_of_tutor", ["review_id", "learner_id", "parent_id", "tutor_id",
                                            "review_date", "rating", "review_text"], rows)

    rows = []
    for i, (lid, tid) in enumerate(random.sample(lt_pairs, min(N_REVIEWS, len(lt_pairs))), 1):
        r = rating(learners[lid - 1]["diligence"])
        rows.append((i, tid, lid, review_date((lid, tid)), r,
                     random.choice(LEARNER_REVIEWS[r]) if random.random() < 0.8 else None))
    copy_rows(cur, f"{S}.review_of_learner", ["review_id", "tutor_id", "learner_id", "review_date",
                                              "rating", "review_text"], rows)
