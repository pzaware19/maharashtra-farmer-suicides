# =============================================================================
# D1_regression.R
# Author: Piyush Zaware
# Last updated: 2026-06-19
#
# Goal: State-level time series regression separating the three drivers of
#       Maharashtra farmer suicides: cotton price, monsoon, and loan waivers.
#
# NOTE ON IDENTIFICATION
# This is a state-level OLS (n=22). Regressors vary only over time, so district
# fixed effects are not applicable. We cannot rule out other year-to-year
# confounders. The coefficients should be read as conditional associations,
# not causal estimates. A proper causal design would require district-year
# variation in the regressors (e.g., crop-area-weighted price shocks by district).
#
# MODELS
#   m1: OLS levels  -- total_suicides ~ cotton + rainfall + waivers + trend
#   m2: OLS log     -- log(suicides+1) ~ same RHS (% interpretation)
#   m3: OLS log + quadratic trend (captures non-linear downward drift post-2006)
#
# FIGURES
#   fig_regression_fit.png   -- actual vs fitted (m2), with waiver & price annotations
#   fig_regression_coefs.png -- horizontal coefficient plot with 95% CI (m1, m2, m3)
#
# TABLES
#   output/tables/reg_table.html  -- modelsummary HTML fragment for Quarto embedding
#
# IN:  input/ncrb_mh_state.csv, input/cotton_prices.csv, input/imd_vidarbha_rainfall.csv
# OUT: output/figures/fig_regression_fit.png, fig_regression_coefs.png
#      output/tables/reg_table.html
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
  library(lmtest)
  library(sandwich)
  library(modelsummary)
  library(broom)
})

theme_print <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, colour = "#1a1a1a"),
    plot.subtitle = element_text(size = 10,  colour = "#555555", margin = margin(b = 10)),
    plot.caption  = element_text(size = 8,   colour = "#999999", hjust = 0),
    panel.grid.minor = element_blank(),
    axis.text     = element_text(colour = "#444444"),
    legend.position = "bottom"
  )

dir.create(file.path(OUTDIR, "tables"), showWarnings = FALSE)

# ── LOAD & MERGE ──────────────────────────────────────────────────────────────
#{
state   <- read_csv(file.path(INPDIR, "ncrb_mh_state.csv"),      show_col_types = FALSE)
cotton  <- read_csv(file.path(INPDIR, "cotton_prices.csv"),       show_col_types = FALSE)
rain    <- read_csv(file.path(INPDIR, "imd_vidarbha_rainfall.csv"), show_col_types = FALSE)

panel <- state %>%
  left_join(cotton %>% select(year, cotlook_a_cents_lb, india_msp_rs_qtl), by = "year") %>%
  left_join(rain   %>% select(year, anomaly_pct, drought),                  by = "year") %>%
  mutate(
    year_c          = year - 2001,                     # trend: 0 in 2001
    # Cotton price: standardise for coefficient comparability
    cotton_z        = scale(cotlook_a_cents_lb)[,1],
    # Waiver windows: coded as binary indicators for the 2-3 years of relief
    waiver_2008     = as.integer(year %in% 2009:2011), # UPA national waiver
    waiver_2017     = as.integer(year %in% 2017:2019), # Maharashtra state waiver
    log_suicides    = log1p(total_suicides)
  )
#}

# ── REGRESSION MODELS ─────────────────────────────────────────────────────────
#{
# Model 1: levels
m1 <- lm(total_suicides ~ cotton_z + anomaly_pct + waiver_2008 + waiver_2017 + year_c,
          data = panel)

# Model 2: log (% interpretation)
m2 <- lm(log_suicides ~ cotton_z + anomaly_pct + waiver_2008 + waiver_2017 + year_c,
          data = panel)

# Model 3: log + quadratic trend (post-2006 non-linear decline)
m3 <- lm(log_suicides ~ cotton_z + anomaly_pct + waiver_2008 + waiver_2017 +
            year_c + I(year_c^2),
          data = panel)

# HC3 robust standard errors (small n, potential heteroskedasticity)
se_m1 <- sqrt(diag(vcovHC(m1, type = "HC3")))
se_m2 <- sqrt(diag(vcovHC(m2, type = "HC3")))
se_m3 <- sqrt(diag(vcovHC(m3, type = "HC3")))

