# Outputs

This directory contains the generated tables, figures and execution logs from the Stata analysis. The numerical findings and interpretation are documented in [docs/RESULTS.md](../docs/RESULTS.md); data coverage and source checks are documented in [docs/DATA_AUDIT.md](../docs/DATA_AUDIT.md).

## Main analysis

The main analysis exports four distinct monochrome figures, each as PNG and editable Stata GPH:

- `figures/mean_credit_gap_by_year.png` and `.gph` — annual unweighted mean BIS credit-to-GDP gap across available economies.
- `figures/credit_gap_gdp_scatter.png` and `.gph` — pooled descriptive relationship between the credit gap and GDP growth one year ahead; not the fixed-effects estimate.
- `figures/fe_horizon_coefficients.png` and `.gph` — one-, two- and three-year-ahead fixed-effects credit-gap coefficients with country-clustered 95% confidence intervals.
- `figures/asymmetric_gap_coefficients.png` and `.gph` — positive- and negative-gap coefficients from the asymmetric one-year-ahead fixed-effects model.

Main tables include `tables/sample_coverage.txt`, `descriptive_statistics.txt`, `correlation_matrix.txt`, `baseline_models.txt`, `asymmetric_model.txt`, `robustness_models.txt`, and `influence_sensitivity.txt`. The optional bootstrap results are stored in `tables/wild_cluster_bootstrap.txt`. The main execution log is `logs/analysis.log`.

## Credit-numerator and GDP-denominator diagnostic

Running `replication/denominator_diagnostic.do` creates:

- `tables/denominator_decomposition.txt` — source alignment, reconstructed denominator, and annual component-growth summaries.
- `tables/denominator_component_models.txt` — matched-sample baseline and numerator-denominator predictive regressions.
- `figures/ratio_component_growth.png` and `.gph` — annual mean changes in nominal credit, implied nominal GDP, and the credit-to-GDP ratio.
- `figures/ratio_component_coefficients.png` and `.gph` — matched-sample component-model coefficients and 95% confidence intervals.
- `logs/denominator_diagnostic.log` — execution record.
- `../data/processed/denominator_components_panel.dta` — matched annual panel.

The diagnostic does not alter the main analysis outputs. Its estimates are predictive associations, not causal effects.

## Independent nominal-GDP validation

The preferred validation uses World Bank WDI indicator `NY.GDP.MKTP.CN.AD` (GDP, linked series, current LCU) and compares it with the BIS-implied Q4 denominator. The completed Stata 17 run matched 1,377 nominal-GDP levels and 1,334 annual growth observations across 43 economies. The growth correlation is 0.9962, the mean absolute difference is 0.2198 percentage points, and the RMSE is 0.7244 points.

Generated validation outputs include:

- `tables/nominal_gdp_linked_validation_overall.txt` — coverage, level-ratio diagnostics, annual log-growth differences, MAE, RMSE and correlation.
- `tables/nominal_gdp_linked_validation_by_country.csv` — country-level overlap and discrepancy summaries.
- `../data/processed/nominal_gdp_linked_validation_panel.dta` — merged BIS and linked WDI country-year panel.
- `../data/processed/nominal_gdp_linked_validation_by_country.dta` — Stata country-level summary.
- `../data/raw/wb_gdp_linked_current_lcu.zip`, `wb_gdp_linked_current_lcu.csv`, and associated metadata — retained source archive, canonical CSV, retrieval metadata and hashes.
- `logs/nominal_gdp_linked_validation.log` — execution record.

The earlier unlinked WDI indicator `NY.GDP.MKTP.CN` is retained as an archival comparison, not as the preferred time-series benchmark. Its outputs are `tables/nominal_gdp_validation_overall.txt`, `tables/nominal_gdp_validation_by_country.csv`, and `logs/nominal_gdp_validation.log`.

## Linked nominal-GDP outlier audit

Running `replication/audit_nominal_gdp_linked.do` after the linked validation creates:

