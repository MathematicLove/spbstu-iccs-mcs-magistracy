"""Генерация drawio-схемы БД источника по init/01_schema.sql.

Позиции таблиц и маршруты связей задаются в layout_<db>.py рядом с этим файлом:
    SQL = путь к 01_schema.sql
    POS = {table: (x, y)}
    ROUTE = {(table, fk_col): [(x, y), ...]}  # необязательные точки излома
    SIDE = {(table, fk_col): ("left"|"right", "left"|"right")}  # необязательные стороны выхода/входа
Запуск: python gen_drawio.py <db>  ->  <db>/<db>.drawio
"""
import html
import importlib
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
ROW, KEY_W, TYPE_W = 30, 50, 90
TYPES = {"SERIAL": "SERIAL", "SMALLSERIAL": "SMALL SERIAL", "BIGSERIAL": "BIG SERIAL", "INTEGER": "INT",
         "SMALLINT": "SMALLINT", "VARCHAR": "VARCHAR", "NUMERIC": "NUMERIC", "CHAR": "CHAR", "TEXT": "TEXT",
         "DATE": "DATE", "BOOLEAN": "BOOLEAN"}
CELL = "rounded=0;whiteSpace=wrap;html=1;"
LABEL = "text;html=1;align=center;verticalAlign=middle;fontStyle=1;"


def parse(sql):
    tables = {}
    for name, body in re.findall(r"CREATE TABLE \w+\.(\w+) \((.*?)\n\);", sql, re.S):
        cols, pk = [], set()
        for line in body.strip().splitlines():
            line = line.strip().rstrip(",")
            m = re.match(r"PRIMARY KEY \((.*)\)", line)
            if m:
                pk |= {c.strip() for c in m.group(1).split(",")}
                continue
            if line.startswith(("UNIQUE", "CHECK")):
                continue
            m = re.match(r"(\w+)\s+([A-Z]+)", line)
            ref = re.search(r"REFERENCES \w+\.(\w+)\((\w+)\)", line)
            cols.append({"name": m.group(1), "type": TYPES[m.group(2)], "pk": "PRIMARY KEY" in line,
                         "uk": "UNIQUE" in line, "ref": ref.groups() if ref else None})
        for c in cols:
            c["pk"] = c["pk"] or c["name"] in pk
        tables[name] = cols
    return tables


def key(c):
    k = [x for x, on in (("PK", c["pk"]), ("FK", c["ref"]), ("UK", c["uk"] and not c["pk"])) if on]
    return " ".join(k)


def build(db):
    lay = importlib.import_module(f"layout_{db}".replace("-", "_"))
    tables = parse((HERE / lay.SQL).read_text())
    route, side = getattr(lay, "ROUTE", {}), getattr(lay, "SIDE", {})
    cells, ids, box, labeled = [], {}, {}, set()
    nid = iter(range(2, 10**6))

    def vertex(value, x, y, w, style=CELL):
        i = next(nid)
        cells.append(f'<mxCell id="{i}" value="{html.escape(value)}" style="{style}" vertex="1" parent="1">'
                     f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{ROW}" as="geometry"/></mxCell>')
        return i

    for t, cols in tables.items():
        x, y = lay.POS[t]
        name_w = max(130, 8 * max(len(c["name"]) for c in cols) + 20)
        w = KEY_W + TYPE_W + name_w
        box[t] = (x, x + w)
        vertex(t.upper(), x, y, w)
        for r, c in enumerate(cols, 1):
            ry = y + r * ROW
            left = vertex(key(c), x, ry, KEY_W)
            vertex(c["type"], x + KEY_W, ry, TYPE_W)
            ids[(t, c["name"])] = (left, vertex(c["name"], x + KEY_W + TYPE_W, ry, name_w))

    for t, cols in tables.items():
        for c in cols:
            if not c["ref"]:
                continue
            rt, rc = c["ref"]
            (sl, sr), (tl, tr) = box[t], box[rt]
            if (t, c["name"]) in side:
                a, b = side[(t, c["name"])]
            elif tl >= sr:
                a, b = "right", "left"
            elif tr <= sl:
                a, b = "left", "right"
            else:
                a = b = "left"
            ex, nx = (1 if a == "right" else 0), (1 if b == "right" else 0)
            pts = "".join(f'<mxPoint x="{px}" y="{py}"/>' for px, py in route.get((t, c["name"]), []))
            pts = f'<Array as="points">{pts}</Array>' if pts else ""
            i = next(nid)
            src, dst = ids[(t, c["name"])][ex], ids[(rt, rc)][nx]
            cells.append(
                f'<mxCell id="{i}" style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=none;endFill=0;'
                f'exitX={ex};exitY=0.5;exitDx=0;exitDy=0;entryX={nx};entryY=0.5;entryDx=0;entryDy=0;" edge="1" '
                f'parent="1" source="{src}" target="{dst}"><mxGeometry relative="1" as="geometry">{pts}'
                f'</mxGeometry></mxCell>')
            ends = [("N", -0.85)] + ([] if (dst, nx) in labeled else [("1", 0.85)])
            labeled.add((dst, nx))
            for val, pos in ends:
                cells.append(f'<mxCell id="{next(nid)}" value="{val}" style="edgeLabel;{LABEL}" vertex="1" '
                             f'connectable="0" parent="{i}"><mxGeometry x="{pos}" y="-10" relative="1" '
                             f'as="geometry"><mxPoint as="offset"/></mxGeometry></mxCell>')

    out = HERE / db / f"{db}.drawio"
    out.parent.mkdir(exist_ok=True)
    out.write_text('<mxfile host="gen"><diagram id="d" name="Page-1"><mxGraphModel grid="1" gridSize="10" '
                   'page="0" background="#ffffff"><root><mxCell id="0"/><mxCell id="1" parent="0"/>'
                   + "".join(cells) + "</root></mxGraphModel></diagram></mxfile>")
    print(out)


if __name__ == "__main__":
    sys.path.insert(0, str(HERE))
    build(sys.argv[1])
