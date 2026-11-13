/***********************************************************************
Project: Financial Cycles and Macroeconomic Fluctuations
File:    balanced_panel_sensitivity.do

Purpose:
    1. Re-estimate the main predictive fixed-effects models across
       balanced and common-period country samples.
    2. Reassess the linked World Bank nominal-GDP validation on
       comparable country and time windows.

Requires:
    Stata 15.1+
    data/processed/financial_cycles_panel.dta
    data/processed/nominal_gdp_linked_validation_panel.dta

Run from the repository root:
    do replication/balanced_panel_sensitivity.do

The script is supplementary. It does not modify the original panel,
the baseline analysis, or the linked-GDP validation results.

Sample definitions:
    full43_unbalanced: all 43 economies, original 1990-2024 coverage.
    balanced31_full:   31 economies with Q4 BIS gaps in every year
                       from 1990 through 2024.
    balanced31_common: the same 31 economies, restricted to 2006-2024.
    all43_common:      all 43 economies, restricted to 2006-2024.

The 43-country common window has complete BIS Q4 coverage, but its
complete-case regression sample is not strictly balanced because
Argentina's CPI observations remain missing for 2006-2017.

For predictive regressions, the final predictor year is 2024 minus
the forecast horizon, so the future outcome remains within 2024.

For linked-GDP validation, levels use 1990-2024 or 2006-2024.
Growth observations are indexed by calendar year. The 2006 growth
observation uses the 2005 GDP level as its lag input, but remains a
2006 observation in the common-period comparison.

No source observations are permanently deleted, winsorized, interpolated,
or adjusted. Sample restrictions are applied only within this diagnostic.
All regression estimates remain conditional predictive associations,
not causal effects.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
set scheme s1mono
capture log close _all

/***********************************************************************
0. Check prerequisites and create output directories
***********************************************************************/

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
capture mkdir "outputs/figures"
capture mkdir "outputs/logs"

log using "outputs/logs/balanced_panel_sensitivity.log", ///
    replace text name(main_log)

display as text "BALANCED-PANEL AND COMMON-PERIOD SENSITIVITY"
display as text "Execution date: " c(current_date)
display as text "Stata version: " c(stata_version)

/***********************************************************************
1. Identify the 31 economies with complete 1990-2024 BIS Q4 coverage
***********************************************************************/

use "data/processed/financial_cycles_panel.dta", clear

foreach required_var in panel_id iso3c country_name year ///
    credit_gap_q4 gdp_growth gdp_growth_lag1 inflation {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable missing from main panel: `required_var'"
        log close main_log
        exit 111
    }
}

isid iso3c year
xtset panel_id year

* Identify countries with exactly 35 nonmissing Q4 observations,
* beginning in 1990 and ending in 2024.
tempfile country_flags model_results validation_results
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

egen byte country_tag = tag(iso3c)
quietly count if country_tag == 1
local total_country_count = r(N)
drop country_tag

if `total_country_count' != 43 {
    display as error "Expected 43 economies in the main panel; found `total_country_count'."
    log close main_log
    exit 459
}

if `balanced_country_count' != 31 {
    display as error "Expected 31 economies with complete 1990-2024 Q4 coverage."
    display as error "Found `balanced_country_count'. Inspect the source vintage and country coverage."
    log close main_log
    exit 459
}

generate byte balanced31 = 0
foreach country_code of local balanced_country_codes {
    replace balanced31 = 1 if iso3c == "`country_code'"
}

egen byte balanced_tag = tag(iso3c) if balanced31 == 1
quietly count if balanced_tag == 1
local verified_balanced_count = r(N)
drop balanced_tag

if `verified_balanced_count' != 31 {
    display as error "Balanced-country membership check failed."
    log close main_log
    exit 459
}

display as result "Total economies in original panel: `total_country_count'"
display as result "Economies with complete 1990-2024 Q4 coverage: `balanced_country_count'"
display as text "Complete-coverage country codes:"
display as result `"`balanced_country_codes'"'

* Save one row per country so the same 31-country definition can be
* applied to the independent linked-GDP validation panel.
preserve
keep iso3c balanced31
duplicates drop
isid iso3c
save `country_flags', replace
restore

/***********************************************************************
2. Construct forecast outcomes and asymmetric gap components
***********************************************************************/

capture drop gap_positive gap_negative ///
    gdp_growth_h1 gdp_growth_h2 gdp_growth_h3 ///
    outcome_year_h1 outcome_year_h2 outcome_year_h3

generate double gap_positive = cond(missing(credit_gap_q4), ., ///
    max(credit_gap_q4, 0))
generate double gap_negative = cond(missing(credit_gap_q4), ., ///
    min(credit_gap_q4, 0))

forvalues h = 1/3 {
    generate double gdp_growth_h`h' = F`h'.gdp_growth
    generate int outcome_year_h`h' = year + `h'
}

