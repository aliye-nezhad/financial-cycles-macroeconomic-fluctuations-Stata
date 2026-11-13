/***********************************************************************
Project:  Financial Cycles and Macroeconomic Fluctuations
File:     inference_diagnostics.do
Purpose:  Optional wild cluster bootstrap inference for the main models
Requires: Stata 18.0+ (official built-in wildbootstrap command)

Run from the repository root, after run_analysis.do:
    do replication/inference_diagnostics.do

The main analysis remains compatible with Stata 15.1. This separate
diagnostic does not alter the main estimation pipeline or its outputs.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
capture log close _all

if c(stata_version) < 18 {
    display as error "This diagnostic requires Stata 18 or later."
    display as text "The main analysis remains available in Stata 15.1 or later."
    exit 9
}

version 18.0

capture confirm file "data/processed/financial_cycles_panel.dta"
if _rc {
    display as error "Processed panel not found. Run replication/run_analysis.do first."
    exit 601
}

capture mkdir "outputs"
capture mkdir "outputs/tables"

use "data/processed/financial_cycles_panel.dta", clear

foreach required_var in panel_id year credit_gap_q4 gdp_growth ///
    gdp_growth_lag1 inflation {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable not found: `required_var'"
        exit 111
    }
}

xtset panel_id year

generate double gap_positive = cond(missing(credit_gap_q4), ., ///
    max(credit_gap_q4, 0))
generate double gap_negative = cond(missing(credit_gap_q4), ., ///
    min(credit_gap_q4, 0))

generate double gdp_growth_h1 = F1.gdp_growth
generate int outcome_year_h1 = year + 1

label variable gap_positive "Positive component of credit-to-GDP gap"
label variable gap_negative "Negative component of credit-to-GDP gap"
label variable gdp_growth_h1 "Real GDP growth one year ahead"
label variable outcome_year_h1 "Outcome year for one-year-ahead GDP growth"

log using "outputs/tables/wild_cluster_bootstrap.txt", ///
    replace text name(wildbootstrap_log)

display as text "Wild cluster bootstrap: baseline one-year-ahead credit-gap coefficient"
quietly count if !missing(gdp_growth_h1, credit_gap_q4, gdp_growth, ///
    gdp_growth_lag1, inflation, outcome_year_h1)
display as result "Baseline complete-case observations: " r(N)

wildbootstrap xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth ///
    c.gdp_growth_lag1 c.inflation i.outcome_year_h1, ///
    coefficients(credit_gap_q4) reps(10000) ///
    errorweight(rademacher) ptype(equal) rseed(13112026)

display as text "Wild cluster bootstrap: asymmetric one-year-ahead specification"
quietly count if !missing(gdp_growth_h1, gap_positive, gap_negative, ///
    gdp_growth, gdp_growth_lag1, inflation, outcome_year_h1)
display as result "Asymmetric complete-case observations: " r(N)

wildbootstrap xtreg gdp_growth_h1 c.gap_positive c.gap_negative ///
    c.gdp_growth c.gdp_growth_lag1 c.inflation i.outcome_year_h1, ///
    test((gap_positive=0) (gap_negative=0) ///
         (gap_positive=gap_negative)) ///
    reps(10000) errorweight(rademacher) ptype(equal) rseed(13112027)

log close wildbootstrap_log

display as result "Wild cluster bootstrap diagnostic completed."
display as result "Output: outputs/tables/wild_cluster_bootstrap.txt"
