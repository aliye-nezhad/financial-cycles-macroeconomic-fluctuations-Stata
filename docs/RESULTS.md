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
- The conventional standard errors are clustered across 43 countries. Finite-cluster inference remains to be checked with an optional wild cluster bootstrap.
- The current horizon models estimate annual growth in the specific future year, not cumulative or average growth over the forecast interval.

## 6. Next empirical steps

1. Run the optional wild cluster bootstrap diagnostic in [`replication/inference_diagnostics.do`](../replication/inference_diagnostics.do), if Stata 18 or later is available.
2. Visually inspect the two exported PNG figures and reconcile them with the logged commands.
3. Investigate the GDP-denominator channel directly by comparing the gap with movements in the underlying credit numerator and GDP denominator. This is the next substantive research question, not an invitation to add unrelated controls.
4. After these checks, decide whether a real-credit-growth or other alternative financial-cycle measure is justified.

The results should be treated as preliminary until these steps are completed.
