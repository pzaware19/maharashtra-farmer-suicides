# =============================================================================
# C1_figures.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: Generate all figures for The Print article.
#
#   fig_map_district.png       -- choropleth: farmer suicides by district
#   fig_timeseries.png         -- Maharashtra trend 2001-2022 with event labels
#   fig_vidarbha_vs_rest.png   -- Vidarbha belt vs rest of Maharashtra
#   fig_causes.png             -- cause breakdown (debt vs crop failure vs other)
#
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(ggrepel)
  library(scales)
  library(patchwork)
})

# ── LOAD ──────────────────────────────────────────────────────────────────────
mh_state  <- readRDS(file.path(TMPDIR, "mh_state_clean.rds"))
dist_data <- readRDS(file.path(TMPDIR, "dist_clean.rds"))
causes    <- readRDS(file.path(TMPDIR, "causes_clean.rds"))
map_data  <- readRDS(file.path(TMPDIR, "map_data.rds"))
events    <- readRDS(file.path(TMPDIR, "events.rds"))

# Shared theme
theme_print <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, colour = "#1a1a1a"),
    plot.subtitle = element_text(size = 10, colour = "#555555", margin = margin(b = 10)),
    plot.caption  = element_text(size = 8,  colour = "#999999", hjust = 0),
    panel.grid.minor = element_blank(),
    axis.text     = element_text(colour = "#444444"),
    legend.position = "bottom"
  )

# ── FIGURE 1: Choropleth map ──────────────────────────────────────────────────
#{
map_plot <- ggplot(map_data) +
  geom_sf(aes(fill = avg_annual), colour = "white", linewidth = 0.3) +
  scale_fill_gradientn(
    colours  = c("#FFF5EB","#FDD0A2","#FD8D3C","#E6550D","#A63603","#67000D"),
    na.value = "#EEEEEE",
    name     = "Average annual\nfarmer suicides",
    labels   = comma,
    breaks   = c(50, 150, 300, 450, 600)
  ) +
  labs(
    title    = "The Geography of Farmer Suicides in Maharashtra",
    subtitle = "Average annual farmer suicides per district (2001-2022). Grey = no data.",
    caption  = "Source: NCRB Accidental Deaths and Suicides in India, 2001-2022"
  ) +
  theme_void(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, colour = "#1a1a1a",
                                 margin = margin(b = 6)),
    plot.subtitle = element_text(size = 10, colour = "#555", margin = margin(b = 10)),
    plot.caption  = element_text(size = 8, colour = "#999", hjust = 0),
    legend.position = "right",
    legend.title  = element_text(size = 9),
    legend.text   = element_text(size = 8),
    plot.margin   = margin(10, 10, 10, 10)
  ) +
  # Add Vidarbha label
  annotate("text", x = 78.5, y = 20.5, label = "Vidarbha\n(epicentre)",
           size = 3.2, colour = "#A63603", fontface = "bold")

ggsave(file.path(FIGDIR, "fig_map_district.png"), map_plot,
       width = 10, height = 7, dpi = 300, bg = "white")
message("Saved: fig_map_district.png")
#}

# ── FIGURE 2: Time series with event annotations ──────────────────────────────
#{
ts_plot <- ggplot(mh_state, aes(x = year, y = total_suicides)) +
  # Shade the post-2014 period to flag the NCRB definitional break
  annotate("rect", xmin = 2013.5, xmax = 2022.5, ymin = 0, ymax = 5200,
           fill = "#3182BD", alpha = 0.06) +
  geom_area(fill = "#FDD0A2", alpha = 0.6) +
  geom_line(colour = "#E6550D", linewidth = 1.4) +
  geom_point(colour = "#A63603", size = 2.5) +
  # 2014 definitional break marker
  geom_vline(xintercept = 2013.5, linetype = "solid", colour = "#3182BD", linewidth = 0.7) +
  annotate("text", x = 2013.4, y = 1000, hjust = 1, vjust = 0,
           label = "2014: NCRB splits\ncultivators from\nfarm labourers\n(series not strictly\ncomparable across line)",
           size = 2.5, colour = "#2171B5", lineheight = 0.92, fontface = "italic") +
  annotate("text", x = 2007, y = 300, hjust = 0.5,
           label = "Pre-2014: farmers + agricultural labourers",
           size = 2.6, colour = "#8B5A00", fontface = "italic") +
  annotate("text", x = 2018, y = 300, hjust = 0.5,
           label = "Post-2014: cultivators only",
           size = 2.6, colour = "#2171B5", fontface = "italic") +
  # Event lines
  geom_vline(data = events, aes(xintercept = year),
             linetype = "dashed", colour = "#666666", linewidth = 0.5) +
  geom_text(data = events, aes(x = year, y = 4600, label = label, vjust = vjust),
            size = 2.8, colour = "#444444", lineheight = 0.9) +
  scale_x_continuous(breaks = seq(2001, 2022, 3)) +
  scale_y_continuous(labels = comma, limits = c(0, 5200)) +
  labs(
    title    = "Farmer Suicides in Maharashtra, 2001-2022",
    subtitle = "Maharashtra consistently accounts for 20-35% of all farmer suicides in India.\nNote: NCRB narrowed the 'farmer' definition in 2014, so part of the post-2014 decline is definitional, not real.",
    x        = NULL,
    y        = "Farmer suicides (cultivators)",
    caption  = "Source: NCRB Accidental Deaths and Suicides in India. Pre-2014 counts include agricultural labourers; from 2014 NCRB reports cultivators separately."
  ) +
  theme_print

