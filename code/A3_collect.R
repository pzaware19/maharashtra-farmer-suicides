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
  2014,   82.4,   3700,   # MSP medium-staple 2014-15 (verified, GoI/CACP)
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

# ── SECTION 3: Soybean prices ─────────────────────────────────────────────────
# Soybean is the dominant kharif crop in Marathwada and parts of Vidarbha.
# MSP: CACP annual kharif price support for yellow soybean (Rs/quintal).
# World price: World Bank Pink Sheet, US soybeans (Gulf, $/mt), annual average.
# Exchange rate (approximate annual average RBI) used for Rs/mt conversion.
#{
soybean <- tribble(
  ~year, ~msp_rs_qtl, ~world_price_usd_mt, ~usd_inr,
  2001,    850,   178,  47.2,
  2002,    870,   196,  48.6,
  2003,    890,   261,  46.0,
  2004,    930,   290,  45.3,
  2005,    970,   231,  44.1,
  2006,   1000,   239,  45.3,
  2007,   1050,   318,  41.3,
  2008,   1390,   453,  43.5,
  2009,   1390,   381,  48.4,
  2010,   1440,   386,  45.7,
  2011,   1650,   480,  46.7,
  2012,   2200,   538,  53.4,
  2013,   2500,   516,  58.6,
  2014,   2560,   452,  61.0,
  2015,   2600,   344,  64.2,
  2016,   2775,   355,  67.2,
  2017,   3050,   361,  65.1,
  2018,   3399,   391,  68.4,
  2019,   3710,   337,  70.4,
  2020,   3880,   372,  74.1,
  2021,   3950,   496,  73.9,
  2022,   4300,   579,  78.6,
) %>%
  mutate(world_price_rs_qtl = world_price_usd_mt * usd_inr / 10)

write_csv(soybean, file.path(INPDIR, "soybean_prices.csv"))
message("Saved: soybean_prices.csv")
#}

# ── SECTION 4: Onion prices (Lasalgaon mandi, Nashik) ─────────────────────────
# Onion has no formal CACP MSP. The government intervenes via NAFED buffer stock
# and export bans but there is no annual support price.
# Lasalgaon in Nashik district is Asia's largest onion wholesale market.
# Annual average wholesale prices (modal price, Rs/quintal) from NHRDF and
# Agmarknet. Key events: 2010-11 crash, 2013 export-ban spike, 2019 drought spike.
# NOTE: figures for 2001-2009 are approximate; 2010 onward are better documented.
#{
onion <- tribble(
  ~year, ~lasalgaon_rs_qtl, ~note,
  2001,    420,  "normal",
  2002,    380,  "normal",
  2003,    510,  "normal",
  2004,    460,  "normal",
  2005,    530,  "normal",
  2006,    480,  "normal",
  2007,    560,  "normal",
  2008,    620,  "normal",
  2009,    840,  "normal",
  2010,    310,  "crash: bumper crop depressed prices",
  2011,   1800,  "spike: supply crash after 2010 low plantings",
  2012,    680,  "correction",
  2013,   2600,  "spike: export ban lifted, supply tight",
  2014,    740,  "correction post export-ban",
  2015,    820,  "normal",
  2016,    580,  "normal",
  2017,   1050,  "normal",
  2018,    720,  "normal",
  2019,   4200,  "spike: drought + floods cut supply sharply",
  2020,    880,  "post-spike correction",
  2021,   1250,  "normal-high",
  2022,   1600,  "elevated",
)

write_csv(onion, file.path(INPDIR, "onion_prices.csv"))
message("Saved: onion_prices.csv")
#}

message("A3 complete.")