- `tables/nominal_gdp_linked_level_outliers_top20.csv` — the 20 largest country-year deviations from each country's median implied/WDI level ratio.
- `tables/nominal_gdp_linked_growth_outliers_top20.csv` — the 20 largest absolute country-year growth differences.
- `tables/nominal_gdp_linked_validation_country_audit.csv` — 43-country summary of level and growth discrepancies.
- `../data/processed/nominal_gdp_linked_validation_country_audit.dta` — Stata country-level audit dataset.
- Five separately named figures, each exported as PNG and editable GPH:
  - `figures/nominal_gdp_validation_scatter`
  - `figures/nominal_gdp_validation_median_growth_difference`
  - `figures/nominal_gdp_validation_p95_growth_difference`
  - `figures/nominal_gdp_validation_country_growth_mae`
  - `figures/nominal_gdp_validation_country_level_deviation`
- `logs/nominal_gdp_linked_outlier_audit.log` — execution record.

The five linked-validation figures have been visually inspected. They are legible, use the project's monochrome style, and are exported as separate files. The full-range scatter retains the high-growth observations rather than hiding them through axis truncation.

The first audit run produced correct rankings and figures, but its two top-20 CSV exports retained the full 73-variable source panel. A corrected rerun on 14 November 2026 successfully exported the two focused top-20 CSVs and five PNG/GPH figure pairs. The two CSVs have been checked for row count, unique country-year keys, rank ordering and discrepancy arithmetic, and committed to GitHub. All five corresponding PNG/GPH pairs have also been published under `outputs/figures/`. The audit does not drop, winsorize or adjust source observations.

## Balanced-panel and common-period sensitivity

Running `replication/balanced_panel_sensitivity.do` creates:

- `tables/balanced_panel_regression_coefficients.csv` — 12 linear horizon regressions and four asymmetric H1 specifications across four country-period samples.
- `tables/balanced_panel_linked_gdp_validation.csv` — linked-GDP measurement comparisons across the same four country-period samples.
- `tables/balanced_panel_common_growth_missing.csv` — the two country-years with matching GDP levels but without matching annual growth.
- `../data/processed/balanced_panel_linked_gdp_validation.dta` — processed four-sample validation results.
- `figures/balanced_panel_h1_coefficients.png` and `.gph` — H1 linear coefficient sensitivity.
- `figures/bal_panel_horizon_coef.png` and `.gph` — H1, H2 and H3 coefficient sensitivity.
- `figures/balanced_panel_asymmetry.png` and `.gph` — positive- and negative-gap slopes across samples.
- `logs/balanced_panel_sensitivity.log` — combined execution record.

The standalone `replication/validate_balanced_panel_samples.do` produces the linked-GDP validation CSV, processed dataset, and `logs/balanced_panel_linked_gdp_sensitivity.log` without rerunning the regressions.

The 31-country common-period linked-GDP validation compares 589 GDP levels and 589 annual growth observations indexed 2006–2024. The corresponding one-year-ahead predictive regression uses predictor years 2006–2023, yielding 558 complete-case observations (31 × 18). The committed regression CSV confirms the H1 linear estimate −0.031353 (SE 0.007305; p = 0.000170), together with the asymmetric H1 estimates. The common-period slope-difference tests have p = 0.22805 (31 countries) and p = 0.08793 (43 countries), neither significant at 5%.

The standalone linked-GDP validation completed successfully on 14 November. The 43-country 2006–2024 comparison contains 817 GDP levels and 815 matched growth observations. The two missing growth comparisons are Brazil 2006 and Colombia 2006 because their BIS series begin in that year; the World Bank 2006 growth rates are present, and their GDP levels are retained. The script saved the four-sample comparison CSV, processed results dataset, and two-row missing-growth audit, and passed its final output checks.

## Current repository state

**Five reviewed output CSV tables and all fourteen PNG/GPH figure pairs are committed to GitHub.** The tables contain 24 regression coefficient records, four linked-GDP sample comparisons, two missing-growth observations and two ranked top-20 outlier reports. Four main-analysis figures, two denominator diagnostic figures, three balanced-panel sensitivity figures and five linked-GDP audit figures were visually reviewed and versioned.

A new **successful full combined sensitivity run** was completed in Stata 17 on 14 November 2026. Its outputs, all four sample checks, twelve linear models, four asymmetric specifications and terminal execution checks passed. Its original log remains local; an audited checksum and summary are documented in [docs/EXECUTION_VERIFICATION.md](../docs/EXECUTION_VERIFICATION.md). Some processed Stata `.dta` outputs, other execution logs and country-audit tables are still local. They can be archived as an optional extension, but they do not invalidate the committed research-portfolio results.

All results describe the specified observational design and must not be presented as causal estimates.
