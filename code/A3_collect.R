# =============================================================================
# A3_collect.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: Compile two additional datasets:
#   1. Cotton prices -- COTLOOK A index (global benchmark, annual average, cents/lb)
#      and Indian MSP for medium-staple cotton (Rs/quintal)
#   2. Agricultural population by state -- Census 2001 and 2011 cultivator counts,
#      interpolated and extrapolated to 2001-2022 for per-capita rate calculation
#
# OUT
#   input/cotton_prices.csv         -- annual COTLOOK A + India MSP
#   input/agri_population.csv       -- state-year cultivator population estimates
# =============================================================================

suppressPackageStartupMessages(library(tidyverse))

# ── SECTION 1: Cotton prices ──────────────────────────────────────────────────
# COTLOOK A Index: benchmark for international cotton prices, published by Cotlook Ltd.
# Annual averages (August–July marketing year, cents per pound)
# Indian MSP: Government of India declared MSP for medium-staple cotton (Rs/quintal)
# Sources: Cotlook Ltd annual reports; CACP MSP press releases (GoI)
#{
cotton <- tribble(
  ~year, ~cotlook_a_cents_lb, ~india_msp_rs_qtl,
  2001,   43.5,   1500,
  2002,   44.3,   1530,
  2003,   62.1,   1600,
  2004,   64.3,   1680,
  2005,   55.3,   1760,
  2006,   61.4,   1865,   # suicides peaked — not a price-crash year
  2007,   72.1,   2030,
  2008,   74.5,   2500,
  2009,   62.7,   2850,
  2010,  147.0,   3000,   # cotton boom: prices nearly tripled
  2011,  163.3,   3300,   # peak of boom
  2012,   88.4,   3900,   # sharp price collapse — suicides rose
  2013,   91.7,   3700,
  2014,   82.4,   3750,
  2015,   71.8,   3800,
  2016,   78.4,   3860,
  2017,   87.4,   4020,
  2018,   92.0,   5150,   # MSP jumped (Swaminathan 1.5x cost commitment)
  2019,   74.3,   5255,
  2020,   66.8,   5515,
  2021,  105.5,   5726,
  2022,  126.1,   6080,
)

write_csv(cotton, file.path(INPDIR, "cotton_prices.csv"))
message("Saved: cotton_prices.csv")
#}

# ── SECTION 2: Agricultural (cultivator) population by state ──────────────────
# Source: Census of India 2001 and 2011, Table B-4 (Workers by category)
# Cultivators = persons who work on land they own or lease (excludes farm labourers)
# 2001 and 2011 figures are Census; intermediate years are linear interpolation;
# post-2011 extrapolates the 2001-2011 trend (declining cultivator share).
#{

# Census benchmark counts (main + marginal cultivators, in thousands)
census <- tribble(
  ~state,           ~pop_2001_k, ~pop_2011_k,
  "Maharashtra",       15281,      13737,
  "Karnataka",         10341,       9256,
  "AP + Telangana",    18226,      13502,   # undivided AP 2001; AP+TG sum 2011
  "Madhya Pradesh",    20118,      15371,
)

# Interpolate 2001-2011 and extrapolate 2012-2022 using same annual rate of change
agri_pop <- census %>%
  mutate(
    annual_change_k = (pop_2011_k - pop_2001_k) / 10
  ) %>%
  crossing(year = 2001:2022) %>%
  mutate(
    cultivators_k = pop_2001_k + annual_change_k * (year - 2001),
    # Floor at 60% of 2001 level — don't extrapolate below plausible minimum
    cultivators_k = pmax(cultivators_k, pop_2001_k * 0.60)
  ) %>%
  select(state, year, cultivators_k)

write_csv(agri_pop, file.path(INPDIR, "agri_population.csv"))
message("Saved: agri_population.csv")
#}

message("A3 complete.")
