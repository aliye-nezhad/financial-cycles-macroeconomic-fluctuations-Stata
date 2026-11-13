# Reproducing the analysis

## Requirements

- Licensed Stata 15.1 or later.
- Internet access is needed only if source files are missing or a new data vintage is requested. The main-analysis source files are retained in the repository; the supplementary nominal-GDP validation data are retrieved by their dedicated script.
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

The analysis script imports and filters the source data, constructs the country crosswalk and annual panel, validates identifiers and sample coverage, estimates the models, and exports tables, figures, processed data and logs. It assigns each figure a distinct Stata graph name and explicitly supplies that name to both `graph export` and `graph save`; this prevents export/save commands from relying on whichever graph window is currently active. Each figure is written to its own PNG file and editable `.gph` file. The script finishes the figure section with `graph dir`, which lists all four named graphs retained in memory. Reopen them individually in Stata with `graph display mean_credit_gap_by_year`, `graph display credit_gap_gdp_scatter`, `graph display fe_horizon_coefficients`, or `graph display asymmetric_gap_coefficients`. The built-in `s1mono` scheme and explicit grayscale options give all four figures a consistent white, black and gray publication style. Re-running the analysis replaces only the corresponding version of each figure; the four files do not overwrite one another.

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

The `PLUS` directory can be confirmed in Stata with `sysdir`; adjust `$plus` if your PLUS path differs. For the v4.5.3 installation block above, both version lines should identify v4.5.3. More generally, use the official tagged release as the authority: the upstream v4.1.0 tag, for example, intentionally contains `boottest.ado` 4.1.0 and `boottest.mata` 4.0.3. Different header numbers alone therefore do not establish that files were mixed. Do not combine files or a compiled Mata library from different tagged releases.

The diagnostic checks for these files and loads the installed Mata source before estimating the models. This order matters: loading the Mata source after estimation can remove the active estimation results.

After running `replication/run_analysis.do`, execute:

```stata
do replication/inference_diagnostics.do
```

The supplementary script reloads the processed panel and estimates the baseline and asymmetric one-year-ahead fixed-effects models. It applies 9,999 Rademacher wild cluster bootstrap replications at the country level to (i) the baseline credit-gap coefficient, (ii) the positive-gap coefficient, (iii) the negative-gap coefficient, and (iv) the equality of the positive- and negative-gap slopes. If `denominator_diagnostic.do` has already generated `data/processed/denominator_components_panel.dta`, the same script also tests the matched-sample baseline credit-gap coefficient, the nominal-credit-growth coefficient, the implied nominal-GDP-growth coefficient, and the joint null that both component coefficients equal zero. The component tests use the exact common sample and specifications reported by the denominator diagnostic. Fixed random seeds are recorded in the do-file.

To obtain the denominator-component bootstrap tests, run the denominator diagnostic in Section 5 first and then rerun `replication/inference_diagnostics.do`; if the matched panel is absent, the component section is skipped while the original baseline and asymmetric tests still run. This diagnostic is optional and does not alter the main estimates or the Stata 15.1-compatible workflow. The output is written to `outputs/tables/wild_cluster_bootstrap.txt`. Report bootstrap results alongside, not as a silent replacement for, the conventional country-clustered estimates.

## 5. Optional credit-numerator and GDP-denominator diagnostic (Stata 15.1+)

After the main analysis has run, execute:

```stata
do replication/denominator_diagnostic.do
```

This supplementary script downloads four additional BIS series when the files are absent. On Windows, it delegates retrieval to `replication/download_denominator_sources.ps1`, using PowerShell's native `Invoke-WebRequest` instead of Stata's Java-dependent HTTPS `copy` command. The helper checks all four files on each Windows run, preserves valid existing files, and redownloads missing or invalid files. Downloads are written to temporary paths and validated as nonempty CSVs with the columns required by the Stata import code before replacing the destination. Changing the do-file's `refresh` setting to `1` forces a new download of all four series. On non-Windows systems, the do-file retains the Stata `copy` fallback.

