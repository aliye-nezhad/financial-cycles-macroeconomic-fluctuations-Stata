/***********************************************************************
Project:  Financial Cycles and Macroeconomic Fluctuations
File:     denominator_diagnostic.do
Purpose:  Separate credit-numerator and nominal-GDP-denominator movements
Requires: Stata 15.1+ and an internet connection if source files are absent

Run from the repository root, after run_analysis.do:
    do replication/denominator_diagnostic.do

This supplementary diagnostic does not alter the main analysis pipeline.
It reconstructs the BIS four-quarter nominal-GDP denominator from the
BIS total-credit stock and its credit-to-GDP ratio, then examines the
numerator and denominator components separately. The resulting regressions
are predictive associations, not causal estimates.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
set scheme s1mono
capture log close _all

local refresh 0

capture confirm file "data/processed/financial_cycles_panel.dta"
if _rc {
    display as error "Processed panel not found. Run replication/run_analysis.do first."
    exit 601
}

capture mkdir "data/raw"
capture mkdir "data/processed"
capture mkdir "outputs"
capture mkdir "outputs/tables"
capture mkdir "outputs/figures"
capture mkdir "outputs/logs"

log using "outputs/logs/denominator_diagnostic.log", replace text name(main_log)

* BIS dataflow versions and dimension keys:
* WS_CREDIT_GAP 1.0: FREQ.BORROWERS_CTY.TC_BORROWERS.TC_LENDERS.CG_DTYPE
* WS_TC 2.0: FREQ.BORROWERS_CTY.TC_BORROWERS.TC_LENDERS.VALUATION.UNIT_TYPE.TC_ADJUST
local gap_ratio_url "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_CREDIT_GAP/1.0/Q..P.A.A?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
local gap_trend_url "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_CREDIT_GAP/1.0/Q..P.A.B?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
local tc_stock_url "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_TC/2.0/Q..P.A.M.XDC.A?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"
local tc_ratio_url "https://stats.bis.org/api/v2/data/dataflow/BIS/WS_TC/2.0/Q..P.A.M.770.A?format=csv&startPeriod=1990-Q1&endPeriod=2024-Q4"

/***********************************************************************
1. Retrieve the four BIS component series if needed
***********************************************************************/

capture confirm file "data/raw/bis_credit_gap_ratio.csv"
if _rc | `refresh' {
    display as text "Downloading BIS credit-to-GDP actual ratio..."
    copy "`gap_ratio_url'" "data/raw/bis_credit_gap_ratio.csv", replace
}

capture confirm file "data/raw/bis_credit_gap_trend.csv"
if _rc | `refresh' {
    display as text "Downloading BIS credit-to-GDP trend..."
    copy "`gap_trend_url'" "data/raw/bis_credit_gap_trend.csv", replace
}

capture confirm file "data/raw/bis_total_credit_xdc.csv"
if _rc | `refresh' {
    display as text "Downloading BIS private non-financial-sector credit stock in domestic currency..."
    copy "`tc_stock_url'" "data/raw/bis_total_credit_xdc.csv", replace
}

capture confirm file "data/raw/bis_total_credit_gdp.csv"
if _rc | `refresh' {
    display as text "Downloading BIS private non-financial-sector credit-to-GDP ratio..."
    copy "`tc_ratio_url'" "data/raw/bis_total_credit_gdp.csv", replace
}

foreach source_file in ///
    "data/raw/bis_credit_gap_ratio.csv" ///
    "data/raw/bis_credit_gap_trend.csv" ///
    "data/raw/bis_total_credit_xdc.csv" ///
    "data/raw/bis_total_credit_gdp.csv" {
    capture confirm file "`source_file'"
    if _rc {
        display as error "Required BIS component file is missing: `source_file'"
        log close main_log
        exit 601
    }
}

/***********************************************************************
2. Import the BIS actual credit-to-GDP ratio and its HP-filter trend
***********************************************************************/

tempfile gap_ratio gap_trend tc_stock tc_ratio country_crosswalk components

insheet using "data/raw/bis_credit_gap_ratio.csv", comma names clear

