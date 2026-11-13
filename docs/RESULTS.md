# Preliminary empirical results

**Execution date:** 13 November 2026  
**Source vintage:** BIS WS_CREDIT_GAP and World Bank WDI files documented in [DATA_AUDIT.md](DATA_AUDIT.md) and [DATA_VINTAGE.md](../data/DATA_VINTAGE.md).  
**Execution record:** User-supplied Stata log from the completed run of `replication/run_analysis.do`.

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
- The conventional standard errors are clustered across 43 countries. The installed `boottest.ado` identifies itself as version 4.1.0, while `boottest.mata` identifies itself as version 4.0.3. This pairing is present in the official upstream v4.1.0 tag; the different header numbers alone do not indicate a mixed installation. The earlier `boottest_stata() not found` error indicates that the compiled Mata function was unavailable in that Stata session. The diagnostic now runs the installed Mata source before estimation to rebuild the library. The complete diagnostic should be rerun to verify the fix and obtain bootstrap inference for the new denominator-component model.
- The current horizon models estimate annual growth in the specific future year, not cumulative or average growth over the forecast interval.

## 6. Wild cluster bootstrap results

The supplementary diagnostic was executed in Stata 17 on the same 1,310-observation, 43-country one-year-ahead sample. Each test used 9,999 Rademacher replications, country-level clustering, and a fixed seed recorded in the do-file.

| Hypothesis | Bootstrap t-statistic | Displayed p-value | 95% bootstrap confidence set |
|---|---:|---:|---:|
| Baseline credit-gap coefficient = 0 | -6.0638 | 0.0000 | [-0.03090, -0.01429] |
| Positive-gap coefficient = 0 | -5.0903 | 0.0000 | [-0.07432, -0.02860] |
| Negative-gap coefficient = 0 | -0.3795 | 0.7163 | [-0.01367, 0.01219] |
| Positive-gap slope = negative-gap slope | -3.8545 | 0.0036 | [-0.07609, -0.01773] |

The displayed value 0.0000 is rounded output, not a probability literally equal to zero. The bootstrap test of equal asymmetric slopes rejects equality at the 1% level (p = 0.0036), consistent with the conventional clustered Wald test, (F(1,42)=14.85), p = 0.0004. The positive-gap coefficient remains negative and statistically distinguishable from zero under the bootstrap; the negative-gap coefficient remains statistically indistinguishable from zero.

**Reproducibility qualification:** the official upstream v4.1.0 tag contains `boottest.ado` 4.1.0 and `boottest.mata` 4.0.3, so this is the intended package pairing, not a mixed-release installation. The earlier `boottest_stata() not found` error is consistent with a missing or unloaded compiled Mata library. The current do-file loads the Mata source before estimation. Rerun the full do-file to verify that the bootstrap tests complete in the current Stata session. The component-model bootstrap tests have been added but have not yet been executed. The bootstrap does not change the point estimates or identify a causal effect.

## 7. Figures and quantitative presentation

The analysis exports four distinct figures, each to its own PNG and editable Stata `.gph` file:

1. **Mean credit-to-GDP gap over time.** Describes the annual unweighted mean across available economies. The country coverage varies by year, so the figure is descriptive rather than a balanced-panel aggregate.
2. **Pooled credit-gap scatter.** Shows the unconditional country-year association between the credit gap and next-year GDP growth. Its fitted line is not the two-way fixed-effects estimate and should not be used as a visual substitute for the adjusted model.
3. **Fixed-effects coefficients across horizons.** Plots the baseline credit-gap coefficients for GDP growth in (t+1), (t+2), and (t+3), with country-clustered 95% confidence intervals. This is the primary figure for communicating the central quantitative result. The estimated coefficients are -0.0228, -0.0290, and -0.0268, respectively.
4. **Asymmetric fixed-effects coefficients.** Plots the positive- and negative-gap slopes from the one-year-ahead asymmetric model, with country-clustered 95% confidence intervals. It makes the difference between the above-trend and below-trend components directly visible.

The first two figures provide descriptive context. Figures 3 and 4 communicate the adjusted estimates and asymmetry that are central to the empirical analysis. The figures do not establish causality.

The active Stata Graph window shows one graph at a time. This is a display behavior, not evidence that the exported files overwrite one another. The do-file explicitly exports and saves each named graph separately and checks for all eight figure files at the end of execution. Open the PNG files in separate image windows to compare them simultaneously. The exported PNGs still require visual inspection before being treated as final presentation outputs.

## 8. Credit-numerator and GDP-denominator diagnostic

**Execution date:** 13 November 2026  
**Execution record:** User-supplied Stata log from the completed run of `replication/denominator_diagnostic.do`.

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
| Credit-to-GDP ratio | 1.4295% |

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

These estimates are predictive associations, not causal effects. In particular, the implied denominator is constructed from credit-related BIS series. Independent validation against a separately published nominal-GDP series is still required before interpreting the component coefficients as evidence about an economic transmission mechanism.

### 8.4 Generated outputs and remaining checks

The run generated:

- `outputs/tables/denominator_decomposition.txt`
- `outputs/tables/denominator_component_models.txt`
- `outputs/figures/ratio_component_growth.png` and its editable `.gph` file
- `outputs/figures/ratio_component_coefficients.png` and its editable `.gph` file
- `outputs/logs/denominator_diagnostic.log`
- `data/processed/denominator_components_panel.dta`

The execution log confirms separate exports and both graph names in memory. It does not establish that the figures are visually publication-ready. The new component-model bootstrap tests have not yet been run.

## 9. Next empirical steps

1. **Rerun wild cluster bootstrap inference.** After the denominator diagnostic has generated the matched panel, run `do replication/inference_diagnostics.do`. The script now tests the original baseline and asymmetric models, the matched-sample baseline, each component coefficient, and the joint null that both component coefficients are zero. It loads the Mata source before estimation. Do not reinstall the package solely because the official v4.1.0 ado and Mata headers show 4.1.0 and 4.0.3, respectively.
2. **Inspect all six PNG figures.** Review the four main-analysis figures and the two denominator-diagnostic figures for legibility, scales, confidence intervals, country coverage, and consistency with the numerical tables.
3. **Validate the implied denominator independently.** Compare the reconstructed BIS four-quarter nominal-GDP series with World Bank GDP in current local currency (NY.GDP.MKTP.CN), checking both levels and annual growth rates, country coverage, and source-vintage differences.
4. **Check sample composition.** Add the number of contributing countries to the annual growth figure and estimate a balanced-panel sensitivity to determine whether changing country coverage affects the descriptive patterns.
5. **Only then consider alternative measures.** Decide whether a real-credit-growth specification or a denominator-adjusted credit measure adds information beyond the current component model.

The results remain preliminary until these inference, measurement, and figure checks are completed.