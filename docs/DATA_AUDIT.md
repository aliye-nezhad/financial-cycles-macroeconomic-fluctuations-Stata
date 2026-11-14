# Data audit and sample verification

**Audit date:** 13 November 2026  
**Source vintage:** World Bank WDI files last updated 11 November 2026; BIS series downloaded 13 November 2026. Exact file hashes are stored in data/raw.sha256.

This audit was computed from the downloaded source CSV files before Stata estimation. The complete Stata execution on 13 November 2026 reproduced the expected horizon-specific sample counts exactly. The baseline, asymmetric, measurement, pandemic, control-variable and country-influence specifications have now been executed. Their main estimates are summarized in [docs/RESULTS.md](RESULTS.md).

## 1. Source-file integrity and BIS coverage

- BIS source: WS_CREDIT_GAP, quarterly, 1990-Q1 to 2024-Q4.
- BIS CSV contains 5,556 rows for the selected dimensions, covering 44 borrower-area codes.
- The 44 codes comprise 43 individual economies plus the euro-area aggregate (XM). XM is excluded from the country panel.
- The 43-country file contains 5,492 valid quarterly observations.
- No duplicate country-quarter keys were found in the 43-country sample.
- The Q4 annual panel contains 1,377 country-year observations across all 43 countries.
- The maximum balanced-panel size would be 43 × 35 = 1,505 observations. The actual panel is unbalanced because several BIS country series begin after 1990.
- 1,371 country-year cells have all four quarterly credit-gap observations. The annual-average robustness measure therefore has six fewer country-year cells than the Q4 measure.

All 5,492 retained quarterly observations have BIS observation status A and confidentiality flag F in the downloaded file. The analysis does not alter or reinterpret those source flags.

## 2. Country coverage

Thirty-one countries have Q4 credit-gap observations for every year from 1990 through 2024. The remaining twelve countries begin later:

| Country | First Q4 observation | Q4 observations through 2024 |
|---|---:|---:|
| Argentina | 1994 | 31 |
| Chile | 1993 | 32 |
| China | 1995 | 30 |
| Türkiye | 1996 | 29 |
| Israel | 2000 | 25 |
| Poland | 2002 | 23 |
| Czechia | 2003 | 22 |
| Saudi Arabia | 2003 | 22 |
| Luxembourg | 2005 | 20 |
| Russian Federation | 2005 | 20 |
| Brazil | 2006 | 19 |
| Colombia | 2006 | 19 |

All 43 individual economies have observations in the one-, two- and three-year-ahead complete-case samples. The number of observations per model varies with the forecast horizon and missing control data.

## 3. World Bank merge and missingness

The two WDI source files in this vintage were last updated on 11 November 2026.

- Current-year GDP growth is available for every Q4 BIS country-year observation.
- Previous-year GDP growth is available for every Q4 BIS country-year observation when 1989 is retained to construct the lag for 1990.
- CPI inflation is missing for Argentina from 1994 through 2017: 24 country-year observations.
- CPI inflation is available for the other Q4 BIS country-year observations.

The baseline includes CPI inflation, so the 24 Argentina observations with missing inflation are excluded from the complete-case regressions. No interpolation or forward filling is used.

The no-inflation sensitivity model is included to show whether this small but concentrated sample loss affects the main credit-gap coefficient. It is not the preferred specification; inflation remains a baseline control.

## 4. Expected regression samples

The following counts apply the model's stated sample rules to the source data: Q4 gap, current and previous-year GDP growth, current-year CPI inflation, and the future GDP-growth outcome. These counts were calculated before estimation and were reproduced exactly in the first complete Stata run on 13 November 2026.

| Specification | Predictor years | Outcome years | Observations | Countries |
|---|---|---|---:|---:|
| One-year ahead | 1990–2023 | 1991–2024 | 1,310 | 43 |
| Two-year ahead | 1990–2022 | 1992–2024 | 1,267 | 43 |
| Three-year ahead | 1990–2021 | 1993–2024 | 1,224 | 43 |

Additional sample checks:

