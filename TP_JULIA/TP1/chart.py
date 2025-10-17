import numpy as np
import matplotlib.pyplot as plt
for k_instance in range(1,5):
    filename = f"solution{k_instance}.txt"

    with open(filename) as f:
        lines = f.read().strip().splitlines()

    m, n = map(int, lines[0].split())

    sep_indices = [i for i, l in enumerate(lines) if l.strip() == "---"]

    # x grid
    x_grid = np.array([list(map(int, lines[i].split())) for i in range(1, sep_indices[0])])
    # z grid
    z_grid = np.array([list(map(int, lines[i].split())) for i in range(sep_indices[0]+1, sep_indices[1])])
    # species survival
    survival_lines = lines[sep_indices[1]+1:sep_indices[2]]
    # solver info
    solver_info_lines = lines[sep_indices[2]+1:]

    # --- Plot ---
    fig, ax = plt.subplots(figsize=(6,6))
    ax.imshow(x_grid, cmap="Blues", origin="upper")

    for i in range(z_grid.shape[0]):
        for j in range(z_grid.shape[1]):
            if z_grid[i,j] == 1:
                ax.add_patch(plt.Rectangle((j+1-0.5, i+1-0.5), 1, 1, facecolor="black", edgecolor="black"))

    ax.set_xticks(range(n))
    ax.set_yticks(range(m))
    ax.set_xticks(np.arange(-.5, n, 1), minor=True)
    ax.set_yticks(np.arange(-.5, m, 1), minor=True)
    ax.grid(which="minor", color="gray", linewidth=0.5)

    # Add survival probabilities and solver info as a textbox
    plt.gcf().text(1.05, 0.5, "\n".join(survival_lines + solver_info_lines), fontsize=10, va="center")

    plt.tight_layout()
    output_name = f"output{k_instance}.png"
    plt.savefig(output_name, dpi=300, bbox_inches="tight")
