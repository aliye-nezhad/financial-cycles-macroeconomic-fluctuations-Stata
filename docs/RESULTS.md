# Preliminary empirical results

**Execution date:** 13 November 2026  
**Source vintage:** BIS WS_CREDIT_GAP and World Bank WDI files documented in [DATA_AUDIT.md](DATA_AUDIT.md) and [DATA_VINTAGE.md](../data/DATA_VINTAGE.md).  
**Execution record:** Stata 17 execution log from the completed run of `replication/run_analysis.do`.

This note records the first complete set of empirical estimates. It documents what the current specifications show; it does not claim causal identification or a novel structural mechanism.

## 1. Baseline predictive regressions

The baseline model includes country fixed effects, outcome-year fixed effects, current and previous-year real GDP growth, current CPI inflation, and standard errors clustered by country. The explanatory variable is the BIS fourth-quarter credit-to-GDP gap, measured in percentage points of GDP.

| Outcome | Credit-gap coefficient | Clustered SE | Observations | Countries |
|---|---:|---:|---:|---:|
| Annual GDP growth in \(t+1\) | -0.0228 | 0.0038 | 1,310 | 43 |
| Annual GDP growth in \(t+2\) | -0.0290 | 0.0036 | 1,267 | 43 |
| Annual GDP growth in \(t+3\) | -0.0268 | 0.0035 | 1,224 | 43 |

All three coefficients have Stata-reported \(p<0.001\).

A 10-percentage-point higher credit gap is associated with approximately 0.228 percentage points lower annual GDP growth in \(t+1\), 0.290 points lower growth in \(t+2\), and 0.268 points lower growth in \(t+3\), conditional on the included controls and fixed effects.

The \(t+2\) and \(t+3\) dependent variables are the annual GDP growth rates in those specific outcome years. They are not cumulative growth over two or three years, and the estimates should not be described as cumulative output losses.

## 2. Asymmetric specification

The asymmetric model replaces the single credit-gap term with:

\[
Gap^+_{i,t}=\max(Gap_{i,t},0),\qquad
Gap^-_{i,t}=\min(Gap_{i,t},0).
\]

| Component | Coefficient | Clustered SE | p-value |
|---|---:|---:|---:|
| Positive credit-gap component | -0.0514 | 0.0101 | <0.001 |
| Negative credit-gap component | -0.0021 | 0.0056 | 0.706 |

The test of equal slopes gives \(F(1,42)=14.85\), \(p=0.0004\).

In this specification, the negative conditional association is concentrated in observations where the credit-to-GDP ratio is above its estimated trend. The below-trend slope is close to zero and statistically indistinguishable from zero. A below-trend gap should not automatically be described as a credit contraction; it means that the observed credit-to-GDP ratio is below the BIS-estimated trend.

## 3. Measurement and specification sensitivities

| Specification | Gap coefficient | Clustered SE | Observations | p-value |
|---|---:|---:|---:|---:|
| Annual-average gap, all four quarters required | -0.0242 | 0.0044 | 1,305 | <0.001 |
| Exclude outcome years 2020 and 2021 | -0.0203 | 0.0027 | 1,224 | <0.001 |
| Omit lagged GDP growth, retain baseline sample | -0.0228 | 0.0039 | 1,310 | <0.001 |
| Omit CPI inflation control | -0.0228 | 0.0038 | 1,334 | <0.001 |

The negative baseline association is not driven solely by the fourth-quarter measurement, the pandemic outcome years, the lagged GDP-growth control, or the 24 Argentina observations omitted because of missing CPI inflation. The annual-average measure gives a somewhat larger absolute coefficient, but the estimates are close in scale.

## 4. Country-influence sensitivities

### Linear specification

| Sample | Gap coefficient | Clustered SE | Observations | Countries |
|---|---:|---:|---:|---:|
| Exclude Ireland | -0.0200 | 0.0032 | 1,276 | 42 |
| Exclude Luxembourg | -0.0231 | 0.0038 | 1,291 | 42 |
| Exclude both | -0.0204 | 0.0034 | 1,257 | 41 |

The linear negative association remains statistically significant at \(p<0.001\) in all three restricted samples.

### Asymmetric specification

