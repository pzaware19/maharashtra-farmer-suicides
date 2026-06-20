# =============================================================================
# C3_figures.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: Two additional figures.
#
#   fig_cotton_price.png    -- COTLOOK A cotton price vs Maharashtra suicides
#   fig_india_percapita.png -- India comparison on per-100K-farmers basis
#
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(ggrepel)
  library(glue)
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
mh_state  <- read_csv(file.path(INPDIR, "ncrb_mh_state.csv"),     show_col_types = FALSE)
india     <- read_csv(file.path(INPDIR, "ncrb_india_states.csv"), show_col_types = FALSE)
cotton    <- read_csv(file.path(INPDIR, "cotton_prices.csv"),      show_col_types = FALSE)
agri_pop  <- read_csv(file.path(INPDIR, "agri_population.csv"),    show_col_types = FALSE)
soybean   <- read_csv(file.path(INPDIR, "soybean_prices.csv"),     show_col_types = FALSE)
onion     <- read_csv(file.path(INPDIR, "onion_prices.csv"),       show_col_types = FALSE)

# ── FIGURE 8: Cotton price vs suicides ────────────────────────────────────────
#{
combined <- mh_state %>%
  select(year, total_suicides) %>%
  left_join(cotton, by = "year")

# Scale factor for dual axis: map price range to suicide range
price_min  <- min(combined$cotlook_a_cents_lb)
price_max  <- max(combined$cotlook_a_cents_lb)
suicide_min <- min(combined$total_suicides)
suicide_max <- max(combined$total_suicides)

scale_price <- function(x) {
  suicide_min + (x - price_min) / (price_max - price_min) * (suicide_max - suicide_min)
}
unscale_price <- function(x) {
  price_min + (x - suicide_min) / (suicide_max - suicide_min) * (price_max - price_min)
}

# Correlation
r_val <- cor(combined$cotlook_a_cents_lb, combined$total_suicides, use = "complete.obs")

cotton_plot <- ggplot(combined, aes(x = year)) +
  # Suicide bars (background)
  geom_col(aes(y = total_suicides), fill = "#FDD0A2", alpha = 0.6, width = 0.7) +
  geom_line(aes(y = total_suicides), colour = "#A63603", linewidth = 1.3) +
  # Cotton price line (scaled to suicide axis)
  geom_line(aes(y = scale_price(cotlook_a_cents_lb)),
            colour = "#2D6A2D", linewidth = 1.3, linetype = "solid") +
  geom_point(aes(y = scale_price(cotlook_a_cents_lb)),
             colour = "#2D6A2D", size = 2.2) +
  # Annotate cotton boom
  annotate("rect", xmin = 2009.5, xmax = 2012.5,
           ymin = -Inf, ymax = Inf, fill = "#F0F7F0", alpha = 0.4) +
  annotate("text", x = 2011, y = 4350,
           label = "Cotton boom\n(2010-12)", size = 2.8,
           colour = "#2D6A2D", hjust = 0.5) +
  # Secondary axis
  scale_y_continuous(
    name   = "Maharashtra farmer suicides (orange bars)",
    labels = comma,
    sec.axis = sec_axis(
      transform = unscale_price,
      name      = "COTLOOK A index (cents/lb, green line)",
      labels    = function(x) paste0(round(x), "¢")
    )
  ) +
  scale_x_continuous(breaks = seq(2001, 2022, 3)) +
  labs(
    title    = "Global Cotton Prices vs. Farmer Suicides in Maharashtra",
    subtitle = glue::glue(
      "Pearson r = {round(r_val, 2)} (inverse: higher prices, fewer suicides). The cotton boom of 2010-12 ",
      "briefly\ndrove suicides down, but the 2012 price crash was followed by a sharp rebound in deaths."
    ),
    x       = NULL,
    caption = "Sources: NCRB ADSI; Cotlook Ltd (COTLOOK A Index, annual average, Aug-Jul marketing year)"
  ) +
  theme_print +
  theme(
    axis.title.y.left  = element_text(colour = "#A63603", size = 9),
    axis.title.y.right = element_text(colour = "#2D6A2D", size = 9)
  )

ggsave(file.path(FIGDIR, "fig_cotton_price.png"), cotton_plot,
       width = 11, height = 6.5, dpi = 300, bg = "white")
message("Saved: fig_cotton_price.png")
#}

# ── FIGURE 9: India comparison — per 100K farmers ─────────────────────────────
#{
india_pc <- india %>%
  left_join(agri_pop, by = c("state", "year")) %>%
  mutate(rate_per_100k = suicides / cultivators_k * 100) %>%
  filter(!is.na(rate_per_100k))

state_colours <- c(
  "Maharashtra"    = "#A63603",
  "Karnataka"      = "#E6550D",
  "AP + Telangana" = "#FDAE6B",
  "Madhya Pradesh" = "#CCCCCC"
)

labels_2022 <- india_pc %>% filter(year == 2022)

# Find year when Karnataka rate exceeded Maharashtra
crossover <- india_pc %>%
  filter(state %in% c("Maharashtra", "Karnataka")) %>%
  select(year, state, rate_per_100k) %>%
  pivot_wider(names_from = state, values_from = rate_per_100k) %>%
  filter(Karnataka > Maharashtra) %>%
  slice_min(year, n = 1) %>%
  pull(year)

