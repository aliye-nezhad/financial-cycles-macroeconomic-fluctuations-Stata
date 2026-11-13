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
| Nominal GDP (supplementary validation) | World Bank, World Development Indicators | NY.GDP.MKTP.CN (current LCU) |

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
    ├── denominator_diagnostic.do
    ├── download_denominator_sources.ps1
    ├── download_data.do
    ├── download_nominal_gdp.ps1
    ├── inference_diagnostics.do
    ├── run_analysis.do
    └── validate_nominal_gdp.do
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
```

The inference diagnostic requires a working installation of David Roodman's `boottest` package. It loads the installed Mata source before estimation and, when the denominator-components panel exists, also tests the matched-sample baseline and numerator-denominator model. Run the denominator diagnostic first to enable those additional tests. The denominator diagnostic downloads additional BIS credit and ratio series, checks their alignment with the main gap data, reconstructs the trailing-four-quarter nominal-GDP denominator, and produces a matched-sample component analysis. The independent nominal-GDP validation then compares that reconstructed denominator with World Bank GDP in current local currency. See [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for the execution sequence.

The repository also includes a GitHub Actions data-acquisition workflow for the main-analysis sources. It can be run manually from the Actions tab or triggered by adding the data/ACQUIRE_DATA marker file. The workflow downloads, validates, checksums and commits those source files to the private repository. The supplementary BIS and World Bank nominal-GDP sources have separate acquisition helpers and are validated in the Windows CI job. The Stata download scripts preserve existing raw archives by default; set their refresh option to 1 only when intentionally retrieving a new vintage. Retrieval dates and checksums are retained with the relevant source files.

See [docs/LITERATURE_NOTES.md](docs/LITERATURE_NOTES.md) for the focused annotated literature review, [docs/RESEARCH_DESIGN.md](docs/RESEARCH_DESIGN.md) for the hypotheses and specifications, [docs/DATA_AUDIT.md](docs/DATA_AUDIT.md) for the actual source-data coverage and expected sample counts, and [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for execution instructions.

## Current status

The complete Stata analysis was executed on 13 November 2026. The one-, two- and three-year-ahead samples match the pre-estimation audit exactly: 1,310, 1,267 and 1,224 observations across 43 economies. The baseline credit-gap coefficient is negative and statistically significant at all three horizons. The asymmetric specification indicates that the negative association is concentrated in above-trend credit observations. Annual-average-gap, pandemic-exclusion, control-variable and country-influence sensitivities have been run; the asymmetric result remains statistically distinguishable across the Ireland and Luxembourg exclusion checks. See [docs/RESULTS.md](docs/RESULTS.md) for the estimates and interpretation.

The main analysis generated its four figures separately, along with the expected tables, processed dataset and logs; the output-existence checks passed. These local outputs have not yet been committed and still require visual inspection. The supplementary [denominator diagnostic](replication/denominator_diagnostic.do) was executed successfully on 13 November 2026. Its supplied log reports 1,377 matched Q4 country-year observations across 43 economies and 1,268 observations in the common regression sample. The maximum discrepancy between the two BIS actual-ratio sources was 0.05005 percentage points, and the maximum credit-gap reconstruction error was 0.00011 percentage points. It generated two additional figures, two result tables, a processed panel and an execution log; these local outputs also require visual inspection and checksum recording. The [wild cluster bootstrap diagnostic](replication/inference_diagnostics.do) was executed successfully on 13 November 2026. All eight tests completed with 9,999 Rademacher replications across 43 country clusters. The positive-gap coefficient and asymmetric slope difference remain significant; the negative-gap coefficient does not. In the component model, nominal credit growth is individually significant (bootstrap p = 0.0178), implied nominal-GDP growth is not (p = 0.1592), and the joint test is marginal at 10% (p = 0.0952), not significant at 5%. See [docs/RESULTS.md](docs/RESULTS.md) for the complete statistics. The new [independent nominal-GDP validation](replication/validate_nominal_gdp.do) has been added but has not yet been executed.

All estimates are conditional predictive associations. They do not identify causal effects of credit supply, leverage, monetary policy or financial shocks. GitHub Actions validates repository structure and source-file integrity and tests the supplementary BIS and World Bank nominal-GDP downloaders on Windows. It does not execute Stata or verify numerical estimates.

## Data attribution

BIS statistics are reproduced with attribution to the Bank for International Settlements. World Bank indicators are attributed to the World Bank's World Development Indicators. Data-source terms and retrieval details are documented in the data notes. This repository does not imply endorsement by either institution.

## License

The MIT License applies to the original code and documentation in this repository. Third-party datasets remain subject to their respective source terms.