| Sample | Positive-gap slope | Negative-gap slope | Equality-test p-value | Observations | Countries |
|---|---:|---:|---:|---:|---:|
| Full sample | -0.0514 | -0.0021 | 0.0004 | 1,310 | 43 |
| Exclude Ireland | -0.0455 | 0.0005 | 0.0040 | 1,276 | 42 |
| Exclude Luxembourg | -0.0537 | -0.0024 | 0.0010 | 1,291 | 42 |
| Exclude both | -0.0471 | -0.0005 | 0.0099 | 1,257 | 41 |

The positive-gap slope remains negative and statistically significant in each restricted sample. The negative-gap slope remains statistically indistinguishable from zero, and the equality test continues to reject equal slopes. The asymmetry is therefore not solely an Ireland- or Luxembourg-driven result in these country-exclusion checks.

These checks are influence diagnostics, not a justification for redefining the preferred sample. The baseline retains all 43 economies.

## 5. Interpretation boundaries

The current results support a consistent conditional predictive association between a higher BIS credit-to-GDP gap and lower subsequent annual GDP growth. They also show that the estimated relationship is asymmetric in the current specification.

Several qualifications remain important:

- The regressions do not identify a causal effect of credit accumulation on output.
- The credit-to-GDP gap is a generated measure based on a one-sided HP trend.
- GDP enters the denominator of the credit-to-GDP ratio. A higher ratio or gap can reflect stronger credit, weaker GDP, or both. Controlling for current and lagged GDP growth does not fully resolve this issue.
- The estimates use historical, revised data and are not a real-time forecasting exercise.
- The conventional standard errors are clustered across 43 countries. The installed `boottest.ado` identifies itself as version 4.1.0, while `boottest.mata` identifies itself as version 4.0.3. This pairing is present in the official upstream v4.1.0 tag; the different header numbers alone do not indicate a mixed installation. The earlier `boottest_stata() not found` error indicated that the compiled Mata function was unavailable in that Stata session. The diagnostic now runs the installed Mata source before estimation to rebuild the library. The subsequent Stata 17 run completed all eight bootstrap tests, including the matched-sample denominator-component tests; see Section 6.
- The current horizon models estimate annual growth in the specific future year, not cumulative or average growth over the forecast interval.

## 6. Wild cluster bootstrap results

**Execution date:** 13 November 2026  
**Execution record:** Stata 17 execution log from the completed run of `replication/inference_diagnostics.do`.

The diagnostic completed successfully. All eight tests used 9,999 Rademacher replications, country-level clustering across 43 economies, and the fixed seeds recorded in the do-file. The original baseline and asymmetric models use 1,310 observations; the matched-sample baseline and component model use 1,268 observations.

| Hypothesis | Bootstrap statistic | Displayed p-value | 95% bootstrap confidence set |
|---|---:|---:|---:|
| Baseline credit-gap coefficient = 0 | t = -6.0638 | 0.0000 | [-0.03090, -0.01429] |
| Positive-gap coefficient = 0 | t = -5.0903 | 0.0000 | [-0.07432, -0.02860] |
| Negative-gap coefficient = 0 | t = -0.3795 | 0.7163 | [-0.01367, 0.01219] |
| Positive-gap slope = negative-gap slope | t = -3.8545 | 0.0036 | [-0.07609, -0.01773] |
| Matched-sample credit-gap coefficient = 0 | t = -6.0226 | 0.0000 | [-0.03187, -0.01446] |
| Nominal credit-growth coefficient = 0 | t = -2.9230 | 0.0178 | [-0.06570, -0.008138] |
| Implied nominal-GDP-growth coefficient = 0 | t = 1.6886 | 0.1592 | [-0.01985, 0.1559] |
| Both component coefficients jointly equal zero | F(2,42) = 5.2084 | 0.0952 | Not applicable |

The displayed value 0.0000 is rounded output, not a probability literally equal to zero.

### 6.1 Interpretation

The bootstrap evidence supports the principal baseline and asymmetric findings. The baseline credit-gap coefficient remains negative and statistically distinguishable from zero. In the asymmetric model, the positive-gap slope is significant, the negative-gap slope is not, and the equality test rejects equal slopes (p = 0.0036). The asymmetry therefore survives this finite-cluster inference check.

The matched-sample baseline credit-gap coefficient is also significant. In the component model, nominal credit growth has a negative coefficient (-0.0380) and remains individually significant under the bootstrap (p = 0.0178). The implied nominal-GDP-growth coefficient is positive (0.0603) but is not individually significant (p = 0.1592).