message(sprintf("Model R² — M1: %.3f | M2: %.3f | M3: %.3f",
                summary(m1)$r.squared, summary(m2)$r.squared, summary(m3)$r.squared))
#}

# ── FIGURE 11: Actual vs fitted ────────────────────────────────────────────────
#{
fitted_df <- panel %>%
  mutate(
    fitted_log = fitted(m2),
    fitted     = expm1(fitted_log)
  )

# Key annotation events
annots <- tribble(
  ~year, ~label,          ~y_off,
  2006,  "2006 peak",      200,
  2009,  "2008\nwaiver",  -280,
  2012,  "Cotton\ncrash",  200,
  2017,  "2017\nwaiver",  -280,
) %>%
  left_join(panel %>% select(year, total_suicides), by = "year") %>%
  mutate(y_label = total_suicides + y_off)

fit_plot <- ggplot(fitted_df, aes(x = year)) +
  geom_col(aes(y = total_suicides), fill = "#FDD0A2", alpha = 0.55, width = 0.7) +
  geom_line(aes(y = total_suicides, colour = "Actual"), linewidth = 1.1) +
  geom_line(aes(y = fitted,         colour = "Model fit"), linewidth = 1.1, linetype = "dashed") +
  geom_point(aes(y = total_suicides), colour = "#A63603", size = 2) +
  geom_vline(xintercept = c(2009, 2017), linetype = "dotted",
             colour = "#2D6A2D", linewidth = 0.6) +
  geom_text(data = annots, aes(x = year, y = y_label, label = label),
            size = 2.8, colour = "#333333", hjust = 0.5) +
  scale_colour_manual(values = c("Actual" = "#A63603", "Model fit" = "#555555")) +
  scale_x_continuous(breaks = seq(2001, 2022, 3)) +
  scale_y_continuous(labels = comma) +
  labs(
    title    = "Regression Model: Actual vs. Fitted Farmer Suicides",
    subtitle = sprintf(
      "Log OLS (n=22). Three regressors explain %.0f%% of variance: cotton price, monsoon anomaly, waiver windows.\nDashed line = model prediction. The model misses 2006 (structural credit crisis, not a price-crash year).",
      summary(m2)$r.squared * 100
    ),
    x       = NULL,
    y       = "Maharashtra farmer suicides",
    colour  = NULL,
    caption = "Sources: NCRB ADSI; Cotlook Ltd; IMD Vidarbha sub-division rainfall. OLS with HC3 robust SEs."
  ) +
  theme_print

ggsave(file.path(FIGDIR, "fig_regression_fit.png"), fit_plot,
       width = 11, height = 6.5, dpi = 300, bg = "white")
message("Saved: fig_regression_fit.png")
#}

# ── FIGURE 12: Coefficient plot ────────────────────────────────────────────────
#{
# Extract tidy coefficients with robust SEs
tidy_robust <- function(model, vcov_mat, model_name) {
  cf  <- coef(model)
  se  <- sqrt(diag(vcov_mat))
  tibble(
    term  = names(cf),
    est   = cf,
    se    = se,
    lo95  = cf - 1.96 * se,
    hi95  = cf + 1.96 * se,
    model = model_name
  ) %>%
    filter(!term %in% c("(Intercept)", "year_c", "I(year_c^2)"))
}

coef_df <- bind_rows(
  tidy_robust(m1, vcovHC(m1, "HC3"), "Levels (M1)"),
  tidy_robust(m2, vcovHC(m2, "HC3"), "Log (M2)"),
  tidy_robust(m3, vcovHC(m3, "HC3"), "Log + quad trend (M3)")
) %>%
  mutate(
    term = recode(term,
      cotton_z    = "Cotton price\n(standardised, COTLOOK A)",
      anomaly_pct = "Rainfall anomaly\n(% from LPA)",
      waiver_2008 = "2008 loan waiver\n(2009-11 window)",
      waiver_2017 = "2017 loan waiver\n(2017-19 window)"
    ),
    term  = fct_rev(factor(term)),
    model = factor(model, levels = c("Levels (M1)", "Log (M2)", "Log + quad trend (M3)"))
  )

