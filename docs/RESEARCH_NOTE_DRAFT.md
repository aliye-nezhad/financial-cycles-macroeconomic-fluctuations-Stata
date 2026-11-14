# Financial Cycles and Macroeconomic Fluctuations

**Cross-Country Evidence from Credit-to-GDP Gaps**

*Research note*

> **Research-portfolio working paper (internally validated).** The empirical specifications, five audited numerical tables and all fourteen figures have been reviewed, and their results have been committed. The latest combined balanced-panel script was successfully executed in Stata 17 on 14 November 2026; the completed log's numerical results and SHA-256 digest are documented in [EXECUTION_VERIFICATION.md](EXECUTION_VERIFICATION.md). This remains an observational applied research note, not a peer-reviewed causal study, independent third-party reproduction or evaluated real-time forecasting exercise.

## Abstract

This project examines whether the BIS credit-to-GDP gap predicts subsequent real GDP growth across 43 economies over 1990–2024, and whether the relationship differs between above-trend and below-trend credit conditions. The main analysis uses an annual country panel with country fixed effects, outcome-year fixed effects, current and lagged GDP growth, CPI inflation, and standard errors clustered by country. The estimated credit-gap coefficient is negative at one-, two-, and three-year horizons. An asymmetric specification indicates that the negative association is concentrated in above-trend credit observations in the full sample. These patterns survive several measurement, specification, country-influence, and finite-cluster inference checks, although the asymmetry is less stable in common-period samples. Supplementary diagnostics examine the GDP-denominator component of the credit-to-GDP ratio and compare the BIS-implied nominal-GDP denominator with the World Bank's linked current-LCU series. The results are conditional predictive associations, not causal estimates.

## Research question and motivation

The central question is whether deviations in private non-financial-sector credit relative to GDP's long-run trend contain information about subsequent real economic activity. A related question is whether the predictive relationship is symmetric: does a credit-to-GDP ratio above trend have a different association with future growth from a ratio below trend?

The project is motivated by the macro-finance literature on leverage cycles, credit booms, and subsequent macroeconomic performance. Schularick and Taylor (2012), Jordà, Schularick and Taylor (2013), and Mian, Sufi and Verner (2017) establish the importance of credit and debt dynamics for macroeconomic outcomes. Drehmann and Yetman (2021) are particularly relevant to measurement: credit-to-GDP gaps are generated indicators, and the GDP denominator and one-sided filtering procedure create interpretive limitations.

The aim here is narrower than identifying a credit-supply shock or estimating the causal effect of leverage. It is to document a transparent cross-country predictive relationship and test how sensitive that relationship is to measurement, sample composition, and inference choices.

## Data and measurement

The main panel combines three sources:

- **Bank for International Settlements:** quarterly WS_CREDIT_GAP observations for private non-financial-sector borrowers and all lender sectors. The analysis uses the fourth-quarter credit-to-GDP gap as its principal financial-cycle measure.
- **World Development Indicators:** annual real GDP growth (NY.GDP.MKTP.KD.ZG) and CPI inflation (FP.CPI.TOTL.ZG).
- **Supplementary BIS series:** actual credit-to-GDP ratios, the one-sided HP trend, and nominal credit stocks, used to reconstruct the trailing-four-quarter nominal-GDP denominator.

The BIS gap is the credit-to-GDP ratio minus its one-sided, backward-looking Hodrick–Prescott trend. It covers domestic and foreign borrowing and is not restricted to bank lending. The downloaded sample contains 1,377 Q4 country-year observations across 43 individual economies from 1990 through 2024; the euro-area aggregate is excluded.

The main complete-case regression samples contain 1,310 observations for the one-year horizon, 1,267 for the two-year horizon, and 1,224 for the three-year horizon. A concentrated source-data limitation is that CPI inflation is missing for Argentina from 1994 through 2017. A no-inflation specification evaluates the associated sample loss.

## Empirical design

For country $i$, predictor year $t$, and horizon $h$, the baseline specification is:

$$
g_{i,t+h}=\alpha_i+\lambda_{t+h}
+\beta_h Gap_{i,t}
+\rho_h g_{i,t}
+\delta_h g_{i,t-1}
+\gamma_h \pi_{i,t}
+\varepsilon_{i,t+h},
$$

where $g$ is annual real GDP growth, $Gap$ is the Q4 BIS credit-to-GDP gap, and $\pi$ is CPI inflation. The model includes country fixed effects and fixed effects for the outcome year. Standard errors are clustered by country.