The joint test of the two component coefficients gives p = 0.0952. It does not reject the joint null at the 5% level; it is marginal at the 10% level. The evidence therefore does not support a strong claim that the two components are jointly significant at conventional 5% levels. The stronger individual result is the negative conditional association for nominal credit growth.

The component coefficients remain predictive associations, not causal effects. The implied nominal-GDP denominator is reconstructed from BIS credit stock and credit-to-GDP ratio data. Independent validation against separately published nominal GDP is the next measurement check.

### 6.2 Reproducibility

The execution log confirms that the installed Mata source was loaded before estimation, the compiled `lboottest.mlib` was found, all eight tests completed, and the output log closed normally. Stata 17 was used. The installed `boottest.ado` 4.1.0 and `boottest.mata` 4.0.3 headers are the intended pairing in the official upstream v4.1.0 tag. No package reinstallation is indicated by this run.

## 7. Figures and quantitative presentation

The analysis exports four distinct figures, each to its own PNG and editable Stata `.gph` file:

1. **Mean credit-to-GDP gap over time.** Describes the annual unweighted mean across available economies. The country coverage varies by year, so the figure is descriptive rather than a balanced-panel aggregate.
2. **Pooled credit-gap scatter.** Shows the unconditional country-year association between the credit gap and next-year GDP growth. Its fitted line is not the two-way fixed-effects estimate and should not be used as a visual substitute for the adjusted model.
3. **Fixed-effects coefficients across horizons.** Plots the baseline credit-gap coefficients for GDP growth in (t+1), (t+2), and (t+3), with country-clustered 95% confidence intervals. This is the primary figure for communicating the central quantitative result. The estimated coefficients are -0.0228, -0.0290, and -0.0268, respectively.
4. **Asymmetric fixed-effects coefficients.** Plots the positive- and negative-gap slopes from the one-year-ahead asymmetric model, with country-clustered 95% confidence intervals. It makes the difference between the above-trend and below-trend components directly visible.

The first two figures provide descriptive context. Figures 3 and 4 communicate the adjusted estimates and asymmetry that are central to the empirical analysis. The figures do not establish causality.

The Stata scripts export each named graph separately. The four main-analysis PNG/GPH pairs were visually inspected and published, together with two denominator-component, three balanced-panel and five GDP-validation/audit pairs. All 14 PNG and 14 editable GPH files are versioned in [outputs/figures](../outputs/figures/). They are legible and do not show a substantive inconsistency with the reviewed tables. Some optional axis-label refinements are recorded in [the output review](OUTPUT_REVIEW.md).

## 8. Credit-numerator and GDP-denominator diagnostic

**Execution date:** 13 November 2026  
**Execution record:** Stata 17 execution log from the completed run of `replication/denominator_diagnostic.do`.

The supplementary diagnostic completed all ten sections, passed its source-alignment checks, estimated both matched-sample models, exported two separately named figures, saved the processed panel, and closed its logs.

### 8.1 Source alignment and accounting identity

| Check | Result |
|---|---:|
| Matched Q4 country-year observations | 1,377 |
| Economies | 43 |
| Common regression sample | 1,268 |
| Maximum absolute difference between WS_TC and WS_CREDIT_GAP actual ratios | 0.05005 percentage points |
| Maximum absolute error reconstructing the published credit gap | 0.00011 percentage points |
| Maximum absolute numerator-denominator identity error | Approximately 1.1 × 10⁻¹² |

Both source-comparison errors are below the pre-specified 0.10-percentage-point tolerance. The accounting identity

\[
\Delta\ln(Credit/GDP)=\Delta\ln(Credit)-\Delta\ln(GDP)
\]

holds to numerical precision in the common sample.

### 8.2 Component growth rates

| Component | Mean annual log change |
|---|---:|
| Nominal credit stock | 8.1912% |
| Implied nominal GDP denominator | 6.7617% |
| Credit-to-GDP ratio growth | 1.4295% |

These are pooled country-year means over the 1,268 matched observations, not balanced-panel or time-series averages. The implied nominal-GDP denominator is reconstructed from the BIS credit stock and credit-to-GDP ratio; it is not an independently observed GDP series.

### 8.3 Matched-sample regressions