foreach required_var in freq borrowers_cty tc_borrowers tc_lenders ///
    cg_dtype unit_mult time_period obs_value {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable not found in BIS ratio file: `required_var'"
        log close main_log
        exit 111
    }
}

keep if freq == "Q" & tc_borrowers == "P" & tc_lenders == "A" & cg_dtype == "A"

capture confirm string variable obs_value
if !_rc {
    destring obs_value, replace force
}
capture confirm string variable unit_mult
if !_rc {
    destring unit_mult, replace force
}

generate int year = real(substr(time_period, 1, 4))
generate byte quarter = real(substr(time_period, 7, 1))
generate double credit_gdp_ratio_gap_source = obs_value * (10^unit_mult)
rename borrowers_cty bis_iso2
keep bis_iso2 year quarter credit_gdp_ratio_gap_source
keep if inrange(year, 1990, 2024) & inrange(quarter, 1, 4)
drop if missing(bis_iso2, year, quarter, credit_gdp_ratio_gap_source)
isid bis_iso2 year quarter
save `gap_ratio', replace

insheet using "data/raw/bis_credit_gap_trend.csv", comma names clear

foreach required_var in freq borrowers_cty tc_borrowers tc_lenders ///
    cg_dtype unit_mult time_period obs_value {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable not found in BIS trend file: `required_var'"
        log close main_log
        exit 111
    }
}

keep if freq == "Q" & tc_borrowers == "P" & tc_lenders == "A" & cg_dtype == "B"

capture confirm string variable obs_value
if !_rc {
    destring obs_value, replace force
}
capture confirm string variable unit_mult
if !_rc {
    destring unit_mult, replace force
}

generate int year = real(substr(time_period, 1, 4))
generate byte quarter = real(substr(time_period, 7, 1))
generate double credit_gdp_trend_source = obs_value * (10^unit_mult)
rename borrowers_cty bis_iso2
keep bis_iso2 year quarter credit_gdp_trend_source
keep if inrange(year, 1990, 2024) & inrange(quarter, 1, 4)
drop if missing(bis_iso2, year, quarter, credit_gdp_trend_source)
isid bis_iso2 year quarter
save `gap_trend', replace

/***********************************************************************
3. Import BIS total credit in domestic currency and as a percentage of GDP

The two WS_TC series share the borrower, lender, valuation and break-
adjustment dimensions. UNIT_MULT is applied so that credit stocks are
expressed in the underlying domestic-currency unit before log changes.
***********************************************************************/

insheet using "data/raw/bis_total_credit_xdc.csv", comma names clear

foreach required_var in freq borrowers_cty tc_borrowers tc_lenders ///
    valuation unit_type tc_adjust unit_mult time_period obs_value {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable not found in BIS credit-stock file: `required_var'"
        log close main_log
        exit 111
    }
}

keep if freq == "Q" & tc_borrowers == "P" & tc_lenders == "A" ///
    & valuation == "M" & unit_type == "XDC" & tc_adjust == "A"

capture confirm string variable obs_value
if !_rc {
    destring obs_value, replace force
}
capture confirm string variable unit_mult
if !_rc {
    destring unit_mult, replace force
}

generate int year = real(substr(time_period, 1, 4))
generate byte quarter = real(substr(time_period, 7, 1))
generate double credit_stock_local = obs_value * (10^unit_mult)
rename borrowers_cty bis_iso2
keep bis_iso2 year quarter credit_stock_local
keep if inrange(year, 1990, 2024) & inrange(quarter, 1, 4)
drop if missing(bis_iso2, year, quarter, credit_stock_local) | credit_stock_local <= 0
isid bis_iso2 year quarter
save `tc_stock', replace

insheet using "data/raw/bis_total_credit_gdp.csv", comma names clear

foreach required_var in freq borrowers_cty tc_borrowers tc_lenders ///
    valuation unit_type tc_adjust unit_mult time_period obs_value {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable not found in BIS ratio-validation file: `required_var'"
        log close main_log
        exit 111
    }
}

keep if freq == "Q" & tc_borrowers == "P" & tc_lenders == "A" ///
    & valuation == "M" & unit_type == "770" & tc_adjust == "A"

capture confirm string variable obs_value
if !_rc {
    destring obs_value, replace force
}
capture confirm string variable unit_mult
if !_rc {
    destring unit_mult, replace force
}

generate int year = real(substr(time_period, 1, 4))
generate byte quarter = real(substr(time_period, 7, 1))
generate double credit_gdp_ratio_tc = obs_value * (10^unit_mult)
rename borrowers_cty bis_iso2
keep bis_iso2 year quarter credit_gdp_ratio_tc
keep if inrange(year, 1990, 2024) & inrange(quarter, 1, 4)
drop if missing(bis_iso2, year, quarter, credit_gdp_ratio_tc)
isid bis_iso2 year quarter
save `tc_ratio', replace

/***********************************************************************
4. Define the same 43-economy crosswalk used by the main analysis
***********************************************************************/

preserve
clear
input str2 bis_iso2 str3 iso3c
"AR" "ARG"
"AU" "AUS"
"AT" "AUT"
"BE" "BEL"
"BR" "BRA"
"CA" "CAN"
"CL" "CHL"
"CN" "CHN"
"CO" "COL"
"CZ" "CZE"
"DK" "DNK"
"FI" "FIN"
"FR" "FRA"
"DE" "DEU"
"GR" "GRC"
"HK" "HKG"
"HU" "HUN"
"IN" "IND"
"ID" "IDN"
"IE" "IRL"
"IL" "ISR"
"IT" "ITA"
"JP" "JPN"
"KR" "KOR"
"LU" "LUX"
"MY" "MYS"
"MX" "MEX"
"NL" "NLD"
"NZ" "NZL"
"NO" "NOR"
"PL" "POL"
"PT" "PRT"
"RU" "RUS"
"SA" "SAU"
"SG" "SGP"
"ZA" "ZAF"
"ES" "ESP"
"SE" "SWE"
"CH" "CHE"
"TH" "THA"
"TR" "TUR"
"GB" "GBR"
"US" "USA"
end
isid bis_iso2
isid iso3c
save `country_crosswalk', replace
restore

/***********************************************************************
5. Merge component series, retain Q4, and match the main analytical panel
***********************************************************************/

use `gap_ratio', clear
merge 1:1 bis_iso2 year quarter using `gap_trend', keep(match) nogen
merge 1:1 bis_iso2 year quarter using `tc_ratio', keep(match) nogen
merge 1:1 bis_iso2 year quarter using `tc_stock', keep(match) nogen
merge m:1 bis_iso2 using `country_crosswalk', keep(match) nogen

keep if quarter == 4
keep iso3c year credit_gdp_ratio_gap_source credit_gdp_trend_source ///
    credit_gdp_ratio_tc credit_stock_local
isid iso3c year
save `components', replace

use "data/processed/financial_cycles_panel.dta", clear
merge 1:1 iso3c year using `components', keep(master match) gen(component_merge)

generate double implied_nominal_gdp_4q = ///
    credit_stock_local / (credit_gdp_ratio_tc / 100) ///
    if credit_stock_local > 0 & credit_gdp_ratio_tc > 0

generate double ratio_source_difference = ///
    credit_gdp_ratio_tc - credit_gdp_ratio_gap_source

generate double gap_reconstruction_error = ///
    credit_gdp_ratio_gap_source - credit_gdp_trend_source - credit_gap_q4

generate double abs_ratio_source_difference = abs(ratio_source_difference)
generate double abs_gap_reconstruction_error = abs(gap_reconstruction_error)

xtset panel_id year

generate double ln_credit_stock = ln(credit_stock_local) if credit_stock_local > 0
generate double ln_implied_nominal_gdp = ///
    ln(implied_nominal_gdp_4q) if implied_nominal_gdp_4q > 0
generate double ln_credit_gdp_ratio = ln(credit_gdp_ratio_tc) ///
    if credit_gdp_ratio_tc > 0

generate double credit_growth_nominal = 100 * D.ln_credit_stock
generate double nominal_gdp_growth_implied = 100 * D.ln_implied_nominal_gdp
generate double ratio_growth_log = 100 * D.ln_credit_gdp_ratio

* This identity follows from ratio = credit / four-quarter nominal GDP:
* dlog(credit/GDP) = dlog(credit) - dlog(GDP).
generate double ratio_identity_error = ///
    ratio_growth_log - (credit_growth_nominal - nominal_gdp_growth_implied)

generate byte component_sample = !missing( ///
    gdp_growth_h1, credit_gap_q4, gdp_growth, gdp_growth_lag1, inflation, ///
    credit_growth_nominal, nominal_gdp_growth_implied, ratio_growth_log)

quietly count if component_sample
if r(N) == 0 {
    display as error "No observations remain for the matched component analysis."
    log close main_log
    exit 2000
}

/***********************************************************************
6. Report source alignment and the numerator-denominator identity
***********************************************************************/

log using "outputs/tables/denominator_decomposition.txt", ///
    replace text name(decomposition_log)

display as text "BIS source alignment: WS_TC ratio versus WS_CREDIT_GAP actual ratio"
summarize ratio_source_difference abs_ratio_source_difference, detail

quietly summarize abs_ratio_source_difference
display as result "Maximum absolute ratio-source difference (percentage points): " %9.5f r(max)

display as text "BIS credit-gap reconstruction: actual ratio minus trend minus published gap"
summarize gap_reconstruction_error abs_gap_reconstruction_error, detail

quietly summarize abs_gap_reconstruction_error
display as result "Maximum absolute gap-reconstruction error (percentage points): " %9.5f r(max)

display as text "Matched Q4 panel and denominator-component coverage"
count if !missing(credit_stock_local, credit_gdp_ratio_tc, implied_nominal_gdp_4q)
count if component_sample
egen byte component_country_tag = tag(panel_id) if component_sample
count if component_country_tag == 1
drop component_country_tag

display as text "Annual log changes, common matched regression sample"
summarize credit_growth_nominal nominal_gdp_growth_implied ratio_growth_log ///
    if component_sample

display as text "Numerator-denominator identity check"
summarize ratio_identity_error if component_sample, detail

log close decomposition_log

quietly summarize abs_ratio_source_difference
if r(max) > 0.10 {
    display as error "WARNING: WS_TC and WS_CREDIT_GAP actual ratios differ by more than 0.10 percentage points."
    display as error "Inspect denominator_decomposition.txt before interpreting the component estimates."
}

quietly summarize abs_gap_reconstruction_error
if r(max) > 0.10 {
    display as error "WARNING: The published gap does not reconstruct as actual ratio minus trend within 0.10 points."
    display as error "Inspect the source vintage and series alignment before interpreting the component estimates."
}

/***********************************************************************
7. Compare the baseline gap model with the numerator-denominator model

The component model includes nominal credit growth and implied nominal GDP
growth together. Current real GDP growth and CPI inflation are omitted from
that model because nominal GDP growth already contains real activity and
price movements. Lagged real GDP growth and outcome-year fixed effects remain.
Both models use the same matched sample and country-clustered inference.
***********************************************************************/

log using "outputs/tables/denominator_component_models.txt", ///
    replace text name(component_models_log)

display as text "Matched-sample baseline credit-gap model"
xtreg gdp_growth_h1 c.credit_gap_q4 c.gdp_growth ///
    c.gdp_growth_lag1 c.inflation i.outcome_year_h1 ///
    if component_sample, fe vce(cluster panel_id)
estimates store GAP_MATCHED

display as text "Joint nominal-credit-growth and implied-nominal-GDP-growth model"
xtreg gdp_growth_h1 c.credit_growth_nominal ///
    c.nominal_gdp_growth_implied c.gdp_growth_lag1 ///
    i.outcome_year_h1 if component_sample, fe vce(cluster panel_id)
estimates store COMPONENTS

display as text "Matched-sample model comparison"
estimates table GAP_MATCHED COMPONENTS, ///
    b(%9.3f) se(%9.3f) stats(N N_g)

log close component_models_log

/***********************************************************************
8. Figure: annual changes in credit, implied nominal GDP, and their ratio
***********************************************************************/

preserve
keep if component_sample
collapse (mean) mean_credit_growth = credit_growth_nominal ///
         (mean) mean_nominal_gdp_growth = nominal_gdp_growth_implied ///
         (mean) mean_ratio_growth = ratio_growth_log, by(year)

twoway (line mean_credit_growth year, ///
            lcolor(black) lwidth(medthick)) ///
       (line mean_nominal_gdp_growth year, ///
            lcolor(gs7) lpattern(dash) lwidth(medthick)) ///
       (line mean_ratio_growth year, ///
            lcolor(gs10) lpattern(dot) lwidth(medthick)), ///
    yline(0, lcolor(gs12) lpattern(shortdash)) ///
    title("Decomposing Changes in the Credit-to-GDP Ratio", ///
        color(black) size(medsmall)) ///
    subtitle("Cross-country annual means; Q4 observations", ///
        color(gs6) size(small)) ///
    xtitle("Year") ///
    ytitle("Annual log change (percent)") ///
    xlabel(, labcolor(gs5) nogrid angle(45) labsize(small)) ///
    ylabel(, labcolor(gs5) nogrid) ///
    legend(order(1 "Nominal credit stock" ///
                 2 "Implied nominal GDP denominator" ///
                 3 "Credit-to-GDP ratio") ///
        rows(3) position(6) size(small) region(lcolor(white) fcolor(white))) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(ratio_component_growth, replace)

graph export "outputs/figures/ratio_component_growth.png", ///
    name(ratio_component_growth) replace width(2000)
graph save ratio_component_growth ///
    "outputs/figures/ratio_component_growth.gph", replace
restore

/***********************************************************************
9. Figure: matched-sample coefficients from the component model
***********************************************************************/

estimates restore COMPONENTS
local credit_b = _b[credit_growth_nominal]
local credit_se = _se[credit_growth_nominal]
local gdp_b = _b[nominal_gdp_growth_implied]
local gdp_se = _se[nominal_gdp_growth_implied]
local component_crit = invttail(e(df_r), .025)

preserve
clear
set obs 2
generate byte component = _n
generate double estimate = .
generate double standard_error = .
generate double critical_value = .

replace estimate = `credit_b' in 1
replace standard_error = `credit_se' in 1
replace critical_value = `component_crit' in 1

replace estimate = `gdp_b' in 2
replace standard_error = `gdp_se' in 2
replace critical_value = `component_crit' in 2

generate double ci_lower = estimate - critical_value * standard_error
generate double ci_upper = estimate + critical_value * standard_error

twoway (rcap ci_lower ci_upper component, horizontal ///
            lcolor(gs7) lwidth(medthick)) ///
       (scatter component estimate, ///
            msymbol(O) msize(medlarge) mcolor(black)), ///
    xline(0, lcolor(gs10) lpattern(dash) lwidth(thin)) ///
    ylabel(1 "Nominal credit growth" 2 "Implied nominal GDP growth", ///
        angle(0) labsize(small)) ///
    yscale(reverse) ///
    xlabel(, labcolor(gs5) nogrid) ///
    ytitle("") ///
    xtitle("Coefficient (next-year real GDP-growth percentage points)") ///
    title("Credit and GDP Components as Predictors of Growth", ///
        color(black) size(medsmall)) ///
    subtitle("Matched sample; country and outcome-year FE; country-clustered 95% CIs", ///
        color(gs6) size(small)) ///
    note("Each coefficient is per 1% annual log change in the component.", ///
        color(gs6) size(vsmall)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    legend(off) ///
    name(ratio_component_coefficients, replace)

graph export "outputs/figures/ratio_component_coefficients.png", ///
    name(ratio_component_coefficients) replace width(2000)
graph save ratio_component_coefficients ///
    "outputs/figures/ratio_component_coefficients.gph", replace
restore

display as text "Denominator diagnostic graphs retained in memory:"
graph dir

/***********************************************************************
10. Save the matched panel and validate expected outputs
***********************************************************************/

save "data/processed/denominator_components_panel.dta", replace

foreach output in ///
    data/processed/denominator_components_panel.dta ///
    outputs/tables/denominator_decomposition.txt ///
    outputs/tables/denominator_component_models.txt ///
    outputs/figures/ratio_component_growth.png ///
    outputs/figures/ratio_component_growth.gph ///
    outputs/figures/ratio_component_coefficients.png ///
    outputs/figures/ratio_component_coefficients.gph ///
    outputs/logs/denominator_diagnostic.log {
    capture confirm file "`output'"
    if _rc {
        display as error "Required output missing: `output'"
        log close main_log
        exit 498
    }
}

display as result "Denominator diagnostic completed."
display as result "Review source-alignment checks before interpreting the component regressions."
log close main_log
