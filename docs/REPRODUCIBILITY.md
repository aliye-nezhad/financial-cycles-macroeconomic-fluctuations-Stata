# Reproducing the analysis

## Requirements

- Licensed Stata 15.1 or later.
- Internet access is needed only if source files are missing or a new data vintage is requested. The current repository includes the downloaded source files.
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

The download script checks the exact, versioned World Bank CSV member names recorded for this data vintage using Stata's `confirm file` command, rather than wildcard directory discovery. The analysis script repeats these explicit file checks before import. On Windows, it extracts the World Bank ZIP archives with PowerShell's native `Expand-Archive` command, so a separate Java installation is not required. On other platforms, it uses Stata's `unzipfile` command. Existing extracted WDI CSV members are preserved when the source vintage is unchanged; they are replaced only when an intentional data refresh is requested. If an endpoint changes or the provider is unavailable, the script stops with an error rather than creating an empty placeholder.

For CSV ingestion, the analysis uses Stata's built-in `insheet` command rather than `import delimited`, avoiding the Java-dependent import path encountered in the current Windows environment. The BIS file is imported with its header row. The World Bank files are imported without variable names; `insheet` skips their blank separator lines, after which the script drops the three remaining metadata/header observations. The script retains the country name, ISO3 code, and 1989-2024 columns (`v34`-`v69`). The 2025 column and trailing empty field in the current WDI download are intentionally excluded. Numeric fields are converted only when Stata has imported them as strings.

## 3. Run the analysis

```stata
do replication/run_analysis.do
```

The analysis script imports and filters the source data, constructs the country crosswalk and annual panel, validates identifiers and sample coverage, estimates the models, and exports tables, figures, processed data and logs.

## 4. Data integrity

After a fresh download or source refresh, calculate SHA-256 checksums from the repository root.

Linux or macOS:

```bash
sha256sum data/raw/bis_credit_gap.csv data/raw/wb_gdp_growth.zip data/raw/wb_cpi_inflation.zip data/raw/API_NY.GDP.MKTP.KD.ZG*.csv data/raw/API_FP.CPI.TOTL.ZG*.csv > data/raw.sha256
sha256sum --check data/raw.sha256
```

Windows PowerShell:

```powershell
Get-FileHash .\data\raw\bis_credit_gap.csv -Algorithm SHA256
Get-FileHash .\data\raw\wb_gdp_growth.zip -Algorithm SHA256
Get-FileHash .\data\raw\wb_cpi_inflation.zip -Algorithm SHA256
Get-ChildItem .\data\raw\API_NY.GDP.MKTP.KD.ZG*.csv | Get-FileHash -Algorithm SHA256
Get-ChildItem .\data\raw\API_FP.CPI.TOTL.ZG*.csv | Get-FileHash -Algorithm SHA256
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
| outputs/tables/robustness_models.txt | Annual-average gap, pandemic-exclusion, lag-control and CPI-control sensitivities |
| outputs/tables/influence_sensitivity.txt | Excluding Ireland and Luxembourg separately and jointly |
| outputs/figures/mean_credit_gap_by_year.png | Unweighted mean credit gap across available economies by year |
| outputs/figures/credit_gap_gdp_scatter.png | Credit gap and subsequent GDP growth |
| outputs/logs/analysis.log | Main execution log |

The expected complete-case sample counts are 1,310, 1,267 and 1,224 for the one-, two- and three-year-ahead models, respectively, before Stata estimation. See docs/DATA_AUDIT.md. The final output list is checked by the Stata script. A successful file-presence check does not establish that the numerical estimates are correct; the log and tables must be inspected.

## 6. GitHub Actions

The workflow performs static repository checks, including required-file checks, expected script commands, and documentation paths. It does not run Stata, execute the regressions, or verify numerical results because a licensed Stata runtime is not configured in GitHub Actions.

A successful workflow run therefore confirms only that the static repository checks passed.

## 7. Reproducibility and source vintages

The BIS and World Bank sources may revise historical observations. The source files used for an analysis should be retained with their checksums and retrieval date. If the data are refreshed, regenerate the outputs and record the new data vintage. Results from different vintages should not be silently mixed.

## 8. Interpretation

The regressions estimate predictive associations. Country fixed effects, outcome-year fixed effects and country-clustered standard errors do not establish causality. The BIS credit-to-GDP gap is a financial-cycle indicator, not an exogenous credit-supply or monetary-policy shock.
