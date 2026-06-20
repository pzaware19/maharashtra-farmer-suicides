# Data Provenance and Reliability Audit

**Project:** Maharashtra Farmer Suicides
**Author:** Piyush Zaware
**Last updated:** 2026-06-19

This document records the source, reliability, and verification status of every data series used in the analysis and on the website. It exists so that anyone, including the author, can distinguish official published figures from reconstructed or illustrative ones before citing them.

Every series is classified into one of three tiers:

- **Tier A (Official, verified):** Traces directly to a named, publicly available official source. Key anchor values have been cross-checked against that source and match.
- **Tier B (Official series, approximate values):** A real published series exists and the broad pattern is accurate, but the exact annual values used here are reconstructed from secondary citations or interpolated, and may differ from the official figure in any given year.
- **Tier C (Reconstructed / illustrative):** Anchored to real benchmarks and real events, but substantially interpolated or modeled. These should be treated as illustrative of magnitude and direction, not cited as primary data.

---

## Summary table

| # | Series | File | Tier | Official source | Verification status |
|---|--------|------|------|-----------------|---------------------|
| 1 | Maharashtra farmer suicides, state total 2001-2022 | `ncrb_mh_state.csv` | **A** | NCRB ADSI Table A-2 | 2012 value (3,786) matches NCRB exactly. Cultivators category. See 2014 caveat below. |
| 2 | Gender split (male/female) | `ncrb_mh_state.csv` | **B** | NCRB ADSI Table A-2 | ~90% male share consistent with literature; exact annual split approximate. |
| 3 | India state comparison (KA, AP+TG, MP) | `ncrb_india_states.csv` | **A/B** | NCRB ADSI Table A-2 | Maharashtra column verified; other states from same series but not independently audited year by year. |
| 4 | Cotton MSP (medium staple) | `cotton_prices.csv` | **A** | GoI / CACP (PIB press releases) | Verified: 2018-19 (5,150), 2020 (5,515), 2022-23 (6,080) exact. 2014-15 corrected to 3,700. |
| 5 | Cotton world price (COTLOOK A index) | `cotton_prices.csv` | **B** | Cotlook Ltd | Boom/bust pattern (2010-12) accurate; exact annual averages approximate. |
| 6 | Soybean MSP | `soybean_prices.csv` | **A** | CACP | Official series, verifiable. |
| 7 | Soybean world price | `soybean_prices.csv` | **B** | World Bank Pink Sheet (US soybeans, Gulf) | Real benchmark; annual values approximate; INR conversion uses approximate annual exchange rate. |
| 8 | Onion price (Lasalgaon mandi) | `onion_prices.csv` | **C** | NHRDF / Agmarknet | Major events real (2010 crash ~Rs 310, 2019 spike ~Rs 4,200); exact annual averages reconstructed. Pre-2010 especially approximate. |
| 9 | Cotton A2 cost of cultivation | `input_costs.csv` | **C** | CACP Cost of Cultivation Survey (Maharashtra) | Reconstructed from published benchmark years, interpolated between. Yield assumption 6-7 qtl/ha (dryland Vidarbha). |
| 10 | Soybean A2 cost of cultivation | `input_costs.csv` | **C** | CACP Cost of Cultivation Survey | Reconstructed and interpolated. |
| 11 | DAP fertiliser price | `input_costs.csv` | **C** | Dept. of Agriculture / FICCI | 2008 phosphate spike real; intermediate years approximate. |
| 12 | Diesel retail price (Delhi) | `input_costs.csv` | **B** | PPAC / IOCL | Verifiable series; values approximate to nearest rupee. |
| 13 | District-level suicides | `ncrb_district.csv` | **C** | NCRB ADSI district tables (partial) | **Representative, not complete.** Only Yavatmal has a full annual series; other districts have benchmark years (2001, 2006, 2012, 2017, 2022) only. Used for the choropleth map and regional shares. |
| 14 | Cause breakdown (debt, crop failure, etc.) | `ncrb_causes.csv` | **B** | NCRB ADSI Table A-2.4 | Categories and rough magnitudes from NCRB; exact percentages for 2015/2019/2022 approximate. |
| 15 | Cultivator population by state | `agri_population.csv` | **B** | Census of India 2001, 2011 (Table B-4) | Census anchor years real; inter-censal interpolation and post-2011 extrapolation are modeled. |
| 16 | Vidarbha monsoon rainfall | `imd_vidarbha_rainfall.csv` | **B** | IMD Vidarbha sub-division | LPA (926 mm) real; annual rainfall and anomalies approximate; drought years directionally correct. |
| 17 | Regional shares (Vidarbha / Marathwada / Rest) | derived in `B1_clean.R` | **C** | Estimated from district data | Marathwada share fixed at ~18%, Vidarbha summed from partial district data. Estimated, not measured. |

---

## The 2014 NCRB definitional break (most important caveat)

Before 2014, NCRB reported a single occupational category for farm-sector suicides (broadly "self-employed in farming/agriculture"), which in practice captured both cultivators and agricultural labourers. **From 2014 onward, NCRB split this into two separate categories: "farmers/cultivators" and "agricultural labourers."**

The series used in this project (`ncrb_mh_state.csv`) is the **cultivators** figure. This has two consequences:

1. **The pre-2014 and post-2014 figures are not strictly comparable.** Pre-2014 numbers are inflated relative to post-2014 numbers because they include agricultural labourers. Part of the apparent decline after 2014 is definitional, not a real fall in deaths.

2. **State and national totals depend on which category you count.** For example, in 2022 NCRB recorded roughly 2,700 cultivator suicides in Maharashtra but roughly 4,250 when agricultural labourers are added. The "more than 70,000 over 2001-2022" headline uses the cultivator series and should be read with the 2014 break in mind.

This break is now marked directly on the time-series chart and noted in the timeline and methods sections of the website.

Source on the reclassification: down-to-earth.org.in coverage of NCRB methodology; NCRB ADSI 2014 onward.

---

## Headline figure

The Maharashtra cultivator series sums to **71,814** for 2001-2022. The website headline uses "more than 70,000," which matches this verified sum. An earlier draft used "66,000"; that figure understated the series and has been corrected.

Caveat: because of the 2014 break, this sum mixes a broader pre-2014 definition with a narrower post-2014 one. It should be read as "more than 70,000 recorded farm-sector suicides, on a definition that narrowed in 2014," not as a single consistent count.

---

## What would move Tier C and B series to Tier A

For a publishable working paper, the following would need to be sourced directly rather than reconstructed:

- **District-level suicides:** download NCRB ADSI district tables for all years (PDF 2001-2013, Excel 2014-2022) and digitise. This is the single biggest upgrade and would enable the district-panel regression the analysis calls for.
- **Cotton/soybean A2 and C2 costs:** extract from CACP Cost of Cultivation reports directly (published per crop per state, with a 2-3 year lag).
- **COTLOOK A annual averages:** obtain from Cotlook Ltd or a licensed terminal; INSEE publishes a free monthly COTLOOK A series that can be averaged to annual.
- **Onion prices:** Agmarknet provides daily Lasalgaon modal prices that can be averaged to annual.
- **Rainfall:** IMD sub-divisional monthly rainfall is downloadable and can replace the approximate annual figures.

Until then, the website labels Tier C figures as illustrative in their captions.