| Sensitivity | One-year observations | Countries |
|---|---:|---:|
| Annual-average credit gap, requiring four quarters | 1,305 | 43 |
| Exclude outcome years 2020 and 2021 | 1,224 | 43 |
| Omit CPI control | 1,334 | 43 |
| Exclude Ireland only | 1,276 | 42 |
| Exclude Luxembourg only | 1,291 | 42 |
| Exclude Ireland and Luxembourg jointly | 1,257 | 41 |

The pandemic-exclusion model removes 86 one-year-ahead observations whose outcome years are 2020 or 2021.

## 5. Credit-gap distribution and influential observations

Across the 1,377 Q4 country-year observations:

| Statistic | Credit-to-GDP gap (percentage points of GDP) |
|---|---:|
| Mean | -0.939 |
| Standard deviation | 17.229 |
| 25th percentile | -8.504 |
| Median | 0.816 |
| 75th percentile | 7.934 |
| Minimum | -110.593 |
| Maximum | 90.040 |

The largest absolute observations include:

| Country | Year | Gap |
|---|---:|---:|
| Ireland | 2021 | -110.593 |
| Ireland | 2022 | -106.989 |
| Ireland | 2020 | -97.040 |
| Ireland | 2019 | -90.875 |
| Luxembourg | 2007 | 90.040 |
| Ireland | 2023 | -85.699 |
| Ireland | 2008 | 80.179 |
| Ireland | 2024 | -78.970 |

These values are not automatically treated as errors and are not winsorized or removed from the baseline. They do, however, warrant influence diagnostics.

Ireland's GDP denominator requires particular caution. The Irish Central Statistics Office explains that globalisation effects, including the relocation of multinational balance sheets and intellectual property, can disproportionately affect GDP measurement. It publishes modified GNI (GNI*) to exclude specified globalisation effects. See:

- CSO, [Modified GNI](https://www.cso.ie/en/interactivezone/statisticsexplained/nationalaccountsexplained/modifiedgni/).
- CSO, [National Income and Expenditure 2017 FAQ](https://www.cso.ie/en/methods/nationalaccounts/din/nie2017faq/).

The WDI GDP-growth series used here is not replaced with Irish GNI*. The baseline retains Ireland for cross-country consistency, while separate sensitivity regressions excluding Ireland, Luxembourg, and both countries will show how influential these observations are. The exclusion exercise is diagnostic, not a preferred sample definition.

## 6. Implications for the empirical design

1. The planned 43-country unbalanced panel is feasible and has substantial coverage: 1,310 complete one-year-ahead observations across 43 countries.
2. The Q4 gap is the baseline annual measure. The annual-average measure is available for 1,371 country-years and gives a closely comparable one-year sample of 1,305 observations.
3. The CPI missingness is concentrated in Argentina. A no-inflation sensitivity is needed to show the effect of retaining those observations.
4. The distribution has influential observations, particularly for Ireland and Luxembourg. The baseline retains them; country-exclusion sensitivities are reported separately.
5. The credit-to-GDP gap contains GDP in its denominator. Current and lagged GDP growth controls address some predictable output dynamics but do not solve the measurement or endogeneity problem.
6. No causal interpretation is warranted. The project estimates conditional predictive associations.

## 7. Audit status

- [x] BIS source file downloaded and checksum recorded.
- [x] WDI GDP-growth and CPI files downloaded and checksums recorded.
- [x] 43-country crosswalk matched to BIS codes.
- [x] Duplicate country-quarter keys checked.
- [x] Q4 annual panel coverage calculated.
- [x] GDP, lagged GDP and inflation missingness audited.
- [x] Expected regression sample counts calculated.
- [x] Extreme credit-gap observations identified.
- [x] Stata do-file executed and its sample counts reconciled with this audit.
- [x] Baseline regression results and the pandemic, missing-inflation and control-variable sensitivities reviewed.
- [x] Linear influence sensitivities excluding Ireland, Luxembourg and both jointly executed.
- [x] Asymmetric regression re-estimated after excluding Ireland, Luxembourg and both jointly; slope-equality tests remain statistically significant.
- [x] Review all fourteen generated PNG figures for numerical alignment, legibility and separation of the outputs; no substantive defect found. [ ] Add the selected figures to GitHub and complete the final publication package.
- [x] Wild cluster bootstrap inference for the matched-sample denominator-component model completed with 9,999 Rademacher replications across 43 country clusters; see [docs/RESULTS.md](RESULTS.md).
- [x] Credit-numerator versus GDP-denominator sensitivity investigated; source alignment and the numerator-denominator identity passed the checks recorded in docs/RESULTS.md.


## 8. Linked nominal-GDP cross-source validation

The linked World Bank current-LCU GDP series (`NY.GDP.MKTP.CN.AD`) was matched to the BIS-implied Q4 denominator for 1,377 country-year levels and 1,334 annual growth observations across all 43 economies. The growth comparison covers 1991–2024. The correlation is 0.9962, the mean absolute growth difference is 0.2198 percentage points, and the RMSE is 0.7244 percentage points. The median absolute time-varying level deviation after country-specific scale adjustment is 0.0541%; its 95th percentile is 2.8228% and its maximum is 9.9510%. Full statistics and interpretation are in [docs/RESULTS.md](RESULTS.md).

- [x] Linked WDI current-LCU source downloaded, validated and checksum recorded.
- [x] BIS-implied nominal-GDP denominator compared with linked WDI levels and annual growth.
- [x] Execute the linked nominal-GDP country-year outlier audit. The Stata 17 run on 13 November 2026 generated both top-20 discrepancy tables, the 43-country summary, the processed country-audit dataset, and all five figures in PNG and GPH formats; the final output-existence checks passed.
- [x] Visually inspect all five linked nominal-GDP validation figures; labels are legible, exports are separate, and the monochrome styling is consistent.
- [x] Rerun the corrected linked-GDP outlier audit on 14 November 2026. Both focused top-20 CSVs were independently checked for 20 unique country-year records, decreasing absolute discrepancies, correct ranks and arithmetic, and committed to `outputs/tables/`. All five updated PNG/GPH figure pairs were visually reviewed.
- [x] Re-estimate the baseline and asymmetric regressions across the 43-country unbalanced, 31-country full-period, 31-country common-period, and 43-country common-period samples; all 12 linear and four asymmetric specifications completed.
- [x] Inspect the 24-row regression CSV: 31-country common-period linear H1 estimate −0.031353, SE 0.007305, p = 0.000170, N = 558 (31 clusters). The asymmetric H1 coefficients, slope tests, confidence intervals, and all other regression samples agree with the exported numerical fields.
- [x] Confirm linked-GDP level and growth counts for the full 43-country sample and the 31-country full-period sample.
- [x] Confirm 589 level and 589 calendar-year growth observations for the 31-country 2006–2024 common-period sample from the Stata execution log; the earlier stop was caused by an incorrect expected count of 558.
- [x] Complete the four-sample linked-GDP validation in Stata 17 on 14 November 2026. The script passed all four count checks, saved the comparison CSV and processed results, and closed the log without error.
- [x] Verify the 43-country common-period sample: 817 matched levels; 815 matched growth observations; growth correlation 0.99744; MAE 0.20060 pp; RMSE 0.63150 pp.
- [x] Audit the two missing 2006 BIS-implied growth comparisons (BRA and COL); both BIS series start in 2006, and both 2006 GDP levels remain included. The diagnostic exported `outputs/tables/balanced_panel_common_growth_missing.csv` without imputing or altering data.
- [x] Inspect and commit `outputs/tables/balanced_panel_regression_coefficients.csv`, `outputs/tables/balanced_panel_linked_gdp_validation.csv`, and `outputs/tables/balanced_panel_common_growth_missing.csv`. Verified sample counts, coefficient tests, confidence intervals, and BRA/COL missing-growth rows.
- [x] Commit and verify 14 PNG and 14 editable GPH figure files in `outputs/figures/`; all earlier reviewed outlier and regression/validation CSVs are now published.
- [x] Execute the latest combined `replication/balanced_panel_sensitivity.do` end to end on 14 November 2026; the uploaded Stata 17 log confirms all regressions, linked-GDP checks, output exports and normal closure. SHA-256 and key numerical checks are recorded in [docs/EXECUTION_VERIFICATION.md](EXECUTION_VERIFICATION.md).
- [ ] Optional archival work: redact local machine paths from the complete execution log before committing it and assess whether remaining processed `.dta` datasets and source-vintage metadata should be included in a historical reproduction archive. The current research-portfolio results are ready; GitHub Actions does not execute Stata.
