/***********************************************************************
Project:  Financial Cycles and Macroeconomic Fluctuations
File:     validate_nominal_gdp_linked.do
Purpose:  Independently validate the BIS-implied nominal-GDP denominator
          against World Bank linked GDP in current local currency
Requires: Stata 15.1+; PowerShell on Windows for source acquisition

Run from the repository root, after denominator_diagnostic.do:
    do replication/validate_nominal_gdp_linked.do

The World Bank indicator is NY.GDP.MKTP.CN.AD (GDP, linked series, current LCU).
It is an annual current-price series. This diagnostic compares annual
log growth and within-country level ratios; pooled LCU levels across
different countries are not economically comparable.

This script does not alter the main analysis or denominator diagnostics.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
set scheme s1mono
capture log close _all

local refresh 0

capture confirm file "data/processed/denominator_components_panel.dta"
if _rc {
    display as error "Denominator-components panel not found."
    display as error "Run replication/denominator_diagnostic.do first."
    exit 601
}

capture mkdir "data/raw"
capture mkdir "data/processed"
capture mkdir "outputs"
capture mkdir "outputs/tables"
capture mkdir "outputs/logs"

log using "outputs/logs/nominal_gdp_linked_validation.log", replace text name(validation_main_log)

/***********************************************************************
1. Retrieve the World Bank nominal-GDP series
***********************************************************************/

local wb_url "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CN.AD?source=2&downloadformat=csv"

if lower("`c(os)'") == "windows" {
    display as text "Checking and retrieving World Bank GDP, linked series (current LCU) with PowerShell..."
    capture noisily shell powershell.exe -NoProfile -ExecutionPolicy Bypass -File "replication/download_linked_nominal_gdp.ps1" -Refresh `refresh'
    local download_rc = _rc
    if `download_rc' {
        display as error "World Bank nominal-GDP retrieval failed with return code `download_rc'."
        log close validation_main_log
        exit `download_rc'
    }
}
else {
    capture confirm file "data/raw/wb_gdp_linked_current_lcu.csv"
    if _rc | `refresh' {
        display as text "Downloading World Bank GDP, linked series (current LCU) archive..."
        copy "`wb_url'" "data/raw/wb_gdp_linked_current_lcu.zip", replace

        local root "`c(pwd)'"
        cd "data/raw"
        capture noisily unzipfile "wb_gdp_linked_current_lcu.zip", replace
        local unzip_rc = _rc
        cd "`root'"

        if `unzip_rc' {
            display as error "Could not extract the World Bank nominal-GDP archive."
            log close validation_main_log
            exit `unzip_rc'
        }

        local wb_files : dir "data/raw" files "API_NY.GDP.MKTP.CN.AD*.csv"
        local wb_file : word 1 of `wb_files'
        if "`wb_file'" == "" {
            display as error "The NY.GDP.MKTP.CN.AD CSV member was not found after extraction."
            log close validation_main_log
            exit 601
        }

        copy "data/raw/`wb_file'" "data/raw/wb_gdp_linked_current_lcu.csv", replace
    }
}

capture confirm file "data/raw/wb_gdp_linked_current_lcu.csv"
if _rc {
    display as error "World Bank nominal-GDP CSV is missing."
    log close validation_main_log
    exit 601
}

capture confirm file "data/raw/wb_gdp_linked_current_lcu_metadata.txt"
if !_rc {
    display as text "World Bank nominal-GDP source metadata:"
    type "data/raw/wb_gdp_linked_current_lcu_metadata.txt"
}

/***********************************************************************
2. Import World Bank GDP, linked series (current LCU), retaining 1990-2024

The World Bank bulk CSV begins with two metadata records, followed by
the column header and country observations. insheet skips the blank
separator, so the script drops only the first two metadata observations.
It then identifies and removes the header row using "Country Code".
Columns v35-v69 correspond to 1990-2024. WDI's ".." missing-value
marker is converted to Stata missing and every annual column is
destringed before reshaping.
***********************************************************************/

tempfile wb_gdp

insheet using "data/raw/wb_gdp_linked_current_lcu.csv", comma nonames clear
drop in 1/2

capture confirm variable v69
if _rc {
    display as error "Expected World Bank year column v69 (2024) was not found."
    log close validation_main_log
    exit 111
}

* Retain the ISO3 code and the 1990-2024 year columns only.
* The first remaining CSV row is the column header, not a country.
* Drop it explicitly before converting the annual values to numeric.
keep v2 v4 v35-v69

count if trim(v2) == "Country Code" & trim(v4) == "Indicator Code"
if r(N) != 1 {
    display as error "Expected exactly one World Bank CSV header row; found " r(N) "."
    log close validation_main_log
    exit 459
}

