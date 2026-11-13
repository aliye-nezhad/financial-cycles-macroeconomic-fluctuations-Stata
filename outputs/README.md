# Outputs

The main Stata analysis has completed successfully. The uploaded execution log confirms that the expected tables, figures, processed dataset and logs were generated locally and that the final file-existence checks passed. The baseline, asymmetric, measurement, pandemic, control-variable and country-influence specifications have all been executed. The numerical findings are summarized in [docs/RESULTS.md](../docs/RESULTS.md).

The generated output artifacts have not yet been committed. The PNG figures must be visually inspected before they are treated as final presentation outputs. The optional wild cluster bootstrap diagnostic is run separately with Stata 15.1 or later and David Roodman's `boottest` package; it writes `tables/wild_cluster_bootstrap.txt`.

Expected outputs:

- tables/sample_coverage.txt
- tables/descriptive_statistics.txt
- tables/correlation_matrix.txt
- tables/baseline_models.txt
- tables/asymmetric_model.txt
- tables/robustness_models.txt
- tables/influence_sensitivity.txt
- tables/wild_cluster_bootstrap.txt (optional; Stata 15.1+ with boottest)
- figures/mean_credit_gap_by_year.png
- figures/mean_credit_gap_by_year.gph
- figures/credit_gap_gdp_scatter.png
- figures/credit_gap_gdp_scatter.gph
- logs/analysis.log

These files are descriptive and inferential outputs from the specified observational design. They must not be described as causal estimates.


Both figures are stored separately under distinct Stata graph names. The do-file explicitly passes each graph name to `graph export` and `graph save`, rather than relying on the active Graph window. Each figure has its own PNG and native Stata `.gph` file. The final `graph dir` command lists the two named graphs retained in memory. Re-running the script replaces only the corresponding figure's own files.
