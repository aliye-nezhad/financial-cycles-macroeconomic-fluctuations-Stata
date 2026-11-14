# Research brief: Credit-to-GDP gaps and subsequent real GDP growth

**Scope:** 43 economies; 1990–2024; quarterly BIS credit-to-GDP gaps matched to annual World Development Indicators (WDI) data.  
**Status:** In-sample regressions, linked-GDP validation, and figure checks completed; the final Stata 17 sensitivity execution is separately documented.

## Question

Does an elevated credit-to-GDP gap predict weaker real GDP growth in subsequent years? Does the relationship differ when the gap is positive rather than negative?

The outcome is **real GDP growth in a particular future year**, not cumulative output growth or a recession/crisis indicator. This distinction is important because the BIS gap was designed primarily as an early-warning indicator of financial distress, while the present exercise studies a different outcome: subsequent economic activity.

## Approach

The principal predictor is the fourth-quarter BIS credit-to-GDP gap for private non-financial-sector borrowers and all lenders. The baseline country-panel model regresses annual real GDP growth in years `t+1`, `t+2`, and `t+3` on the gap in predictor year `t`, controlling for current and lagged real GDP growth and CPI inflation. The specification includes country fixed effects, **outcome-year** fixed effects, and country-clustered standard errors.

An asymmetric model separates positive and negative credit-gap values and tests equality of the two slopes. Further specifications use annual-average gaps, omit particular controls, exclude pandemic outcome years, and remove Ireland and Luxembourg to assess country influence. Wild cluster bootstrap inference uses 9,999 Rademacher replications across 43 countries for the main-sample tests. The four-sample sensitivity additionally compares the complete-coverage 31-country panel with the full 43-country panel, both over the full historical period and the common 2006–2024 window.

## Principal results

| Annual real GDP growth outcome | Credit-gap slope | Country-clustered SE | Observations |
|---|---:|---:|---:|
| Year `t+1` | −0.02280 | 0.00376 | 1,310 |
| Year `t+2` | −0.02901 | 0.00357 | 1,267 |
| Year `t+3` | −0.02675 | 0.00348 | 1,224 |

All three estimates are negative and significant at the 1% level. In the one-year model, a credit gap higher by 10 percentage points is associated with **0.228 percentage points lower annual real GDP growth in the following year**, conditional on the fixed effects and controls. This is an association, not an estimated causal effect or cumulative output decline.

The main-sample asymmetric model estimates a positive-gap slope of **−0.05138** (p < 0.001) and a negative-gap slope of **−0.00211** (p = 0.706). The difference is significant with conventional country-clustered inference (p = 0.00039), and a separate wild cluster bootstrap test also rejects slope equality (p = 0.0036).

### Sensitivity to countries and years

| Country-period sample | One-year coefficient (SE) | N | Asymmetric slope-equality p-value |
|---|---:|---:|---:|
| 43 economies, original coverage | −0.02280 (0.00376) | 1,310 | 0.00039 |
| 31 economies, complete 1990–2024 coverage | −0.01950 (0.00412) | 1,054 | 0.00205 |
| 31 economies, common 2006–2024 period | −0.03135 (0.00731) | 558 | 0.22805 |
| 43 economies, common 2006–2024 period | −0.03381 (0.00610) | 762 | 0.08793 |

Across all four country-period samples and three horizons, **all 12 linear slopes are negative and statistically significant at 1%**. However, the asymmetry claim is materially weaker: both full-period samples reject equal positive and negative slopes, while neither common-period sample rejects at 5%. In the latter samples, both slopes are individually negative and statistically significant. The evidence therefore supports the negative linear association more consistently than the particular interpretation that it arises primarily above trend.

## Measurement checks

Because GDP is in the denominator of the credit-to-GDP ratio, a high gap need not originate solely from faster nominal credit expansion. Supplementary BIS ratio and nominal-credit data are used to reconstruct the implied nominal-GDP denominator and evaluate numerator and denominator components separately. The identity and source-alignment checks pass; the component regressions remain descriptive/predictive rather than causal.

A further cross-source check compares BIS-implied nominal-GDP growth with the World Bank linked current-LCU series (`NY.GDP.MKTP.CN.AD`):

