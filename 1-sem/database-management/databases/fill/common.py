import os
import random
from datetime import date, timedelta
from pathlib import Path

import psycopg

ROOT = Path(__file__).resolve().parents[3]

def load_env(prefix):
    wanted = {f"{prefix}_DB_{k}" for k in ("HOST", "PORT", "NAME", "USER", "PASSWORD")}
    found = {}
    path = ROOT / "credentials.env"
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.split("#", 1)[0].strip()
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            if key.strip() in wanted:
                found[key.strip()] = value.strip()
    for key in wanted:
        if os.environ.get(key):
            found[key] = os.environ[key]
    missing = wanted - found.keys()
    if missing:
        raise SystemExit(f"credentials.env: нет {', '.join(sorted(missing))}")
    return found

def connect(prefix):
    e = load_env(prefix)
    return psycopg.connect(
        host=e[f"{prefix}_DB_HOST"], port=e[f"{prefix}_DB_PORT"], dbname=e[f"{prefix}_DB_NAME"],
        user=e[f"{prefix}_DB_USER"], password=e[f"{prefix}_DB_PASSWORD"],
    )

def copy_rows(cur, table, columns, rows):
    n = 0
    with cur.copy(f"COPY {table} ({', '.join(columns)}) FROM STDIN") as cp:
        for row in rows:
            cp.write_row(row)
            n += 1
    print(f"    {table:<45} {n:>8}")
    return n

def reset_sequences(cur, schema):
    cur.execute("""
        SELECT c.table_name, c.column_name
        FROM information_schema.columns c
        WHERE c.table_schema = %s AND c.column_default LIKE 'nextval%%'
    """, (schema,))
    for table, column in cur.fetchall():
        cur.execute(
            f"SELECT setval(pg_get_serial_sequence('{schema}.{table}', '{column}'), "
            f"COALESCE((SELECT max({column}) FROM {schema}.{table}), 0) + 1, false)"
        )

def truncate_schema(cur, schema):
    cur.execute("SELECT tablename FROM pg_tables WHERE schemaname = %s", (schema,))
    tables = [f"{schema}.{t}" for (t,) in cur.fetchall()]
    if tables:
        cur.execute(f"TRUNCATE {', '.join(tables)} RESTART IDENTITY CASCADE")

def rand_date(start, end):
    return start + timedelta(days=random.randint(0, (end - start).days))

def weighted(items):
    values, weights = zip(*items)
    return random.choices(values, weights=weights, k=1)[0]

MALE_FIRST = ["Александр", "Дмитрий", "Максим", "Сергей", "Андрей", "Алексей", "Артём", "Илья", "Кирилл",
              "Михаил", "Никита", "Матвей", "Роман", "Егор", "Арсений", "Иван", "Денис", "Евгений", "Даниил",
              "Тимофей", "Владислав", "Игорь", "Владимир", "Павел", "Руслан", "Марк", "Константин", "Тимур",
              "Олег", "Ярослав", "Антон", "Николай", "Глеб", "Данила", "Степан", "Фёдор", "Лев", "Григорий",
              "Виктор", "Юрий", "Василий", "Пётр", "Вадим", "Станислав", "Борис"]
FEMALE_FIRST = ["Анастасия", "Мария", "Анна", "Виктория", "Екатерина", "Наталья", "Марина", "Полина",
                "Софья", "Дарья", "Алиса", "Ксения", "Александра", "Елена", "Ольга", "Юлия", "Татьяна",
                "Ирина", "Вероника", "Арина", "Валерия", "Елизавета", "Варвара", "Милана", "Кира",
                "Ульяна", "Алина", "Светлана", "Ева", "Василиса", "Диана", "Маргарита", "Людмила",
                "Галина", "Надежда", "Вера", "Любовь", "Кристина", "Яна", "Олеся"]