/***********************************************************************
3. Estimate baseline horizon models across four sample definitions
***********************************************************************/

tempname model_post
postfile `model_post' ///
    str24 sample_name ///
    str16 model_name ///
    str24 term_name ///
    byte horizon ///
    double estimate standard_error p_value ci_lower ci_upper ///
    long observations ///
    int clusters ///
    using `model_results', replace

local sample_names ///
    "full43_unbalanced balanced31_full balanced31_common all43_common"

foreach sample_name of local sample_names {

    forvalues h = 1/3 {

        local max_predictor_year = 2024 - `h'

        if "`sample_name'" == "full43_unbalanced" {
            local sample_if "year <= `max_predictor_year'"
        }
        else if "`sample_name'" == "balanced31_full" {
            local sample_if "balanced31 == 1 & year <= `max_predictor_year'"
        }
        else if "`sample_name'" == "balanced31_common" {
            local sample_if "balanced31 == 1 & inrange(year, 2006, `max_predictor_year')"
        }
        else if "`sample_name'" == "all43_common" {
            local sample_if "inrange(year, 2006, `max_predictor_year')"
        }

        display as text " "
        display as text "------------------------------------------------------------"
        display as text "Sample: `sample_name'; horizon: H`h'"
        display as text "Predictor years end in `max_predictor_year'"

        xtreg gdp_growth_h`h' ///
            c.credit_gap_q4 ///
            c.gdp_growth ///
            c.gdp_growth_lag1 ///
            c.inflation ///
            i.outcome_year_h`h' ///
            if `sample_if', fe vce(cluster panel_id)

        local b = _b[credit_gap_q4]
        local se = _se[credit_gap_q4]
        local df = e(df_r)
        local p = 2 * ttail(`df', abs(`b' / `se'))
        local crit = invttail(`df', .025)
        local lo = `b' - `crit' * `se'
        local hi = `b' + `crit' * `se'
        local n = e(N)
        local clusters = e(N_g)

        * The 31-country common-period H1 regression uses predictor years
        * 2006-2023: 31 countries x 18 years = 558 observations. This is
        * distinct from the 589 linked-GDP validation observations (2006-2024).
        if "`sample_name'" == "balanced31_common" & `h' == 1 & `n' != 558 {
            display as error "Expected 558 observations in the 31-country common-period H1 regression; found `n'."
            postclose `model_post'
            log close main_log
            exit 459
        }

        post `model_post' ///
            ("`sample_name'") ///
            ("linear") ///
            ("credit_gap_q4") ///
            (`h') ///
            (`b') (`se') (`p') (`lo') (`hi') ///
            (`n') (`clusters')

        display as result ///
            "Credit-gap coefficient: " %9.5f `b' ///
            " | SE: " %9.5f `se' ///
            " | p-value: " %8.5f `p' ///
            " | N: " %6.0f `n' ///
            " | clusters: " %3.0f `clusters'
    }
}

/***********************************************************************
4. Estimate asymmetric H1 models across the same samples
***********************************************************************/

foreach sample_name of local sample_names {

    if "`sample_name'" == "full43_unbalanced" {
        local sample_if "year <= 2023"
    }
    else if "`sample_name'" == "balanced31_full" {
        local sample_if "balanced31 == 1 & year <= 2023"
    }
    else if "`sample_name'" == "balanced31_common" {
        local sample_if "balanced31 == 1 & inrange(year, 2006, 2023)"
    }
    else if "`sample_name'" == "all43_common" {
        local sample_if "inrange(year, 2006, 2023)"
    }

    display as text " "
    display as text "------------------------------------------------------------"
    display as text "Asymmetric H1 model: `sample_name'"

    xtreg gdp_growth_h1 ///
        c.gap_positive ///
        c.gap_negative ///
        c.gdp_growth ///
        c.gdp_growth_lag1 ///
        c.inflation ///
        i.outcome_year_h1 ///
        if `sample_if', fe vce(cluster panel_id)

    local df = e(df_r)
    local n = e(N)
    local clusters = e(N_g)

    if "`sample_name'" == "balanced31_common" & `n' != 558 {
        display as error "Expected 558 observations in the 31-country common-period asymmetric H1 regression; found `n'."
        postclose `model_post'
        log close main_log
        exit 459
    }

    local crit = invttail(`df', .025)

    local b_positive = _b[gap_positive]
    local se_positive = _se[gap_positive]
    local p_positive = 2 * ttail(`df', abs(`b_positive' / `se_positive'))

    local b_negative = _b[gap_negative]
    local se_negative = _se[gap_negative]
    local p_negative = 2 * ttail(`df', abs(`b_negative' / `se_negative'))

    post `model_post' ///
        ("`sample_name'") ("asymmetric") ("gap_positive") (1) ///
        (`b_positive') (`se_positive') (`p_positive') ///
        (`b_positive' - `crit' * `se_positive') ///
        (`b_positive' + `crit' * `se_positive') ///
        (`n') (`clusters')

    post `model_post' ///
        ("`sample_name'") ("asymmetric") ("gap_negative") (1) ///
        (`b_negative') (`se_negative') (`p_negative') ///
        (`b_negative' - `crit' * `se_negative') ///
        (`b_negative' + `crit' * `se_negative') ///
        (`n') (`clusters')

    test gap_positive = gap_negative
    local slope_difference = _b[gap_positive] - _b[gap_negative]
    local equality_f = r(F)
    local equality_p = r(p)
    local equality_se = .
    local equality_lo = .
    local equality_hi = .

    if `equality_f' > 0 {
        local equality_se = abs(`slope_difference') / sqrt(`equality_f')
        local equality_lo = `slope_difference' - `crit' * `equality_se'
        local equality_hi = `slope_difference' + `crit' * `equality_se'
    }

    post `model_post' ///
        ("`sample_name'") ("asymmetric") ("slope_difference") (1) ///
        (`slope_difference') (`equality_se') (`equality_p') ///
        (`equality_lo') (`equality_hi') ///
        (`n') (`clusters')

    display as result ///
        "Positive-gap slope: " %9.5f `b_positive' ///
        " | p-value: " %8.5f `p_positive'
    display as result ///
        "Negative-gap slope: " %9.5f `b_negative' ///
        " | p-value: " %8.5f `p_negative'
    display as result ///
        "Equality-test p-value: " %8.5f `equality_p'
}

postclose `model_post'

/***********************************************************************
5. Export regression results and separate coefficient figures
***********************************************************************/

use `model_results', clear

format estimate standard_error p_value ci_lower ci_upper %10.5f
sort model_name sample_name horizon term_name

export delimited using ///
    "outputs/tables/balanced_panel_regression_coefficients.csv", replace

display as text " "
display as text "BALANCED-PANEL REGRESSION COEFFICIENT SUMMARY"
list sample_name model_name term_name horizon ///
    estimate standard_error p_value observations clusters, ///
    noobs sepby(model_name sample_name) abbreviate(24)

generate byte sample_order = .
replace sample_order = 1 if sample_name == "full43_unbalanced"
replace sample_order = 2 if sample_name == "balanced31_full"
replace sample_order = 3 if sample_name == "balanced31_common"
replace sample_order = 4 if sample_name == "all43_common"

label define sample_lbl ///
    1 "43 unbalanced" ///
    2 "31 full period" ///
    3 "31 common period" ///
    4 "43 common period", replace
label values sample_order sample_lbl

* Figure 1: H1 baseline coefficient across the four sample definitions.
twoway ///
    (rcap ci_lower ci_upper sample_order ///
        if model_name == "linear" & horizon == 1, ///
        lcolor(gs7) lwidth(medthick)) ///
    (scatter estimate sample_order ///
        if model_name == "linear" & horizon == 1, ///
        msymbol(O) msize(medlarge) mcolor(black)), ///
    yline(0, lcolor(gs10) lpattern(dash)) ///
    xlabel(1 "43 unbalanced" ///
           2 "31 full" ///
           3 "31 common" ///
           4 "43 common", angle(25) labsize(small)) ///
    xtitle("") ///
    ytitle("Credit-gap coefficient") ///
    title("Balanced-Panel Sensitivity: One-Year-Ahead Model", ///
        color(black) size(medsmall)) ///
    subtitle("Country and outcome-year fixed effects; country-clustered 95% CIs", ///
        color(gs6) size(small)) ///
    note("Outcome: annual real GDP growth in t+1. All estimates are conditional associations.", ///
        color(gs6) size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    legend(off) ///
    name(balanced_panel_h1_coefficients, replace)

graph export ///
    "outputs/figures/balanced_panel_h1_coefficients.png", ///
    name(balanced_panel_h1_coefficients) replace width(2200)
graph save balanced_panel_h1_coefficients ///
    "outputs/figures/balanced_panel_h1_coefficients.gph", replace

* Figure 2: all three forecast horizons across the four sample definitions.
generate byte horizon_plot_order = ///
    (sample_order - 1) * 3 + horizon if model_name == "linear"

twoway ///
    (rcap ci_lower ci_upper horizon_plot_order ///
        if model_name == "linear", ///
        lcolor(gs7) lwidth(medthin)) ///
    (scatter estimate horizon_plot_order ///
        if model_name == "linear", ///
        msymbol(O) msize(small) mcolor(black)), ///
    yline(0, lcolor(gs10) lpattern(dash)) ///
    xlabel(1 "43U H1" 2 "43U H2" 3 "43U H3" ///
           4 "31F H1" 5 "31F H2" 6 "31F H3" ///
           7 "31C H1" 8 "31C H2" 9 "31C H3" ///
           10 "43C H1" 11 "43C H2" 12 "43C H3", ///
           angle(45) labsize(vsmall)) ///
    xtitle("Country sample and forecast horizon") ///
    ytitle("Credit-gap coefficient") ///
    title("Credit-Gap Coefficients Across Samples and Horizons", ///
        color(black) size(medsmall)) ///
    subtitle("Country and outcome-year fixed effects; country-clustered 95% CIs", ///
        color(gs6) size(small)) ///
    note("43U: original unbalanced; 31F: 31-country full period; 31C: 31-country common period; 43C: 43-country common period.", ///
        color(gs6) size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    legend(off) ///
    name(bal_panel_horizon_coef, replace)

graph export ///
    "outputs/figures/bal_panel_horizon_coef.png", ///
    name(bal_panel_horizon_coef) replace width(2400)
graph save bal_panel_horizon_coef ///
    "outputs/figures/bal_panel_horizon_coef.gph", replace

* Figure 3: positive and negative gap slopes in the asymmetric H1 models.
generate double asym_plot_order = .
replace asym_plot_order = sample_order - .12 ///
    if model_name == "asymmetric" & term_name == "gap_positive"
replace asym_plot_order = sample_order + .12 ///
    if model_name == "asymmetric" & term_name == "gap_negative"

twoway ///
    (rcap ci_lower ci_upper asym_plot_order ///
        if model_name == "asymmetric" & term_name == "gap_positive", ///
        lcolor(black) lwidth(medthin)) ///
    (scatter estimate asym_plot_order ///
        if model_name == "asymmetric" & term_name == "gap_positive", ///
        msymbol(O) mcolor(black) msize(medium)) ///
    (rcap ci_lower ci_upper asym_plot_order ///
        if model_name == "asymmetric" & term_name == "gap_negative", ///
        lcolor(gs7) lpattern(dash) lwidth(medthin)) ///
    (scatter estimate asym_plot_order ///
        if model_name == "asymmetric" & term_name == "gap_negative", ///
        msymbol(D) mcolor(gs7) msize(medium)), ///
    yline(0, lcolor(gs10) lpattern(dash)) ///
    xlabel(1 "43 unbalanced" ///
           2 "31 full" ///
           3 "31 common" ///
           4 "43 common", angle(25) labsize(small)) ///
    xtitle("") ///
    ytitle("Credit-gap component coefficient") ///
    title("Asymmetric Credit-Gap Slopes Across Samples", ///
        color(black) size(medsmall)) ///
    subtitle("One-year-ahead model; country-clustered 95% CIs", ///
        color(gs6) size(small)) ///
    legend(order(2 "Positive gap" 4 "Negative gap") ///
        rows(1) position(6) size(small) region(lcolor(white) fcolor(white))) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(balanced_panel_asymmetry, replace)

graph export ///
    "outputs/figures/balanced_panel_asymmetry.png", ///
    name(balanced_panel_asymmetry) replace width(2200)
graph save balanced_panel_asymmetry ///
    "outputs/figures/balanced_panel_asymmetry.gph", replace

/***********************************************************************
6. Apply the same country definitions to linked nominal-GDP validation
***********************************************************************/

use "data/processed/nominal_gdp_linked_validation_panel.dta", clear

foreach required_var in iso3c year level_overlap growth_overlap ///
    log_level_ratio growth_difference ///
    absolute_growth_difference squared_growth_difference ///
    nominal_gdp_growth_implied wb_nominal_gdp_growth {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable missing from linked validation panel: `required_var'"
        log close main_log
        exit 111
    }
}

