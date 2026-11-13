/***********************************************************************
Project:  Financial Cycles and Macroeconomic Fluctuations
File:     audit_nominal_gdp_linked.do
Purpose:  Identify country-year and country-level discrepancies in the
          linked World Bank validation of the BIS-implied GDP denominator
Requires: Stata 15.1+

Run from the repository root, after:
    do replication/validate_nominal_gdp_linked.do

This is a supplementary measurement audit. It does not alter the main
analysis, the denominator-component panel, or the validation estimates.
All figures are exported separately in monochrome PNG and editable GPH
formats. The audit reports discrepancies; it does not automatically
delete, winsorize, or adjust observations.
***********************************************************************/

version 15.1
clear all
set more off
set linesize 100
set scheme s1mono
capture log close _all

capture confirm file "data/processed/nominal_gdp_linked_validation_panel.dta"
if _rc {
    display as error "Linked nominal-GDP validation panel not found."
    display as error "Run replication/validate_nominal_gdp_linked.do first."
    exit 601
}

capture mkdir "outputs"
capture mkdir "outputs/tables"
capture mkdir "outputs/figures"
capture mkdir "outputs/logs"

log using "outputs/logs/nominal_gdp_linked_outlier_audit.log", ///
    replace text name(audit_log)

use "data/processed/nominal_gdp_linked_validation_panel.dta", clear

foreach required_var in iso3c country_name year implied_nominal_gdp_4q ///
    wb_nominal_gdp_lcu nominal_gdp_growth_implied ///
    wb_nominal_gdp_growth level_ratio scale_adjusted_pct_deviation ///
    growth_difference absolute_growth_difference squared_growth_difference {
    capture confirm variable `required_var'
    if _rc {
        display as error "Required variable missing from validation panel: `required_var'"
        log close audit_log
        exit 111
    }
}

isid iso3c year

capture confirm variable abs_scale_adj_dev
if _rc {
    generate double abs_scale_adj_dev = ///
        abs(scale_adjusted_pct_deviation)
}

quietly count if !missing(growth_difference)
local n_growth = r(N)

quietly count if !missing(scale_adjusted_pct_deviation)
local n_levels = r(N)

if `n_growth' == 0 | `n_levels' == 0 {
    display as error "The validation panel contains no usable overlapping observations."
    log close audit_log
    exit 2000
}

display as text "Linked nominal-GDP validation: country-year outlier audit"
display as result "Matched level observations: `n_levels'"
display as result "Matched growth observations: `n_growth'"

/***********************************************************************
1. Largest country-year deviations in nominal-GDP levels
***********************************************************************/

display as text " "
display as text "TOP 20 COUNTRY-YEAR LEVEL DEVIATIONS"
display as text "Absolute deviation from each country's median implied/WDI level ratio."

preserve
keep if !missing(abs_scale_adj_dev)
gsort -abs_scale_adj_dev
generate int rank = _n
list rank iso3c year level_ratio scale_adjusted_pct_deviation ///
    abs_scale_adj_dev in 1/20, noobs abbreviate(24) separator(0)
keep in 1/20
* Export only the variables needed to interpret the level discrepancy.
keep rank iso3c country_name year level_ratio ///
    scale_adjusted_pct_deviation abs_scale_adj_dev
export delimited using ///
    "outputs/tables/nominal_gdp_linked_level_outliers_top20.csv", replace
restore

/***********************************************************************
2. Largest country-year deviations in annual nominal-GDP growth
***********************************************************************/

display as text " "
display as text "TOP 20 COUNTRY-YEAR GROWTH DEVIATIONS"
display as text "Absolute difference = BIS-implied growth minus World Bank growth."

preserve
keep if !missing(absolute_growth_difference)
gsort -absolute_growth_difference
generate int rank = _n
list rank iso3c year nominal_gdp_growth_implied ///
    wb_nominal_gdp_growth growth_difference ///
    absolute_growth_difference in 1/20, ///
    noobs abbreviate(24) separator(0)
keep in 1/20
* Export only the variables needed to interpret the growth discrepancy.
keep rank iso3c country_name year nominal_gdp_growth_implied ///
    wb_nominal_gdp_growth growth_difference absolute_growth_difference
export delimited using ///
    "outputs/tables/nominal_gdp_linked_growth_outliers_top20.csv", replace
restore

/***********************************************************************
3. Country-level discrepancy summary
***********************************************************************/

