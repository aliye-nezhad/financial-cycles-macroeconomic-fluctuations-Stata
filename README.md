# Financial Cycles and Macroeconomic Fluctuations: Cross-Country Evidence from Credit-to-GDP Gaps

This repository contains a reproducible Stata project examining whether the BIS credit-to-GDP gap predicts subsequent real GDP growth across economies. The empirical design uses an unbalanced annual country panel, country fixed effects, outcome-year fixed effects, and country-clustered standard errors.

The project is an observational predictive exercise. Its estimates describe conditional associations; they do not identify causal effects of credit supply, monetary policy, or financial shocks.

## Research question

Do credit-to-GDP gaps predict subsequent macroeconomic fluctuations across countries, and does the relationship differ between above-trend and below-trend credit conditions?

The primary outcome is annual real GDP growth. The principal financial-cycle indicator is the BIS credit-to-GDP gap, defined as the difference between the credit-to-GDP ratio and its one-sided long-run trend. The gap is measured in percentage points of GDP.

## Empirical design

The baseline horizon-specific specification is:

\[
g_{i,t+h}=\alpha_i+\lambda_{t+h}
+\beta_h Gap_{i,t}
+\rho_h g_{i,t}
+\delta_h g_{i,t-1}
+\gamma_h \pi_{i,t}
+\varepsilon_{i,t+h},
\]

where \(g\) is annual real GDP growth, \(Gap\) is the BIS credit-to-GDP gap, \(\pi\) is CPI inflation, \(\alpha_i\) denotes country fixed effects, and \(\lambda_{t+h}\) denotes fixed effects for the outcome year. Current and lagged GDP growth are included to condition on output-growth persistence and to address, but not eliminate, concerns arising from GDP's appearance in the credit-to-GDP denominator. The primary horizon is one year ahead; two- and three-year-ahead specifications are extensions. Standard errors are clustered by country.

An asymmetric specification separates positive and negative credit gaps. A robustness specification uses the annual mean of the four quarterly gap observations rather than the fourth-quarter observation.

These are in-sample predictive regressions, not causal designs or out-of-sample forecasting tests. Outcome-year fixed effects are estimated using realized observations; their fitted coefficients are not available for an unseen future forecast year. The BIS gap is an indicator of the financial cycle and potential excessive credit accumulation; it is not an exogenous monetary-policy shock.

## Data

The observation window is 1990–2024. The BIS reports 44 economies in its credit-gap dataset; the euro-area aggregate is excluded so that the analytical sample contains 43 individual economies. The downloaded vintage contains 1,377 Q4 country-year observations. After requiring current and previous-year GDP growth, inflation and the future outcome, the one-year-ahead complete-case sample contains 1,310 observations; see the data audit for the full horizon-specific counts.

| Variable | Source | Indicator or series |
|---|---|---|
| Credit-to-GDP gap | Bank for International Settlements | WS_CREDIT_GAP; quarterly; private non-financial sector borrowers; all lenders; actual-minus-trend gap |
| Real GDP growth | World Bank, World Development Indicators | NY.GDP.MKTP.KD.ZG |
| CPI inflation | World Bank, World Development Indicators | FP.CPI.TOTL.ZG |
| Nominal GDP (archival comparison) | World Bank, World Development Indicators | NY.GDP.MKTP.CN (unlinked current LCU) |
| Nominal GDP (preferred linked validation) | World Bank, World Development Indicators | NY.GDP.MKTP.CN.AD (linked current LCU) |

The BIS credit-gap measure covers borrowing from domestic and foreign sources and is not restricted to bank lending. It is calculated as the credit-to-GDP ratio minus a one-sided, backward-looking Hodrick–Prescott trend. The measure may differ from national-authority credit-gap estimates.

Source documentation, download instructions, transformations, and attribution requirements are recorded in [data/README.md](data/README.md).

## Repository structure