Both models use 1,268 observations across 43 countries, country fixed effects, outcome-year fixed effects, and country-clustered standard errors.

| Variable | Matched baseline coefficient | p-value | Component-model coefficient | p-value |
|---|---:|---:|---:|---:|
| Credit-to-GDP gap | -0.0236 | <0.001 | — | — |
| Current real GDP growth | 0.2475 | <0.001 | — | — |
| Previous-year real GDP growth | 0.0137 | 0.466 | 0.1240 | 0.001 |
| CPI inflation | -0.0401 | 0.008 | — | — |
| Nominal credit growth | — | — | -0.0380 | 0.006 |
| Implied nominal GDP growth | — | — | 0.0603 | 0.099 |

Within-sample \(R^2\) is 0.5155 for the matched baseline and 0.4600 for the component model. These values should not be treated as a direct model-performance comparison because the specifications contain different regressors.

The component model indicates a negative conditional association between nominal credit growth and next-year real GDP growth, controlling for implied nominal-GDP growth, lagged real GDP growth, country fixed effects, and outcome-year fixed effects. The implied nominal-GDP-growth coefficient is positive but is not statistically distinguishable from zero at the conventional 5% level.

The component model omits current real GDP growth and CPI inflation, while retaining lagged real GDP growth. The common matched sample nevertheless requires current GDP growth and inflation so that the baseline and component specifications use the same observations.

These estimates are predictive associations, not causal effects. In particular, the implied denominator is constructed from credit-related BIS series. The linked World Bank cross-source validation is now reported in Section 10; it supports the denominator's measurement consistency but does not establish fully independent underlying source construction or identify an economic transmission mechanism.

### 8.4 Generated outputs and remaining checks

The run generated:

- `outputs/tables/denominator_decomposition.txt`
- `outputs/tables/denominator_component_models.txt`
- `outputs/figures/ratio_component_growth.png` and its editable `.gph` file
- `outputs/figures/ratio_component_coefficients.png` and its editable `.gph` file
- `outputs/logs/denominator_diagnostic.log`
- `data/processed/denominator_components_panel.dta`

The execution log confirms separate exports and both graph names in memory. Both denominator-component PNG/GPH pairs have since been visually inspected and committed. The component-model bootstrap tests are reported in Section 6.

## 9. Research-portfolio release status

The tested empirical specifications and numerical findings are **frozen for the research portfolio**. Five reviewed CSV outputs, including the 24 regression rows and the two top-20 linked-GDP discrepancy tables, are committed in [`outputs/tables/`](../outputs/tables/). All 14 PNG and 14 GPH figure pairs are committed in [`outputs/figures/`](../outputs/figures/).

On **14 November 2026**, Stata 17 successfully completed the latest combined `replication/balanced_panel_sensitivity.do`: 12 linear regressions, four asymmetric H1 specifications, four linked nominal-GDP sample comparisons, all required exports, and normal log closure. The 2,322-line execution log was directly inspected for completeness and terminal errors, and its numerical results match the versioned CSV files. The unmodified log's SHA-256 and results are documented in [EXECUTION_VERIFICATION.md](EXECUTION_VERIFICATION.md), without publishing local machine paths. The prior stopped combined log is superseded. The standalone validation-only script also completed successfully.

No further exploration or Stata rerun is required for the **validated portfolio results**. Optional archival work would preserve a privacy-sanitized complete log, some processed `.dta` datasets, and additional source-vintage records. Neither successful local execution nor GitHub Actions static/data-acquisition checks should be described as an independent third-party raw-data reproduction. The findings remain conditional in-sample predictive associations, not causal effects or tested real-time forecasts.

## 10. Linked nominal-GDP validation using the World Bank linked current-LCU series

**Execution date:** 13 November 2026  
**Execution record:** Stata 17 execution log from the completed run of `replication/validate_nominal_gdp_linked.do`.  
**World Bank vintage:** Indicator `NY.GDP.MKTP.CN.AD`; last updated 11 November 2026; retrieved 13 November 2026.

The validation compares the BIS-implied Q4 nominal-GDP denominator (Q4 credit stock divided by the Q4 credit-to-GDP ratio) with the World Bank's linked annual current-LCU GDP series. The linked WDI series is used because it is designed to reduce historical breaks associated with changes in national-accounts base years, source data, and methodologies.