capture drop balanced31
merge m:1 iso3c using `country_flags', keep(match) nogen
isid iso3c year

egen byte validation_country_tag = tag(iso3c)
quietly count if validation_country_tag == 1
local validation_country_count = r(N)
drop validation_country_tag

if `validation_country_count' != 43 {
    display as error "Expected 43 economies in the linked validation panel."
    log close main_log
    exit 459
}

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
foreach sample_name of local sample_names {

    if "`sample_name'" == "full43_unbalanced" {
        local validation_if "inrange(year, 1990, 2024)"
        local growth_if "growth_overlap == 1"
        local expected_levels = 1377
        local expected_growth = 1334
        local expected_countries = 43
    }
    else if "`sample_name'" == "balanced31_full" {
        local validation_if "balanced31 == 1 & inrange(year, 1990, 2024)"
        local growth_if "growth_overlap == 1"
        local expected_levels = 1085
        local expected_growth = 1054
        local expected_countries = 31
    }
    else if "`sample_name'" == "balanced31_common" {
        local validation_if "balanced31 == 1 & inrange(year, 2006, 2024)"
        local growth_if "growth_overlap == 1"
        local expected_levels = 589
        local expected_growth = 589
        local expected_countries = 31
    }
    else if "`sample_name'" == "all43_common" {
        local validation_if "inrange(year, 2006, 2024)"
        local growth_if "growth_overlap == 1"
        local expected_levels = 817
        local expected_growth = 817
        local expected_countries = 43
    }

    preserve
    keep if `validation_if'

    quietly count if level_overlap == 1
    local n_levels = r(N)

    egen byte level_country_tag = tag(iso3c) if level_overlap == 1
    quietly count if level_country_tag == 1
    local n_level_countries = r(N)

    * Recalculate each country's median scale within the current sample.
    * This prevents the common-period validation from inheriting a scale
    * factor estimated using observations outside that period.
    bysort iso3c: egen double sample_median_log_scale = ///
        median(log_level_ratio) if level_overlap == 1
    generate double sample_abs_level_deviation = ///
        abs(100 * (exp(log_level_ratio - sample_median_log_scale) - 1)) ///
        if level_overlap == 1

    summarize sample_abs_level_deviation if level_overlap == 1, detail
    local median_level_deviation = r(p50)
    local p95_level_deviation = r(p95)
    local max_level_deviation = r(max)

    * Growth uses a distinct period condition. In the common-period
    * samples, the 2006 annual growth rate is a valid calendar-year
    * observation. It uses the 2005 GDP level only as its lag input.
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
        log close main_log
        exit 459
    }

    if `n_growth' != `expected_growth' {
        display as error ///
            "Unexpected growth count for `sample_name': expected `expected_growth', found `n_growth'."
        restore
        postclose `validation_post'
        log close main_log
        exit 459
    }

    if `n_level_countries' != `expected_countries' | ///
        `n_growth_countries' != `expected_countries' {
        display as error ///
            "Unexpected country coverage for `sample_name'. Expected `expected_countries' countries."
        restore
        postclose `validation_post'
        log close main_log
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

/***********************************************************************
7. Confirm generated outputs
***********************************************************************/

foreach output in ///
    outputs/tables/balanced_panel_regression_coefficients.csv ///
    outputs/tables/balanced_panel_linked_gdp_validation.csv ///
    data/processed/balanced_panel_linked_gdp_validation.dta ///
    outputs/figures/balanced_panel_h1_coefficients.png ///
    outputs/figures/balanced_panel_h1_coefficients.gph ///
    outputs/figures/bal_panel_horizon_coef.png ///
    outputs/figures/bal_panel_horizon_coef.gph ///
    outputs/figures/balanced_panel_asymmetry.png ///
    outputs/figures/balanced_panel_asymmetry.gph {
    capture confirm file "`output'"
    if _rc {
        display as error "Required sensitivity output missing: `output'"
        log close main_log
        exit 498
    }
}

display as result "Balanced-panel and common-period sensitivity completed."
display as result "Review the regression and linked-GDP validation outputs before interpretation."
log close main_log
