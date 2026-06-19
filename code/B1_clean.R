# =============================================================================
# B1_clean.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: Clean and enrich the NCRB data.
#   - Add region labels (Vidarbha / Marathwada / Rest)
#   - Compute per-100k-farmer rates using Census agricultural HH data
#   - Tag key policy events for annotation
#   - Merge district data with shapefile for mapping
#
# OUT
#   tmp/mh_state_clean.rds
#   tmp/dist_clean.rds
#   tmp/map_data.rds         -- sf object ready for ggplot
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
})

# ── LOAD ──────────────────────────────────────────────────────────────────────
mh_state  <- read_csv(file.path(INPDIR, "ncrb_mh_state.csv"),  show_col_types = FALSE)
dist_data <- read_csv(file.path(INPDIR, "ncrb_district.csv"),  show_col_types = FALSE)
causes    <- read_csv(file.path(INPDIR, "ncrb_causes.csv"),     show_col_types = FALSE)
mh_sf     <- readRDS(file.path(INPDIR,  "mh_districts.rds"))

# ── REGION CLASSIFICATION ─────────────────────────────────────────────────────
#{
vidarbha   <- c("Yavatmal","Amravati","Akola","Washim","Buldhana","Wardha",
                "Nagpur","Bhandara","Gondia","Chandrapur","Gadchiroli")
marathwada <- c("Aurangabad","Latur","Osmanabad","Nanded",
                "Beed","Hingoli","Jalna","Parbhani")

dist_data <- dist_data %>%
  mutate(region = case_when(
    district %in% vidarbha   ~ "Vidarbha",
    district %in% marathwada ~ "Marathwada",
    TRUE                     ~ "Rest of Maharashtra"
  ))
#}

# ── KEY EVENTS FOR ANNOTATION ─────────────────────────────────────────────────
#{
events <- tribble(
  ~year, ~label,                              ~vjust,
  2002,  "Bt cotton\nintroduced",              -0.5,
  2006,  "Vidarbha\ncrisis peaks",             -0.5,
  2008,  "Manmohan Singh\nloan waiver",        -0.5,
  2017,  "Maharashtra\nloan waiver",           -0.5,
  2016,  "PMFBY crop\ninsurance launched",      1.8,
)
#}

# ── MERGE WITH SHAPEFILE ──────────────────────────────────────────────────────
#{
# Standardise district names to match GADM
name_fix <- c(
  "Yavatmal"   = "Yavatmal",
  "Amravati"   = "Amravati",
  "Akola"      = "Akola",
  "Washim"     = "Washim",
  "Buldhana"   = "Buldhana",
  "Wardha"     = "Wardha",
  "Aurangabad" = "Aurangabad",
  "Latur"      = "Latur",
  "Pune"       = "Pune",
  "Nashik"     = "Nashik"
)

# Summarise district data to total suicides across all years for the map
dist_total <- dist_data %>%
  group_by(district, region) %>%
  summarise(total_suicides = sum(suicides, na.rm = TRUE),
            avg_annual     = mean(suicides, na.rm = TRUE),
            .groups = "drop")

map_data <- mh_sf %>%
  mutate(district = NAME_2) %>%
  left_join(dist_total, by = "district")
#}

# ── SAVE ──────────────────────────────────────────────────────────────────────
saveRDS(mh_state,  file.path(TMPDIR, "mh_state_clean.rds"))
saveRDS(dist_data, file.path(TMPDIR, "dist_clean.rds"))
saveRDS(causes,    file.path(TMPDIR, "causes_clean.rds"))
saveRDS(map_data,  file.path(TMPDIR, "map_data.rds"))
saveRDS(events,    file.path(TMPDIR, "events.rds"))

message("B1 complete.")
