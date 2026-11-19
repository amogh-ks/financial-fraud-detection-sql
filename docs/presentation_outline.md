# Presentation Outline: Banking Fraud Detection & Anomaly Analysis

Use this outline to create a PowerPoint presentation. Replace bracketed fields with measured results from `results/sample_outputs.md`; do not present placeholders as findings.

## Slide 1 — Title
**Banking Fraud Detection & Anomaly Analysis**  
PaySim transaction dataset · SQL investigation project

## Slide 2 — Objective and dataset
- Explore transaction patterns associated with the dataset's fraud labels.
- PaySim provides transaction type, amount, account identifiers, balances, simulation step, and fraud/flag indicators.
- Dataset size and exact version: **[fill in after import]**.
- Analysis is exploratory; a rule match is not proof of criminal activity.

## Slide 3 — Method overview
- PostgreSQL table and B-tree indexes for common filters and account joins.
- Seven query sections: distribution, timing, liquidation, chains, draining/structuring, mule candidates, and ledger/flag audits.
- Import assumptions and database version: **[fill in]**.

## Slide 4 — Fraud distribution
- Show query 1 results by transaction type.
- Highlight confirmed fraud totals, system-flag totals, fraud rate, and amount marked fraudulent.
- Key measured takeaway: **[fill in from actual output]**.

## Slide 5 — Timing patterns
- Plot fraud rate by `step % 24` for `TRANSFER` and `CASH_OUT`.
- State the observed high-rate bucket and its transaction count: **[fill in]**.
- Explain the 24-steps-per-day assumption.

## Slide 6 — Transfer to cash-out
- Diagram: origin account → transfer destination → cash-out origin.
- Query requires same amount and cash-out within zero or one step.
- Candidate pairs returned: **[fill in]**.
- Discuss false positives and missed amount/timing variants.

## Slide 7 — Chains, draining, and structuring
- Explain recursive transfer-chain hop depth.
- Show counts for chain depth and query 5 candidate rows: **[fill in]**.
- Distinguish balance draining from repeated small transfers.

## Slide 8 — Mule candidates and ledger audits
- Summarize destination accounts with multiple origins and fraud-marked activity: **[fill in]**.
- Summarize sender-freeze and destination-mismatch counts: **[fill in]**.
- Treat balance discrepancies as audit leads, not automatic fraud decisions.

## Slide 9 — Conclusions and next steps
- Evidence-based takeaway: **[fill in after execution]**.
- Validate candidates with transaction context and independent controls.
- Consider query-plan review, thresholds, time-window sensitivity, and model evaluation.

## Slide 10 — Reproducibility
- Point to `sql/01_schema_setup.sql` and `sql/02_fraud_analysis.sql`.
- Include dataset provenance, import row count, database version, and run date.
- Link to the report and measured outputs.
