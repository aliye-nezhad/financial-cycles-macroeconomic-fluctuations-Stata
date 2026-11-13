# Financial Cycles and Macroeconomic Fluctuations: Cross-Country Evidence from Credit-to-GDP Gaps

This repository contains a reproducible Stata project examining whether the BIS credit-to-GDP gap predicts subsequent real GDP growth across economies. The empirical design uses an unbalanced annual country panel, country fixed effects, outcome-year fixed effects, and country-clustered standard errors.

The project is an observational predictive exercise. Its estimates describe conditional associations; they do not identify causal effects of credit supply, monetary policy, or financial shocks.

## Research question

Do credit-to-GDP gaps predict subsequent macroeconomic fluctuations across countries, and does the relationship differ between above-trend and below-trend credit conditions?

The primary outcome is annual real GDP growth. The principal financial-cycle indicator is the BIS credit-to-GDP gap, defined as the difference between the credit-to-GDP ratio and its one-sided long-run trend. The gap is measured in percentage points of GDP.

## Empirical design

The baseline horizon-specific specification is:

\[
g_{i,t+h}=\alpha_i+\lambda_{t+h}
+\beta_h Gap_{i,t}
+\rho_h g_{i,t}
+\delta_h g_{i,t-1}
+\gamma_h \pi_{i,t}
+\varepsilon_{i,t+h},
\]

where \(g\) is annual real GDP growth, \(Gap\) is the BIS credit-to-GDP gap, \(\pi\) is CPI inflation, \(\alpha_i\) denotes country fixed effects, and \(\lambda_{t+h}\) denotes fixed effects for the outcome year. Current and lagged GDP growth are included to condition on output-growth persistence and to address, but not eliminate, concerns arising from GDP's appearance in the credit-to-GDP denominator. The primary horizon is one year ahead; two- and three-year-ahead specifications are extensions. Standard errors are clustered by country.

An asymmetric specification separates positive and negative credit gaps. A robustness specification uses the annual mean of the four quarterly gap observations rather than the fourth-quarter observation.

These are predictive regressions, not causal designs. The BIS gap is an indicator of the financial cycle and potential excessive credit accumulation; it is not an exogenous monetary-policy shock.

## Data

The observation window is 1990–2024. The BIS reports 44 economies in its credit-gap dataset; the euro-area aggregate is excluded so that the analytical sample contains 43 individual economies. The downloaded vintage contains 1,377 Q4 country-year observations. After requiring current and previous-year GDP growth, inflation and the future outcome, the one-year-ahead complete-case sample contains 1,310 observations; see the data audit for the full horizon-specific counts.

| Variable | Source | Indicator or series |
|---|---|---|
| Credit-to-GDP gap | Bank for International Settlements | WS_CREDIT_GAP; quarterly; private non-financial sector borrowers; all lenders; actual-minus-trend gap |
| Real GDP growth | World Bank, World Development Indicators | NY.GDP.MKTP.KD.ZG |
| CPI inflation | World Bank, World Development Indicators | FP.CPI.TOTL.ZG |
| Nominal GDP (archival comparison) | World Bank, World Development Indicators | NY.GDP.MKTP.CN (unlinked current LCU) |
| Nominal GDP (preferred linked validation) | World Bank, World Development Indicators | NY.GDP.MKTP.CN.AD (linked current LCU) |

The BIS credit-gap measure covers borrowing from domestic and foreign sources and is not restricted to bank lending. It is calculated as the credit-to-GDP ratio minus a one-sided, backward-looking Hodrick–Prescott trend. The measure may differ from national-authority credit-gap estimates.

Source documentation, download instructions, transformations, and attribution requirements are recorded in [data/README.md](data/README.md).

## Repository structure

```text
├── .github/workflows/
│   ├── data-acquisition.yml
│   └── reproducibility.yml
├── data/
│   ├── raw/
│   ├── processed/
│   ├── DATA_VINTAGE.md
│   ├── raw.sha256
│   └── README.md
├── docs/
│   ├── DATA_AUDIT.md
│   ├── LITERATURE_NOTES.md
│   ├── RESEARCH_DESIGN.md
│   ├── RESULTS.md
│   └── REPRODUCIBILITY.md
├── outputs/
│   ├── figures/
│   ├── logs/
│   ├── tables/
│   └── README.md
└── replication/
    ├── balanced_panel_sensitivity.do
    ├── audit_nominal_gdp_linked.do
    ├── denominator_diagnostic.do
    ├── download_denominator_sources.ps1
    ├── download_data.do
    ├── download_nominal_gdp.ps1
    ├── download_linked_nominal_gdp.ps1
    ├── inference_diagnostics.do
    ├── run_analysis.do
    ├── validate_balanced_panel_samples.do
    ├── validate_nominal_gdp.do
    └── validate_nominal_gdp_linked.do
```

