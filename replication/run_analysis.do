/***********************************************************************
Project:  Financial Cycles and Macroeconomic Fluctuations
File:     run_analysis.do
Purpose:  Construct the country panel and estimate predictive FE models
Requires: Stata 15.1+

Run from the repository root:
    do replication/run_analysis.do

The script downloads source files only when they are absent. See
replication/download_data.do to intentionally refresh the data vintage.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100

* Use a consistent, publication-style monochrome scheme for all figures.
set scheme s1mono
capture log close _all

capture mkdir "data"
capture mkdir "data/raw"
capture mkdir "data/processed"
capture mkdir "outputs"
capture mkdir "outputs/tables"
capture mkdir "outputs/figures"
capture mkdir "outputs/logs"

/***********************************************************************
0. Obtain source files if they are not already present
***********************************************************************/

do replication/download_data.do

local missing_output_count 0

capture confirm file "data/raw/bis_credit_gap.csv"
if _rc {
    display as error "BIS input file is missing."
    exit 601
}

log using "outputs/logs/analysis.log", replace text name(main_log)

/***********************************************************************
1. Define the BIS-to-World-Bank country-code crosswalk

The BIS dataset contains 44 economies including the euro-area aggregate.
The project retains the 43 individual economies listed below and excludes
the euro-area aggregate to avoid double-counting.
***********************************************************************/

tempfile country_crosswalk
preserve
clear
input str2 bis_iso2 str3 iso3c str24 country_name
"AR" "ARG" "Argentina"
"AU" "AUS" "Australia"
"AT" "AUT" "Austria"
"BE" "BEL" "Belgium"
"BR" "BRA" "Brazil"
"CA" "CAN" "Canada"
"CL" "CHL" "Chile"
"CN" "CHN" "China"
"CO" "COL" "Colombia"
"CZ" "CZE" "Czechia"
"DK" "DNK" "Denmark"
"FI" "FIN" "Finland"
"FR" "FRA" "France"
"DE" "DEU" "Germany"
"GR" "GRC" "Greece"
"HK" "HKG" "Hong Kong SAR"
"HU" "HUN" "Hungary"
"IN" "IND" "India"
"ID" "IDN" "Indonesia"
"IE" "IRL" "Ireland"
"IL" "ISR" "Israel"
"IT" "ITA" "Italy"
"JP" "JPN" "Japan"
"KR" "KOR" "Korea"
"LU" "LUX" "Luxembourg"
"MY" "MYS" "Malaysia"
"MX" "MEX" "Mexico"
"NL" "NLD" "Netherlands"
"NZ" "NZL" "New Zealand"
"NO" "NOR" "Norway"
"PL" "POL" "Poland"
"PT" "PRT" "Portugal"
"RU" "RUS" "Russian Federation"
"SA" "SAU" "Saudi Arabia"
"SG" "SGP" "Singapore"
"ZA" "ZAF" "South Africa"
"ES" "ESP" "Spain"
"SE" "SWE" "Sweden"
"CH" "CHE" "Switzerland"
"TH" "THA" "Thailand"
"TR" "TUR" "Türkiye"
"GB" "GBR" "United Kingdom"
"US" "USA" "United States"
end
isid bis_iso2
isid iso3c
save `country_crosswalk', replace
restore

/***********************************************************************
2. Import and validate BIS quarterly credit-gap observations
***********************************************************************/

* Use insheet to avoid the Java-dependent import delimited backend.
* The BIS header is read as variable names; quoted CSV fields remain intact.
insheet using "data/raw/bis_credit_gap.csv", comma names clear

foreach required_var in freq borrowers_cty tc_borrowers tc_lenders ///
    cg_dtype time_period obs_value {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required BIS variable not found: `required_var'"
        display as error "Inspect the BIS CSV header and revise the import mapping."
        log close main_log
        exit 111
    }
}

keep if freq == "Q"
keep if tc_borrowers == "P"
keep if tc_lenders == "A"
keep if cg_dtype == "C"