### 10.1 Coverage

| Measure | Result |
|---|---:|
| Matched nominal-GDP levels | 1,377 |
| Countries with matched levels | 43 |
| Matched annual growth observations | 1,334 |
| Countries with matched growth | 43 |
| Growth comparison period | 1991–2024 |

No country was missing from the positive-level or annual-growth comparison. The first growth observation is 1991 because a preceding 1990 level is required.

### 10.2 Annual nominal-GDP growth

| Statistic | Result |
|---|---:|
| Mean BIS-implied nominal-GDP growth | 6.9897% |
| Mean World Bank linked nominal-GDP growth | 7.0235% |
| Mean signed difference (BIS minus WDI) | -0.0337 percentage points |
| Median signed difference | 0.0004 percentage points |
| Mean absolute error | 0.2198 percentage points |
| Root mean squared error | 0.7244 percentage points |
| Correlation | 0.9962 |
| 95th percentile absolute difference | 0.9566 percentage points |
| 99th percentile absolute difference | 2.9546 percentage points |
| Maximum absolute difference | 8.7760 percentage points |

The two growth series track one another very closely in the matched sample. The small mean signed difference and near-zero median difference indicate little overall directional bias. The RMSE is larger than the MAE because a relatively small number of observations lie in the upper tail; those observations are the subject of the next country-year audit.

### 10.3 Within-country level comparison

Raw local-currency levels are not pooled across countries. The comparison therefore reports each country's implied/WDI level ratio and separately examines the time variation around that country's median ratio.

| Statistic for the scale-adjusted deviation | Result |
|---|---:|
| Median absolute deviation | 0.0541% |
| Mean absolute deviation | 0.4574% |
| 75th percentile | 0.1596% |
| 95th percentile | 2.8228% |
| 99th percentile | 8.2413% |
| Maximum | 9.9510% |

The median country-specific level ratios are close to one for most economies, but persistent differences remain in some cases. Examples from the country-level output include Indonesia (1.0638), India (0.9337), Australia (1.0283), and Malaysia (1.0288). These are country-specific median level ratios, not time-varying deviations. The scale-adjusted statistic measures the latter and deliberately removes each country's median level scale.

The upper tail in the level-deviation distribution should be inspected rather than dismissed. The validation script does not delete, winsorize, or adjust any observations.

### 10.4 Interpretation and limits

The comparison provides strong cross-source evidence that the BIS-implied denominator reproduces the annual movement in nominal GDP. It supports using the reconstructed denominator in the supplementary numerator-denominator diagnostic, subject to the country-year outlier audit.

This is not proof that the two sources are fully independent in their underlying national-accounts inputs. Nor does it establish that the component regressions identify an economic transmission mechanism. The component estimates remain conditional predictive associations. The comparison validates a measurement construction; it does not establish causality.

The linked-GDP outlier audit in `replication/audit_nominal_gdp_linked.do` completed in Stata 17 on 13 November 2026 and was rerun on 14 November with focused top-20 discrepancy CSV exports. The narrowed level and growth outlier tables have now been independently checked for correct rankings, signed differences, nonmissing values and unique country-year keys, then committed. The five linked-GDP validation/audit PNG and GPH figure pairs have been visually inspected and published. No observations were removed, winsorized, or adjusted.

The audit confirms that the pooled validation statistics are strong, but the upper tail is not evenly distributed across country-years. The largest absolute annual-growth differences are:

| Rank | Country | Year | BIS-implied growth | WDI linked growth | Difference (BIS minus WDI) |
|---:|---|---:|---:|---:|---:|
| 1 | United Kingdom | 1995 | 4.9601% | 13.7362% | -8.7760 pp |
| 2 | Indonesia | 1993 | 15.4671% | 23.8176% | -8.3504 pp |
| 3 | Argentina | 2004 | 17.4795% | 25.5038% | -8.0243 pp |
| 4 | Hungary | 1991 | 10.0371% | 17.8783% | -7.8411 pp |
| 5 | Russia | 2011 | 18.9083% | 26.0916% | -7.1834 pp |

The largest absolute time-varying level deviations from each country's median implied/WDI level ratio are also concentrated in a small set of early observations:

