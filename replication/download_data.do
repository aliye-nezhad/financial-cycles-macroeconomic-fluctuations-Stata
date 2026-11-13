/***********************************************************************
Project:  Financial Cycles and Macroeconomic Fluctuations
File:     download_data.do
Purpose:  Retrieve the BIS credit-gap series and World Bank WDI indicators
Requires: Stata 15.1+ and an internet connection

Run from the repository root:
    do replication/download_data.do

Existing source files are preserved by default. Set refresh to 1 only when
intentionally retrieving a new source-data vintage. Record the retrieval
date and regenerate data/raw.sha256 after refreshing.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
capture log close _all

local refresh 0

capture mkdir "data"
capture mkdir "data/raw"
capture mkdir "data/processed"
capture mkdir "outputs"
capture mkdir "outputs/logs"

log using "outputs/logs/data_download.log", replace text name(download_log)

local bis_url "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_CREDIT_GAP/1.0/Q..P.A.C?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
local gdp_url "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.KD.ZG?source=2&downloadformat=csv"
local cpi_url "https://api.worldbank.org/v2/country/all/indicator/FP.CPI.TOTL.ZG?source=2&downloadformat=csv"

/***********************************************************************
1. BIS credit-to-GDP gap data

The BIS key selects quarterly frequency, all borrower countries, private
non-financial-sector borrowers, all lender sectors, and the actual-minus-
trend credit-to-GDP gap. The euro-area aggregate is excluded later by the
country crosswalk in run_analysis.do.
***********************************************************************/

capture confirm file "data/raw/bis_credit_gap.csv"
if _rc | `refresh' {
    display as text "Downloading BIS credit-to-GDP gaps..."
    copy "`bis_url'" "data/raw/bis_credit_gap.csv", replace
}

capture confirm file "data/raw/bis_credit_gap.csv"
if _rc {
    display as error "BIS source file was not created. Check the BIS API endpoint and internet connection."
    log close download_log
    exit 601
}

/***********************************************************************
2. World Bank GDP growth and CPI inflation

The World Bank API distributes CSV downloads as ZIP archives. The archives
are retained in data/raw; their CSV members are extracted into the same
directory for the analysis script.
***********************************************************************/

capture confirm file "data/raw/wb_gdp_growth.zip"
if _rc | `refresh' {
    display as text "Downloading World Bank GDP growth..."
    copy "`gdp_url'" "data/raw/wb_gdp_growth.zip", replace
}

capture confirm file "data/raw/wb_cpi_inflation.zip"
if _rc | `refresh' {
    display as text "Downloading World Bank CPI inflation..."
    copy "`cpi_url'" "data/raw/wb_cpi_inflation.zip", replace
}

foreach source_file in ///
    "data/raw/wb_gdp_growth.zip" ///
    "data/raw/wb_cpi_inflation.zip" {
    capture confirm file "`source_file'"
    if _rc {
        display as error "World Bank source archive missing: `source_file'"
        log close download_log
        exit 601
    }
}

local root "`c(pwd)'"

* Keep valid extracted WDI members when the source vintage is unchanged.
* Remove them only when an intentional refresh has been requested.
local gdp_files : dir "data/raw" files "API_NY.GDP.MKTP.KD.ZG*.csv"
local cpi_files : dir "data/raw" files "API_FP.CPI.TOTL.ZG*.csv"

if `refresh' {
    foreach old_file of local gdp_files {
        erase "data/raw/`old_file'"
    }
    foreach old_file of local cpi_files {
        erase "data/raw/`old_file'"
    }
    local gdp_files ""
    local cpi_files ""
}

* Extract only when one or both required CSV members are absent.
* On Windows, use PowerShell's native ZIP support so Java is not required.
* On other platforms, retain Stata's unzipfile implementation.
if "`gdp_files'" == "" | "`cpi_files'" == "" {
    if "`c(os)'" == "Windows" {
        display as text "Extracting World Bank archives with Windows PowerShell..."
        capture noisily shell powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath 'data/raw/wb_gdp_growth.zip' -DestinationPath 'data/raw' -Force"
        capture noisily shell powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath 'data/raw/wb_cpi_inflation.zip' -DestinationPath 'data/raw' -Force"
    }
    else {
        cd "data/raw"
        capture noisily unzipfile "wb_gdp_growth.zip", replace
        local unzip_gdp_rc = _rc
        capture noisily unzipfile "wb_cpi_inflation.zip", replace
        local unzip_cpi_rc = _rc
        cd "`root'"

        if `unzip_gdp_rc' != 0 | `unzip_cpi_rc' != 0 {
            display as error "At least one World Bank archive could not be extracted."
            log close download_log
            exit 612
        }
    }
}

* Metadata members are retained inside the original ZIP archives and are
* not required by the Stata import routine.
local metadata_files : dir "data/raw" files "Metadata_*.csv"
foreach metadata_file of local metadata_files {
    erase "data/raw/`metadata_file'"
}

/***********************************************************************
3. Confirm expected World Bank CSV members
***********************************************************************/

local gdp_files : dir "data/raw" files "API_NY.GDP.MKTP.KD.ZG*.csv"
local cpi_files : dir "data/raw" files "API_FP.CPI.TOTL.ZG*.csv"

if "`gdp_files'" == "" {
    display as error "World Bank GDP CSV member not found after extraction."
    display as error "Inspect data/raw/wb_gdp_growth.zip and update the filename pattern if the provider changed it."
    log close download_log
    exit 601
}

if "`cpi_files'" == "" {
    display as error "World Bank CPI CSV member not found after extraction."
    display as error "Inspect data/raw/wb_cpi_inflation.zip and update the filename pattern if the provider changed it."
    log close download_log
    exit 601
}

display as result "Data acquisition completed."
display as text "BIS file: data/raw/bis_credit_gap.csv"
display as text "GDP archive: data/raw/wb_gdp_growth.zip"
display as text "CPI archive: data/raw/wb_cpi_inflation.zip"
display as text "Retrieval date: `c(current_date)'"
display as text "Refresh setting: `refresh'"

log close download_log