generate int year = real(substr(time_period, 1, 4))
generate byte quarter = real(substr(time_period, 7, 1))
capture confirm string variable obs_value
if !_rc {
    destring obs_value, replace force
}
rename borrowers_cty bis_iso2
rename obs_value credit_gap

keep if inrange(year, 1990, 2024)
keep if inrange(quarter, 1, 4)
drop if missing(bis_iso2, year, quarter, credit_gap)

merge m:1 bis_iso2 using `country_crosswalk', keep(match) nogen

isid iso3c year quarter

quietly count
if r(N) == 0 {
    display as error "No BIS observations remain after filtering and country matching."
    log close main_log
    exit 2000
}

/***********************************************************************
3. Construct annual credit-gap measures

Baseline: fourth-quarter observation.
Robustness: annual mean, retained only with all four quarters present.
***********************************************************************/

tempfile gap_q4 gap_average

preserve
keep if quarter == 4
keep iso3c country_name year credit_gap
rename credit_gap credit_gap_q4
isid iso3c year
save `gap_q4', replace
restore

collapse (mean) credit_gap_average = credit_gap ///
         (count) quarters_observed = credit_gap, by(iso3c year)

keep if quarters_observed == 4
isid iso3c year
save `gap_average', replace

use `gap_q4', clear
merge 1:1 iso3c year using `gap_average', keep(master match) nogen
isid iso3c year
tempfile annual_gap
save `annual_gap', replace

/***********************************************************************
4. Import World Bank wide CSV files and reshape 1989-2024 to long format

The World Bank CSV files contain two metadata records, blank separator
lines, a header row, and then country observations. The `insheet` command
skips blank lines, leaving three pre-data records (source metadata, update
date, and header); the analysis drops those three records. The files currently
include annual columns through 2025 and a trailing empty field. The analysis
retains only 1989-2024, which map to v34-v69; 2025 is excluded by design.
***********************************************************************/

local gdp_file "API_NY.GDP.MKTP.KD.ZG_DS2_EN_csv_v2_78346.csv"
local cpi_file "API_FP.CPI.TOTL.ZG_DS2_EN_csv_v2_79094.csv"

capture confirm file "data/raw/`gdp_file'"
if _rc {
    display as error "World Bank GDP CSV is missing: `gdp_file'. Run replication/download_data.do."
    log close main_log
    exit 601
}

capture confirm file "data/raw/`cpi_file'"
if _rc {
    display as error "World Bank CPI CSV is missing: `cpi_file'. Run replication/download_data.do."
    log close main_log
    exit 601
}

tempfile gdp_long cpi_long