## Reproducing the project

A licensed installation of Stata 15.1 or later is required. The main analysis and supplementary measurement diagnostics use built-in Stata commands. The optional wild cluster bootstrap diagnostic requires David Roodman's user-written `boottest` package.

Clone the repository and change the working directory to its root:

```bash
git clone https://github.com/aliye-nezhad/financial-cycles-macroeconomic-fluctuations-Stata.git
cd financial-cycles-macroeconomic-fluctuations-Stata
```

Download the source data:

```stata
do replication/download_data.do
```

Run the main analysis:

```stata
do replication/run_analysis.do
```

The supplementary diagnostics can then be run separately:

```stata
do replication/denominator_diagnostic.do
do replication/inference_diagnostics.do
do replication/validate_nominal_gdp.do
do replication/validate_nominal_gdp_linked.do
do replication/audit_nominal_gdp_linked.do
do replication/balanced_panel_sensitivity.do

# Optional: rerun only the linked-GDP sample comparison
do replication/validate_balanced_panel_samples.do
```

The inference diagnostic requires a working installation of David Roodman's `boottest` package. It loads the installed Mata source before estimation and, when the denominator-components panel exists, also tests the matched-sample baseline and numerator-denominator model. Run the denominator diagnostic first to enable those additional tests. The denominator diagnostic downloads additional BIS credit and ratio series, checks their alignment with the main gap data, reconstructs the trailing-four-quarter nominal-GDP denominator, and produces a matched-sample component analysis. The linked nominal-GDP validation compares that reconstructed denominator with World Bank linked GDP in current local currency. The follow-up `replication/audit_nominal_gdp_linked.do` reports the largest country-year discrepancies and exports five separately named monochrome figures. The combined `replication/balanced_panel_sensitivity.do` reruns the baseline and asymmetric regressions across four samples and compares linked-GDP validation across the same country-period definitions. The standalone `replication/validate_balanced_panel_samples.do` reruns only the linked-GDP sample comparison when the regression section has already been completed. Both scripts use the 2006–2024 calendar-year window for common-period levels and growth. The 2006 growth rate uses the 2005 GDP level only as its lag input; the observation remains indexed to 2006. See [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for the execution sequence.

The repository also includes a GitHub Actions data-acquisition workflow for the main-analysis sources. It can be run manually from the Actions tab or triggered by adding the data/ACQUIRE_DATA marker file. The workflow downloads, validates, checksums and commits those source files to the private repository. The supplementary BIS series and both unlinked and linked World Bank nominal-GDP indicators have separate acquisition helpers and are checked in the Windows CI job. The WDI checks verify the requested indicator code, required year columns, archive/CSV checksums, and no-refresh idempotence. The Stata download scripts preserve existing raw archives by default; set their refresh option to 1 only when intentionally retrieving a new vintage. Retrieval dates and checksums are retained with the relevant source files.