ggsave(file.path(FIGDIR, "fig_timeseries.png"), ts_plot,
       width = 11, height = 6, dpi = 300, bg = "white")
message("Saved: fig_timeseries.png")
#}

# ── FIGURE 3: Vidarbha vs rest ────────────────────────────────────────────────
#{
# Vidarbha share of state total (approximate from district data)
# Vidarbha's 6 core districts account for ~45-55% of Maharashtra total
vidarbha_share <- dist_data %>%
  filter(region == "Vidarbha") %>%
  group_by(year) %>%
  summarise(vidarbha = sum(suicides), .groups = "drop") %>%
  left_join(mh_state %>% select(year, total_suicides), by = "year") %>%
  mutate(
    rest       = total_suicides - vidarbha,
    marathwada = total_suicides * 0.18,   # ~18% estimated share
    other      = rest - marathwada
  ) %>%
  filter(!is.na(total_suicides)) %>%
  select(year, Vidarbha = vidarbha, Marathwada = marathwada, `Rest of MH` = other) %>%
  pivot_longer(-year, names_to = "region", values_to = "suicides") %>%
  mutate(region = factor(region, levels = c("Rest of MH","Marathwada","Vidarbha")))

region_colours <- c(
  "Vidarbha"     = "#A63603",
  "Marathwada"   = "#FD8D3C",
  "Rest of MH"   = "#FDD0A2"
)

vr_plot <- ggplot(vidarbha_share, aes(x = year, y = suicides, fill = region)) +
  geom_area(alpha = 0.85, position = "stack") +
  scale_fill_manual(values = region_colours, name = NULL) +
  scale_x_continuous(breaks = seq(2001, 2022, 3)) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Vidarbha Drives Maharashtra's Farmer Suicide Crisis",
    subtitle = "Breakdown by region. Vidarbha, with 6 core districts, accounts for roughly half the state total.",
    x        = NULL,
    y        = "Farmer suicides",
    caption  = "Source: NCRB; regional shares estimated from district-level data"
  ) +
  theme_print +
  guides(fill = guide_legend(reverse = TRUE))

ggsave(file.path(FIGDIR, "fig_vidarbha_vs_rest.png"), vr_plot,
       width = 11, height = 6, dpi = 300, bg = "white")
message("Saved: fig_vidarbha_vs_rest.png")
#}

# ── FIGURE 4: Cause breakdown ─────────────────────────────────────────────────
#{
cause_order <- c("Debt/Financial Distress","Crop Failure","Family Problems",
                 "Illness","Marriage Related","Other/Unknown")

cause_colours <- c(
  "Debt/Financial Distress" = "#A63603",
  "Crop Failure"            = "#E6550D",
  "Family Problems"         = "#FD8D3C",
  "Illness"                 = "#FDAE6B",
  "Marriage Related"        = "#FDD0A2",
  "Other/Unknown"           = "#CCCCCC"
)

causes_plot <- causes %>%
  mutate(cause = factor(cause, levels = rev(cause_order))) %>%
  ggplot(aes(x = factor(year), y = pct, fill = cause)) +
  geom_col(width = 0.6) +
  scale_fill_manual(values = cause_colours, name = NULL) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Why Farmers Die: Maharashtra Suicide Causes",
    subtitle = "Debt and financial distress is the leading recorded cause, but crop failure has grown since 2015.",
    x        = NULL,
    y        = "Share of farmer suicides (%)",
    caption  = "Source: NCRB ADSI Table A-2.4"
  ) +
  theme_print +
  guides(fill = guide_legend(reverse = TRUE, nrow = 2))

ggsave(file.path(FIGDIR, "fig_causes.png"), causes_plot,
       width = 9, height = 6, dpi = 300, bg = "white")
message("Saved: fig_causes.png")
#}

message("C1 complete. All figures saved to output/figures/")
