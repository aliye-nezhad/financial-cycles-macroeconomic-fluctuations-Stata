# Credit-to-GDP Gaps and Subsequent Real GDP Growth: Cross-Country Evidence

> **Internal working draft.** This note summarizes the current empirical project for research-portfolio development. It is not yet an external-ready working paper: final export and inspection of the four-sample linked-GDP comparison and its two unmatched growth observations, inspection of the newly regenerated audit tables and regression CSV, and review of the remaining figures are still outstanding. The numerical findings below are drawn from the Stata 17 execution records documented in this repository. GitHub Actions does not execute Stata.

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

For country \(i\), predictor year \(t\), and horizon \(h\), the baseline specification is:

\[
g_{i,t+h}=\alpha_i+\lambda_{t+h}
+\beta_h Gap_{i,t}
+\rho_h g_{i,t}
+\delta_h g_{i,t-1}
+\gamma_h \pi_{i,t}
+\varepsilon_{i,t+h},
\]

where \(g\) is annual real GDP growth, \(Gap\) is the Q4 BIS credit-to-GDP gap, and \(\pi\) is CPI inflation. The model includes country fixed effects and fixed effects for the outcome year. Standard errors are clustered by country.

The primary outcome is annual growth in the specific future year, not cumulative growth over the forecast horizon. The one-year-ahead specification is primary; two- and three-year horizons are extensions.

The asymmetric model replaces the single gap term with:

\[
Gap^+_{i,t}=\max(Gap_{i,t},0),\qquad
Gap^-_{i,t}=\min(Gap_{i,t},0).
\]

This allows the above-trend and below-trend slopes to differ. The sign and magnitude of the below-trend slope are treated as empirical questions rather than assumed to mirror the above-trend slope.

## Main findings

### Baseline predictive regressions

| Outcome | Credit-gap coefficient | Clustered SE | Observations |
|---|---:|---:|---:|
| GDP growth in \(t+1\) | -0.0228 | 0.0038 | 1,310 |
| GDP growth in \(t+2\) | -0.0290 | 0.0036 | 1,267 |
| GDP growth in \(t+3\) | -0.0268 | 0.0035 | 1,224 |

All three coefficients are statistically significant at \(p<0.001\) using conventional country-clustered inference. A 10-percentage-point higher credit gap is associated with approximately 0.228 percentage points lower annual GDP growth in the following year, conditional on the included controls and fixed effects. The corresponding associations are 0.290 and 0.268 percentage points at the two- and three-year horizons.

These are annual growth rates in the respective outcome years, not cumulative output losses.

### Asymmetry

| Component | Coefficient | Clustered SE | p-value |
|---|---:|---:|---:|
| Positive credit-gap component | -0.0514 | 0.0101 | <0.001 |
| Negative credit-gap component | -0.0021 | 0.0056 | 0.706 |

The test of equal slopes gives \(F(1,42)=14.85\), \(p=0.0004\). In the full sample, the negative conditional association is concentrated in observations where the credit-to-GDP ratio is above its estimated trend. The below-trend slope is close to zero and statistically indistinguishable from zero.

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
| 31 economies, common period | N=558; p=0.00017; coefficient/SE not in log excerpt | -0.04057 (0.00515), 527 | -0.03874 (0.00732), 496 |
| 43 economies, common period | -0.03381 (0.00610), 762 | -0.04139 (0.00562), 719 | -0.03883 (0.00659), 676 |

The 14 November Stata excerpt now confirms 558 observations, 31 country clusters and p = 0.00017 for the 31-country common-period H1 regression, resolving its sample-count inconsistency. The excerpt omits the coefficient and standard error, so those values should be copied from the newly exported regression CSV before this table is finalized. The other 11 previously reported linear estimates are negative and significant at 1%. The count-consistent common-period estimates are larger in absolute value than the full-period estimates, indicating sensitivity to the period covered.

The asymmetric results are less stable. The full-period samples reproduce the original pattern of a negative and significant positive-gap slope, a near-zero negative-gap slope, and rejection of equal slopes. The 14 November run exported the asymmetric sensitivity figure, but the pasted excerpt does not give the 31-country common-period H1 coefficients or slope test. Retain these as unverified until the generated regression CSV is inspected. In the 43-country common-period sample, both component slopes are negative and individually significant, but the equality test does not reject equal slopes at 5%. The asymmetry should not be presented as invariant to sample period.

## Measurement diagnostics

### Credit numerator and GDP denominator

The BIS actual-ratio series used in the diagnostic align within the pre-specified 0.10-percentage-point tolerance, and the published credit gap is reconstructed to numerical precision. The maximum difference between the two BIS actual-ratio sources is 0.05005 percentage points; the maximum gap-reconstruction error is 0.00011 percentage points. The numerator-denominator accounting identity holds to numerical precision.