- `WS_CREDIT_GAP` actual credit-to-GDP ratio and HP-filter trend (dataflow 1.0; `CG_DTYPE=A` and `B`);
- `WS_TC` private non-financial-sector credit stock in domestic currency (dataflow 2.0; all lenders, market valuation, adjusted for breaks, `UNIT_TYPE=XDC`);
- `WS_TC` credit-to-GDP ratio (same dimensions, `UNIT_TYPE=770`).

The `UNIT_TYPE` code `770` is numeric in the source CSV. Because `insheet` may infer this column as numeric, the do-file converts it to a string before applying the dimension filter; this avoids a string/numeric type mismatch across Stata imports.

The BIS defines the credit-to-GDP ratio as end-of-quarter outstanding credit divided by the sum of nominal GDP over the previous four quarters. The script therefore reconstructs the four-quarter nominal-GDP denominator as `100 × credit stock / credit-to-GDP ratio`. At Q4, the denominator corresponds to calendar-year nominal GDP. The underlying nominal-GDP series is reconstructed from BIS credit and ratio data; it is not a separately published BIS GDP series.

Before estimation, the script compares the WS_TC ratio with the WS_CREDIT_GAP actual ratio and checks that actual ratio minus trend reproduces the published gap. If either source comparison differs by more than 0.10 percentage points, the script stops before estimating the component regressions. Resolve the source-vintage or series mismatch first; the files must represent compatible data vintages.

The script then calculates annual log changes in nominal credit, the implied nominal-GDP denominator, and the credit-to-GDP ratio. It estimates a matched-sample baseline gap model and a joint component model with nominal credit growth and implied nominal-GDP growth, country fixed effects, outcome-year fixed effects, lagged real GDP growth, and country-clustered standard errors. Current real GDP growth and CPI inflation are omitted from the joint component regression; the common matched sample nevertheless requires those variables so that the baseline and component specifications are compared on the same observations. The component model is a diagnostic of predictive associations, not a causal decomposition.

Outputs are written to:

- `outputs/tables/denominator_decomposition.txt`
- `outputs/tables/denominator_component_models.txt`
- `outputs/figures/ratio_component_growth.png` and `.gph`
- `outputs/figures/ratio_component_coefficients.png` and `.gph`
- `outputs/logs/denominator_diagnostic.log`
- `data/processed/denominator_components_panel.dta`

This supplementary script does not alter the main analysis pipeline or the original BIS credit-gap series.

## 7. Independent nominal-GDP validation (Stata 15.1+)

After `replication/denominator_diagnostic.do` has created `data/processed/denominator_components_panel.dta`, run:

```stata
do replication/validate_nominal_gdp.do
```

The script retrieves World Bank WDI indicator `NY.GDP.MKTP.CN` (GDP, current local currency) through the Indicators API. On Windows, it uses `replication/download_nominal_gdp.ps1` and PowerShell's `Invoke-WebRequest` and `Expand-Archive`, avoiding Stata's Java-dependent HTTPS download path. The helper validates the CSV header and the 1989 and 2024 columns, retains the original ZIP archive, writes a canonical CSV, and records the retrieval date, World Bank update date when present, and SHA-256 hashes in `data/raw/wb_gdp_current_lcu_metadata.txt`. Existing validated files are preserved unless the do-file's `refresh` setting is changed to 1.

The Stata script retains 1989–2024, drops the two metadata observations (the blank separator is skipped by `insheet`), explicitly identifies and removes the following CSV header row, converts WDI's ".." missing-value marker to Stata missing, and destrings all 36 annual columns before reshaping to country-year form. It computes annual log changes in nominal GDP and merges the series with the BIS denominator panel by ISO3 country code and year. The 1989 observation is retained to calculate World Bank nominal-GDP growth for 1990. Because the BIS-implied growth series is calculated from Q4-to-Q4 first differences and the current BIS denominator panel begins in 1990, the common growth comparison currently starts in 1991 and runs through 2024. The script reports the actual matched years rather than assuming a fixed start date. It reports the matched level and growth coverage, country-specific ratios of the BIS-implied denominator to World Bank GDP, within-country deviations from each country's median level ratio, and differences between annual log-growth rates. The overall report includes mean absolute growth error, root mean squared growth error, and the correlation between the two growth series. Country-level results are exported separately.

