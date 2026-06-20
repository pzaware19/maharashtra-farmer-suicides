# =============================================================================
# D2_input_costs.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: Show that MSP has never covered the cost of cultivation for
#       Vidarbha's rainfed cotton, and that the gap in absolute rupees
#       has been widening since 2001.
#
# Two figures:
#   fig_msp_vs_cost.png   -- Cotton MSP per quintal vs A2 cost per quintal,
#                            with shaded shortfall. The single most important
#                            chart for the "MSP alone doesn't work" argument.
#   fig_input_index.png   -- DAP + diesel price index vs cotton + soybean MSP
#                            index (2001 = 100). Shows who gained more over time.
#
# IN:  input/input_costs.csv, input/cotton_prices.csv, input/soybean_prices.csv
# OUT: output/figures/fig_msp_vs_cost.png, fig_input_index.png
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

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
costs   <- read_csv(file.path(INPDIR, "input_costs.csv"),    show_col_types = FALSE)
cotton  <- read_csv(file.path(INPDIR, "cotton_prices.csv"),  show_col_types = FALSE)
soybean <- read_csv(file.path(INPDIR, "soybean_prices.csv"), show_col_types = FALSE)

# ── FIGURE 13: MSP vs A2 cost per quintal (cotton) ────────────────────────────
#{
msp_cost <- costs %>%
  left_join(cotton %>% select(year, india_msp_rs_qtl), by = "year") %>%
  mutate(
    shortfall     = cotton_a2_rs_qtl - india_msp_rs_qtl,
    shortfall_pct = shortfall / cotton_a2_rs_qtl * 100,
    covered       = india_msp_rs_qtl >= cotton_a2_rs_qtl
  )

# Swaminathan C2 cost (≈ 1.65× A2: adds imputed family labour + land rent)
msp_cost <- msp_cost %>%
  mutate(c2_rs_qtl = cotton_a2_rs_qtl * 1.65)

msp_vs_cost_plot <- ggplot(msp_cost, aes(x = year)) +
  # Shaded shortfall region (between MSP and A2 cost)
  geom_ribbon(aes(ymin = india_msp_rs_qtl, ymax = cotton_a2_rs_qtl),
              fill = "#FDAE6B", alpha = 0.35) +
  # C2 cost line (Swaminathan benchmark)
  geom_line(aes(y = c2_rs_qtl, colour = "C2 cost (Swaminathan benchmark, ≈1.65× A2)"),
            linewidth = 0.9, linetype = "dashed") +
  # A2 cost line
  geom_line(aes(y = cotton_a2_rs_qtl, colour = "A2 cost of cultivation"),
            linewidth = 1.3) +
  geom_point(aes(y = cotton_a2_rs_qtl, colour = "A2 cost of cultivation"), size = 2) +
  # MSP line
  geom_line(aes(y = india_msp_rs_qtl, colour = "Government MSP"),
            linewidth = 1.3) +
  geom_point(aes(y = india_msp_rs_qtl, colour = "Government MSP"), size = 2) +
  # Annotate shortfall in 2022
  annotate("text", x = 2019.5, y = (msp_cost$cotton_a2_rs_qtl[msp_cost$year==2022] +
                                      msp_cost$india_msp_rs_qtl[msp_cost$year==2022])/2,
           label = "Shortfall:\nRs 3,600/quintal\n(2022)",
           size = 3, colour = "#8B3000", hjust = 0.5, fontface = "italic") +
  annotate("text", x = 2001.5, y = (msp_cost$cotton_a2_rs_qtl[msp_cost$year==2001] +
                                      msp_cost$india_msp_rs_qtl[msp_cost$year==2001])/2 - 200,
           label = "Rs 833/quintal\n(2001)",
           size = 2.8, colour = "#8B3000", hjust = 0, fontface = "italic") +
  scale_colour_manual(values = c(
    "A2 cost of cultivation"                       = "#A63603",
    "Government MSP"                               = "#2D6A2D",
    "C2 cost (Swaminathan benchmark, ≈1.65× A2)"  = "#888888"
  )) +
  scale_x_continuous(breaks = seq(2001, 2022, 3)) +
  scale_y_continuous(labels = function(x) paste0("Rs ", comma(x))) +
  labs(
    title    = "Cotton MSP Has Never Covered the Cost of Growing It in Vidarbha",
    subtitle = paste0(
      "A2 cost = paid-out cultivation costs per quintal (CACP Maharashtra estimates, typical Vidarbha yield ~7 qtl/ha).\n",
      "MSP is the government's announced minimum support price. The shaded gap is what farmers lose even if they sell at MSP."
    ),
    x       = NULL,
    y       = "Rs per quintal (kapas)",
    colour  = NULL,
    caption = paste0(
      "Sources: CACP Cost of Cultivation Survey (Maharashtra); GoI MSP press releases.\n",
      "A2 cost covers seed, fertiliser, pesticide, hired labour, irrigation, and machine hire. Excludes family labour and land rent.\n",
      "C2 cost adds imputed family labour and land rent (Swaminathan Commission definition). Yield = 6–7 quintals/hectare (dryland Vidarbha)."
    )
  ) +
  theme_print +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 9))

