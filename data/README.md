# Data sources and construction

## Source files

The main analysis uses three public source datasets. The optional denominator diagnostic adds four supplementary BIS series, and the independent denominator-validation diagnostic adds one World Bank nominal-GDP series:

| Local file | Source | Series |
|---|---|---|
| bis_credit_gap.csv | Bank for International Settlements (BIS) | WS_CREDIT_GAP |
| wb_gdp_growth.zip | World Bank, World Development Indicators | NY.GDP.MKTP.KD.ZG |
| wb_cpi_inflation.zip | World Bank, World Development Indicators | FP.CPI.TOTL.ZG |
| wb_gdp_current_lcu.zip | World Bank, World Development Indicators | NY.GDP.MKTP.CN (supplementary validation) |

The main-analysis source files can be downloaded locally by replication/download_data.do or through the GitHub Actions workflow in .github/workflows/data-acquisition.yml. That workflow commits the main-analysis archives, extracted WDI CSV members, a retrieval-date note and SHA-256 checksums to the private repository. The supplementary BIS components and nominal-GDP validation series use separate acquisition helpers and are not added to the main-analysis source vintage. Existing local raw archives are not overwritten unless the relevant refresh option is enabled.

## BIS credit-to-GDP gap

Official topic page: https://data.bis.org/topics/CREDIT_GAPS

Official bulk-download page: https://data.bis.org/bulkdownload

API documentation: https://stats.bis.org/api-doc/v2/

The BIS API query used by the download script is:

https://stats.bis.org/api/v2/data/dataflow/BIS/WS_CREDIT_GAP/1.0/Q..P.A.C?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4

The key selects quarterly frequency (Q), all borrower countries, the private non-financial sector (P), all lender sectors (A), and the credit-to-GDP gap (C). The time range is restricted to 1990-Q1 through 2024-Q4.

The data are filtered and validated again in Stata. The expected dimensions are:

| Dimension | Code | Meaning |
|---|---|---|
| FREQ | Q | Quarterly |
| BORROWERS_CTY | Country code | Borrowers' country |
| TC_BORROWERS | P | Private non-financial sector |
| TC_LENDERS | A | All lender sectors |
| CG_DTYPE | C | Credit-to-GDP gap, actual minus trend |
| TIME_PERIOD | YYYY-Qn | Quarterly reference period |
| OBS_VALUE | Numeric | Gap in percentage points of GDP |

The BIS defines the gap as the credit-to-GDP ratio minus its long-run trend. The trend is generated with a one-sided, backward-looking Hodrick–Prescott filter. The underlying credit measure captures borrowing from domestic and foreign sources and is not limited to bank lending.

The BIS reports 44 economies in the dataset, including the euro-area aggregate. The project uses a 43-country ISO crosswalk and excludes the euro-area aggregate.

## Supplementary BIS components for the denominator diagnostic

The optional `replication/denominator_diagnostic.do` script retrieves additional series to distinguish movements in the credit numerator from movements in the nominal-GDP denominator.

From the BIS `WS_CREDIT_GAP` dataflow (version 1.0), the script retrieves:

| `CG_DTYPE` code | Meaning | Local file |
|---|---|---|
| A | Actual credit-to-GDP ratio | `bis_credit_gap_ratio.csv` |
| B | One-sided HP-filter trend | `bis_credit_gap_trend.csv` |