Do not pool or compare nominal LCU levels across countries: the currency units differ. The raw level ratio is therefore reported by country. The country-specific median ratio absorbs a constant unit-scale difference only for the purpose of assessing whether the ratio is stable over time; it does not rescale or replace either source series. Annual log-growth comparisons are invariant to a constant currency-unit scale.

This is a cross-source measurement check, not an additional regression or a causal test. The World Bank series is compiled from country official statistics, national statistical organizations and central banks, OECD national-accounts files, and World Bank staff estimates; its underlying national-accounts inputs may overlap with those used by the BIS. Differences may reflect national-account definitions, revisions, currency redenominations, coverage, or source-vintage differences. Review the recorded WDI update date and retrieval metadata before interpreting discrepancies. The new WDI download does not overwrite the GDP-growth or CPI archives used by the main analysis.

Expected outputs:

- `data/raw/wb_gdp_current_lcu.zip`
- `data/raw/wb_gdp_current_lcu.csv`
- `data/raw/wb_gdp_current_lcu_metadata.txt`
- `data/processed/nominal_gdp_validation_panel.dta`
- `data/processed/nominal_gdp_validation_by_country.dta`
- `outputs/tables/nominal_gdp_validation_overall.txt`
- `outputs/tables/nominal_gdp_validation_by_country.csv`
- `outputs/logs/nominal_gdp_validation.log`