preserve
collapse (count) n_level=level_ratio ///
                 n_growth=absolute_growth_difference ///
         (mean) mean_abs_growth_difference=absolute_growth_difference ///
                mean_squared_growth_difference=squared_growth_difference ///
         (median) median_level_ratio=level_ratio ///
                  median_abs_scale_deviation=abs_scale_adj_dev ///
                  median_abs_growth_difference=absolute_growth_difference ///
         (p95) p95_abs_scale_deviation=abs_scale_adj_dev ///
               p95_abs_growth_difference=absolute_growth_difference ///
         (max) max_abs_scale_deviation=abs_scale_adj_dev ///
               max_abs_growth_difference=absolute_growth_difference, ///
         by(iso3c)

generate double rmse_growth_difference = ///
    sqrt(mean_squared_growth_difference)

generate double abs_median_level_deviation = ///
    100 * abs(median_level_ratio - 1)

drop mean_squared_growth_difference
sort iso3c

display as text " "
display as text "COUNTRY-LEVEL VALIDATION SUMMARY"
list iso3c n_level n_growth median_level_ratio ///
    abs_median_level_deviation mean_abs_growth_difference ///
    median_abs_growth_difference p95_abs_growth_difference ///
    rmse_growth_difference median_abs_scale_deviation ///
    p95_abs_scale_deviation max_abs_scale_deviation ///
    max_abs_growth_difference, noobs abbreviate(24) separator(0)

export delimited using ///
    "outputs/tables/nominal_gdp_linked_validation_country_audit.csv", replace
save "data/processed/nominal_gdp_linked_validation_country_audit.dta", replace

/***********************************************************************
4. Graph: BIS-implied versus World Bank annual nominal-GDP growth
***********************************************************************/

restore

twoway ///
    (scatter wb_nominal_gdp_growth nominal_gdp_growth_implied ///
        if !missing(wb_nominal_gdp_growth, nominal_gdp_growth_implied), ///
        msymbol(oh) msize(vsmall) mcolor(gs8)) ///
    (function y=x, range(-25 115) lcolor(black) ///
        lpattern(dash) lwidth(medthin)), ///
    title("BIS-Implied and World Bank Nominal GDP Growth", ///
        color(black) size(medsmall)) ///
    subtitle("Country-year observations, 43 economies", ///
        color(gs6) size(small)) ///
    xtitle("BIS-implied nominal GDP growth (%)") ///
    ytitle("World Bank linked nominal GDP growth (%)") ///
    xscale(range(-25 115)) yscale(range(-25 115)) aspect(1) ///
    xlabel(-20(20)100, labsize(small)) ///
    ylabel(-20(20)100, labsize(small) angle(horizontal)) ///
    legend(order(1 "Country-year observations" ///
                 2 "45-degree reference") ///
        rows(1) size(small) region(lcolor(white) fcolor(white))) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(gdp_validation_scatter, replace)

graph export "outputs/figures/nominal_gdp_validation_scatter.png", ///
    replace width(2400)
graph save "outputs/figures/nominal_gdp_validation_scatter.gph", replace

/***********************************************************************
5. Graph: median signed annual growth difference by year
***********************************************************************/

preserve
keep if !missing(growth_difference)
collapse (median) median_growth_difference=growth_difference ///
         (count) growth_observations=growth_difference, by(year)

