# Preliminary data audit

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
- [ ] Exported figures visually inspected and selected output artifacts prepared for publication.
- [ ] Optional wild cluster bootstrap inference completed (requires Stata 18+).
- [ ] Credit-numerator versus GDP-denominator sensitivity investigated.