| Rank | Country | Year | Implied/WDI level ratio | Absolute scale-adjusted deviation |
|---:|---|---:|---:|---:|
| 1 | Indonesia | 1991 | 1.16965 | 9.9510% |
| 2 | United Kingdom | 1990 | 1.09315 | 9.3058% |
| 3 | United Kingdom | 1991 | 1.09261 | 9.2522% |
| 4 | Hungary | 1990 | 1.09021 | 9.1866% |
| 5 | United Kingdom | 1993 | 1.09170 | 9.1608% |

Country-level mean absolute growth differences are largest for Australia (1.2258 percentage points), South Africa (0.6779), New Zealand (0.6012), Indonesia (0.5996), Russia (0.5399), and Argentina (0.4790). These country averages should be read alongside their maxima and RMSEs: a small number of large observations can dominate the latter even when the median absolute difference is modest. For example, the United Kingdom's mean absolute growth difference is 0.2866 percentage points, but its maximum is 8.7760 points and its RMSE is 1.5056 points.

The country-specific median level ratios identify a different issue from the time-varying deviations above. The largest absolute median level differences are India (6.6294%), Indonesia (6.3792%), Malaysia (2.8793%), and Australia (2.8349%). These reflect country-specific scale differences in the median ratio; they should not be conflated with the year-specific deviations around each country's median. The United Kingdom, for example, has a median level ratio very close to one (1.00008) despite several early-year deviations above 9%.

The audit identifies where source-level investigation should focus, but it does not establish why the discrepancies occur. Possible explanations such as historical national-accounts revisions, source coverage, timing conventions, or changes in underlying series must be checked against source documentation and country-specific data before being asserted. The observations remain in the validation panel unchanged.

### 10.6 Balanced-panel and common-period sensitivity

A final combined Stata 17 sensitivity run on **14 November 2026** successfully completed all 12 baseline horizon regressions and all four asymmetric one-year-ahead regressions across four sample definitions, and subsequently completed all four linked-GDP validation samples and required exports. The linear models retain country fixed effects, outcome-year fixed effects, current and lagged real GDP growth, CPI inflation, and country-clustered standard errors. The future outcome remains within 2024.

#### Linear predictive regressions

| Sample | H1 coefficient (SE), N | H2 coefficient (SE), N | H3 coefficient (SE), N |
|---|---:|---:|---:|
| 43 economies, unbalanced | -0.02280 (0.00376), 1,310 | -0.02901 (0.00357), 1,267 | -0.02675 (0.00348), 1,224 |
| 31 economies, full period | -0.01950 (0.00412), 1,054 | -0.02658 (0.00408), 1,023 | -0.02454 (0.00404), 992 |
| 31 economies, common period | -0.03135 (0.00731), 558 | -0.04057 (0.00515), 527 | -0.03874 (0.00732), 496 |
| 43 economies, common period | -0.03381 (0.00610), 762 | -0.04139 (0.00562), 719 | -0.03883 (0.00659), 676 |

The committed `outputs/tables/balanced_panel_regression_coefficients.csv` confirms the exact 31-country common-period H1 estimate of **−0.031353** (clustered SE **0.007305**), based on **558 observations** and **31 country clusters** (p = 0.000170). This resolves the earlier sample-count discrepancy without changing the estimation window. All **12 linear coefficients** are negative and significant at the 1% level. The common-period coefficients are larger in absolute magnitude than the corresponding full-period coefficients. This is evidence of period sensitivity, not causality or automatic superiority of the common-period specification. The 43-economy common-period regression sample is not strictly balanced because Argentina's CPI observations are missing for 2006–2017. The 24-row coefficient export contains no missing fields or duplicate model-term keys; reported p-values and 95% confidence intervals were checked against country-cluster degrees of freedom.

#### Asymmetric one-year-ahead regressions

| Sample | Positive-gap slope (p) | Negative-gap slope (p) | Slope difference (p) | N |
|---|---:|---:|---:|---:|
| 43 economies, unbalanced | -0.05138 (<0.001) | -0.00211 (0.7063) | -0.04927 (0.00039) | 1,310 |
| 31 economies, full period | -0.04842 (0.00023) | -0.00037 (0.9480) | -0.04806 (0.00205) | 1,054 |
| 31 economies, common period | -0.05075 (0.03043) | -0.01740 (0.02664) | -0.03335 (0.22805) | 558 |
| 43 economies, common period | -0.05327 (0.00278) | -0.01783 (0.01064) | -0.03544 (0.08793) | 762 |

