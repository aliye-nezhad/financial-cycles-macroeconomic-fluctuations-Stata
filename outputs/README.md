# Outputs

The main Stata analysis has completed successfully. The uploaded execution log confirms that the expected tables, figures, processed dataset and logs were generated locally and that the final file-existence checks passed. The baseline, asymmetric, measurement, pandemic, control-variable and country-influence specifications have all been executed. The numerical findings are summarized in [docs/RESULTS.md](../docs/RESULTS.md).

The analysis now exports four separate figures:

1. `mean_credit_gap_by_year.png` — the annual unweighted mean BIS credit-to-GDP gap across available economies.
2. `credit_gap_gdp_scatter.png` — the pooled, unconditional relationship between the credit gap and GDP growth one year ahead. This is descriptive and is not the fixed-effects estimate.
3. `fe_horizon_coefficients.png` — the estimated credit-gap coefficients from the one-, two-, and three-year-ahead country and outcome-year fixed-effects models, with country-clustered 95% confidence intervals. This is the main model-based figure.
4. `asymmetric_gap_coefficients.png` — the positive- and negative-gap coefficients from the asymmetric one-year-ahead fixed-effects model, with country-clustered 95% confidence intervals.

Each PNG has a separately named native Stata `.gph` counterpart for editing. The do-file explicitly supplies the graph name to each export and save command, then lists all four names with `graph dir`. Stata's Graph window displays one active graph at a time; switching the active display does not mean that the other graph's file has been replaced. To compare the figures simultaneously, open the four PNG files from `outputs/figures/` in separate image windows.

The generated output artifacts have not yet been committed. All six PNGs (four main-analysis figures and two denominator-diagnostic figures) still need visual inspection before they are treated as final presentation outputs. The wild cluster bootstrap diagnostic is run separately with Stata 15.1 or later and David Roodman's `boottest` package; after the denominator panel exists, it also tests the matched-sample baseline and numerator-denominator component model. It writes `tables/wild_cluster_bootstrap.txt`.

Expected outputs:

- `tables/sample_coverage.txt`
- `tables/descriptive_statistics.txt`
- `tables/correlation_matrix.txt`
- `tables/baseline_models.txt`
- `tables/asymmetric_model.txt`
- `tables/robustness_models.txt`
- `tables/influence_sensitivity.txt`
- `tables/wild_cluster_bootstrap.txt` (optional; Stata 15.1+ with boottest)
- `figures/mean_credit_gap_by_year.png`
- `figures/mean_credit_gap_by_year.gph`
- `figures/credit_gap_gdp_scatter.png`
- `figures/credit_gap_gdp_scatter.gph`
- `figures/fe_horizon_coefficients.png`
- `figures/fe_horizon_coefficients.gph`
- `figures/asymmetric_gap_coefficients.png`
- `figures/asymmetric_gap_coefficients.gph`
- `logs/analysis.log`

## Optional denominator diagnostic outputs

Running `replication/denominator_diagnostic.do` after the main analysis creates a separate set of supplementary outputs. The script completed successfully on 13 November 2026. The supplied Stata log confirms that the source-alignment checks passed, both matched-sample regressions ran, and the two figures were exported separately. The generated files are local and have not yet been committed:

- `tables/denominator_decomposition.txt` — source-alignment checks, reconstructed denominator, and annual component-growth summaries.
- `tables/denominator_component_models.txt` — matched-sample baseline and numerator-denominator predictive regressions.
- `figures/ratio_component_growth.png` and `figures/ratio_component_growth.gph` — annual mean changes in nominal credit, implied nominal GDP, and the credit-to-GDP ratio.
- `figures/ratio_component_coefficients.png` and `figures/ratio_component_coefficients.gph` — matched-sample component-model coefficients and 95% confidence intervals.
- `logs/denominator_diagnostic.log` — execution record.
- `../data/processed/denominator_components_panel.dta` — matched annual panel with the reconstructed denominator and component growth rates.

The source-alignment checks must be reviewed before interpreting the component regressions. The diagnostic does not alter the main analysis outputs.

These are descriptive and inferential outputs from the specified observational design. They must not be described as causal estimates.
