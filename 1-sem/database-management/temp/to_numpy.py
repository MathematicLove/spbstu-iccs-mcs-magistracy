import numpy as np
import matplotlib.pyplot as plt

def to_arrays(rows):
    labels = np.array([" ".join(str(cell) for cell in row[:-1]) for row in rows])
    values = np.array([float(row[-1]) for row in rows])
    return labels, values

def show_table(columns, rows):
    table = [columns] + [[str(cell) for cell in row] for row in rows]
    widths = [max(len(line[i]) for line in table) for i in range(len(columns))]
    for line in table:
        print("  ".join(cell.ljust(widths[i]) for i, cell in enumerate(line)))

def plot(rows, kind):
    labels, values = to_arrays(rows)
    positions = np.arange(len(values))
    figure, axes = plt.subplots()
    if kind == "bar":
        axes.bar(positions, values)
    else:
        axes.scatter(positions, values)
    axes.set_xticks(positions)
    axes.set_xticklabels(labels, rotation=45, ha="right")
    figure.tight_layout()
    plt.show()