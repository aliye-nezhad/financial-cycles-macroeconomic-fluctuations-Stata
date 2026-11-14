# Final balanced-panel execution verification

**Execution date:** 14 November 2026  
**Stata version:** 17  
**Local log:** `outputs/logs/balanced_panel_sensitivity.log` (uploaded and directly reviewed)  
**Source:** `replication/balanced_panel_sensitivity.do`  
**Status:** **Completed successfully, without a terminal Stata error**

## Evidence and provenance

The user-supplied execution log begins at 09:47:19 and closes at 09:47:36 on 14 November 2026. The unmodified uploaded log is 125,777 bytes (2,322 lines) with SHA-256:

`b342627bde4c74c90c5f8835e007c88a7d148ea507df8e83c949f6ed5a81220f`

This digest identifies the exact reviewed log and avoids reproducing private computer paths in the repository. The file remains available as the original local execution record; this document is an independently checked summary, **not** a fabricated Stata log. The log contains the terminal message `Balanced-panel and common-period sensitivity completed.`, the subsequent required-output checks, and a normal `log close main_log`. No terminal `r(...)` error code appears.

The completed run supersedes the archived earlier `balanced_panel_sensitivity.log` that stopped at an obsolete sample-count assertion. The successfully executed standalone GDP sample-validation script remains a separate independent check of the four linked-GDP sample definitions.

## Confirmed regression results

All 12 linear horizon regressions completed, across 43-country unbalanced, 31-country full-period, 31-country common-period, and 43-country common-period samples. The log's reported coefficient/SE/observations/cluster counts agree with the [reviewed committed regression CSV](../outputs/tables/balanced_panel_regression_coefficients.csv), at the precision printed in the log.

| Sample | H1 coefficient (SE), N | H2 coefficient (SE), N | H3 coefficient (SE), N |
|---|---|---|---|
| 43 unbalanced | −0.02280 (0.00376), 1,310 | −0.02901 (0.00357), 1,267 | −0.02675 (0.00348), 1,224 |
| 31 full | −0.01950 (0.00412), 1,054 | −0.02658 (0.00408), 1,023 | −0.02454 (0.00404), 992 |
| 31 common | −0.03135 (0.00731), 558 | −0.04057 (0.00515), 527 | −0.03874 (0.00732), 496 |
| 43 common | −0.03381 (0.00610), 762 | −0.04139 (0.00562), 719 | −0.03883 (0.00659), 676 |

The four asymmetric H1 slope-equality p-values are **0.00039**, **0.00205**, **0.22805** and **0.08793** in the same sample order. All match the committed table. In the two common-period samples, equality is **not rejected at 5%**. All these results are in-sample conditional associations, not causal effects or measured out-of-sample forecast skill.

## Confirmed linked-GDP validation

| Sample | Level matches | Growth matches | Growth correlation | Growth MAE (pp) | Growth RMSE (pp) |
|---|---:|---:|---:|---:|---:|
| 43 unbalanced | 1,377 | 1,334 | 0.99616 | 0.21985 | 0.72444 |
| 31 full | 1,085 | 1,054 | 0.99039 | 0.23247 | 0.73805 |
| 31 common | 589 | 589 | 0.99098 | 0.22043 | 0.67067 |
| 43 common | 817 | 815 | 0.99744 | 0.20060 | 0.63150 |

The script explicitly lists **Brazil and Colombia, 2006** as the two matched-level observations without matched BIS-implied annual GDP growth. It generates the [two-row audit](../outputs/tables/balanced_panel_common_growth_missing.csv) and exports the four-sample comparison. All sample-count and country-count assertions pass.

The log confirms the following generated files exist after execution:

- `outputs/tables/balanced_panel_regression_coefficients.csv`
- `outputs/tables/balanced_panel_linked_gdp_validation.csv`
- `outputs/tables/balanced_panel_common_growth_missing.csv`
- `data/processed/balanced_panel_linked_gdp_validation.dta`
- Three balanced-panel PNG and three editable GPH figures

## Repository release status

All **14 reviewed PNGs and 14 GPHs** have been published in [`outputs/figures/`](../outputs/figures/), and all five audited CSV result tables are committed in [`outputs/tables/`](../outputs/tables/). The latest GitHub Actions static/source-acquisition checks passed after the figure publication. The complete combined-sensitivity run has now been verified from the uploaded Stata log.

**Qualified conclusion:** The repository is ready for an applied-economics **research portfolio** freeze. It is not a claim that GitHub Actions executes licensed Stata, that a new analyst has independently reproduced every earlier data download and model from scratch, or that the regressions have causal or real-time forecasting validity. Full raw-data replay and external peer review are distinct exercises.