In the matched sample of 1,268 observations, average annual log changes are 8.1912% for nominal credit, 6.7617% for the implied nominal-GDP denominator, and 1.4295% for the credit-to-GDP ratio. In the component regression, nominal credit growth has a negative coefficient and is significant under the wild cluster bootstrap (p = 0.0178). Implied nominal-GDP growth is not individually significant under the bootstrap (p = 0.1592), and the joint test is not significant at 5% (p = 0.0952).

This decomposition is a measurement and predictive diagnostic. It does not identify a causal transmission mechanism.

### Comparison with World Bank linked nominal GDP

The BIS-implied denominator was compared with World Bank WDI indicator NY.GDP.MKTP.CN.AD, GDP in linked current local currency. The full-sample validation matched 1,377 levels and 1,334 annual growth observations across 43 economies. The correlation between BIS-implied and World Bank linked nominal-GDP growth is 0.9962; the mean absolute difference is 0.2198 percentage points and the RMSE is 0.7244 percentage points.

The median absolute time-varying level deviation after country-specific scale adjustment is 0.0541%, while the upper tail reaches 9.95%. The largest growth differences are concentrated in a small number of country-years, including the United Kingdom in 1995, Indonesia in 1993, Argentina in 2004, Hungary in 1991, and Russia in 2011. The validation retains all observations; none are removed, winsorized, or adjusted.

This is a cross-source consistency check, not proof that the two sources are fully independent in their underlying national-accounts inputs.

## Interpretation and limitations

The results show a consistent negative conditional predictive association between the BIS credit-to-GDP gap and subsequent annual real GDP growth in the main and linear sample-sensitivity specifications. The full-sample asymmetric model suggests that the relationship is concentrated in above-trend credit observations, but common-period estimates show that this asymmetry is sensitive to the sample window.

Several limitations constrain interpretation:

1. **No causal identification.** Country and outcome-year fixed effects, controls, clustered standard errors, and bootstrap inference do not make the credit gap exogenous.
2. **Generated explanatory variable.** The BIS gap is constructed using a one-sided HP trend and can be affected by endpoint behavior and historical revisions.
3. **GDP denominator.** GDP is part of the credit-to-GDP ratio. A higher ratio can reflect stronger credit, weaker GDP, or both. Controlling for current and lagged GDP growth does not eliminate this issue.
4. **Historical rather than real-time data.** The exercise uses revised historical series and is not a real-time forecasting evaluation.
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

Before this note is used externally, the following items remain:

1. Inspect the new regression CSV to verify the 31-country common-period H1 linear and asymmetric coefficients and standard errors. The 14 November standalone validation calculated 817 level matches and 815 growth matches for all 43 economies over 2006–2024 (growth correlation 0.99744, MAE 0.20060 pp, RMSE 0.63150 pp), but its obsolete 817-growth count assertion stopped the export. The committed standalone script now expects 815 and outputs the two unmatched country-years. Run it once to produce and review the consolidated four-sample CSV and missing-growth audit.
2. The linked-GDP audit was rerun successfully on 14 November 2026. Review and commit its regenerated, narrowed top-20 CSV files and the other audit outputs when available.
3. Review the four main-analysis figures, two denominator-diagnostic figures, and three balanced-panel figures against their tables and logs.
4. Freeze the final source metadata, checksums, tables, figures, and logs. GitHub Actions checks repository structure and source acquisition; it does not run Stata or validate numerical estimates.

## References

- Drehmann, M. and Yetman, J. (2021). “Which Credit Gap Is Better at Predicting Financial Crises? A Comparison of Univariate Filters.” *International Journal of Central Banking*, 17(4), 1–31. [Article](https://www.ijcb.org/journal/v17n4/which-credit-gap-better-predicting-financial-crises-comparison-univariate-filters).
- Jordà, Ò., Schularick, M. and Taylor, A. M. (2013). “When Credit Bites Back.” *Journal of Money, Credit and Banking*, 45(s2), 3–28. [DOI](https://doi.org/10.1111/jmcb.12069).
- Mian, A., Sufi, A. and Verner, E. (2017). “Household Debt and Business Cycles Worldwide.” *The Quarterly Journal of Economics*, 132(4), 1755–1817. [DOI](https://doi.org/10.1093/qje/qjx017).
- Schularick, M. and Taylor, A. M. (2012). “Credit Booms Gone Bust: Monetary Policy, Leverage Cycles, and Financial Crises, 1870–2008.” *American Economic Review*, 102(2), 1029–1061. [DOI](https://doi.org/10.1257/aer.102.2.1029).

---

This draft is an internal research-portfolio document. It should be updated only after the remaining Stata validation and output-review tasks are completed.