The primary outcome is annual growth in the specific future year, not cumulative growth over the forecast horizon. The one-year-ahead specification is primary; two- and three-year horizons are extensions.

The asymmetric model replaces the single gap term with:

$$
Gap^+_{i,t}=\max(Gap_{i,t},0),\qquad
Gap^-_{i,t}=\min(Gap_{i,t},0).
$$

This allows the above-trend and below-trend slopes to differ. The sign and magnitude of the below-trend slope are treated as empirical questions rather than assumed to mirror the above-trend slope.

## Main findings

### Baseline predictive regressions

| Outcome | Credit-gap coefficient | Clustered SE | Observations |
|---|---:|---:|---:|
| GDP growth in $t+1$ | -0.0228 | 0.0038 | 1,310 |
| GDP growth in $t+2$ | -0.0290 | 0.0036 | 1,267 |
| GDP growth in $t+3$ | -0.0268 | 0.0035 | 1,224 |

All three coefficients are statistically significant at $p<0.001$ using conventional country-clustered inference. A 10-percentage-point higher credit gap is associated with approximately 0.228 percentage points lower annual GDP growth in the following year, conditional on the included controls and fixed effects. The corresponding associations are 0.290 and 0.268 percentage points at the two- and three-year horizons.

These are annual growth rates in the respective outcome years, not cumulative output losses.

### Asymmetry

| Component | Coefficient | Clustered SE | p-value |
|---|---:|---:|---:|
| Positive credit-gap component | -0.0514 | 0.0101 | <0.001 |
| Negative credit-gap component | -0.0021 | 0.0056 | 0.706 |

The test of equal slopes gives $F(1,42)=14.85$, $p=0.0004$. In the full sample, the negative conditional association is concentrated in observations where the credit-to-GDP ratio is above its estimated trend. The below-trend slope is close to zero and statistically indistinguishable from zero.

### Specification and country-influence checks

The negative baseline association remains statistically significant when the gap is measured as the annual average of all four quarters, when outcome years 2020 and 2021 are excluded, when lagged GDP growth is omitted, and when CPI inflation is omitted. The corresponding gap coefficients are -0.0242, -0.0203, -0.0228, and -0.0228.

The linear association also remains negative and statistically significant when Ireland, Luxembourg, or both are excluded. The positive-gap slope remains negative and significant across the same exclusion checks, while the negative-gap slope remains statistically indistinguishable from zero. These are influence diagnostics, not reasons to redefine the preferred sample.

### Finite-cluster inference

A wild cluster bootstrap diagnostic completed eight tests using 9,999 Rademacher replications across 43 country clusters. The bootstrap supports the baseline credit-gap coefficient and positive-gap coefficient; the negative-gap coefficient is not significant. The equality test for the positive- and negative-gap slopes has a bootstrap p-value of 0.0036. The matched-sample baseline coefficient also remains significant.

## Sample-period sensitivity

The regression sensitivity estimates the baseline model across four samples: the original 43-country unbalanced panel, the 31 economies with complete 1990–2024 BIS Q4 coverage, and both country sets over the common 2006–2024 period.

| Sample | H1 coefficient (SE), N | H2 coefficient (SE), N | H3 coefficient (SE), N |
|---|---:|---:|---:|
| 43 economies, unbalanced | -0.02280 (0.00376), 1,310 | -0.02901 (0.00357), 1,267 | -0.02675 (0.00348), 1,224 |
| 31 economies, full period | -0.01950 (0.00412), 1,054 | -0.02658 (0.00408), 1,023 | -0.02454 (0.00404), 992 |
| 31 economies, common period | -0.03135 (0.00731), 558 | -0.04057 (0.00515), 527 | -0.03874 (0.00732), 496 |
| 43 economies, common period | -0.03381 (0.00610), 762 | -0.04139 (0.00562), 719 | -0.03883 (0.00659), 676 |

The committed 24-row regression CSV verifies the exact 31-country common-period H1 coefficient **−0.031353** (SE **0.007305**; p = **0.000170**; 558 observations and 31 countries). All 12 linear credit-gap coefficients are negative and statistically significant at 1%. The coefficients in the common-window specifications are larger in absolute value than those in the corresponding full-window specifications, indicating sensitivity to the time period covered.