percap_plot <- ggplot(india_pc, aes(x = year, y = rate_per_100k, colour = state)) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 1.8) +
  { if (length(crossover) > 0)
      annotate("text", x = crossover, y = 26,
               label = paste0("Karnataka\nexceeds MH\n(", crossover, ")"),
               size = 2.6, colour = "#E6550D", hjust = 0)
  } +
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
  geom_vline(xintercept = 2014, linetype = "dashed",
             colour = "#888888", linewidth = 0.4) +
  scale_colour_manual(values = state_colours, guide = "none") +
  scale_x_continuous(breaks = seq(2001, 2022, 3),
                     limits = c(2001, 2025)) +
  scale_y_continuous(labels = function(x) paste0(round(x, 1))) +
  labs(
    title    = "Farmer Suicide Rates per 100,000 Cultivators: State Comparison",
    subtitle = "Normalising by agricultural population changes the picture. Maharashtra leads throughout,\nbut Karnataka's per-capita rate has exceeded Maharashtra's in some years.",
    x        = NULL,
    y        = "Suicides per 100,000 cultivators",
    caption  = "Sources: NCRB ADSI Table A-2; Census of India 2001 and 2011 (cultivators, main + marginal).\nInter-censal years interpolated; post-2011 extrapolated on 2001-11 trend."
  ) +
  theme_print +
  theme(legend.position = "none")

ggsave(file.path(FIGDIR, "fig_india_percapita.png"), percap_plot,
       width = 11, height = 6.5, dpi = 300, bg = "white")
message("Saved: fig_india_percapita.png")
#}

# ── FIGURE 10: Multi-crop price index ─────────────────────────────────────────
# Index all three crops to 2001=100 so they're comparable on one chart.
# Cotton: COTLOOK A world price (cents/lb)
# Soybean: world price converted to Rs/quintal (via annual USD/INR average)
# Onion: Lasalgaon mandi annual average (Rs/quintal)
#{
base_yr <- 2001

crop_index <- bind_rows(
  cotton %>%
    select(year, price = cotlook_a_cents_lb) %>%
    mutate(crop = "Cotton (COTLOOK A, world)", region = "Vidarbha"),
  soybean %>%
    select(year, price = world_price_rs_qtl) %>%
    mutate(crop = "Soybean (world price, Rs/qtl)", region = "Marathwada"),
  onion %>%
    select(year, price = lasalgaon_rs_qtl) %>%
    mutate(crop = "Onion (Lasalgaon mandi, Rs/qtl)", region = "Nashik belt")
) %>%
  group_by(crop) %>%
  mutate(index = price / price[year == base_yr] * 100) %>%
  ungroup()

crop_colours <- c(
  "Cotton (COTLOOK A, world)"         = "#A63603",
  "Soybean (world price, Rs/qtl)"     = "#2D6A2D",
  "Onion (Lasalgaon mandi, Rs/qtl)"   = "#7B4F9E"
)

# Key annotation events
events <- tibble(
  year  = c(2010, 2011, 2013, 2019, 2012),
  label = c("Onion\ncrash", "Cotton\nboom peak", "Onion\nspike", "Onion\nspike", "Cotton\nbust"),
  crop  = c("Onion (Lasalgaon mandi, Rs/qtl)",
            "Cotton (COTLOOK A, world)",
            "Onion (Lasalgaon mandi, Rs/qtl)",
            "Onion (Lasalgaon mandi, Rs/qtl)",
            "Cotton (COTLOOK A, world)"),
  vjust = c(1.6, -0.6, -0.6, -0.6, 1.6)
) %>%
  left_join(crop_index %>% select(year, crop, index), by = c("year", "crop"))

multi_crop_plot <- ggplot(crop_index, aes(x = year, y = index, colour = crop)) +
  geom_hline(yintercept = 100, linetype = "dotted", colour = "#AAAAAA", linewidth = 0.5) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 1.8) +
  geom_text(
    data    = events,
    aes(label = label, vjust = vjust),
    size    = 2.5,
    fontface = "italic",
    show.legend = FALSE
  ) +
  annotate("text", x = 2001.2, y = 107, label = "baseline (2001 = 100)",
           size = 2.4, colour = "#AAAAAA", hjust = 0) +
  scale_colour_manual(
    values = crop_colours,
    labels = c(
      "Cotton (COTLOOK A, world)"         = "Cotton  |  Vidarbha",
      "Soybean (world price, Rs/qtl)"     = "Soybean  |  Marathwada",
      "Onion (Lasalgaon mandi, Rs/qtl)"   = "Onion  |  Nashik belt"
    )
  ) +
  scale_x_continuous(breaks = seq(2001, 2022, 3)) +
  scale_y_continuous(labels = function(x) paste0(round(x), "")) +
  labs(
    title    = "Commodity Price Volatility Across Maharashtra's Three Agricultural Zones",
    subtitle = "All prices indexed to 2001 = 100. Onion swings far more violently than cotton or soybean.\nEach crash lands on a different region and a different set of farmers.",
    x        = NULL,
    y        = "Price index (2001 = 100)",
    colour   = NULL,
    caption  = paste0(
      "Sources: Cotlook Ltd (COTLOOK A Index); World Bank Pink Sheet (US soybeans, Gulf);\n",
      "NHRDF / Agmarknet (Lasalgaon mandi, Nashik). Onion 2001-2009 approximate."
    )
  ) +
  theme_print +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 9))

ggsave(file.path(FIGDIR, "fig_crop_prices.png"), multi_crop_plot,
       width = 11, height = 6.5, dpi = 300, bg = "white")
message("Saved: fig_crop_prices.png")
#}

message("C3 complete.")
