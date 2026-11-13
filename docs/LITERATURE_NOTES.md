# Literature notes

These notes identify the literature that motivates the project. They are a focused working review, not a systematic review or a claim of novelty. The project should be positioned as a transparent empirical panel exercise connected to established macro-finance research.

## 1. Credit booms, leverage and financial crises

### Schularick and Taylor (2012)

**Reference:** Schularick, M. and Taylor, A. M. (2012). "Credit Booms Gone Bust: Monetary Policy, Leverage Cycles, and Financial Crises, 1870–2008." *American Economic Review*, 102(2), 1029–1061. https://doi.org/10.1257/aer.102.2.1029

**Contribution relevant to this project:** The paper documents the importance of credit and leverage cycles for financial crises using a long historical panel of advanced economies. It helps establish why financial-cycle measures should be studied alongside conventional business-cycle indicators.

**Connection and distinction:** The current project does not estimate crisis probabilities or reproduce the paper's historical crisis database. It studies whether a BIS credit-to-GDP gap is associated with subsequent annual GDP growth.

### Jordà, Schularick and Taylor (2013)

**Reference:** Jordà, Ò., Schularick, M. and Taylor, A. M. (2013). "When Credit Bites Back." *Journal of Money, Credit and Banking*, 45(s2), 3–28. https://doi.org/10.1111/jmcb.12069

**Contribution relevant to this project:** Using 14 advanced economies over 1870–2008, the authors document that financial-crisis recessions are more costly and that more credit-intensive expansions tend to be followed by deeper recessions and slower recoveries. They use local projections and a broad set of macroeconomic controls to study output and other outcomes.

**Connection and distinction:** This is a close conceptual reference for studying the future macroeconomic consequences of credit conditions. The current project uses the BIS credit-to-GDP gap as the financial-cycle indicator and estimates horizon-specific predictive panel regressions. It does not reproduce the authors' local-projection design or crisis classification.

## 2. Household debt and subsequent macroeconomic outcomes

### Mian, Sufi and Verner (2017)

**Reference:** Mian, A., Sufi, A. and Verner, E. (2017). "Household Debt and Business Cycles Worldwide." *The Quarterly Journal of Economics*, 132(4), 1755–1817. https://doi.org/10.1093/qje/qjx017

**Contribution relevant to this project:** The paper uses an unbalanced panel of 30 countries over 1960–2012. Increases in the household debt-to-GDP ratio predict lower GDP growth and higher unemployment in the medium run. The authors also examine credit-supply conditions and monetary-policy constraints.

**Connection and distinction:** The paper is a direct precedent for relating private debt measures to subsequent output growth. Its household-debt measure is narrower than the BIS private non-financial-sector credit gap used here. Its identification strategy and distributed-horizon analysis are also more developed than the current project's baseline.

## 3. Financialization and business-cycle characteristics

### Jordà, Schularick and Taylor (2017)

**Reference:** Jordà, Ò., Schularick, M. and Taylor, A. M. (2017). "Macrofinancial History and the New Business Cycle Facts." *NBER Macroeconomics Annual*, 31, 213–263. https://doi.org/10.1086/690241

**Contribution relevant to this project:** The authors document relationships between financial leverage and business-cycle moments, including growth, real volatility, tail risk and the co-movement of real and financial cycles.

**Connection and distinction:** This paper supports the macro-finance framing of the project. It also reminds us that the relationship between financial conditions and the macroeconomy is broader than a single regression coefficient.

## 4. Credit-gap measurement

### Drehmann and Yetman (2021)

**Reference:** Drehmann, M. and Yetman, J. (2021). "Which Credit Gap Is Better at Predicting Financial Crises? A Comparison of Univariate Filters." *International Journal of Central Banking*, 17(4), 1–31. Earlier version: BIS Working Paper 878 (2020). https://www.ijcb.org/journal/v17n4/which-credit-gap-better-predicting-financial-crises-comparison-univariate-filters

**Contribution relevant to this project:** The paper compares alternative credit-gap constructions using quarterly data for 41 economies. It discusses criticisms of the one-sided HP-filtered credit-to-GDP gap, including endpoint behavior and the fact that normalizing credit by GDP can induce a negative relationship with output.

**Connection and distinction:** This is essential for interpreting the project's principal explanatory variable. The BIS credit gap is an established financial-vulnerability indicator, but it is not a directly observed structural measure of credit supply. Its GDP denominator creates a potential mechanical relationship with output. The baseline therefore controls for current and lagged GDP growth, but these controls do not eliminate the measurement issue or provide causal identification.

## 5. Implications for the present research design

The literature supports studying the relationship between financial-cycle conditions and subsequent macroeconomic performance. It also establishes that credit booms, debt accumulation, leverage and credit gaps are related but distinct concepts.

The current project makes a deliberately modest empirical choice:

- Use the BIS credit-to-GDP gap as the main financial-cycle indicator.
- Use annual real GDP growth as the primary macroeconomic outcome.
- Estimate one-year-ahead growth as the primary specification, with two- and three-year horizons as extensions.
- Include current and lagged GDP growth, inflation, country fixed effects and outcome-year fixed effects.
- Separate positive and negative credit gaps to test whether the conditional relationship is asymmetric.
- Treat estimates as predictive associations, not causal effects.

The project does not claim to identify credit-supply shocks, monetary-policy transmission, speculative credit allocation, or the causal effect of leverage on output. Those questions require additional data and identification strategies.

## Reading priority

For efficient preparation, read in this order:

1. Jordà, Schularick and Taylor (2013): understand the credit-cycle-to-output relationship and horizon-based empirical reasoning.
2. Mian, Sufi and Verner (2017): understand a closely related cross-country debt-growth design.
3. Drehmann and Yetman (2021): understand the measurement caveats of the credit gap used in this project.
4. Schularick and Taylor (2012): understand the broader historical credit-cycle and crisis literature.
5. Jordà, Schularick and Taylor (2017): deepen the macro-finance framing.