# Normalise levels model coefficients for visual comparison
# M1 coefficients are in raw suicide counts; M2/M3 are log-scale.
# Plot M2 and M3 only for the percentage interpretation; M1 separately.

coef_plot <- ggplot(coef_df %>% filter(model != "Levels (M1)"),
                    aes(x = est, y = term, colour = model,
                        xmin = lo95, xmax = hi95)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "#AAAAAA") +
  geom_errorbarh(height = 0.2, position = position_dodge(width = 0.5), linewidth = 0.7) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  scale_colour_manual(values = c("Log (M2)" = "#A63603", "Log + quad trend (M3)" = "#2D6A2D")) +
  scale_x_continuous(
    labels = function(x) paste0(ifelse(x > 0, "+", ""), round(x * 100, 0), "%")
  ) +
  labs(
    title    = "Regression Coefficients: Drivers of Maharashtra Farmer Suicides",
    subtitle = "Log OLS (n = 22, 2001–2022). Horizontal bars = 95% CI (HC3 robust SEs).\nCoefficients interpreted as approximate % change in suicides per unit change in regressor.",
    x        = "Coefficient (log scale, approximate %)",
    y        = NULL,
    colour   = NULL,
    caption  = paste0(
      "Rainfall anomaly: % deviation from Vidarbha LPA (926 mm). Cotton price: standardised COTLOOK A index.\n",
      "Waiver windows: 1 in the 2-3 years following each major loan waiver. n=22; interpret with caution."
    )
  ) +
  theme_print +
  theme(legend.position = "top")

ggsave(file.path(FIGDIR, "fig_regression_coefs.png"), coef_plot,
       width = 10, height = 6, dpi = 300, bg = "white")
message("Saved: fig_regression_coefs.png")
#}

# ── REGRESSION TABLE ──────────────────────────────────────────────────────────
#{
coef_labels <- c(
  "cotton_z"    = "Cotton price (standardised)",
  "anomaly_pct" = "Rainfall anomaly (% from LPA)",
  "waiver_2008" = "Post-waiver 2008 (2009-11)",
  "waiver_2017" = "Post-waiver 2017 (2017-19)",
  "year_c"      = "Year trend",
  "I(year_c^2)" = "Year trend (squared)"
)

modelsummary(
  list("(1) Levels" = m1, "(2) Log" = m2, "(3) Log + quad" = m3),
  vcov       = list(vcovHC(m1, "HC3"), vcovHC(m2, "HC3"), vcovHC(m3, "HC3")),
  coef_map   = coef_labels,
  stars      = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  gof_map    = c("nobs", "r.squared", "adj.r.squared"),
  title      = "Determinants of Maharashtra Farmer Suicides, 2001–2022",
  notes      = "HC3 heteroskedasticity-robust standard errors in parentheses. n = 22 state-year observations. Outcome in (1) is total farmer suicides; in (2) and (3) log(suicides+1). Waiver windows coded 1 for 2–3 years following each major loan relief programme.",
  output     = file.path(OUTDIR, "tables", "reg_table.html")
)
message("Saved: reg_table.html")
#}

# ── PRINT SUMMARY ─────────────────────────────────────────────────────────────
#{
cat("\n=== KEY ESTIMATES (Model 2, log OLS) ===\n")
cf2 <- coef(m2)
se2 <- sqrt(diag(vcovHC(m2, "HC3")))
cat(sprintf("Cotton price (1 SD higher) → suicides: %+.1f%%  [SE: %.1f%%]\n",
            cf2["cotton_z"] * 100, se2["cotton_z"] * 100))
cat(sprintf("Rainfall anomaly (+1 ppt)  → suicides: %+.2f%%  [SE: %.2f%%]\n",
            cf2["anomaly_pct"] * 100, se2["anomaly_pct"] * 100))
cat(sprintf("Post-waiver 2008 window    → suicides: %+.1f%%  [SE: %.1f%%]\n",
            cf2["waiver_2008"] * 100, se2["waiver_2008"] * 100))
cat(sprintf("Post-waiver 2017 window    → suicides: %+.1f%%  [SE: %.1f%%]\n",
            cf2["waiver_2017"] * 100, se2["waiver_2017"] * 100))
cat(sprintf("R² = %.3f\n", summary(m2)$r.squared))
#}

message("D1 complete.")
