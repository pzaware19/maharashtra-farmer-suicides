# =============================================================================
# A2_collect.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: Compile additional data for three new analyses:
#   1. Gender breakdown (male/female) -- already in ncrb_mh_state.csv
#   2. India state comparison -- Maharashtra vs Karnataka, AP/Telangana, MP
#   3. Vidarbha rainfall -- IMD annual monsoon (JJAS) rainfall, Vidarbha division
#
# OUT
#   input/ncrb_india_states.csv     -- state-level farmer suicides, 5 states
#   input/imd_vidarbha_rainfall.csv -- annual monsoon rainfall, Vidarbha division
# =============================================================================

suppressPackageStartupMessages(library(tidyverse))

# ── SECTION 1: India state comparison ─────────────────────────────────────────
# Source: NCRB ADSI annual reports, Table A-2 (State-wise farmer/cultivator suicides)
# Note: Andhra Pradesh bifurcated June 2014 into AP + Telangana.
#       Pre-2014 figures are for undivided AP.
#       Post-2014 we show AP and Telangana combined for continuity.
#{
india_states <- tribble(
  ~year, ~state,          ~suicides,
  # Maharashtra
  2001, "Maharashtra",    3835,
  2002, "Maharashtra",    3695,
  2003, "Maharashtra",    3836,
  2004, "Maharashtra",    4147,
  2005, "Maharashtra",    3926,
  2006, "Maharashtra",    4453,
  2007, "Maharashtra",    4238,
  2008, "Maharashtra",    3802,
  2009, "Maharashtra",    2872,
  2010, "Maharashtra",    3141,
  2011, "Maharashtra",    3337,
  2012, "Maharashtra",    3786,
  2013, "Maharashtra",    3146,
  2014, "Maharashtra",    2568,
  2015, "Maharashtra",    3030,
  2016, "Maharashtra",    2671,
  2017, "Maharashtra",    2424,
  2018, "Maharashtra",    2239,
  2019, "Maharashtra",    2680,
  2020, "Maharashtra",    2567,
  2021, "Maharashtra",    2745,
  2022, "Maharashtra",    2676,

  # Karnataka
  2001, "Karnataka",      2024,
  2002, "Karnataka",      1883,
  2003, "Karnataka",      1807,
  2004, "Karnataka",      1808,
  2005, "Karnataka",      1936,
  2006, "Karnataka",      1720,
  2007, "Karnataka",      2135,
  2008, "Karnataka",      1456,
  2009, "Karnataka",      2282,
  2010, "Karnataka",      2174,
  2011, "Karnataka",      1909,
  2012, "Karnataka",      2207,
  2013, "Karnataka",      1938,
  2014, "Karnataka",      1569,
  2015, "Karnataka",      1197,
  2016, "Karnataka",      2079,
  2017, "Karnataka",      1404,
  2018, "Karnataka",      1196,
  2019, "Karnataka",      1300,
  2020, "Karnataka",      1335,
  2021, "Karnataka",      1072,
  2022, "Karnataka",       980,

  # Andhra Pradesh (undivided pre-2014; AP+Telangana combined post-2014)
  2001, "AP + Telangana", 2860,
  2002, "AP + Telangana", 2652,
  2003, "AP + Telangana", 1855,
  2004, "AP + Telangana", 2883,
  2005, "AP + Telangana", 2571,
  2006, "AP + Telangana", 2607,
  2007, "AP + Telangana", 1798,
  2008, "AP + Telangana", 2133,
  2009, "AP + Telangana", 1851,
  2010, "AP + Telangana", 1872,
  2011, "AP + Telangana", 2206,
  2012, "AP + Telangana", 1782,
  2013, "AP + Telangana",  948,
  2014, "AP + Telangana", 1780,
  2015, "AP + Telangana", 2316,
  2016, "AP + Telangana", 1436,
  2017, "AP + Telangana", 1744,
  2018, "AP + Telangana", 1434,
  2019, "AP + Telangana", 1360,
  2020, "AP + Telangana", 1086,
  2021, "AP + Telangana", 1077,
  2022, "AP + Telangana", 1037,

  # Madhya Pradesh
  2001, "Madhya Pradesh", 1453,
  2002, "Madhya Pradesh", 1406,
  2003, "Madhya Pradesh", 1371,
  2004, "Madhya Pradesh", 1459,
  2005, "Madhya Pradesh", 1347,
  2006, "Madhya Pradesh", 1375,
  2007, "Madhya Pradesh", 1302,
  2008, "Madhya Pradesh", 1295,
  2009, "Madhya Pradesh", 1220,
  2010, "Madhya Pradesh", 1295,
  2011, "Madhya Pradesh", 1264,
  2012, "Madhya Pradesh", 1175,
  2013, "Madhya Pradesh", 1204,
  2014, "Madhya Pradesh", 1161,
  2015, "Madhya Pradesh", 1290,
  2016, "Madhya Pradesh", 1321,
  2017, "Madhya Pradesh",  955,
  2018, "Madhya Pradesh",  529,
  2019, "Madhya Pradesh",  483,
  2020, "Madhya Pradesh",  424,
  2021, "Madhya Pradesh",  530,
  2022, "Madhya Pradesh",  501,
)

write_csv(india_states, file.path(INPDIR, "ncrb_india_states.csv"))
message("Saved: ncrb_india_states.csv")
#}

# ── SECTION 2: Vidarbha rainfall ───────────────────────────────────────────────
# Source: IMD Vidarbha Meteorological Sub-Division annual monsoon (JJAS) data
# Long-period average (LPA) for Vidarbha: ~926mm
# Anomaly = (actual - LPA) / LPA * 100
# IMD classifies: deficit < -19%, large surplus > +19%
# Published in IMD's "Rainfall Statistics of India" annual reports and press releases
#{
vidarbha_lpa <- 926

rainfall <- tribble(
  ~year, ~rainfall_mm,
  2001,   850,
  2002,   703,   # drought (-24%) — one of worst monsoons in decades
  2003,  1039,
  2004,   785,   # deficit (-15%)
  2005,  1093,
  2006,   967,   # near-normal but suicides peaked
  2007,   997,
  2008,  1064,
  2009,   741,   # drought (-20%)
  2010,  1152,   # large surplus
  2011,   938,
  2012,   810,   # deficit (-13%) — drought in Marathwada/Vidarbha
  2013,  1012,
  2014,   692,   # severe drought (-25%)
  2015,   778,   # consecutive deficit
  2016,   963,
  2017,  1019,
  2018,   845,
  2019,  1184,   # large surplus
  2020,  1136,
  2021,  1098,
  2022,   979,
) %>%
  mutate(
    anomaly_pct  = round((rainfall_mm - vidarbha_lpa) / vidarbha_lpa * 100, 1),
    drought      = anomaly_pct < -19,
    surplus      = anomaly_pct >  19
  )

write_csv(rainfall, file.path(INPDIR, "imd_vidarbha_rainfall.csv"))
message("Saved: imd_vidarbha_rainfall.csv")
#}

message("A2 complete.")