See [docs/LITERATURE_NOTES.md](docs/LITERATURE_NOTES.md) for the focused annotated literature review, [docs/RESEARCH_DESIGN.md](docs/RESEARCH_DESIGN.md) for the hypotheses and specifications, [docs/DATA_AUDIT.md](docs/DATA_AUDIT.md) for the actual source-data coverage and expected sample counts, and [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for execution instructions.

## Current status

The complete Stata analysis was executed on 13 November 2026. The one-, two- and three-year-ahead samples match the pre-estimation audit exactly: 1,310, 1,267 and 1,224 observations across 43 economies. The baseline credit-gap coefficient is negative and statistically significant at all three horizons. The asymmetric specification indicates that the negative association is concentrated in above-trend credit observations. Annual-average-gap, pandemic-exclusion, control-variable and country-influence sensitivities have been run; the asymmetric result remains statistically distinguishable across the Ireland and Luxembourg exclusion checks. See [docs/RESULTS.md](docs/RESULTS.md) for the estimates and interpretation.

The main analysis generated its four figures separately, along with the expected tables, processed dataset and logs; the output-existence checks passed. These local outputs have not yet been committed and still require visual inspection. The supplementary [denominator diagnostic](replication/denominator_diagnostic.do) was executed successfully on 13 November 2026. Its supplied log reports 1,377 matched Q4 country-year observations across 43 economies and 1,268 observations in the common regression sample. The maximum discrepancy between the two BIS actual-ratio sources was 0.05005 percentage points, and the maximum credit-gap reconstruction error was 0.00011 percentage points. It generated two additional figures, two result tables, a processed panel and an execution log; these local outputs also require visual inspection and checksum recording. The [wild cluster bootstrap diagnostic](replication/inference_diagnostics.do) was executed successfully on 13 November 2026. All eight tests completed with 9,999 Rademacher replications across 43 country clusters. The positive-gap coefficient and asymmetric slope difference remain significant; the negative-gap coefficient does not. In the component model, nominal credit growth is individually significant (bootstrap p = 0.0178), implied nominal-GDP growth is not (p = 0.1592), and the joint test is marginal at 10% (p = 0.0952), not significant at 5%. See [docs/RESULTS.md](docs/RESULTS.md) for the complete statistics. The first independent nominal-GDP check used the unlinked WDI current-LCU series (`NY.GDP.MKTP.CN`). Its historical growth comparisons contain large country-specific discontinuities, so it is retained as an archival comparison rather than the preferred time-series benchmark. The preferred linked-series validation (`NY.GDP.MKTP.CN.AD`) was completed in Stata 17 on 13 November 2026. It matched 1,377 nominal-GDP levels and 1,334 annual growth observations across all 43 economies. The correlation between BIS-implied and World Bank nominal-GDP growth is 0.9962; the mean absolute difference is 0.2198 percentage points and the RMSE is 0.7244 points. The median absolute time-varying level deviation after country-specific scale adjustment is 0.0541%, although the upper tail reaches 9.95%. These results support the denominator reconstruction, subject to inspection of the outlier observations. The linked nominal-GDP outlier audit (`replication/audit_nominal_gdp_linked.do`) completed successfully in Stata 17 on 13 November 2026. It matched 1,377 level observations and 1,334 growth observations across 43 economies; generated the top-20 level and growth discrepancy tables, the 43-country summary, and the processed country-audit dataset; and exported all five figures in both PNG and editable GPH formats. The final output-existence checks passed. No observations were removed, winsorized, or adjusted. The largest growth discrepancies are concentrated in a small number of country-years, led by the United Kingdom (1995), Indonesia (1993), Argentina (2004), Hungary (1991), and Russia (2011). The largest time-varying level deviations include early observations for Indonesia, the United Kingdom, and Hungary. The numerical findings are documented in [docs/RESULTS.md](docs/RESULTS.md). The five linked-validation figures have been visually inspected and are legible in the project's monochrome style. The top-20 CSV exports have been narrowed to relevant audit fields in the updated do-file and must be regenerated before the linked-audit outputs are committed. The balanced-panel regression sensitivity has been run across four country-period samples: all 43 economies over the available period, the 31 complete-coverage economies over 1990–2024, and both country sets over the common 2006–2024 period. The combined source file `replication/balanced_panel_sensitivity.do` has been reconstructed from the Stata execution transcript and committed alongside the validation-only runner `replication/validate_balanced_panel_samples.do`. Both use separate level and growth filters: common-period levels cover 2006–2024, while common-period growth covers 2006–2024. The earlier Stata run correctly included the 2006 annual growth observation but stopped because the expected count was incorrectly set to 558 rather than 589. The 31-country common-period growth statistics were calculated in the log; the corrected script updates the count assertion and continues to the 43-country common-period comparison. Separately, the earlier regression sensitivity output reports 589 observations for the 31-country common-period H1 linear and asymmetric models, but their 2006–2023 predictor window allows at most 558. Those two H1 estimates are provisional; the combined script now checks the 558-observation count and must be rerun before the coefficients are reported. The corrected combined script must be executed in Stata to complete the 43-country common-period comparison and produce the consolidated four-sample linked-GDP output.

All estimates are conditional predictive associations. They do not identify causal effects of credit supply, leverage, monetary policy or financial shocks. GitHub Actions validates repository structure and source-file integrity and tests the supplementary BIS and World Bank nominal-GDP downloaders on Windows. It does not execute Stata or verify numerical estimates.

## Data attribution

BIS statistics are reproduced with attribution to the Bank for International Settlements. World Bank indicators are attributed to the World Bank's World Development Indicators. Data-source terms and retrieval details are documented in the data notes. This repository does not imply endorsement by either institution.

## License

The MIT License applies to the original code and documentation in this repository. Third-party datasets remain subject to their respective source terms.