Official references: [World Bank indicator definition](https://databank.worldbank.org/metadataglossary/world-development-indicators/series/NY.GDP.MKTP.CN), [Indicators API documentation](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392-about-the-indicators-api-documentation), and [API query structure](https://datahelpdesk.worldbank.org/knowledgebase/articles/898581-api-basic-call-structures).

## 7. Data integrity

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

After the optional denominator diagnostic has downloaded its four BIS component files, record their checksums separately so the main analysis vintage is not silently changed.

Linux, macOS or Git Bash:

```bash
sha256sum data/raw/bis_credit_gap_ratio.csv data/raw/bis_credit_gap_trend.csv data/raw/bis_total_credit_xdc.csv data/raw/bis_total_credit_gdp.csv > data/denominator_components.sha256
sha256sum --check data/denominator_components.sha256
```

Windows PowerShell:

```powershell
Get-FileHash .\data\raw\bis_credit_gap_ratio.csv -Algorithm SHA256
Get-FileHash .\data\raw\bis_credit_gap_trend.csv -Algorithm SHA256
Get-FileHash .\data\raw\bis_total_credit_xdc.csv -Algorithm SHA256
Get-FileHash .\data\raw\bis_total_credit_gdp.csv -Algorithm SHA256
```

Record the retrieval date printed in `outputs/logs/denominator_diagnostic.log` alongside these hashes.

## 8. Expected outputs

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
| outputs/figures/fe_horizon_coefficients.png | Fixed-effects credit-gap coefficients across one-, two- and three-year horizons |
| outputs/figures/fe_horizon_coefficients.gph | Editable Stata graph for the horizon coefficient plot |
| outputs/figures/asymmetric_gap_coefficients.png | Positive- and negative-gap coefficients with 95% confidence intervals |
| outputs/figures/asymmetric_gap_coefficients.gph | Editable Stata graph for the asymmetric coefficient plot |
| outputs/logs/analysis.log | Main execution log |
| outputs/tables/denominator_decomposition.txt | Optional source-alignment and credit/GDP component summary |
| outputs/tables/denominator_component_models.txt | Optional matched-sample component regressions |
| outputs/figures/ratio_component_growth.png and .gph | Optional annual growth decomposition figure |
| outputs/figures/ratio_component_coefficients.png and .gph | Optional component-model coefficient plot |
| outputs/logs/denominator_diagnostic.log | Optional denominator-diagnostic execution log |
| data/processed/denominator_components_panel.dta | Optional matched panel with reconstructed GDP denominator |

The expected complete-case sample counts are 1,310, 1,267 and 1,224 for the one-, two- and three-year-ahead models, respectively, before Stata estimation. See docs/DATA_AUDIT.md. The final output list is checked by the Stata script. A successful file-presence check does not establish that the numerical estimates are correct; the log and tables must be inspected.

## 9. GitHub Actions

GitHub Actions runs two separate checks. The Ubuntu job performs static repository validation, including required-file checks, expected script commands, documentation paths, and the committed main-source checksums. The Windows job executes `replication/download_denominator_sources.ps1` against the live BIS API and `replication/download_nominal_gdp.ps1` against the World Bank Indicators API. It verifies that all four supplementary BIS CSV files and the World Bank nominal-GDP archive, CSV, and metadata file are downloaded. These checks test the Windows source-acquisition paths. Neither job runs Stata, executes the regressions, or verifies numerical estimates because a licensed Stata runtime is not configured in GitHub Actions.

A successful workflow run therefore confirms repository integrity and the supplementary Windows BIS and World Bank data-acquisition paths, but not Stata execution or numerical reproducibility.

## 10. Reproducibility and source vintages

The BIS and World Bank sources may revise historical observations. The source files used for an analysis should be retained with their checksums and retrieval date. If the data are refreshed, regenerate the outputs and record the new data vintage. Results from different vintages should not be silently mixed.

## 11. Interpretation

The regressions estimate predictive associations. Country fixed effects, outcome-year fixed effects and country-clustered standard errors do not establish causality. The BIS credit-to-GDP gap is a financial-cycle indicator, not an exogenous credit-supply or monetary-policy shock.


## 9. Preferred independent nominal-GDP validation using the linked WDI series (Stata 15.1+)

The first-pass validation in Section 7 used `NY.GDP.MKTP.CN`, the unlinked GDP (current LCU) indicator. Keep its outputs for transparency, but do not treat its historical growth discontinuities as a decisive test of the BIS-implied denominator. The World Bank explicitly publishes a linked current-LCU GDP series to reduce breaks caused by changes in national-accounts base years, source data and methodologies.

After `replication/denominator_diagnostic.do` has created the BIS denominator panel, run:

```stata
do replication/validate_nominal_gdp_linked.do
```

The script uses WDI indicator `NY.GDP.MKTP.CN.AD` (GDP, linked series, current LCU). On Windows, it calls `replication/download_linked_nominal_gdp.ps1`, which uses PowerShell's native HTTPS and ZIP support rather than Stata's Java-dependent `copy` path. The helper preserves the archive, validates the 1990 and 2024 year columns, writes a canonical CSV, and records retrieval metadata and SHA-256 hashes. Existing validated linked-series files are preserved unless the script's `refresh` setting is changed to 1.

The Stata script retains 1990–2024, converts WDI's `..` missing-value marker to Stata missing, destrings the annual columns, reshapes the data to country-year form, and merges it with the BIS-implied denominator panel by ISO3 code and year. It compares country-specific level ratios and annual log-growth differences. The first growth comparison year is 1991 because 1990 is required to calculate the preceding annual change. It reports coverage, country-level summaries, mean absolute growth error, root mean squared growth error and the correlation between the BIS-implied and linked WDI growth series.

The linked series is preferred for historical growth continuity, not because it is an exact replica of the national-accounts source used by the BIS. Its levels may differ from other historical national-accounts series, and underlying inputs may overlap with those used by the BIS. This remains a cross-source measurement check rather than proof of fully independent source construction.

Expected outputs:

- `data/raw/wb_gdp_linked_current_lcu.zip`
- `data/raw/wb_gdp_linked_current_lcu.csv`
- `data/raw/wb_gdp_linked_current_lcu_metadata.txt`
- `data/processed/nominal_gdp_linked_validation_panel.dta`
- `data/processed/nominal_gdp_linked_validation_by_country.dta`
- `outputs/tables/nominal_gdp_linked_validation_overall.txt`
- `outputs/tables/nominal_gdp_linked_validation_by_country.csv`
- `outputs/logs/nominal_gdp_linked_validation.log`

Official references: [World Bank linked-series metadata](https://databank.worldbank.org/metadataglossary/world-development-indicators/series/NY.GDP.MKTP.CN.AD) and [World Bank explanation of linked current-price GDP series](https://documents1.worldbank.org/curated/en/661311618822193354/pdf/World-Development-Indicators-2017.pdf).
