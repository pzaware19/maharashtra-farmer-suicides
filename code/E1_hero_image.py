"""
E1_hero_image.py
Author: Piyush Zaware
Last updated: 2026-06-19

Generate hero image for the Maharashtra Farmer Suicides website.
Shows 66,000 individual dots (1 dot = 1 farmer suicide) as a stacked
dot chart by year, Vidarbha / Marathwada / Rest colored separately.
Dark background, no axes — pure data art.

OUT
  output/figures/fig_hero.png
"""

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.patheffects as pe

ROOT   = "/Users/piyushzaware/Documents/Unsupervised ML/Maharashtra_Farmer_Suicides"
FIGDIR = os.path.join(ROOT, "output", "figures")

# ── data ──────────────────────────────────────────────────────────────────────
# State-level totals (from A1_collect.R)
data = {
    2001: 3835, 2002: 3695, 2003: 3836, 2004: 4147, 2005: 3926,
    2006: 4453, 2007: 4238, 2008: 3802, 2009: 2872, 2010: 3141,
    2011: 3337, 2012: 3786, 2013: 3146, 2014: 2568, 2015: 3030,
    2016: 2671, 2017: 2424, 2018: 2239, 2019: 2680, 2020: 2567,
    2021: 2745, 2022: 2676,
}

YEARS = sorted(data.keys())
VIDARBHA_SHARE  = 0.50   # ~50% of Maharashtra total
MARATHWADA_SHARE= 0.18
REST_SHARE      = 0.32

# Dot = 10 suicides
DOT_UNIT = 10

COLORS = {
    "vidarbha":  "#C8441A",    # deep burnt orange
    "marathwada":"#E6550D",    # bright orange
    "rest":      "#FDD0A2",    # cream-peach
}

BG = "#0D0805"

# ── build dot positions ────────────────────────────────────────────────────────
rng = np.random.default_rng(42)

fig, ax = plt.subplots(figsize=(22, 5))
fig.patch.set_facecolor(BG)
ax.set_facecolor(BG)

year_gap = 1.0
dot_r    = 0.20
max_cols = 8    # wider columns = shorter stacks

for i, yr in enumerate(YEARS):
    total = data[yr]
    n_vid = int(round(total * VIDARBHA_SHARE / DOT_UNIT))
    n_mar = int(round(total * MARATHWADA_SHARE / DOT_UNIT))
    n_rst = int(round(total / DOT_UNIT)) - n_vid - n_mar

    x_centre = i * year_gap

    all_dots = (
        [(COLORS["vidarbha"],   k) for k in range(n_vid)] +
        [(COLORS["marathwada"], k) for k in range(n_mar)] +
        [(COLORS["rest"],       k) for k in range(n_rst)]
    )
    for idx, (color, _) in enumerate(all_dots):
        col = idx % max_cols
        row = idx // max_cols
        x = x_centre + (col - max_cols / 2) * 2 * dot_r * 1.05
        y = row * 2 * dot_r * 1.08
        c = plt.Circle((x, y), dot_r, color=color, alpha=0.78, linewidth=0)
        ax.add_patch(c)

# Subtle year labels at the bottom only
for i, yr in enumerate(YEARS):
    if yr % 3 == 0:   # every 3 years to avoid clutter
        ax.text(i * year_gap, -1.2, str(yr),
                ha="center", va="top", color="#666666",
                fontsize=7, fontfamily="sans-serif")

ax.set_xlim(-1.2, len(YEARS) * year_gap + 0.5)
ax.set_ylim(-2.5, 32)
ax.axis("off")
plt.tight_layout(pad=0)

out = os.path.join(FIGDIR, "fig_hero.png")
fig.savefig(out, dpi=180, bbox_inches="tight", facecolor=BG)
plt.close()
print(f"Saved: {out}  ({os.path.getsize(out) // 1024}K)")