```text
├── .github/workflows/
│   ├── data-acquisition.yml
│   └── reproducibility.yml
├── data/
│   ├── raw/
│   ├── processed/
│   ├── DATA_VINTAGE.md
│   ├── raw.sha256
│   └── README.md
├── docs/
│   ├── DATA_AUDIT.md
│   ├── LITERATURE_NOTES.md
│   ├── EXECUTION_VERIFICATION.md
│   ├── OUTPUT_REVIEW.md
│   ├── RESEARCH_DESIGN.md
│   ├── RESEARCH_BRIEF.md
│   ├── RESEARCH_NOTE_DRAFT.md
│   ├── RESULTS.md
│   └── REPRODUCIBILITY.md
├── outputs/
│   ├── figures/
│   ├── logs/
│   ├── tables/
│   └── README.md
└── replication/
    ├── balanced_panel_sensitivity.do
    ├── audit_nominal_gdp_linked.do
    ├── denominator_diagnostic.do
    ├── download_denominator_sources.ps1
    ├── download_data.do
    ├── download_nominal_gdp.ps1
    ├── download_linked_nominal_gdp.ps1
    ├── inference_diagnostics.do
    ├── run_analysis.do
    ├── validate_balanced_panel_samples.do
    ├── validate_nominal_gdp.do
    └── validate_nominal_gdp_linked.do
```

## Reproducing the project

A licensed installation of Stata 15.1 or later is required. The main analysis and supplementary measurement diagnostics use built-in Stata commands. The optional wild cluster bootstrap diagnostic requires David Roodman's user-written `boottest` package.

Clone the repository and change the working directory to its root:

```bash
git clone https://github.com/aliye-nezhad/financial-cycles-macroeconomic-fluctuations-Stata.git
cd financial-cycles-macroeconomic-fluctuations-Stata
```

Download the source data:

```stata
do replication/download_data.do
```

Run the main analysis:

```stata
do replication/run_analysis.do
```

The supplementary diagnostics can then be run separately:

```stata
do replication/denominator_diagnostic.do
do replication/inference_diagnostics.do
do replication/validate_nominal_gdp.do
do replication/validate_nominal_gdp_linked.do
do replication/audit_nominal_gdp_linked.do
do replication/balanced_panel_sensitivity.do

* Optional: rerun only the linked-GDP sample comparison
do replication/validate_balanced_panel_samples.do
```

The inference diagnostic requires a working installation of David Roodman's `boottest` package. It loads the installed Mata source before estimation and, when the denominator-components panel exists, also tests the matched-sample baseline and numerator-denominator model. Run the denominator diagnostic first to enable those additional tests. The denominator diagnostic downloads additional BIS credit and ratio series, checks their alignment with the main gap data, reconstructs the trailing-four-quarter nominal-GDP denominator, and produces a matched-sample component analysis. The linked nominal-GDP validation compares that reconstructed denominator with World Bank linked GDP in current local currency. The follow-up `replication/audit_nominal_gdp_linked.do` reports the largest country-year discrepancies and exports five separately named monochrome figures. The combined `replication/balanced_panel_sensitivity.do` reruns the baseline and asymmetric regressions across four samples and compares linked-GDP validation across the same country-period definitions. The standalone `replication/validate_balanced_panel_samples.do` reruns only the linked-GDP sample comparison when the regression section has already been completed. Both scripts use the 2006–2024 calendar-year window for common-period levels and growth. The 2006 growth rate uses the 2005 GDP level only as its lag input; the observation remains indexed to 2006. See [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for the execution sequence.

The repository also includes a GitHub Actions data-acquisition workflow for the main-analysis sources. It can be run manually from the Actions tab or triggered by adding the data/ACQUIRE_DATA marker file. The workflow downloads, validates, checksums and commits those source files to the private repository. The supplementary BIS series and both unlinked and linked World Bank nominal-GDP indicators have separate acquisition helpers and are checked in the Windows CI job. The WDI checks verify the requested indicator code, required year columns, archive/CSV checksums, and no-refresh idempotence. The Stata download scripts preserve existing raw archives by default; set their refresh option to 1 only when intentionally retrieving a new vintage. Retrieval dates and checksums are retained with the relevant source files.

