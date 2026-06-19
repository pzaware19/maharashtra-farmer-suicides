# =============================================================================
# _master.R — Maharashtra Farmer Suicides: Data Journalism Pipeline
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Outputs:
#   output/figures/fig_map_district.png       -- choropleth: suicides by district
#   output/figures/fig_timeseries.png         -- Maharashtra trend 2001-2022
#   output/figures/fig_vidarbha_vs_rest.png   -- Vidarbha belt vs rest
#   output/figures/fig_heatmap.png            -- district x year heatmap
#   output/figures/fig_causes.png             -- cause breakdown
#   output/reports/article_draft.md           -- article draft for The Print
# =============================================================================

if (Sys.info()["user"] == "piyushzaware") {
  root <- "/Users/piyushzaware/Documents/Unsupervised ML/Maharashtra_Farmer_Suicides"
}

INPDIR  <- file.path(root, "input")
CODDIR  <- file.path(root, "code")
OUTDIR  <- file.path(root, "output")
FIGDIR  <- file.path(root, "output", "figures")
TABDIR  <- file.path(root, "output", "tables")
TMPDIR  <- file.path(root, "tmp")

Rscript <- "/usr/local/bin/Rscript"

source(file.path(CODDIR, "A1_collect.R"))
source(file.path(CODDIR, "A2_collect.R"))
source(file.path(CODDIR, "B1_clean.R"))
source(file.path(CODDIR, "C1_figures.R"))
source(file.path(CODDIR, "C2_figures.R"))