program define import_wdi_long
    args csv_path value_variable output_path

    * insheet skips blank CSV lines. The three remaining pre-data records are
    * the source metadata, update date and column header.
    * This also avoids the Java-dependent import delimited backend.
    insheet using "`csv_path'", comma nonames clear
    drop in 1/3

    capture confirm variable v69
    if _rc {
        display as error "Expected WDI year column v69 (2024) was not found in `csv_path'."
        exit 111
    }

    keep v1 v2 v34-v69
    rename v1 country_name_wdi
    rename v2 iso3c

    forvalues y = 1989/2024 {
        local source_column = `y' - 1955
        rename v`source_column' v`y'
    }

    isid iso3c
    reshape long v, i(iso3c) j(year)
    rename v `value_variable'
    capture confirm string variable `value_variable'
    if !_rc {
        destring `value_variable', replace force
    }
    keep iso3c year `value_variable'
    keep if inrange(year, 1989, 2024)
    isid iso3c year
    save "`output_path'", replace
end

import_wdi_long "data/raw/`gdp_file'" gdp_growth "`gdp_long'"
import_wdi_long "data/raw/`cpi_file'" inflation "`cpi_long'"

tempfile gdp_current gdp_lag cpi_current

use `gdp_long', clear
keep if inrange(year, 1990, 2024)
isid iso3c year
save `gdp_current', replace

use `gdp_long', clear
keep if inrange(year, 1989, 2023)
replace year = year + 1
rename gdp_growth gdp_growth_lag1
keep iso3c year gdp_growth_lag1
isid iso3c year
save `gdp_lag', replace

use `cpi_long', clear
keep if inrange(year, 1990, 2024)
isid iso3c year
save `cpi_current', replace

/***********************************************************************
5. Merge the financial-cycle and macroeconomic series
***********************************************************************/

use `annual_gap', clear

merge 1:1 iso3c year using `gdp_current', keep(master match)
generate byte matched_gdp = (_merge == 3)
drop _merge

merge 1:1 iso3c year using `gdp_lag', keep(master match)
generate byte matched_gdp_lag1 = (_merge == 3)
drop _merge

merge 1:1 iso3c year using `cpi_current', keep(master match)
generate byte matched_inflation = (_merge == 3)
drop _merge

keep if inrange(year, 1990, 2024)
isid iso3c year

egen long panel_id = group(iso3c)
label variable panel_id "Country panel identifier"
label variable iso3c "World Bank ISO3 country code"
label variable country_name "Country"
label variable year "Calendar year"
label variable credit_gap_q4 "BIS credit-to-GDP gap, fourth quarter (percentage points of GDP)"
label variable credit_gap_average "BIS credit-to-GDP gap, annual average (percentage points of GDP)"
label variable gdp_growth "Real GDP growth (annual percent)"
label variable gdp_growth_lag1 "Previous-year real GDP growth (annual percent)"
label variable inflation "CPI inflation (annual percent)"
label variable matched_gdp "Current GDP observation matched"
label variable matched_gdp_lag1 "Previous-year GDP observation matched"
label variable matched_inflation "Inflation observation matched"

xtset panel_id year

generate byte complete_baseline = !missing(credit_gap_q4, gdp_growth, gdp_growth_lag1, inflation)
label variable complete_baseline "Complete observation for baseline regressors, including lagged GDP growth"

xtdescribe

save "data/processed/financial_cycles_panel.dta", replace

/***********************************************************************
6. Sample coverage and data-quality audit
***********************************************************************/

log using "outputs/tables/sample_coverage.txt", ///
    replace text name(coverage_log)

display as text "Country coverage in the merged BIS-led panel"
tabulate country_name

display as text "Merged panel structure"
xtdescribe

display as text "Source-match indicators"
tabulate matched_gdp
tabulate matched_gdp_lag1
tabulate matched_inflation

display as text "Complete observations for baseline variables"
count if complete_baseline == 1

display as text "Country-level coverage"
preserve
collapse (count) n_gap = credit_gap_q4 ///
         n_gdp = gdp_growth ///
         n_gdp_lag1 = gdp_growth_lag1 ///
         n_inflation = inflation ///
         (min) first_year = year ///
         (max) last_year = year, by(iso3c country_name)
list iso3c country_name first_year last_year n_gap n_gdp n_gdp_lag1 n_inflation, ///
    noobs sep(0)
restore

log close coverage_log

/***********************************************************************
7. Descriptive statistics and correlation matrix
***********************************************************************/

log using "outputs/tables/descriptive_statistics.txt", ///
    replace text name(descriptive_log)

summarize credit_gap_q4 credit_gap_average gdp_growth gdp_growth_lag1 inflation
summarize credit_gap_q4 gdp_growth inflation if complete_baseline == 1

log close descriptive_log

log using "outputs/tables/correlation_matrix.txt", ///
    replace text name(correlation_log)

pwcorr credit_gap_q4 gdp_growth inflation, obs sig

log close correlation_log

/***********************************************************************
8. Construct future-growth outcomes and asymmetric gap variables
***********************************************************************/

generate double gap_positive = cond(missing(credit_gap_q4), ., ///
    max(credit_gap_q4, 0))
generate double gap_negative = cond(missing(credit_gap_q4), ., ///
    min(credit_gap_q4, 0))

generate double gdp_growth_h1 = F1.gdp_growth
generate double gdp_growth_h2 = F2.gdp_growth
generate double gdp_growth_h3 = F3.gdp_growth

generate int outcome_year_h1 = year + 1
generate int outcome_year_h2 = year + 2
generate int outcome_year_h3 = year + 3

label variable gdp_growth_h1 "Real GDP growth one year ahead"
label variable gdp_growth_h2 "Real GDP growth two years ahead"
label variable gdp_growth_h3 "Real GDP growth three years ahead"
label variable gap_positive "Positive component of credit-to-GDP gap"
label variable gap_negative "Negative component of credit-to-GDP gap"

/***********************************************************************
9. Baseline two-way fixed-effects predictive regressions

The year fixed effects refer to the outcome year (t+h), not the predictor
year (t). Country-clustered standard errors allow within-country
heteroskedasticity and serial dependence.
***********************************************************************/

log using "outputs/tables/baseline_models.txt", ///
    replace text name(baseline_log)

display as text "Horizon 1: next-year GDP growth"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h1, fe vce(cluster panel_id)
estimates store H1

display as text "Horizon 2: GDP growth two years ahead"
xtreg gdp_growth_h2 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h2, fe vce(cluster panel_id)
estimates store H2

display as text "Horizon 3: GDP growth three years ahead"
xtreg gdp_growth_h3 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h3, fe vce(cluster panel_id)
estimates store H3

display as text "Horizon-specific model comparison"
estimates table H1 H2 H3, b(%9.3f) se(%9.3f) stats(N N_g)

log close baseline_log

/***********************************************************************
10. Asymmetric credit-gap specification
***********************************************************************/

log using "outputs/tables/asymmetric_model.txt", ///
    replace text name(asymmetric_log)

xtreg gdp_growth_h1 c.gap_positive c.gap_negative ///
    c.gdp_growth c.gdp_growth_lag1 c.inflation i.outcome_year_h1, ///
    fe vce(cluster panel_id)
estimates store ASYM

display as text "Test of equal slopes above and below the trend"
test gap_positive = gap_negative

estimates table ASYM, b(%9.3f) se(%9.3f) stats(N N_g)

log close asymmetric_log

/***********************************************************************
11. Robustness specifications
***********************************************************************/

log using "outputs/tables/robustness_models.txt", ///
    replace text name(robustness_log)

display as text "Annual-average gap, requiring four quarterly observations"
xtreg gdp_growth_h1 c.credit_gap_average c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h1, fe vce(cluster panel_id)
estimates store AVG_GAP

display as text "Fourth-quarter gap, excluding outcome years 2020 and 2021"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h1 if !inlist(outcome_year_h1, 2020, 2021), ///
    fe vce(cluster panel_id)
estimates store NO_PANDEMIC

display as text "One-year model omitting lagged GDP growth, on the baseline complete-case sample"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth c.inflation ///
    i.outcome_year_h1 if !missing(gdp_growth_lag1), ///
    fe vce(cluster panel_id)
estimates store NO_LAG

display as text "Expanded sample omitting CPI inflation control"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 ///
    i.outcome_year_h1, fe vce(cluster panel_id)
estimates store NO_INFLATION

estimates table AVG_GAP NO_PANDEMIC NO_LAG NO_INFLATION, ///
    b(%9.3f) se(%9.3f) stats(N N_g)

log close robustness_log

/***********************************************************************
12. Influence sensitivity for the largest absolute credit-gap observations
***********************************************************************/

log using "outputs/tables/influence_sensitivity.txt", ///
    replace text name(influence_log)

display as text "Exclude Ireland"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h1 if iso3c != "IRL", ///
    fe vce(cluster panel_id)
estimates store NO_IRL

display as text "Exclude Luxembourg"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h1 if iso3c != "LUX", ///
    fe vce(cluster panel_id)
estimates store NO_LUX

display as text "Exclude Ireland and Luxembourg jointly"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth c.gdp_growth_lag1 c.inflation ///
    i.outcome_year_h1 if !inlist(iso3c, "IRL", "LUX"), ///
    fe vce(cluster panel_id)
estimates store NO_IRL_LUX

estimates table NO_IRL NO_LUX NO_IRL_LUX, ///
    b(%9.3f) se(%9.3f) stats(N N_g)

log close influence_log

/***********************************************************************
13. Figures
***********************************************************************/

preserve
collapse (mean) mean_credit_gap = credit_gap_q4 ///
         (count) countries_observed = credit_gap_q4, by(year)

twoway line mean_credit_gap year, sort ///
    lcolor(black) lwidth(medthick) ///
    yline(0, lcolor(gs10) lpattern(dash) lwidth(thin)) ///
    title("Mean Credit-to-GDP Gap Across Available Economies", ///
        color(black) size(medsmall)) ///
    subtitle("Unweighted mean; country coverage varies by year", ///
        color(gs6) size(small)) ///
    xtitle("Year", color(black)) ///
    ytitle("Percentage points of GDP", color(black)) ///
    xlabel(, labcolor(gs5) nogrid) ///
    ylabel(, labcolor(gs5) nogrid) ///
    graphregion(color(white)) plotregion(color(white)) ///
    legend(off) ///
    name(mean_credit_gap_by_year, replace)

graph export "outputs/figures/mean_credit_gap_by_year.png", ///
    replace width(2000)
graph save "outputs/figures/mean_credit_gap_by_year.gph", replace
restore

twoway (scatter gdp_growth_h1 credit_gap_q4 if !missing(gdp_growth_h1), ///
            msize(vsmall) mcolor(gs8) mlcolor(gs8)) ///
       (lfit gdp_growth_h1 credit_gap_q4 if !missing(gdp_growth_h1), ///
            lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs10) lpattern(dash) lwidth(thin)) ///
    title("Credit-to-GDP Gaps and Subsequent GDP Growth", ///
        color(black) size(medsmall)) ///
    subtitle("Unconditional pooled association; not the fixed-effects estimate", ///
        color(gs6) size(small)) ///
    xtitle("Credit-to-GDP gap (percentage points of GDP)", color(black)) ///
    ytitle("GDP growth one year ahead (annual percent)", color(black)) ///
    xlabel(, labcolor(gs5) nogrid) ///
    ylabel(, labcolor(gs5) nogrid) ///
    graphregion(color(white)) plotregion(color(white)) ///
    legend(order(1 "Country-year observations" 2 "Linear fit") ///
        rows(1) position(6) size(small) region(lcolor(white) fcolor(white))) ///
    name(credit_gap_gdp_scatter, replace)

