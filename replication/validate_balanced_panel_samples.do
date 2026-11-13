/***********************************************************************
Project: Financial Cycles and Macroeconomic Fluctuations
File:    validate_balanced_panel_samples.do

Purpose:
    Reassess the linked World Bank nominal-GDP validation across
    balanced-country and common-period samples.

Requires:
    Stata 15.1+
    data/processed/financial_cycles_panel.dta
    data/processed/nominal_gdp_linked_validation_panel.dta

Run from the repository root:
    do replication/validate_balanced_panel_samples.do

Level windows:
    full43_unbalanced: 1990-2024
    balanced31_full:   1990-2024, 31 complete-coverage economies
    balanced31_common: 2006-2024, the same 31 economies
    all43_common:      2006-2024, all 43 economies

Growth windows:
    Full-period samples begin in 1991 because annual growth requires
    the preceding year's GDP level.
    Common-period samples begin in 2007 because 2006 is the first
    level year in the common window.

The common-period growth filter is intentionally separate from the
level filter. Including 2006 growth would use the 2005 GDP level and
would not represent the stated 2006-2024 common-period comparison.

This script does not alter source data, the main analysis, or the
original linked-GDP validation panel.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
set scheme s1mono
capture log close _all

foreach required_file in ///
    "data/processed/financial_cycles_panel.dta" ///
    "data/processed/nominal_gdp_linked_validation_panel.dta" {
    capture confirm file "`required_file'"
    if _rc {
        display as error "Required processed dataset not found: `required_file'"
        display as error "Run the main analysis and linked nominal-GDP validation first."
        exit 601
    }
}

capture mkdir "data"
capture mkdir "data/processed"
capture mkdir "outputs"
capture mkdir "outputs/tables"
capture mkdir "outputs/logs"

log using "outputs/logs/balanced_panel_linked_gdp_sensitivity.log", ///
    replace text name(validation_log)

display as text "BALANCED-PANEL LINKED NOMINAL-GDP VALIDATION"
display as text "Execution date: " c(current_date)
display as text "Stata version: " c(stata_version)

/***********************************************************************
1. Identify the 31 economies with complete 1990-2024 BIS Q4 coverage
***********************************************************************/

use "data/processed/financial_cycles_panel.dta", clear

foreach required_var in iso3c year credit_gap_q4 {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable missing from main panel: `required_var'"
        log close validation_log
        exit 111
    }
}

isid iso3c year

egen byte main_country_tag = tag(iso3c)
quietly count if main_country_tag == 1
local main_country_count = r(N)
drop main_country_tag

if `main_country_count' != 43 {
    display as error "Expected 43 economies in the main panel; found `main_country_count'."
    log close validation_log
    exit 459
}

preserve
keep if !missing(credit_gap_q4)
bysort iso3c: egen int q4_year_count = count(credit_gap_q4)
bysort iso3c: egen int first_q4_year = min(year)
bysort iso3c: egen int last_q4_year = max(year)

keep if q4_year_count == 35 ///
    & first_q4_year == 1990 ///
    & last_q4_year == 2024

keep iso3c
duplicates drop
isid iso3c

quietly count
local balanced_country_count = r(N)
levelsof iso3c, local(balanced_country_codes)
restore

if `balanced_country_count' != 31 {
    display as error "Expected 31 economies with complete 1990-2024 Q4 coverage."
    display as error "Found `balanced_country_count'. Inspect the BIS source vintage."
    log close validation_log
    exit 459
}

/***********************************************************************
2. Load the linked-GDP validation panel and apply country membership
***********************************************************************/

use "data/processed/nominal_gdp_linked_validation_panel.dta", clear

