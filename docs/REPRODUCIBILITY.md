# Reproducing the analysis

## Requirements

- Licensed Stata 15.1 or later.
- Internet access for the initial data download.
- A working directory set to the repository root.

The analysis uses built-in Stata commands. No user-written ado packages are required.

## 1. Obtain the repository

```bash
git clone https://github.com/aliye-nezhad/financial-cycles-macroeconomic-fluctuations-Stata.git
cd financial-cycles-macroeconomic-fluctuations-Stata
```

## 2. Download the source data

In Stata, run:

```stata
do replication/download_data.do
```

The script retrieves the BIS credit-gap series and the two World Bank indicators. It preserves existing raw source files by default. To refresh the source vintage, change the refresh setting at the beginning of the download do-file and rerun it.

The download script checks that the expected files exist after retrieval. If an endpoint changes or the provider is unavailable, the script stops with an error rather than creating an empty placeholder.

## 3. Run the analysis

```stata
do replication/run_analysis.do
```

The analysis script imports and filters the source data, constructs the country crosswalk and annual panel, validates identifiers and sample coverage, estimates the models, and exports tables, figures, processed data and logs.

## 4. Data integrity

After downloading source files, calculate SHA-256 checksums from the repository root.

Linux or macOS:

```bash
sha256sum data/raw/bis_credit_gap.csv data/raw/wb_gdp_growth.zip data/raw/wb_cpi_inflation.zip > data/raw.sha256
sha256sum --check data/raw.sha256
```

Windows PowerShell:

```powershell
Get-FileHash .\data\raw\bis_credit_gap.csv -Algorithm SHA256
Get-FileHash .\data\raw\wb_gdp_growth.zip -Algorithm SHA256
Get-FileHash .\data\raw\wb_cpi_inflation.zip -Algorithm SHA256
```

The checksum file records the exact source-file vintage used for an analysis. Regenerate it only when the source files are intentionally refreshed. Do not copy checksum values from a different data vintage.

## 5. Expected outputs

| Path | Contents |
|---|---|
| data/processed/financial_cycles_panel.dta | Merged annual country panel |
| outputs/tables/sample_coverage.txt | Country, year and missingness audit |
| outputs/tables/descriptive_statistics.txt | Summary statistics |
| outputs/tables/correlation_matrix.txt | Pairwise correlations |
| outputs/tables/baseline_models.txt | One-, two- and three-year-ahead estimates |
| outputs/tables/asymmetric_model.txt | Positive- and negative-gap slopes |
| outputs/tables/robustness_models.txt | Annual-average gap and pandemic-exclusion sensitivity |
| outputs/figures/credit_gap_by_country.png | Credit-gap series by country |
| outputs/figures/credit_gap_gdp_scatter.png | Credit gap and subsequent GDP growth |
| outputs/logs/analysis.log | Main execution log |

The final output list is checked by the Stata script. A successful file-presence check does not establish that the numerical estimates are correct; the log and tables must be inspected.

## 6. GitHub Actions

The workflow performs static repository checks, including required-file checks, expected script commands, and documentation paths. It does not run Stata, execute the regressions, or verify numerical results because a licensed Stata runtime is not configured in GitHub Actions.

A successful workflow run therefore confirms only that the static repository checks passed.

## 7. Reproducibility and source vintages

The BIS and World Bank sources may revise historical observations. The source files used for an analysis should be retained with their checksums and retrieval date. If the data are refreshed, regenerate the outputs and record the new data vintage. Results from different vintages should not be silently mixed.

## 8. Interpretation

The regressions estimate predictive associations. Country fixed effects, outcome-year fixed effects and country-clustered standard errors do not establish causality. The BIS credit-to-GDP gap is a financial-cycle indicator, not an exogenous credit-supply or monetary-policy shock.