graph export "outputs/figures/credit_gap_gdp_scatter.png", ///
    replace width(2000)
graph save "outputs/figures/credit_gap_gdp_scatter.gph", replace

/***********************************************************************
14. Save final analysis dataset and validate expected outputs
***********************************************************************/

save "data/processed/financial_cycles_panel.dta", replace

foreach output in ///
    data/processed/financial_cycles_panel.dta ///
    outputs/tables/sample_coverage.txt ///
    outputs/tables/descriptive_statistics.txt ///
    outputs/tables/correlation_matrix.txt ///
    outputs/tables/baseline_models.txt ///
    outputs/tables/asymmetric_model.txt ///
    outputs/tables/robustness_models.txt ///
    outputs/tables/influence_sensitivity.txt ///
    outputs/figures/mean_credit_gap_by_year.png ///
    outputs/figures/mean_credit_gap_by_year.gph ///
    outputs/figures/credit_gap_gdp_scatter.png ///
    outputs/figures/credit_gap_gdp_scatter.gph ///
    outputs/logs/analysis.log {
    capture confirm file "`output'"
    if _rc {
        display as error "Required output missing: `output'"
        local missing_output_count = `missing_output_count' + 1
    }
}

if `missing_output_count' > 0 {
    display as error "Analysis failed: `missing_output_count' expected output file(s) are missing."
    display as result "Review outputs/logs/analysis.log."
    log close main_log
    exit 498
}

display as result "Analysis completed. Inspect all tables, diagnostics and sample counts before interpretation."
display as result "Main log: outputs/logs/analysis.log"
log close main_log