twoway ///
    (line median_growth_difference year, ///
        lcolor(black) lwidth(medthick)), ///
    yline(0, lcolor(gs10) lpattern(dash)) ///
    title("Median Nominal GDP Growth Difference", ///
        color(black) size(medsmall)) ///
    subtitle("BIS-implied minus World Bank, by year", ///
        color(gs6) size(small)) ///
    xtitle("Year") ///
    ytitle("Percentage points") ///
    xlabel(1990(5)2025, labsize(small)) ///
    ylabel(, angle(horizontal) labsize(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(gdp_validation_median_difference, replace)

graph export ///
    "outputs/figures/nominal_gdp_validation_median_growth_difference.png", ///
    replace width(2400)
graph save ///
    "outputs/figures/nominal_gdp_validation_median_growth_difference.gph", ///
    replace
restore

/***********************************************************************
6. Graph: 95th percentile absolute growth difference by year
***********************************************************************/

preserve
keep if !missing(absolute_growth_difference)
collapse (p95) p95_abs_growth_difference=absolute_growth_difference ///
         (count) growth_observations=absolute_growth_difference, by(year)

twoway ///
    (line p95_abs_growth_difference year, ///
        lcolor(gs6) lwidth(medthick)), ///
    title("Upper-Tail Nominal GDP Growth Discrepancy", ///
        color(black) size(medsmall)) ///
    subtitle("95th percentile of absolute country-level differences", ///
        color(gs6) size(small)) ///
    xtitle("Year") ///
    ytitle("Absolute difference (percentage points)") ///
    xlabel(1990(5)2025, labsize(small)) ///
    ylabel(, angle(horizontal) labsize(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(gdp_validation_p95_difference, replace)

graph export ///
    "outputs/figures/nominal_gdp_validation_p95_growth_difference.png", ///
    replace width(2400)
graph save ///
    "outputs/figures/nominal_gdp_validation_p95_growth_difference.gph", ///
    replace
restore

/***********************************************************************
7. Graph: countries with the largest mean absolute growth differences
***********************************************************************/

preserve
use "data/processed/nominal_gdp_linked_validation_country_audit.dta", clear
gsort -mean_abs_growth_difference
keep in 1/15

graph hbar mean_abs_growth_difference, ///
    over(iso3c, sort(1) descending label(labsize(small))) ///
    bar(1, color(gs8)) ///
    title("Countries with Largest Mean GDP Growth Differences", ///
        color(black) size(medsmall)) ///
    subtitle("Top 15 by mean absolute difference", ///
        color(gs6) size(small)) ///
    ytitle("Mean absolute difference (percentage points)") ///
    ylabel(, labsize(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(gdp_val_country_mae, replace)

graph export ///
    "outputs/figures/nominal_gdp_validation_country_growth_mae.png", ///
    replace width(2400)
graph save ///
    "outputs/figures/nominal_gdp_validation_country_growth_mae.gph", ///
    replace
restore

/***********************************************************************
8. Graph: countries with the largest persistent level differences
***********************************************************************/

preserve
use "data/processed/nominal_gdp_linked_validation_country_audit.dta", clear
gsort -abs_median_level_deviation
keep in 1/15

graph hbar abs_median_level_deviation, ///
    over(iso3c, sort(1) descending label(labsize(small))) ///
    bar(1, color(gs8)) ///
    title("Largest Country-Level Nominal GDP Level Differences", ///
        color(black) size(medsmall)) ///
    subtitle("Top 15 absolute deviations of median level ratio from one", ///
        color(gs6) size(small)) ///
    ytitle("Absolute deviation from unity (%)") ///
    ylabel(, labsize(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    name(gdp_validation_country_level, replace)

graph export ///
    "outputs/figures/nominal_gdp_validation_country_level_deviation.png", ///
    replace width(2400)
graph save ///
    "outputs/figures/nominal_gdp_validation_country_level_deviation.gph", ///
    replace
restore

/***********************************************************************
9. Confirm all audit outputs
***********************************************************************/

foreach output in ///
    outputs/tables/nominal_gdp_linked_level_outliers_top20.csv ///
    outputs/tables/nominal_gdp_linked_growth_outliers_top20.csv ///
    outputs/tables/nominal_gdp_linked_validation_country_audit.csv ///
    data/processed/nominal_gdp_linked_validation_country_audit.dta ///
    outputs/figures/nominal_gdp_validation_scatter.png ///
    outputs/figures/nominal_gdp_validation_scatter.gph ///
    outputs/figures/nominal_gdp_validation_median_growth_difference.png ///
    outputs/figures/nominal_gdp_validation_median_growth_difference.gph ///
    outputs/figures/nominal_gdp_validation_p95_growth_difference.png ///
    outputs/figures/nominal_gdp_validation_p95_growth_difference.gph ///
    outputs/figures/nominal_gdp_validation_country_growth_mae.png ///
    outputs/figures/nominal_gdp_validation_country_growth_mae.gph ///
    outputs/figures/nominal_gdp_validation_country_level_deviation.png ///
    outputs/figures/nominal_gdp_validation_country_level_deviation.gph {
    capture confirm file "`output'"
    if _rc {
        display as error "Required audit output missing: `output'"
        log close audit_log
        exit 498
    }
}

display as result "Linked nominal-GDP outlier audit completed."
display as result "Five figures were exported separately as PNG and editable GPH files."
display as result "No observations were removed, winsorized, or adjusted."
log close audit_log
