/***********************************************************************
Project:  Financial Cycles and Macroeconomic Fluctuations
File:     inference_diagnostics.do
Purpose:  Wild cluster bootstrap inference for the main one-year models
Requires: Stata 15.1+ and David Roodman's user-written boottest package

Run from the repository root, after run_analysis.do:
    do replication/inference_diagnostics.do

The main analysis remains compatible with Stata 15.1 and uses built-in
commands only. This optional diagnostic uses boottest after xtreg, fe.
It does not alter the main estimation pipeline or its outputs.

The installed boottest Mata source is loaded before estimation. This avoids
a function-not-found failure observed when the Mata functions were not
loaded into the current Stata session. Do not run the Mata source after
estimation, because doing so can clear the active estimation results.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
set scheme s1mono
capture log close _all

/***********************************************************************
0. Check the optional boottest dependency and load its Mata functions
***********************************************************************/

capture which boottest
if _rc {
    display as error "The user-written boottest package is not installed."
    display as text "Install it in Stata with: ssc install boottest, replace"
    display as text "If SSC installation fails, see docs/REPRODUCIBILITY.md."
    exit 499
}

capture findfile boottest.mata
if _rc {
    display as error "boottest.mata was not found on the Stata ado-path."
    display as text "Check the boottest installation before running this diagnostic."
    exit 601
}
local boottest_mata `"`r(fn)'"'

capture findfile lboottest.mlib
if _rc {
    display as error "lboottest.mlib was not found on the Stata ado-path."
    display as text "Check the boottest installation before running this diagnostic."
    exit 601
}

display as text "Stata version: " c(stata_version)
display as text "Installed boottest ado-file:"
which boottest
display as text "Installed boottest Mata source:"
which boottest.mata

capture noisily run `"`boottest_mata'"'
local mata_rc = _rc
if `mata_rc' != 0 {
    display as error "Could not load the boottest Mata source."
    exit `mata_rc'
}

/***********************************************************************
1. Load and validate the processed panel
***********************************************************************/

capture confirm file "data/processed/financial_cycles_panel.dta"
if _rc {
    display as error "Processed panel not found. Run replication/run_analysis.do first."
    exit 601
}

capture mkdir "outputs"
capture mkdir "outputs/tables"
capture mkdir "outputs/logs"

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

* Recreate diagnostic variables so the script is safe to rerun against
* a processed panel that may already contain variables from an earlier run.
capture drop gap_positive gap_negative gdp_growth_h1 outcome_year_h1

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

/***********************************************************************
2. Wild cluster bootstrap inference
***********************************************************************/

log using "outputs/tables/wild_cluster_bootstrap.txt", ///
    replace text name(wildbootstrap_log)

display as text "============================================================"
display as text "Wild cluster bootstrap inference"
display as text "Stata version: " c(stata_version)
display as text "Cluster variable: panel_id (country)"
display as text "Replications: 9,999"
display as text "Weight distribution: Rademacher"
display as text "Installed boottest ado-file:"
which boottest
display as text "Installed boottest Mata source:"
which boottest.mata
display as text "============================================================"

display as text "A. Baseline one-year-ahead credit-gap coefficient"

xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth ///
    c.gdp_growth_lag1 c.inflation i.outcome_year_h1, ///
    fe vce(cluster panel_id)

quietly count if e(sample)
local baseline_n = r(N)
display as result "Baseline estimation observations: `baseline_n'"
display as result "Baseline country clusters: " e(N_g)

boottest credit_gap_q4, reps(9999) seed(13112026) weight(rademacher)

display as text "B. Asymmetric one-year-ahead specification"

xtreg gdp_growth_h1 c.gap_positive c.gap_negative ///
    c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h1, fe vce(cluster panel_id)

estimates store ASYM_BOOT

quietly count if e(sample)
local asymmetric_n = r(N)
display as result "Asymmetric estimation observations: `asymmetric_n'"
display as result "Asymmetric country clusters: " e(N_g)

display as text "Conventional cluster-robust equality-of-slopes test"
test gap_positive = gap_negative

display as text "Wild bootstrap test: positive-gap coefficient equals zero"
boottest gap_positive, reps(9999) seed(13112027) weight(rademacher)

estimates restore ASYM_BOOT
display as text "Wild bootstrap test: negative-gap coefficient equals zero"
boottest gap_negative, reps(9999) seed(13112028) weight(rademacher)

estimates restore ASYM_BOOT
display as text "Wild bootstrap test: positive-gap slope equals negative-gap slope"
boottest gap_positive = gap_negative, ///
    reps(9999) seed(13112029) weight(rademacher)

log close wildbootstrap_log

display as result "Wild cluster bootstrap diagnostic completed."
display as result "Output: outputs/tables/wild_cluster_bootstrap.txt"