ggsave(file.path(FIGDIR, "fig_msp_vs_cost.png"), msp_vs_cost_plot,
       width = 11, height = 6.5, dpi = 300, bg = "white")
message("Saved: fig_msp_vs_cost.png")
#}

# ── FIGURE 14: Input price index vs MSP index (2001 = 100) ────────────────────
#{
base <- 2001

index_df <- bind_rows(
  costs %>%
    transmute(year,
              value = dap_rs_bag50kg / dap_rs_bag50kg[year == base] * 100,
              series = "DAP fertiliser price"),
  costs %>%
    transmute(year,
              value = diesel_rs_litre / diesel_rs_litre[year == base] * 100,
              series = "Diesel price"),
  cotton %>%
    transmute(year,
              value = india_msp_rs_qtl / india_msp_rs_qtl[year == base] * 100,
              series = "Cotton MSP"),
  soybean %>%
    transmute(year,
              value = msp_rs_qtl / msp_rs_qtl[year == base] * 100,
              series = "Soybean MSP")
)

# Compute compound annual growth rates for subtitle
cagr <- function(start, end, n) ((end/start)^(1/n) - 1) * 100
v <- index_df %>%
  filter(year %in% c(2001, 2022)) %>%
  pivot_wider(names_from = year, values_from = value) %>%
  mutate(cagr_pct = cagr(`2001`, `2022`, 21)) %>%
  select(series, cagr_pct)

series_cols <- c(
  "DAP fertiliser price" = "#8B3000",
  "Diesel price"         = "#CC5500",
  "Cotton MSP"           = "#2D6A2D",
  "Soybean MSP"          = "#74C476"
)

labels_2022 <- index_df %>%
  filter(year == 2022) %>%
  left_join(v, by = "series") %>%
  mutate(label = paste0(series, "\n(CAGR ", round(cagr_pct, 1), "%/yr)"))

index_plot <- ggplot(index_df, aes(x = year, y = value, colour = series)) +
  geom_hline(yintercept = 100, linetype = "dotted", colour = "#AAAAAA") +
  geom_line(linewidth = 1.3) +
  geom_point(size = 1.8) +
  # Annotate 2008 DAP spike
  annotate("text", x = 2008.3, y = 255,
           label = "2008: phosphate\nprice shock", size = 2.5,
           colour = "#8B3000", hjust = 0, fontface = "italic") +
  geom_text(data = labels_2022,
            aes(x = 2022.3, label = label),
            hjust = 0, size = 2.8, fontface = "bold", show.legend = FALSE) +
  scale_colour_manual(values = series_cols, guide = "none") +
  scale_x_continuous(breaks = seq(2001, 2022, 3), limits = c(2001, 2027)) +
  scale_y_continuous(labels = function(x) paste0(round(x), "")) +
  labs(
    title    = "Input Costs Outpaced MSP Support for Key Maharashtra Crops",
    subtitle = paste0(
      "All series indexed to 2001 = 100. Diesel and DAP fertiliser are the two largest variable cost items for cotton and soybean.\n",
      "Cotton MSP rose faster than diesel but has not kept pace with the full cost of cultivation when labour is included."
    ),
    x       = NULL,
    y       = "Price index (2001 = 100)",
    caption = paste0(
      "Sources: PPAC (diesel retail, Delhi); FICCI / DAC (DAP Rs/50 kg bag); CACP MSP press releases.\n",
      "DAP and diesel together account for 40-50% of A2 cost of cotton cultivation in Maharashtra."
    )
  ) +
  theme_print

ggsave(file.path(FIGDIR, "fig_input_index.png"), index_plot,
       width = 11, height = 6.5, dpi = 300, bg = "white")
message("Saved: fig_input_index.png")
#}

message("D2 complete.")