# фамилия в мужской форме -> женская форма строится по окончанию
LAST_NAMES = ["Иванов", "Смирнов", "Кузнецов", "Попов", "Васильев", "Петров", "Соколов", "Михайлов",
              "Новиков", "Фёдоров", "Морозов", "Волков", "Алексеев", "Лебедев", "Семёнов", "Егоров",
              "Павлов", "Козлов", "Степанов", "Николаев", "Орлов", "Андреев", "Макаров", "Никитин",
              "Захаров", "Зайцев", "Соловьёв", "Борисов", "Яковлев", "Григорьев", "Романов", "Воробьёв",
              "Сергеев", "Кузьмин", "Фролов", "Александров", "Дмитриев", "Королёв", "Гусев", "Киселёв",
              "Ильин", "Максимов", "Поляков", "Сорокин", "Виноградов", "Ковалёв", "Белов", "Медведев",
              "Антонов", "Тарасов", "Жуков", "Баранов", "Филиппов", "Комаров", "Давыдов", "Беляев",
              "Герасимов", "Богданов", "Осипов", "Сидоров", "Матвеев", "Титов", "Марков", "Миронов",
              "Крылов", "Куликов", "Карпов", "Власов", "Мельников", "Денисов", "Гаврилов", "Тихонов",
              "Казаков", "Афанасьев", "Данилов", "Савельев", "Тимофеев", "Фомин", "Чернов", "Абрамов",
              "Мартынов", "Ефимов", "Федотов", "Щербаков", "Назаров", "Калинин", "Исаев", "Чернышёв",
              "Быков", "Маслов", "Родионов", "Коновалов", "Лазарев", "Воронин", "Климов", "Филатов",
              "Пономарёв", "Голубев", "Кудрявцев", "Прохоров", "Наумов", "Потапов", "Журавлёв", "Овчинников",
              "Трофимов", "Леонов", "Соболев", "Ермаков", "Колесников", "Гончаров", "Емельянов", "Никифоров",
              "Грачёв", "Котов", "Гришин", "Ефремов", "Архипов", "Громов", "Кириллов", "Малышев", "Панов",
              "Моисеев", "Румянцев", "Акимов", "Кондратьев", "Бирюков", "Горбунов", "Анисимов", "Ерёмин",
              "Тихомиров", "Галкин", "Лукьянов", "Михеев", "Скворцов", "Юдин", "Белоусов", "Нестеров",
              "Симонов", "Прокофьев", "Харитонов", "Князев", "Цветков", "Левин", "Митрофанов", "Воронов",
              "Аксёнов", "Софронов", "Мальцев", "Логинов", "Горшков", "Савин", "Краснов", "Майоров",
              "Демидов", "Елисеев", "Рыбаков", "Сафонов", "Плотников", "Дёмин", "Хохлов", "Жданов",
              "Островский", "Вишневский", "Белинский", "Покровский", "Черных", "Седых", "Долгих"]

# отчество по имени отца: (мужское, женское)
PATRONYMICS = [("Александрович", "Александровна"), ("Дмитриевич", "Дмитриевна"), ("Сергеевич", "Сергеевна"),
               ("Андреевич", "Андреевна"), ("Алексеевич", "Алексеевна"), ("Михайлович", "Михайловна"),
               ("Иванович", "Ивановна"), ("Владимирович", "Владимировна"), ("Николаевич", "Николаевна"),
               ("Игоревич", "Игоревна"), ("Евгеньевич", "Евгеньевна"), ("Олегович", "Олеговна"),
               ("Викторович", "Викторовна"), ("Павлович", "Павловна"), ("Юрьевич", "Юрьевна"),
               ("Максимович", "Максимовна"), ("Романович", "Романовна"), ("Денисович", "Денисовна"),
               ("Константинович", "Константиновна"), ("Васильевич", "Васильевна"), ("Петрович", "Петровна"),
               ("Анатольевич", "Анатольевна"), ("Вадимович", "Вадимовна"), ("Борисович", "Борисовна"),
               ("Артёмович", "Артёмовна"), ("Кириллович", "Кирилловна"), ("Ильич", "Ильинична"),
               ("Григорьевич", "Григорьевна"), ("Антонович", "Антоновна"), ("Фёдорович", "Фёдоровна")]

def female_last(last):
    if last.endswith(("ов", "ев", "ёв", "ин")):
        return last + "а"
    if last.endswith("ский"):
        return last[:-4] + "ская"
    return last

def person(gender=None):
    """(first, last, middle, gender 'M'/'F') с согласованными родом фамилии и отчества."""
    g = gender or random.choice("MF")
    last = random.choice(LAST_NAMES)
    pm, pf = random.choice(PATRONYMICS)
    if g == "M":
        return random.choice(MALE_FIRST), last, pm, g
    return random.choice(FEMALE_FIRST), female_last(last), pf, g

def phone():
    return f"+7 9{random.randint(0, 99):02d} {random.randint(100, 999)}-{random.randint(10, 99)}-{random.randint(10, 99)}"

TODAY = date(2025, 12, 31)