count if trim(v2) != "Country Code" & !missing(v2) ///
    & trim(v4) != "NY.GDP.MKTP.CN.AD"
if r(N) > 0 {
    display as error "The linked nominal-GDP CSV contains rows with an unexpected indicator code."
    log close validation_main_log
    exit 459
}

count if trim(v4) == "NY.GDP.MKTP.CN.AD"
if r(N) == 0 {
    display as error "No country rows for NY.GDP.MKTP.CN.AD were found in the CSV."
    log close validation_main_log
    exit 459
}

drop if trim(v2) == "Country Code"
drop v4

rename v2 iso3c
drop if missing(iso3c)

* WDI represents unavailable observations as "..". Convert that marker
* to Stata missing, then destring every year column so all reshape
* variables have the same numeric storage type.
foreach yearvar of varlist v35-v69 {
    capture confirm string variable `yearvar'
    if !_rc {
        replace `yearvar' = "" if trim(`yearvar') == ".."
        destring `yearvar', replace
    }
}

isid iso3c

forvalues y = 1990/2024 {
    local source_column = `y' - 1955
    rename v`source_column' v`y'
}

reshape long v, i(iso3c) j(year)
rename v wb_nominal_gdp_lcu

capture confirm string variable wb_nominal_gdp_lcu
if !_rc {
    destring wb_nominal_gdp_lcu, replace force
}

keep if inrange(year, 1990, 2024)
sort iso3c year

by iso3c: generate double wb_nominal_gdp_growth = ///
    100 * (ln(wb_nominal_gdp_lcu) - ln(wb_nominal_gdp_lcu[_n-1])) ///
    if _n > 1 & year == year[_n-1] + 1 ///
    & wb_nominal_gdp_lcu > 0 & wb_nominal_gdp_lcu[_n-1] > 0

keep iso3c year wb_nominal_gdp_lcu wb_nominal_gdp_growth
isid iso3c year
save `wb_gdp', replace

/***********************************************************************
3. Merge independent GDP data with the BIS denominator panel
***********************************************************************/

use "data/processed/denominator_components_panel.dta", clear

foreach required_var in iso3c year implied_nominal_gdp_4q ///
    nominal_gdp_growth_implied {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable not found in denominator panel: `required_var'"
        log close validation_main_log
        exit 111
    }
}

isid iso3c year
merge 1:1 iso3c year using "`wb_gdp'", keep(master match) gen(wb_merge)

generate byte level_overlap = ///
    !missing(implied_nominal_gdp_4q, wb_nominal_gdp_lcu) ///
    & implied_nominal_gdp_4q > 0 & wb_nominal_gdp_lcu > 0

generate byte growth_overlap = ///
    !missing(nominal_gdp_growth_implied, wb_nominal_gdp_growth)

generate double log_level_ratio = ///
    ln(implied_nominal_gdp_4q) - ln(wb_nominal_gdp_lcu) if level_overlap

generate double level_ratio = exp(log_level_ratio) if level_overlap

* A country-specific median ratio absorbs a constant currency-unit scale
* difference. Its time variation is then assessed separately.
bysort iso3c: egen double country_median_log_scale = median(log_level_ratio)

generate double scale_adjusted_pct_deviation = ///
    100 * (exp(log_level_ratio - country_median_log_scale) - 1) ///
    if level_overlap

generate double growth_difference = ///
    nominal_gdp_growth_implied - wb_nominal_gdp_growth if growth_overlap

generate double absolute_growth_difference = abs(growth_difference) ///
    if growth_overlap

generate double squared_growth_difference = growth_difference^2 ///
    if growth_overlap

/***********************************************************************
4. Report coverage, level ratios, and annual growth comparisons
***********************************************************************/

quietly count
local panel_observations = r(N)

egen byte panel_country_tag = tag(iso3c)
quietly count if panel_country_tag == 1
local panel_countries = r(N)
drop panel_country_tag

quietly count if level_overlap
local level_observations = r(N)

egen byte level_country_tag = tag(iso3c) if level_overlap
quietly count if level_country_tag == 1
local level_countries = r(N)
drop level_country_tag

quietly count if growth_overlap
local growth_observations = r(N)

egen byte growth_country_tag = tag(iso3c) if growth_overlap
quietly count if growth_country_tag == 1
local growth_countries = r(N)
drop growth_country_tag

if `level_observations' == 0 | `growth_observations' == 0 {
    display as error "No overlapping positive nominal-GDP levels or annual growth observations were found."
    log close validation_main_log
    exit 2000
}

bysort iso3c: egen byte country_has_level = max(level_overlap)
bysort iso3c: egen byte country_has_growth = max(growth_overlap)
egen byte panel_country_tag = tag(iso3c)