See [docs/LITERATURE_NOTES.md](docs/LITERATURE_NOTES.md) for the focused annotated literature review, [docs/RESEARCH_DESIGN.md](docs/RESEARCH_DESIGN.md) for the hypotheses and specifications, [docs/DATA_AUDIT.md](docs/DATA_AUDIT.md) for the actual source-data coverage and expected sample counts, and [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md) for execution instructions. The concise [research brief](docs/RESEARCH_BRIEF.md) summarizes the confirmed findings and limitations. The longer [research-note draft](docs/RESEARCH_NOTE_DRAFT.md) provides methodological detail. The [output review](docs/OUTPUT_REVIEW.md) documents inspection of the fourteen generated PNGs, the two top-20 outlier tables, execution logs, and the remaining release conditions.

## Output publication and final execution status

The project contains **five reviewed numerical/audit CSVs**, **14 PNG figures** and **14 editable Stata GPH figures**, all committed to the repository. The figures were inspected for legibility, labeling and consistency with the numerical summaries. The final combined `replication/balanced_panel_sensitivity.do` was run successfully in **Stata 17 on 14 November 2026**: all 12 linear regressions, four asymmetric models and four linked-GDP sample validations completed, all requested files were generated, and no terminal Stata error occurred. The uploaded execution log was checked directly; its SHA-256 and numerical summaries are preserved in [the execution-verification record](docs/EXECUTION_VERIFICATION.md).

The full output assessment is in [docs/OUTPUT_REVIEW.md](docs/OUTPUT_REVIEW.md). The optional `replication/publish_reviewed_figures.ps1` helper can republish a *new* reviewed graph export from the local computer using an isolated Git worktree; **it is not necessary to rerun it for the current published figures**.

## Current status

**Research-portfolio release: ready.** The source-data acquisition and internal audit, 43-economy main regressions, wild cluster bootstrap checks, numerator/denominator diagnostics, balanced and common-period sensitivities, linked-GDP measurement validation and focused outlier audits are complete. The exact five reviewed CSV tables and all 28 figure exports are available in this repository. The Stata results are consistent with the checked-in tables.

The full-sample annual real-GDP-growth coefficients for one, two and three years ahead are **−0.02280**, **−0.02901** and **−0.02675** (43 country clusters; N = 1,310, 1,267 and 1,224). All twelve linear credit-gap coefficients across the four sample definitions and three horizons are negative and significant at 1% under conventional country-clustered inference. The asymmetric H1 slope-difference tests reject equality in the two full-period samples, but not in either common 2006–2024 sample at 5% (p = **0.22805** for 31 countries and **0.08793** for all 43). The asymmetry therefore **is not invariant to the time window**.

For the 43-country 2006–2024 linked nominal-GDP comparison, **817** country-year GDP levels and **815** annual growth rates match; Brazil and Colombia lack the BIS-implied growth value for their 2006 entry year. No missing observations are imputed. See the [full results](docs/RESULTS.md), [research brief](docs/RESEARCH_BRIEF.md) and [numerical tables](outputs/tables/).

These estimates are **conditional in-sample associations**. They do not establish causality, demonstrate real-time forecast accuracy or identify a structural credit-supply mechanism. GitHub Actions validates source-data acquisition, static structure, and published CSV formats; it does not independently execute licensed Stata. The verified local Stata 17 run is separately documented. An exact third-party raw-data replay remains a different standard from a validated portfolio release.

## Data attribution

BIS statistics are reproduced with attribution to the Bank for International Settlements. World Bank indicators are attributed to the World Bank's World Development Indicators. Data-source terms and retrieval details are documented in the data notes. This repository does not imply endorsement by either institution.

## License

The MIT License applies to the original code and documentation in this repository. Third-party datasets remain subject to their respective source terms.