The committed regression CSV confirms all four asymmetric H1 specifications, including the 31-country common-period coefficients and slope-equality test. **In both full-period samples**, the above-trend slope is negative and significant, the below-trend slope is close to zero and insignificant, and equal slopes are rejected at the 5% level. **In both common-period samples**, the above-trend and below-trend component slopes are each negative and individually significant, but the equality test fails to reject equal slopes at 5% (p = 0.22805 for 31 countries; p = 0.08793 for all 43). Consequently, the negative linear credit-gap association is robust across country-period definitions, while the specific asymmetry claim is not robust to the common-window restriction. These are country-clustered conventional tests in the sensitivity models; the main-sample wild bootstrap is documented separately and does not establish bootstrap significance for the common-period differences.

#### Linked nominal-GDP validation across country-period samples

The validation-only script `replication/validate_balanced_panel_samples.do` **completed successfully in Stata 17 on 14 November 2026**, including all four count checks, the four-sample CSV export, the processed validation dataset, and a separate two-observation missing-growth audit.

| Sample | Level observations | Growth observations | Growth correlation | Growth MAE (pp) | Growth RMSE (pp) | Median absolute level deviation | 95th percentile |
|---|---:|---:|---:|---:|---:|---:|---:|
| 43 economies, unbalanced | 1,377 | 1,334 | 0.99616 | 0.21985 | 0.72444 | 0.05411% | 2.82283% |
| 31 economies, full period | 1,085 | 1,054 | 0.99039 | 0.23247 | 0.73805 | 0.04398% | 2.80148% |
| 31 economies, common 2006–2024 | 589 | 589 | 0.99098 | 0.22043 | 0.67067 | 0.03398% | 1.29870% |
| 43 economies, common 2006–2024 | 817 | 815 | 0.99744 | 0.20060 | 0.63150 | 0.04423% | 1.04359% |

The 31-country full-period and common-period samples are based on 31 economies with complete BIS Q4 credit-gap coverage from 1990 through 2024. The common-period GDP level window is 2006–2024 for all 43 economies. The growth window is indexed by the same calendar years, but the number of valid pairs can differ from the number of levels.

**Two missing common-period growth comparisons are explained by source coverage.** The 2006 BIS-implied nominal-GDP growth is missing for Brazil (BRA) and Colombia (COL); their linked World Bank nominal-GDP growth observations are 10.440199% and 12.146179%, respectively. Both economies' BIS series begin in 2006, so the implied growth rate lacks the preceding 2005 BIS-implied level. Their 2006 GDP levels remain in the 817 level comparisons, while the 815 growth comparisons exclude the two unavailable BIS rates. The script exports these observations to `outputs/tables/balanced_panel_common_growth_missing.csv`. No missing growth values were imputed.

The high correlations and low average growth discrepancies persist across country-composition and sample-window choices. These results provide evidence of cross-source measurement consistency, not causal identification or evidence that the underlying national-accounts data are fully independent.

**Different sample-count conventions must not be confused.** The 31-country common-period H1 predictive regression uses predictor years 2006–2023, with 558 complete-case observations, to predict real growth in 2007–2024. The linked-GDP validation instead compares annual nominal-GDP growth indexed 2006–2024 and therefore includes 589 matched observations across the same 31 countries.

All five audited numerical outputs are committed to this repository: [24-row regression coefficients](../outputs/tables/balanced_panel_regression_coefficients.csv), [four-sample linked-GDP validation](../outputs/tables/balanced_panel_linked_gdp_validation.csv), [two-row BRA/COL missing-growth audit](../outputs/tables/balanced_panel_common_growth_missing.csv), [20 largest level deviations](../outputs/tables/nominal_gdp_linked_level_outliers_top20.csv), and [20 largest growth differences](../outputs/tables/nominal_gdp_linked_growth_outliers_top20.csv). All 28 figure files are also published. Both the standalone GDP validation and latest combined sensitivity script finished successfully in Stata 17; [the execution record](EXECUTION_VERIFICATION.md) documents the combined log digest and checks. Country-clustered p-values and confidence intervals were checked for internal consistency. GitHub Actions does not run Stata. All estimates remain observational in-sample predictive associations, not causal effects or evidence of out-of-sample forecast accuracy.
