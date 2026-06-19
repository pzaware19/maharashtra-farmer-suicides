# =============================================================================
# C2_figures.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: Generate three additional figures.
#
#   fig_gender.png           -- male vs female farmer suicides over time
#   fig_india_comparison.png -- Maharashtra vs Karnataka, AP+TG, MP
#   fig_rainfall.png         -- Vidarbha rainfall anomaly vs suicides
#
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggrepel)
  library(scales)
})

# Shared theme (mirrors C1_figures.R)
theme_print <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, colour = "#1a1a1a"),
    plot.subtitle = element_text(size = 10, colour = "#555555", margin = margin(b = 10)),
    plot.caption  = element_text(size = 8,  colour = "#999999", hjust = 0),
    panel.grid.minor = element_blank(),
    axis.text     = element_text(colour = "#444444"),
    legend.position = "bottom"
  )

# ── LOAD ──────────────────────────────────────────────────────────────────────
mh_state    <- read_csv(file.path(INPDIR, "ncrb_mh_state.csv"),     show_col_types = FALSE)
india       <- read_csv(file.path(INPDIR, "ncrb_india_states.csv"), show_col_types = FALSE)
rainfall    <- read_csv(file.path(INPDIR, "imd_vidarbha_rainfall.csv"), show_col_types = FALSE)

# ── FIGURE 5: Gender breakdown ─────────────────────────────────────────────────
#{
gender_long <- mh_state %>%
  select(year, Male = male, Female = female) %>%
  pivot_longer(-year, names_to = "gender", values_to = "suicides") %>%
  mutate(gender = factor(gender, levels = c("Male", "Female")))

gender_pct <- mh_state %>%
  mutate(male_pct = round(male / total_suicides * 100, 1)) %>%
  summarise(avg_male_pct = mean(male_pct, na.rm = TRUE)) %>%
  pull(avg_male_pct)

gender_plot <- ggplot(gender_long, aes(x = year, y = suicides, fill = gender)) +
  geom_area(alpha = 0.88, position = "stack") +
  scale_fill_manual(
    values = c("Male" = "#A63603", "Female" = "#FDAE6B"),
    name   = NULL
  ) +
  scale_x_continuous(breaks = seq(2001, 2022, 3)) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Farmer Suicides in Maharashtra by Gender, 2001–2022",
    subtitle = glue::glue("Male farmers account for {round(gender_pct)}% of all farmer suicides on average. Female farmer suicides,\nthough smaller in number, follow the same trend and are not a statistical footnote."),
    x        = NULL,
    y        = "Farmer suicides",
    caption  = "Source: NCRB Accidental Deaths and Suicides in India, Table A-2"
  ) +
  theme_print

ggsave(file.path(FIGDIR, "fig_gender.png"), gender_plot,
       width = 11, height = 6, dpi = 300, bg = "white")
message("Saved: fig_gender.png")
#}

# ── FIGURE 6: India comparison ─────────────────────────────────────────────────
#{
state_colours <- c(
  "Maharashtra"    = "#A63603",
  "Karnataka"      = "#E6550D",
  "AP + Telangana" = "#FDAE6B",
  "Madhya Pradesh" = "#CCCCCC"
)

# Label positions at last year
labels_2022 <- india %>% filter(year == 2022)

india_plot <- ggplot(india, aes(x = year, y = suicides, colour = state)) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 1.8) +
  geom_text_repel(
    data        = labels_2022,
    aes(label   = state),
    hjust       = -0.1,
    size        = 3.2,
    fontface    = "bold",
    direction   = "y",
    nudge_x     = 0.5,
    segment.size= 0.3,
    show.legend = FALSE
  ) +
  # Mark AP bifurcation
  geom_vline(xintercept = 2014, linetype = "dashed",
             colour = "#888888", linewidth = 0.5) +
  annotate("text", x = 2014.2, y = 4200,
           label = "AP bifurcation\n(2014)", hjust = 0,
           size = 2.8, colour = "#888888") +
  scale_colour_manual(values = state_colours, guide = "none") +
  scale_x_continuous(breaks = seq(2001, 2022, 3),
                     limits = c(2001, 2025)) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Farmer Suicides: Maharashtra vs Other High-Burden States",
    subtitle = "Maharashtra has led India's farmer suicide count for most of the past two decades,\nalthough its share has narrowed as other states' numbers fell faster.",
    x        = NULL,
    y        = "Farmer suicides",
    caption  = "Source: NCRB ADSI, Table A-2. AP + Telangana shown as combined for continuity; undivided AP pre-2014."
  ) +
  theme_print +
  theme(legend.position = "none")

ggsave(file.path(FIGDIR, "fig_india_comparison.png"), india_plot,
       width = 11, height = 6.5, dpi = 300, bg = "white")
message("Saved: fig_india_comparison.png")
#}

# ── FIGURE 7: Rainfall vs suicides scatter ────────────────────────────────────
#{
rain_suicide <- rainfall %>%
  left_join(mh_state %>% select(year, total_suicides), by = "year")

# Correlation
r_val <- cor(rain_suicide$anomaly_pct, rain_suicide$total_suicides, use = "complete.obs")

# Label only notable years
label_yrs <- c(2002, 2006, 2008, 2009, 2012, 2014, 2017, 2018)

scatter_plot <- ggplot(rain_suicide, aes(x = anomaly_pct, y = total_suicides)) +
  # Shade drought zone
  annotate("rect", xmin = -Inf, xmax = -19, ymin = -Inf, ymax = Inf,
           fill = "#FFF3F0", alpha = 0.6) +
  annotate("text", x = -22, y = 4400, label = "Drought\n(<-19%)",
           size = 2.8, colour = "#CC6633", hjust = 1) +
  annotate("rect", xmin = 19, xmax = Inf, ymin = -Inf, ymax = Inf,
           fill = "#F0F7F0", alpha = 0.6) +
  annotate("text", x = 22, y = 4400, label = "Surplus\n(>+19%)",
           size = 2.8, colour = "#2D6A2D", hjust = 0) +
  geom_smooth(method = "lm", se = TRUE, colour = "#888888",
              fill = "#DDDDDD", linewidth = 0.8, linetype = "dashed") +
  geom_point(aes(colour = drought), size = 3.5, alpha = 0.85) +
  geom_text_repel(
    data        = rain_suicide %>% filter(year %in% label_yrs),
    aes(label   = year),
    size        = 3,
    colour      = "#333333",
    segment.size= 0.3,
    box.padding = 0.4
  ) +
  scale_colour_manual(
    values = c("TRUE" = "#A63603", "FALSE" = "#666666"),
    labels = c("TRUE" = "Drought year", "FALSE" = "Other year"),
    name   = NULL
  ) +
  labs(
    title    = "Does Rainfall Predict Farmer Suicides in Maharashtra?",
    subtitle = glue::glue("Pearson r = {round(r_val, 2)}. Below-normal rainfall is associated with higher suicides, but the\nrelationship is noisy — 2006 peaked in a near-normal monsoon year, and 2009 saw drought\nbut low suicides due to the 2008 loan waiver."),
    x        = "Vidarbha monsoon rainfall anomaly (% from long-period average)",
    y        = "Maharashtra farmer suicides",
    caption  = "Sources: NCRB ADSI; IMD Vidarbha meteorological sub-division, JJAS rainfall. LPA = 926mm."
  ) +
  theme_print +
  theme(legend.position = "bottom")

ggsave(file.path(FIGDIR, "fig_rainfall.png"), scatter_plot,
       width = 10, height = 7, dpi = 300, bg = "white")
message("Saved: fig_rainfall.png")
#}

message("C2 complete.")