foreach required_var in iso3c year level_overlap growth_overlap ///
    log_level_ratio growth_difference absolute_growth_difference ///
    squared_growth_difference nominal_gdp_growth_implied ///
    wb_nominal_gdp_growth {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable missing from linked validation panel: `required_var'"
        log close validation_log
        exit 111
    }
}

isid iso3c year

egen byte validation_country_tag = tag(iso3c)
quietly count if validation_country_tag == 1
local validation_country_count = r(N)
drop validation_country_tag

if `validation_country_count' != 43 {
    display as error "Expected 43 economies in the linked validation panel."
    log close validation_log
    exit 459
}

generate byte balanced31 = 0
foreach country_code of local balanced_country_codes {
    replace balanced31 = 1 if iso3c == "`country_code'"
}

egen byte balanced_country_tag = tag(iso3c) if balanced31 == 1
quietly count if balanced_country_tag == 1
local verified_balanced_count = r(N)
drop balanced_country_tag

if `verified_balanced_count' != 31 {
    display as error "Balanced-country membership check failed in the validation panel."
    log close validation_log
    exit 459
}

/***********************************************************************
3. Calculate level and growth comparisons for four sample definitions
***********************************************************************/

tempfile validation_results
tempname validation_post

postfile `validation_post' ///
    str24 sample_name ///
    long level_observations ///
    int level_countries ///
    long growth_observations ///
    int growth_countries ///
    double median_abs_level_deviation ///
    double p95_abs_level_deviation ///
    double max_abs_level_deviation ///
    double growth_correlation ///
    double growth_mae ///
    double growth_rmse ///
    double median_abs_growth_difference ///
    double p95_abs_growth_difference ///
    double max_abs_growth_difference ///
    double mean_signed_growth_difference ///
    using `validation_results', replace

local sample_names ///
    "full43_unbalanced balanced31_full balanced31_common all43_common"

foreach sample_name of local sample_names {

    if "`sample_name'" == "full43_unbalanced" {
        local level_if "inrange(year, 1990, 2024)"
        local growth_if "growth_overlap == 1"
        local expected_levels = 1377
        local expected_growth = 1334
        local expected_countries = 43
    }
    else if "`sample_name'" == "balanced31_full" {
        local level_if "balanced31 == 1 & inrange(year, 1990, 2024)"
        local growth_if "balanced31 == 1 & growth_overlap == 1"
        local expected_levels = 1085
        local expected_growth = 1054
        local expected_countries = 31
    }
    else if "`sample_name'" == "balanced31_common" {
        local level_if "balanced31 == 1 & inrange(year, 2006, 2024)"
        local growth_if "balanced31 == 1 & growth_overlap == 1 & inrange(year, 2007, 2024)"
        local expected_levels = 589
        local expected_growth = 558
        local expected_countries = 31
    }
    else if "`sample_name'" == "all43_common" {
        local level_if "inrange(year, 2006, 2024)"
        local growth_if "growth_overlap == 1 & inrange(year, 2007, 2024)"
        local expected_levels = 817
        local expected_growth = 774
        local expected_countries = 43
    }

    preserve

    quietly count if `level_if'
    local n_levels = r(N)

    egen byte level_country_tag = tag(iso3c) if `level_if'
    quietly count if level_country_tag == 1
    local n_level_countries = r(N)

    * Re-estimate the country-specific scale within each level sample.
    bysort iso3c: egen double sample_median_log_scale = ///
        median(log_level_ratio) if `level_if'

    generate double sample_abs_level_deviation = ///
        abs(100 * (exp(log_level_ratio - sample_median_log_scale) - 1)) ///
        if `level_if'

    summarize sample_abs_level_deviation if `level_if', detail
    local median_level_deviation = r(p50)
    local p95_level_deviation = r(p95)
    local max_level_deviation = r(max)

    quietly count if `growth_if'
    local n_growth = r(N)

    egen byte growth_country_tag = tag(iso3c) if `growth_if'
    quietly count if growth_country_tag == 1
    local n_growth_countries = r(N)

    summarize absolute_growth_difference if `growth_if', detail
    local growth_mae = r(mean)
    local median_growth_difference = r(p50)
    local p95_growth_difference = r(p95)
    local max_growth_difference = r(max)

    summarize squared_growth_difference if `growth_if', meanonly
    local growth_rmse = sqrt(r(mean))

    summarize growth_difference if `growth_if', meanonly
    local mean_signed_difference = r(mean)

    quietly correlate nominal_gdp_growth_implied wb_nominal_gdp_growth ///
        if `growth_if'
    matrix validation_correlation = r(C)
    local growth_correlation = validation_correlation[1,2]

    display as text " "
    display as text "Linked GDP validation sample: `sample_name'"
    display as result ///
        "Levels: " %6.0f `n_levels' ///
        " observations across " %3.0f `n_level_countries' " countries"
    display as result ///
        "Growth: " %6.0f `n_growth' ///
        " observations across " %3.0f `n_growth_countries' " countries"
    display as result ///
        "Growth correlation: " %8.5f `growth_correlation' ///
        " | MAE: " %8.5f `growth_mae' ///
        " | RMSE: " %8.5f `growth_rmse'
    display as result ///
        "Median absolute level deviation: " %8.5f `median_level_deviation' ///
        "% | 95th percentile: " %8.5f `p95_level_deviation' "%"

    if `n_levels' != `expected_levels' {
        display as error ///
            "Unexpected level count for `sample_name': expected `expected_levels', found `n_levels'."
        restore
        postclose `validation_post'
        log close validation_log
        exit 459
    }

    if `n_growth' != `expected_growth' {
        display as error ///
            "Unexpected growth count for `sample_name': expected `expected_growth', found `n_growth'."
        restore
        postclose `validation_post'
        log close validation_log
        exit 459
    }

    if `n_level_countries' != `expected_countries' | ///
        `n_growth_countries' != `expected_countries' {
        display as error ///
            "Unexpected country coverage for `sample_name'. Expected `expected_countries' countries."
        restore
        postclose `validation_post'
        log close validation_log
        exit 459
    }

    post `validation_post' ///
        ("`sample_name'") ///
        (`n_levels') (`n_level_countries') ///
        (`n_growth') (`n_growth_countries') ///
        (`median_level_deviation') ///
        (`p95_level_deviation') ///
        (`max_level_deviation') ///
        (`growth_correlation') ///
        (`growth_mae') (`growth_rmse') ///
        (`median_growth_difference') ///
        (`p95_growth_difference') ///
        (`max_growth_difference') ///
        (`mean_signed_difference')

    restore
}

postclose `validation_post'

/***********************************************************************
4. Export the comparison table and confirm generated outputs
***********************************************************************/

use `validation_results', clear

generate byte sample_order = .
replace sample_order = 1 if sample_name == "full43_unbalanced"
replace sample_order = 2 if sample_name == "balanced31_full"
replace sample_order = 3 if sample_name == "balanced31_common"
replace sample_order = 4 if sample_name == "all43_common"
sort sample_order

format median_abs_level_deviation p95_abs_level_deviation ///
    max_abs_level_deviation growth_correlation growth_mae growth_rmse ///
    median_abs_growth_difference p95_abs_growth_difference ///
    max_abs_growth_difference mean_signed_growth_difference %10.5f

export delimited using ///
    "outputs/tables/balanced_panel_linked_gdp_validation.csv", replace

save "data/processed/balanced_panel_linked_gdp_validation.dta", replace

list sample_name level_observations level_countries ///
    growth_observations growth_countries growth_correlation ///
    growth_mae growth_rmse median_abs_level_deviation ///
    p95_abs_level_deviation, noobs abbreviate(24)

foreach output in ///
    outputs/tables/balanced_panel_linked_gdp_validation.csv ///
    data/processed/balanced_panel_linked_gdp_validation.dta {
    capture confirm file "`output'"
    if _rc {
        display as error "Required validation output missing: `output'"
        log close validation_log
        exit 498
    }
}

display as result "Balanced-panel linked-GDP validation completed."
display as result "No source observations were removed, winsorized, or adjusted."
log close validation_log