From the BIS `WS_TC` total-credit dataflow (version 2.0), it retrieves the private non-financial sector (`TC_BORROWERS=P`), all lenders (`TC_LENDERS=A)), market valuation (`VALUATION=M`), and break-adjusted series (`TC_ADJUST=A`):

| `UNIT_TYPE` code | Meaning | Local file |
|---|---|---|
| XDC | Credit stock in domestic currency | `bis_total_credit_xdc.csv` |
| 770 | Credit-to-GDP ratio, percent of GDP | `bis_total_credit_gdp.csv` |

The BIS states that the credit-to-GDP ratio is the outstanding amount of debt at the end of the quarter divided by the sum of nominal GDP over the previous four quarters. The script reconstructs this denominator as:

[
GDP^{4Q}_{i,t}=100\times\frac{Credit_{i,t}}{Credit/GDP_{i,t}}.
]

At Q4, the trailing four-quarter denominator corresponds to calendar-year nominal GDP. This is an implied denominator reconstructed from BIS credit and ratio series, not a separately published BIS GDP series. The script applies the SDMX unit multiplier to the domestic-currency credit stock before computing log changes.

The diagnostic checks that the `WS_TC` ratio aligns with the `WS_CREDIT_GAP` actual ratio and that actual ratio minus trend reproduces the published gap. If either discrepancy exceeds 0.10 percentage points, the script stops before estimating component regressions. Source vintages must be aligned before the results are interpreted.

Official references:

- [BIS credit-to-GDP gaps](https://data.bis.org/topics/CREDIT_GAPS)
- [BIS credit to the non-financial sector](https://data.bis.org/topics/TOTAL_CREDIT)
- [BIS statistical API documentation](https://stats.bis.org/api-doc/v2/)
- [BIS FAQ on the credit-to-GDP denominator](https://data.bis.org/faq)

These supplementary files are required only for the denominator diagnostic, not for the main analysis. On Windows, the Stata script calls `replication/download_denominator_sources.ps1`, which uses PowerShell's `Invoke-WebRequest` rather than Stata's Java-dependent HTTPS `copy` path. The helper checks all four files on each Windows run, preserves valid existing files, and redownloads missing or invalid files. Downloads are written to temporary paths and validated for the required CSV columns before replacing the destination. On non-Windows systems, the Stata script retains its native `copy` fallback. Set the refresh option to 1 only when intentionally retrieving a new source vintage.

### BIS-to-World Bank country-code crosswalk

| BIS code | World Bank code | Economy |
|---|---|---|
| AR | ARG | Argentina |
| AU | AUS | Australia |
| AT | AUT | Austria |
| BE | BEL | Belgium |
| BR | BRA | Brazil |
| CA | CAN | Canada |
| CL | CHL | Chile |
| CN | CHN | China |
| CO | COL | Colombia |
| CZ | CZE | Czechia |
| DK | DNK | Denmark |
| FI | FIN | Finland |
| FR | FRA | France |
| DE | DEU | Germany |
| GR | GRC | Greece |
| HK | HKG | Hong Kong SAR |
| HU | HUN | Hungary |
| IN | IND | India |
| ID | IDN | Indonesia |
| IE | IRL | Ireland |
| IL | ISR | Israel |
| IT | ITA | Italy |
| JP | JPN | Japan |
| KR | KOR | Korea |
| LU | LUX | Luxembourg |
| MY | MYS | Malaysia |
| MX | MEX | Mexico |
| NL | NLD | Netherlands |
| NZ | NZL | New Zealand |
| NO | NOR | Norway |
| PL | POL | Poland |
| PT | PRT | Portugal |
| RU | RUS | Russian Federation |
| SA | SAU | Saudi Arabia |
| SG | SGP | Singapore |
| ZA | ZAF | South Africa |
| ES | ESP | Spain |
| SE | SWE | Sweden |
| CH | CHE | Switzerland |
| TH | THA | Thailand |
| TR | TUR | Türkiye |
| GB | GBR | United Kingdom |
| US | USA | United States |

The crosswalk is explicit rather than inferred from country names. Any BIS country code not in the crosswalk is excluded from the country panel and reported in the data audit.

## World Bank indicators

The download script retrieves CSV ZIP files from the World Bank Indicators API.

GDP growth:

https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.KD.ZG?source=2&downloadformat=csv

CPI inflation:

https://api.worldbank.org/v2/country/all/indicator/FP.CPI.TOTL.ZG?source=2&downloadformat=csv

The World Bank API documentation is available at https://datahelpdesk.worldbank.org/knowledgebase/articles/898581-api-basic-call-structures.

The WDI files are distributed in wide format, with country identifiers followed by annual columns. Stata reshapes the 1989–2024 columns into country-year observations. The 1989 GDP-growth observation is retained solely to construct the one-year lag for the first predictor year (1990); the analytical panel itself remains restricted to 1990–2024. The ISO3 country code is used for merging.

## Independent nominal-GDP validation

The supplementary `replication/validate_nominal_gdp.do` script compares the BIS-implied four-quarter nominal-GDP denominator with World Bank GDP in current local currency (WDI indicator `NY.GDP.MKTP.CN`). The World Bank defines this as GDP at current prices, expressed in local currency units; it is an annual nominal series and is not adjusted for price changes.

Source/API endpoint:

`https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CN?source=2&downloadformat=csv`

On Windows, `replication/download_nominal_gdp.ps1` downloads and validates the WDI CSV archive, retains the archive and a canonical extracted CSV, and records retrieval date, the World Bank last-updated date when present, and SHA-256 hashes in `data/raw/wb_gdp_current_lcu_metadata.txt`. The Stata script retains 1989–2024, using 1989 to calculate the first available annual log change, and matches the WDI series to the project's 43-country BIS panel by ISO3 code.

The validation reports country-year coverage, within-country ratios between the BIS-implied and WDI GDP levels, annual log-growth differences, mean absolute error, root mean squared error, and the correlation between the two growth series. Raw LCU level ratios are reported by country because currency units are not comparable across countries. A country-specific median scale factor is used to assess whether the level ratio is stable over time; it is not used to alter either source series.

The validation uses a separately retrieved WDI vintage. Its retrieval date and source update date must be considered when interpreting differences from the GDP-growth series used in the main regressions. It does not overwrite the original GDP-growth or CPI source archives. The World Bank series is compiled from country official statistics, national statistical organizations and central banks, OECD national-accounts files, and World Bank staff estimates. It is a separate published series, but its underlying national-accounts inputs may overlap with those used by the BIS; treat the exercise as a cross-source consistency check, not proof of fully independent underlying measurement.

Official references:

- [World Bank indicator definition: GDP (current LCU), NY.GDP.MKTP.CN](https://databank.worldbank.org/metadataglossary/world-development-indicators/series/NY.GDP.MKTP.CN)
- [World Bank Indicators API documentation](https://datahelpdesk.worldbank.org/knowledgebase/articles/889392-about-the-indicators-api-documentation)
- [World Bank API basic call structures](https://datahelpdesk.worldbank.org/knowledgebase/articles/898581-api-basic-call-structures)

## Annual construction

- **Baseline credit gap:** fourth-quarter observation in each calendar year.
- **Robustness credit gap:** arithmetic mean of the four quarterly observations, retained only when all four quarters are present.
- **GDP growth:** annual WDI value.
- **Inflation:** annual WDI CPI inflation value.

The analytical window is restricted to 1990–2024. The future-growth outcome means that the available predictor years become shorter as the forecast horizon increases. For example, a three-year-ahead outcome ending in 2024 requires a predictor observation no later than 2021.

## Missing observations and sample reporting

The panel is expected to be unbalanced. The do-file reports:

- countries represented in each source;
- the earliest and latest observation by country;
- unmatched and missing observations after merging;
- the number of observations available for each regression horizon;
- the number of country clusters used in each regression.

No missing credit-gap, GDP-growth or inflation observation is interpolated or filled forward. In the retrieved WDI vintage, CPI inflation is missing for Argentina in 1994–2017 (24 country-year observations); the baseline complete-case sample excludes those observations. The project includes a no-inflation sensitivity model to assess this sample loss. The baseline regressions use the complete observations required by the model.

The pre-estimation data audit, including country coverage, actual expected sample sizes, and influential gap observations, is documented in [docs/DATA_AUDIT.md](../docs/DATA_AUDIT.md).

## Attribution and permitted use

BIS statistics may be reproduced provided the BIS is cited as the source and the use is not misleading or presented as endorsed by the BIS. See https://data.bis.org/help/legal.

World Bank indicators should be cited as World Development Indicators, World Bank, with the relevant indicator code and retrieval date.

The repository records the source URLs and retrieval date in data/DATA_VINTAGE.md and stores checksums in data/raw.sha256 after acquisition. Source data may be updated by the providers; a new download is a new data vintage and should not silently replace the vintage used for a previously reported result.
