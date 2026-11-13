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

The provisional observation window is 1990–2024. The BIS reports 44 economies in its credit-gap dataset; the euro-area aggregate is excluded so that the analytical sample contains at most 43 individual economies. The actual unbalanced-panel sample is determined by the intersection of available BIS and World Bank observations after validation.

| Variable | Source | Indicator or series |
|---|---|---|
| Credit-to-GDP gap | Bank for International Settlements | WS_CREDIT_GAP; quarterly; private non-financial sector borrowers; all lenders; actual-minus-trend gap |
| Real GDP growth | World Bank, World Development Indicators | NY.GDP.MKTP.KD.ZG |
| CPI inflation | World Bank, World Development Indicators | FP.CPI.TOTL.ZG |

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
│   └── README.md
├── docs/
│   ├── LITERATURE_NOTES.md
│   ├── RESEARCH_DESIGN.md
│   └── REPRODUCIBILITY.md
├── outputs/
│   ├── figures/
│   ├── logs/
│   ├── tables/
│   └── README.md
└── replication/
    ├── download_data.do
    └── run_analysis.do
```

## Reproducing the project

A licensed installation of Stata 15.1 or later is required. The project uses built-in Stata commands and does not require user-written ado packages.

Clone the repository and change the working directory to its root:

```bash
git clone https://github.com/aliye-nezhad/financial-cycles-macroeconomic-fluctuations-Stata.git
cd financial-cycles-macroeconomic-fluctuations-Stata
```

Download the source data:

```stata
do replication/download_data.do
```

Run the analysis:

```stata
do replication/run_analysis.do
```

The repository also includes a GitHub Actions data-acquisition workflow. It can be run manually from the Actions tab or triggered by adding the data/ACQUIRE_DATA marker file. The workflow downloads, validates, checksums and commits the source files to the private repository. The Stata download script preserves existing raw archives by default; set its refresh option to 1 only when intentionally retrieving a new vintage. The retrieval date and checksums are retained with the source files.

See [docs/LITERATURE_NOTES.md](docs/LITERATURE_NOTES.md) for the focused annotated literature review, [docs/RESEARCH_DESIGN.md](docs/RESEARCH_DESIGN.md) for the hypotheses and specifications, and [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for execution instructions.

## Current status

The research design and repository workflow are being prepared. No regression estimates or empirical findings are reported until the source files have been downloaded, the merged sample has been validated, and the Stata analysis has been executed. GitHub Actions performs repository-level static checks; it does not execute Stata or verify numerical estimates.

## Data attribution

BIS statistics are reproduced with attribution to the Bank for International Settlements. World Bank indicators are attributed to the World Bank's World Development Indicators. Data-source terms and retrieval details are documented in the data notes. This repository does not imply endorsement by either institution.

## License

The MIT License applies to the original code and documentation in this repository. Third-party datasets remain subject to their respective source terms.