quietly summarize year if growth_overlap, meanonly
local first_growth_year = r(min)
local last_growth_year = r(max)

log using "outputs/tables/nominal_gdp_linked_validation_overall.txt", ///
    replace text name(validation_results_log)

display as text "Independent validation of the BIS-implied nominal-GDP denominator"
display as text "World Bank indicator: NY.GDP.MKTP.CN.AD (GDP, linked series, current LCU)"
display as text "BIS-implied denominator: Q4 credit stock divided by Q4 credit-to-GDP ratio"
display as text "World Bank series: linked annual current-price GDP in local currency"
display as result "BIS panel observations: `panel_observations'"
display as result "BIS panel countries: `panel_countries'"
display as result "Positive matched nominal-GDP levels: `level_observations'"
display as result "Countries with matched nominal-GDP levels: `level_countries'"
display as result "Matched annual nominal-GDP growth observations: `growth_observations'"
display as result "Countries with matched annual growth: `growth_countries'"
display as result "Annual growth comparison years: `first_growth_year' to `last_growth_year'"
display as text "Countries without matched positive GDP levels:"
list iso3c if panel_country_tag == 1 & country_has_level == 0, noobs
display as text "Countries without matched annual GDP growth:"
list iso3c if panel_country_tag == 1 & country_has_growth == 0, noobs

display as text "------------------------------------------------------------"
display as text "Within-country nominal-GDP level comparison"
display as text "Raw level ratios are reported by country; pooled LCU levels across countries are not comparable."
display as text "The following statistic measures deviations from each country's median implied/WDI level ratio."
summarize scale_adjusted_pct_deviation if level_overlap, detail
* Keep generated variable names within Stata's 32-character limit.
generate double abs_scale_adj_dev = ///
    abs(scale_adjusted_pct_deviation) if level_overlap
summarize abs_scale_adj_dev if level_overlap, detail

display as text "------------------------------------------------------------"
display as text "Annual nominal-GDP log-growth comparison"
display as text "Growth difference = BIS-implied nominal-GDP growth minus World Bank nominal-GDP growth."
summarize nominal_gdp_growth_implied wb_nominal_gdp_growth if growth_overlap
summarize growth_difference if growth_overlap, detail
summarize absolute_growth_difference if growth_overlap, detail

quietly summarize absolute_growth_difference if growth_overlap, meanonly
local mean_absolute_error = r(mean)

quietly summarize squared_growth_difference if growth_overlap, meanonly
local root_mean_squared_error = sqrt(r(mean))

display as result "Mean absolute growth difference (percentage points): " %9.4f `mean_absolute_error'
display as result "Root mean squared growth difference (percentage points): " %9.4f `root_mean_squared_error'

display as text "Correlation between BIS-implied and World Bank nominal-GDP growth:"
correlate nominal_gdp_growth_implied wb_nominal_gdp_growth if growth_overlap

log close validation_results_log

/***********************************************************************
5. Save country-level diagnostics and the merged validation panel
***********************************************************************/

preserve
keep if level_overlap | growth_overlap

collapse (count) level_observations=level_ratio ///
                 growth_observations=growth_difference ///
         (mean) mean_growth_difference=growth_difference ///
         (median) median_level_ratio=level_ratio ///
                  median_abs_growth_diff=absolute_growth_difference ///
                  median_absolute_scale_deviation=abs_scale_adj_dev, ///
         by(iso3c)

sort iso3c
list iso3c level_observations growth_observations median_level_ratio ///
    mean_growth_difference median_abs_growth_diff ///
    median_absolute_scale_deviation, noobs abbreviate(24) separator(0)

export delimited using "outputs/tables/nominal_gdp_linked_validation_by_country.csv", replace
save "data/processed/nominal_gdp_linked_validation_by_country.dta", replace
restore

save "data/processed/nominal_gdp_linked_validation_panel.dta", replace

/***********************************************************************
6. Confirm generated outputs
***********************************************************************/

foreach output in ///
    data/processed/nominal_gdp_linked_validation_panel.dta ///
    data/processed/nominal_gdp_linked_validation_by_country.dta ///
    outputs/tables/nominal_gdp_linked_validation_overall.txt ///
    outputs/tables/nominal_gdp_linked_validation_by_country.csv ///
    outputs/logs/nominal_gdp_linked_validation.log {
    capture confirm file "`output'"
    if _rc {
        display as error "Required validation output missing: `output'"
        log close validation_main_log
        exit 498
    }
}

display as result "Independent nominal-GDP validation completed."
display as result "Review source coverage, level scaling, and annual growth differences before interpreting the component model."
log close validation_main_log
