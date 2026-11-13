# Reproducing the analysis

## Requirements

- Licensed Stata 15.1 or later.
- Internet access is needed only if source files are missing or a new data vintage is requested. The current repository includes the downloaded source files.
- A working directory set to the repository root.

The main analysis uses built-in Stata commands only. The optional wild cluster bootstrap diagnostic requires David Roodman's user-written `boottest` package; it is not needed to reproduce the main regressions.

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

The analysis script imports and filters the source data, constructs the country crosswalk and annual panel, validates identifiers and sample coverage, estimates the models, and exports tables, figures, processed data and logs. It assigns each figure a distinct Stata graph name, exports each figure to its own PNG file, and also saves an editable `.gph` copy. The built-in `s1mono` scheme and explicit grayscale options give both figures a consistent white, black and gray publication style. Re-running the analysis replaces only the corresponding version of each figure; the two figures do not overwrite one another.

## 4. Optional wild cluster bootstrap inference (Stata 15.1+)

The main analysis remains compatible with Stata 15.1 and uses built-in commands only. The optional finite-cluster inference diagnostic uses David Roodman's user-written `boottest` package. The package supports Stata 11.2 and later and works after `xtreg, fe`; Stata 13 or later is recommended. See the [official package repository](https://github.com/droodman/boottest) and Roodman, MacKinnon, Nielsen and Webb (2019), *Fast and wild: Bootstrap inference in Stata using boottest*, *The Stata Journal*, 19(1), 4–60.

Install the package from Stata when the SSC connection is available:

```stata
ssc install boottest, replace
```

If SSC installation fails in Windows with an error such as `Java installation not found`, close Stata and use PowerShell to install one complete, tagged release without invoking Stata's Java-dependent installer. The following uses the official v4.5.3 release. It backs up any existing package files before replacing them:

```powershell
$ErrorActionPreference = "Stop"
$release = "v4.5.3"
$archive = Join-Path $env:TEMP "boottest-$release.zip"
$extract = Join-Path $env:TEMP "boottest-$release"

if (Test-Path $extract) {
    Remove-Item $extract -Recurse -Force
}

Invoke-WebRequest `
    -Uri "https://github.com/droodman/boottest/archive/refs/tags/$release.zip" `
    -OutFile $archive

Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force
$source = Get-ChildItem $extract -Directory | Select-Object -First 1
$plus = Join-Path $env:USERPROFILE "ado\plus"
$backup = Join-Path $env:TEMP ("boottest-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

$files = @(
    @{ Name = "boottest.ado";      Folder = "b" },
    @{ Name = "boottest.mata";     Folder = "b" },
    @{ Name = "boottest.sthlp";    Folder = "b" },
    @{ Name = "artest.ado";        Folder = "a" },
    @{ Name = "scoretest.ado";     Folder = "s" },
    @{ Name = "waldtest.ado";      Folder = "w" },
    @{ Name = "lboottest.mlib";    Folder = "l" }
)

foreach ($item in $files) {
    $targetFolder = Join-Path $plus $item.Folder
    New-Item -ItemType Directory -Force -Path $targetFolder | Out-Null
    $target = Join-Path $targetFolder $item.Name

    if (Test-Path $target) {
        $backupFolder = Join-Path $backup $item.Folder
        New-Item -ItemType Directory -Force -Path $backupFolder | Out-Null
        Copy-Item -LiteralPath $target -Destination $backupFolder -Force
    }

    Copy-Item -LiteralPath (Join-Path $source.FullName $item.Name) `
        -Destination $target -Force
}

Get-Content (Join-Path $plus "b\boottest.ado") -TotalCount 1
Get-Content (Join-Path $plus "b\boottest.mata") -TotalCount 1
Write-Host "Backup of replaced files: $backup"
```

The `PLUS` directory can be confirmed in Stata with `sysdir`; adjust `$plus` if your PLUS path differs. The two version lines printed at the end should identify the same release. Do not mix `boottest.ado`, `boottest.mata` and `lboottest.mlib` from different releases.

The diagnostic checks for these files and loads the installed Mata source before estimating the models. This order matters: loading the Mata source after estimation can remove the active estimation results.

After running `replication/run_analysis.do`, execute:

```stata
do replication/inference_diagnostics.do
```

The supplementary script reloads the processed panel and estimates the baseline and asymmetric one-year-ahead fixed-effects models. It applies 9,999 Rademacher wild cluster bootstrap replications at the country level to (i) the baseline credit-gap coefficient, (ii) the positive-gap coefficient, (iii) the negative-gap coefficient, and (iv) the equality of the positive- and negative-gap slopes. Fixed random seeds are recorded in the do-file.

This diagnostic is optional and does not alter the main estimates or the Stata 15.1-compatible workflow. The output is written to `outputs/tables/wild_cluster_bootstrap.txt`. Report bootstrap results alongside, not as a silent replacement for, the conventional country-clustered estimates.

## 5. Data integrity

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

## 6. Expected outputs

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
| outputs/tables/wild_cluster_bootstrap.txt | Optional wild cluster bootstrap inference using boottest (Stata 15.1+) |
| outputs/figures/mean_credit_gap_by_year.png | Monochrome PNG of the unweighted mean credit gap by year |
| outputs/figures/mean_credit_gap_by_year.gph | Editable Stata graph for the mean credit gap figure |
| outputs/figures/credit_gap_gdp_scatter.png | Monochrome PNG of the credit gap and subsequent GDP growth |
| outputs/figures/credit_gap_gdp_scatter.gph | Editable Stata graph for the credit-gap/GDP-growth scatter figure |
| outputs/logs/analysis.log | Main execution log |

The expected complete-case sample counts are 1,310, 1,267 and 1,224 for the one-, two- and three-year-ahead models, respectively, before Stata estimation. See docs/DATA_AUDIT.md. The final output list is checked by the Stata script. A successful file-presence check does not establish that the numerical estimates are correct; the log and tables must be inspected.

## 7. GitHub Actions

The workflow performs static repository checks, including required-file checks, expected script commands, and documentation paths. It does not run Stata, execute the regressions, or verify numerical results because a licensed Stata runtime is not configured in GitHub Actions.

A successful workflow run therefore confirms only that the static repository checks passed.

## 8. Reproducibility and source vintages

The BIS and World Bank sources may revise historical observations. The source files used for an analysis should be retained with their checksums and retrieval date. If the data are refreshed, regenerate the outputs and record the new data vintage. Results from different vintages should not be silently mixed.

## 9. Interpretation

The regressions estimate predictive associations. Country fixed effects, outcome-year fixed effects and country-clustered standard errors do not establish causality. The BIS credit-to-GDP gap is a financial-cycle indicator, not an exogenous credit-supply or monetary-policy shock.
