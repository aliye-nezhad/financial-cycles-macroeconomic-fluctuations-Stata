# Research design

## Working title

**Financial Cycles and Macroeconomic Fluctuations: Cross-Country Evidence from Credit-to-GDP Gaps**

## Research question

Do credit-to-GDP gaps predict subsequent real GDP growth across countries, and does the relationship differ between above-trend and below-trend credit conditions?

The project studies the predictive relationship between a financial-cycle indicator and subsequent real economic activity. It is an international macro-finance panel exercise, not a causal evaluation of monetary policy or bank credit supply.

## Motivation and literature

Credit is central to the interaction between financial conditions and the business cycle. A build-up of private-sector leverage can support current demand while increasing the economy's exposure to future balance-sheet adjustment. The credit-to-GDP gap is used as a summary indicator of deviations in private credit relative to a long-run trend and is part of the Basel III countercyclical capital-buffer framework.

The empirical motivation draws on the following literature:

1. **Schularick, M. and Taylor, A. M. (2012).** "Credit Booms Gone Bust: Monetary Policy, Leverage Cycles, and Financial Crises, 1870–2008." *American Economic Review*, 102(2), 1029–1061. [https://doi.org/10.1257/aer.102.2.1029](https://doi.org/10.1257/aer.102.2.1029). Establishes the importance of credit and leverage cycles for financial crises.
2. **Jordà, Ò., Schularick, M. and Taylor, A. M. (2013).** "When Credit Bites Back." *Journal of Money, Credit and Banking*, 45(s2), 3–28. [https://doi.org/10.1111/jmcb.12069](https://doi.org/10.1111/jmcb.12069). Studies the relationship between credit-intensive expansions, recessions and recoveries.
3. **Mian, A., Sufi, A. and Verner, E. (2017).** "Household Debt and Business Cycles Worldwide." *The Quarterly Journal of Economics*, 132(4), 1755–1817. [https://doi.org/10.1093/qje/qjx017](https://doi.org/10.1093/qje/qjx017). Examines household debt and subsequent macroeconomic outcomes across countries.
4. **Jordà, Ò., Schularick, M. and Taylor, A. M. (2017).** "Macrofinancial History and the New Business Cycle Facts." NBER Working Paper 22743. [https://www.nber.org/papers/w22743](https://www.nber.org/papers/w22743). Connects leverage and financial conditions with business-cycle dynamics.
5. **Drehmann, M. and Yetman, J. (2021).** "Which Credit Gap Is Better at Predicting Financial Crises? A Comparison of Univariate Filters." *International Journal of Central Banking*, 17(4), 1–31. [Published article](https://www.ijcb.org/journal/v17n4/which-credit-gap-better-predicting-financial-crises-comparison-univariate-filters). An earlier version is BIS Working Paper 878 (2020). This paper is particularly important for the measurement limitations of credit-to-GDP gaps.

This is a focused literature map rather than a claim to have completed a systematic review. The papers motivate the question and measurement choices; they do not establish that this project's specification is novel.

### A central measurement issue: the GDP denominator

The credit-to-GDP gap is built from a ratio whose denominator is GDP. As a result, movements in GDP can affect the measured credit-to-GDP ratio even when the numerator does not change proportionately. Drehmann and Yetman (2021) discuss this criticism explicitly, alongside concerns about HP-filter dynamics and endpoint behavior. This is not a minor footnote: it is a central reason to interpret the estimates as predictive associations rather than causal effects.

The baseline therefore controls for current GDP growth and its one-year lag, in addition to inflation, country fixed effects and outcome-year fixed effects. These controls do not eliminate the denominator issue or establish exogeneity. In the downloaded WDI vintage, CPI inflation is missing for Argentina from 1994 through 2017 (24 country-year observations); a no-inflation sensitivity model assesses the effect of this concentrated sample loss. The Q4 gap distribution also contains extreme observations for Ireland and Luxembourg. The baseline retains both countries, while separate influence checks exclude Ireland, Luxembourg, and both jointly. Ireland's GDP denominator deserves particular caution because the Irish Central Statistics Office documents large globalisation-related distortions in GDP and publishes modified GNI (GNI*) to exclude specified effects. See docs/DATA_AUDIT.md for the observations and source references.

## Data and sample

The outcome window is 1990–2024. The BIS credit-gap dataset covers 44 economies, including the euro-area aggregate. The aggregate is excluded to avoid double-counting countries represented individually, leaving 43 individual country units in the retrieved vintage. The preliminary source-data audit confirms 43 individual economies and 1,377 Q4 country-year observations. The panel is unbalanced: 31 countries have Q4 observations for all years from 1990 through 2024, while 12 begin later. The one-year-ahead complete-case sample has 1,310 observations across all 43 countries; the two- and three-year-ahead samples have 1,267 and 1,224 observations, respectively. See docs/DATA_AUDIT.md for country coverage, missingness, data distributions and pre-estimation sample counts.

### Main variables

| Variable | Definition | Source |
|---|---|---|
| Real GDP growth | Annual percentage growth in real GDP | World Bank WDI, NY.GDP.MKTP.KD.ZG |
| Credit-to-GDP gap | Actual private non-financial-sector credit-to-GDP ratio minus its long-run trend, in percentage points of GDP | BIS, WS_CREDIT_GAP, CG_DTYPE = C |
| CPI inflation | Annual percentage change in consumer prices | World Bank WDI, FP.CPI.TOTL.ZG |

The BIS gap is quarterly and measured at period end. The baseline annual measure is the fourth-quarter observation. An annual average of the four quarterly observations is used as a robustness measure when all four quarters are available.

The BIS measure covers borrowing by the private non-financial sector from all domestic and foreign sources and from all lender sectors. It is not a bank-only credit measure. The BIS constructs the trend using a one-sided, backward-looking Hodrick–Prescott filter. The indicator is intended to summarize excessive credit accumulation; it is not a monetary-policy shock or a direct measure of credit supply.

## Hypotheses

- **H1 (predictive association):** A higher credit-to-GDP gap is associated with lower subsequent real GDP growth, conditional on current and previous-year growth, inflation, country fixed effects and outcome-year fixed effects.
- **H2 (asymmetry):** The relationship between the credit gap and subsequent growth differs between observations above and below the estimated credit-to-GDP trend. The sign and magnitude of the below-trend slope are treated as empirical questions rather than assumed to be the mirror image of the above-trend slope.
- **H3 (horizon):** The predictive association may differ across one-, two- and three-year-ahead growth outcomes.

These hypotheses concern conditional prediction. They do not imply a causal effect.

## Econometric specifications

Let i index countries, t index the predictor year, and h denote the forecast horizon. The baseline is:

\[
g_{i,t+h}=\alpha_i+\lambda_{t+h}
+\beta_h Gap_{i,t}
+\rho_h g_{i,t}
+\delta_h g_{i,t-1}
+\gamma_h \pi_{i,t}
+\varepsilon_{i,t+h},
\]

where:

- \(g_{i,t+h}\) is annual real GDP growth h years after the credit-gap observation;
- \(Gap_{i,t}\) is the fourth-quarter BIS credit-to-GDP gap in year t;
- \(g_{i,t}\) is current-year real GDP growth;
- \(g_{i,t-1}\) is the previous year's real GDP growth;
- \(\pi_{i,t}\) is current-year CPI inflation;
- \(\alpha_i\) are country fixed effects;
- \(\lambda_{t+h}\) are fixed effects for the outcome year.

The primary specification uses h = 1. The h = 2 and h = 3 specifications are secondary horizon extensions. The coefficient \(\beta_h\) is a predictive association: a one-percentage-point increase in the credit gap is associated with a \(\beta_h\)-percentage-point difference in subsequent annual GDP growth, conditional on the included controls and fixed effects.

Country fixed effects absorb time-invariant country characteristics. Outcome-year fixed effects absorb shocks common to countries in the same outcome year. Standard errors are clustered by country to allow heteroskedasticity and serial correlation within countries. The current sample contains 43 country clusters. Because finite-cluster performance depends on the number and balance of clusters, an optional wild cluster bootstrap diagnostic is provided using David Roodman's user-written `boottest` package, which works after `xtreg, fe` in Stata 15.1 and later; it supplements rather than replaces the baseline clustered inference.

### Asymmetric specification

Define:

\[
Gap^+_{i,t}=\max(Gap_{i,t},0),\qquad
Gap^-_{i,t}=\min(Gap_{i,t},0).
\]

Replace the single gap term with both components:

\[
g_{i,t+1}=\alpha_i+\lambda_{t+1}
+\beta^+ Gap^+_{i,t}
+\beta^- Gap^-_{i,t}
+\rho g_{i,t}+\delta g_{i,t-1}+\gamma\pi_{i,t}+\varepsilon_{i,t+1}.
\]

The equality of the two slopes is tested directly. A negative gap is not automatically interpreted as a credit contraction; it means the observed credit-to-GDP ratio is below the BIS-estimated trend.

### Robustness checks

1. Replace the fourth-quarter gap with the annual mean of the four quarterly gap observations, requiring all four quarters.
2. Re-estimate the one-year-ahead specification after excluding outcome years 2020 and 2021, to assess sensitivity to the pandemic period.
3. Report the one-, two- and three-year-ahead estimates separately rather than treating the overlapping horizons as independent observations in a pooled regression.
4. Compare the baseline with a specification omitting the lagged GDP-growth control, to show whether the main coefficient is sensitive to additional conditioning for output-growth persistence.
5. Omit the CPI control to recover the Argentina observations missing from the WDI inflation series.
6. Re-estimate both the linear and asymmetric one-year specifications excluding Ireland, Luxembourg, and both jointly as influence diagnostics. For the asymmetric models, report the two component slopes and test their equality in each restricted sample. These are sensitivities, not preferred sample definitions.

The project will not add FGLS, AR(1), random-effects or dynamic-panel estimators merely to increase the number of procedures. Any additional estimator must be motivated by the research question and the properties of the data.

## Interpretation and limitations

1. **No causal identification.** Credit gaps can respond to expected output, financial conditions, policy, and other shocks. Country and year fixed effects do not eliminate all time-varying confounding or reverse causality.
2. **Measurement.** The BIS gap is a generated indicator based on a one-sided HP trend. It is not directly observed and may be revised as the source data are updated. The retrieved sample contains extreme values, including large positive gaps for Luxembourg and large negative gaps for Ireland; these are retained in the baseline and examined through influence sensitivities.
3. **Credit composition.** The measure includes household and non-financial corporate borrowing and all lender sectors. It cannot isolate bank lending, household debt, corporate debt, or speculative credit allocation.
4. **Cross-country comparability.** BIS harmonization improves comparability, but national data sources and institutional settings still differ.
5. **Unbalanced coverage.** The effective sample may vary by horizon and specification. In the retrieved vintage, CPI is missing for Argentina in 1994–2017, and observation coverage starts later than 1990 for 12 countries. Observation counts, country counts and year coverage must be reported for every model.
6. **Inference.** Country clustering is appropriate for within-country dependence, but the effective number of clusters and sample composition must be reported. Robustness of inference should be discussed rather than assumed.
7. **Outcome scope.** The main outcome is real GDP growth. The title refers to macroeconomic fluctuations broadly, but the empirical analysis does not claim to measure every dimension of macroeconomic volatility.

## Implementation status and next diagnostics

The complete analysis script has been executed. Its one-, two- and three-year-ahead sample counts match the pre-estimation data audit, and the baseline, asymmetric, annual-average-gap, pandemic-exclusion, control-variable and country-influence specifications have been reviewed. The asymmetric specification has also been re-estimated after excluding Ireland, Luxembourg and both jointly; the difference between the positive- and negative-gap slopes remains statistically significant in each restricted sample.

The results are recorded in [docs/RESULTS.md](RESULTS.md). They remain preliminary as a research contribution, even though the programmed models have run successfully.

The next steps are deliberately limited to questions that affect interpretation:

1. The baseline and all three asymmetric wild cluster bootstrap tests have been executed with 9,999 Rademacher replications in Stata 17. However, the installed `boottest.ado` and `boottest.mata` identify different versions (4.1.0 and 4.0.3). Install one consistent tagged release and rerun the diagnostic before treating the bootstrap results as final.
2. Inspect the four exported PNG figures and compare them with the numerical tables. The latest execution log confirms that the four graph objects were exported separately, but the images have not yet been visually reviewed.
3. Run `replication/denominator_diagnostic.do`. This supplementary script obtains the BIS actual credit-to-GDP ratio and trend, together with the underlying private non-financial-sector credit stock. It reconstructs the trailing-four-quarter nominal-GDP denominator, checks the identities across BIS series, and compares the predictive content of nominal credit growth and implied nominal-GDP growth on a common sample. The script has been added but has not yet been executed.
4. Only after these checks, decide whether a modified credit-gap measure using a smoothed GDP denominator or a real-credit-growth alternative is justified. Do not add estimators merely to enlarge the model list.

The project remains an observational predictive exercise. No result should be described as a causal effect.