The asymmetric models make the conclusion more qualified. In both full-period samples, the positive credit-gap component is negative and significant, the negative-gap component is approximately zero and insignificant, and the slopes differ significantly. In both common-period samples, **both slopes are individually negative and significant**, but their equality tests fail to reject at 5%. The slope-difference p-values are **0.22805** for the 31-country common sample and **0.08793** for the 43-country common sample. The asymmetry is therefore sensitive to the observation window, even though the linear association remains negative across all samples. This is an in-sample conditional predictive pattern, not causal identification or a real-time forecasting result.

## Measurement diagnostics

### Credit numerator and GDP denominator

The BIS actual-ratio series used in the diagnostic align within the pre-specified 0.10-percentage-point tolerance, and the published credit gap is reconstructed to numerical precision. The maximum difference between the two BIS actual-ratio sources is 0.05005 percentage points; the maximum gap-reconstruction error is 0.00011 percentage points. The numerator-denominator accounting identity holds to numerical precision.

In the matched sample of 1,268 observations, average annual log changes are 8.1912% for nominal credit, 6.7617% for the implied nominal-GDP denominator, and 1.4295% for the credit-to-GDP ratio. In the component regression, nominal credit growth has a negative coefficient and is significant under the wild cluster bootstrap (p = 0.0178). Implied nominal-GDP growth is not individually significant under the bootstrap (p = 0.1592), and the joint test is not significant at 5% (p = 0.0952).

This decomposition is a measurement and predictive diagnostic. It does not identify a causal transmission mechanism.

### Comparison with World Bank linked nominal GDP

The BIS-implied denominator was compared with World Bank WDI indicator NY.GDP.MKTP.CN.AD, GDP in linked current local currency. The full-sample validation matched 1,377 levels and 1,334 annual growth observations across 43 economies. The correlation between BIS-implied and World Bank linked nominal-GDP growth is 0.9962; the mean absolute difference is 0.2198 percentage points and the RMSE is 0.7244 percentage points.

The median absolute time-varying level deviation after country-specific scale adjustment is 0.0541%, while the upper tail reaches 9.95%. The largest growth differences are concentrated in a small number of country-years, including the United Kingdom in 1995, Indonesia in 1993, Argentina in 2004, Hungary in 1991, and Russia in 2011. The validation retains all observations; none are removed, winsorized, or adjusted.

This is a cross-source consistency check, not proof that the two sources are fully independent in their underlying national-accounts inputs.

### Four-sample linked-GDP validation

The complete sample-composition check compares the 43-economy unbalanced sample, 31 economies with complete 1990–2024 BIS Q4 credit-gap coverage, and both country sets over 2006–2024.

| Sample | GDP levels | Matched annual GDP growth | Correlation | Growth MAE (pp) | Growth RMSE (pp) |
|---|---:|---:|---:|---:|---:|
| 43 economies, original window | 1,377 | 1,334 | 0.99616 | 0.21985 | 0.72444 |
| 31 economies, full window | 1,085 | 1,054 | 0.99039 | 0.23247 | 0.73805 |
| 31 economies, 2006–2024 | 589 | 589 | 0.99098 | 0.22043 | 0.67067 |
| 43 economies, 2006–2024 | 817 | 815 | 0.99744 | 0.20060 | 0.63150 |

Both **Brazil and Colombia** enter the BIS sample in 2006. Their World Bank linked series report 2006 nominal-GDP growth, but the BIS-implied 2006 growth cannot be calculated without a BIS-implied denominator for 2005. Both countries retain their 2006 level comparisons; only their unavailable growth comparisons are excluded. The script exported the two-row audit as `outputs/tables/balanced_panel_common_growth_missing.csv`. It passed all four observation-count checks and final output-existence checks. The source data were not modified.

## Interpretation and limitations

The results show a consistent negative conditional predictive association between the BIS credit-to-GDP gap and subsequent annual real GDP growth in the main and linear sample-sensitivity specifications. The full-sample asymmetric model suggests that the relationship is concentrated in above-trend credit observations, but common-period estimates show that this asymmetry is sensitive to the sample window.

Several limitations constrain interpretation:

1. **No causal identification.** Country and outcome-year fixed effects, controls, clustered standard errors, and bootstrap inference do not make the credit gap exogenous.
2. **Generated explanatory variable.** The BIS gap is constructed using a one-sided HP trend and can be affected by endpoint behavior and historical revisions.
3. **GDP denominator.** GDP is part of the credit-to-GDP ratio. A higher ratio can reflect stronger credit, weaker GDP, or both. Controlling for current and lagged GDP growth does not eliminate this issue.
4. **Historical rather than real-time forecasting.** The exercise uses revised historical data. Its outcome-year fixed effects are estimated using realized observations from the full sample; although the outcome year is known in advance, the estimated year effects are not available for a genuinely new forecast period. The results are in-sample conditional associations, not an out-of-sample forecast accuracy assessment.
5. **Annual outcome scope.** The models study annual GDP growth in specific future years; they do not measure every dimension of macroeconomic volatility or cumulative output losses.
6. **Cross-source dependence.** The linked World Bank validation supports measurement consistency but does not establish fully independent national-accounts inputs.

The defensible contribution is a reproducible applied macro-finance panel analysis with transparent sample, inference, and denominator diagnostics. It should not be described as identifying credit-supply shocks, monetary-policy transmission, speculative credit diversion, or a causal effect of leverage on output.

## Reproducibility and remaining validation

The code is organized as a Stata project and is designed to run with Stata 15.1 or later; the recorded empirical runs used Stata 17. The main analysis uses built-in Stata commands. The optional wild cluster bootstrap requires David Roodman's boottest package.

The main entry points are:

- replication/download_data.do — main BIS and WDI source acquisition.
- replication/run_analysis.do — panel construction and baseline regressions.
- replication/inference_diagnostics.do — wild cluster bootstrap.
- replication/denominator_diagnostic.do — BIS numerator-denominator decomposition.
- replication/validate_nominal_gdp_linked.do — linked WDI cross-source validation.
- replication/audit_nominal_gdp_linked.do — country-year discrepancy audit.
- replication/balanced_panel_sensitivity.do — regression and linked-GDP sample sensitivity.

The following numerical outputs have been inspected for internal consistency and committed: [balanced-panel regression coefficients](../outputs/tables/balanced_panel_regression_coefficients.csv), [four-sample linked-GDP validation](../outputs/tables/balanced_panel_linked_gdp_validation.csv), and the [two-row missing-growth audit](../outputs/tables/balanced_panel_common_growth_missing.csv). The regression CSV contains 24 coefficient rows with no duplicate model-term combinations or missing numeric fields. Its p-values and 95% confidence intervals are consistent with the reported standard errors and country-cluster degrees of freedom.

The five published result tables and fourteen PNG/GPH graph pairs are now committed. The final 14 November 2026 combined sensitivity log ran through its last output assertion and normal log closure without a Stata error. Its reported coefficients, asymmetric equality tests and four linked-GDP comparisons match the committed tables. See [the independent output review](OUTPUT_REVIEW.md) and [the execution-verification record](EXECUTION_VERIFICATION.md).

The note is suitable for a **research portfolio** subject to the interpretive limits discussed above. Optional archival enhancements include publishing a privacy-sanitized full Stata log, preserving the remaining locally generated processed `.dta` data artifacts, and obtaining an independent third-party reproduction from the locked data vintage. These are distinct from the successfully completed local execution and are not prerequisites to showcasing the existing research results.

## References

- Drehmann, M. and Yetman, J. (2021). “Which Credit Gap Is Better at Predicting Financial Crises? A Comparison of Univariate Filters.” *International Journal of Central Banking*, 17(4), 1–31. [Article](https://www.ijcb.org/journal/v17n4/which-credit-gap-better-predicting-financial-crises-comparison-univariate-filters).
- Jordà, Ò., Schularick, M. and Taylor, A. M. (2013). “When Credit Bites Back.” *Journal of Money, Credit and Banking*, 45(s2), 3–28. [DOI](https://doi.org/10.1111/jmcb.12069).
- Mian, A., Sufi, A. and Verner, E. (2017). “Household Debt and Business Cycles Worldwide.” *The Quarterly Journal of Economics*, 132(4), 1755–1817. [DOI](https://doi.org/10.1093/qje/qjx017).
- Schularick, M. and Taylor, A. M. (2012). “Credit Booms Gone Bust: Monetary Policy, Leverage Cycles, and Financial Crises, 1870–2008.” *American Economic Review*, 102(2), 1029–1061. [DOI](https://doi.org/10.1257/aer.102.2.1029).

---

This research-portfolio note summarizes completed, documented Stata 17 analysis. Five verified CSV outputs and fourteen PNG/GPH figure pairs are published, and a successful final combined sensitivity execution has been verified. The estimates are in-sample conditional associations, not causal effects or externally validated real-time forecasts.