| Validation sample | Matched nominal-GDP levels | Matched annual growth | Growth correlation | Growth MAE (pp) |
|---|---:|---:|---:|---:|
| All 43 economies, available years | 1,377 | 1,334 | 0.99616 | 0.21985 |
| 31 complete-coverage economies, full period | 1,085 | 1,054 | 0.99039 | 0.23247 |
| 31 economies, 2006–2024 | 589 | 589 | 0.99098 | 0.22043 |
| All 43 economies, 2006–2024 | 817 | 815 | 0.99744 | 0.20060 |

The two unavailable 2006 BIS-implied growth observations in the last sample are Brazil and Colombia, whose BIS series begin in 2006. Their matched 2006 GDP levels remain in the comparison. No missing rates were imputed. The validation documents measurement consistency, but the underlying national-accounts inputs of BIS and WDI may overlap.

## Interpretation and limits

**What is supported:** A negative *conditional in-sample association* between the BIS credit-to-GDP gap and annual real GDP growth in the following one to three years, robust to the four documented country-period choices and several specification checks.

**What is not supported:** A causal credit-supply effect; proof that the positive/negative slope difference persists in the common period; a statement about cumulative output losses; or evidence of live forecasting performance. In particular, outcome-year fixed effects are estimated using realized outcomes, so the fitted models are **not an operational real-time forecasting exercise**. Historical data revisions and the one-sided HP-filtered credit-gap construction also matter. Country clustering addresses within-country error dependence, not every possible form of cross-country dependence.

The work contributes a transparent *applied macro-finance research workflow*: source acquisition, country-year panel construction, fixed-effects modeling, asymmetric and sample-window diagnostics, finite-cluster inference, GDP-denominator validation, and country-year discrepancy audits. It is not positioned as a structural or causal identification design.

## Reproducibility and release status

The applied macro-finance analysis and its documented sensitivities were executed in **Stata 17**. On 14 November 2026 the latest combined balanced-panel sensitivity script completed its twelve linear models, four asymmetric models, four linked-GDP comparisons, figure exports, dataset export and final output checks. The completed execution log was checked against the result tables, and its SHA-256 and selected results are preserved in [EXECUTION_VERIFICATION.md](EXECUTION_VERIFICATION.md).

Five numerical/audit tables are committed: the [24-row coefficient table](../outputs/tables/balanced_panel_regression_coefficients.csv), [four-sample GDP validation](../outputs/tables/balanced_panel_linked_gdp_validation.csv), [two-row missing-growth report](../outputs/tables/balanced_panel_common_growth_missing.csv), and the [top-20 GDP-level](../outputs/tables/nominal_gdp_linked_level_outliers_top20.csv) and [growth-discrepancy](../outputs/tables/nominal_gdp_linked_growth_outliers_top20.csv) tables. All **14 reviewed PNG figures and 14 editable GPH files** are versioned in [`outputs/figures/`](../outputs/figures/).

The full [results and numerical diagnostics](RESULTS.md), [research design](RESEARCH_DESIGN.md), [data audit](DATA_AUDIT.md), [output-quality review](OUTPUT_REVIEW.md), [reproducibility instructions](REPRODUCIBILITY.md) and [long-form research note](RESEARCH_NOTE_DRAFT.md) provide the underlying detail.

The project is **ready as a research-portfolio artifact**. The original local execution log and some processed Stata datasets are not all committed; optional archival work could add these after checking for personal machine paths. GitHub Actions checks source acquisition and static/report structure but does not itself run licensed Stata. An independent fresh-data reproduction, out-of-sample forecast evaluation and causal identification are **not** claimed.

## Selected sources

- [BIS Data Portal, “Credit-to-GDP gaps”](https://data.bis.org/topics/CREDIT_GAPS) — indicator definition, filtering, coverage and policy context.
- Drehmann, M. and Yetman, J. (2021). “[Which Credit Gap Is Better at Predicting Financial Crises? A Comparison of Univariate Filters](https://www.ijcb.org/journal/v17n4/which-credit-gap-better-predicting-financial-crises-comparison-univariate-filters).” *International Journal of Central Banking*, 17(4), 1–31.
- Jordà, Ò., Schularick, M. and Taylor, A. M. (2013). “[When Credit Bites Back](https://doi.org/10.1111/jmcb.12069).” *Journal of Money, Credit and Banking*, 45(s2), 3–28.
- Mian, A., Sufi, A. and Verner, E. (2017). “[Household Debt and Business Cycles Worldwide](https://doi.org/10.1093/qje/qjx017).” *The Quarterly Journal of Economics*, 132(4), 1755–1817.
