# Banking Fraud Detection & Anomaly Analysis — Report

## Executive summary

This project uses SQL to investigate potential fraud patterns in the PaySim mobile-money dataset. Its seven analyses compare transaction types and fraud labels, inspect time buckets, search for transfer-to-cash-out sequences, trace marked fraudulent transfer chains, identify draining and repeated small-transfer behavior, rank destination accounts with multiple senders, and audit selected balance and system-flag inconsistencies.

The repository does not include computed findings. Run the scripts against the dataset and enter measured figures in `results/sample_outputs.md` before treating this report as a results-based assessment.

## Method

The schema is designed for PostgreSQL and includes numeric balance/amount fields and indexes on transaction type/time and origin/destination account names. Analysis queries use aggregation, conditional sums, a self-join, a recursive CTE, window frames, `HAVING`, and CTE/`UNION ALL` combinations.

The analysis assumes 24 PaySim steps represent a day for the hour bucket calculation. It also treats a transfer and subsequent same-amount cash-out through the receiving account within one step as a candidate liquidation sequence. These are investigative heuristics and are not conclusive classifications.

## Analysis sections

1. **Executive overview:** counts transactions and fraud labels by type and sums the amounts on rows marked fraudulent.
2. **Timing:** calculates fraud rates by `step % 24` for transfers and cash-outs.
3. **Two-step liquidation:** links a transfer destination to a later cash-out origin and requires the same amount.
4. **Transfer chains:** recursively follows later fraudulent transfers from an account that received a fraudulent transfer.
5. **Draining and structuring:** detects origin balances ending at zero and multiple small transactions inside a five-step range.
6. **Mule candidates:** groups transfer/cash-out destinations and requires multiple distinct origins and confirmed fraud rows.
7. **Ledger and flag audits:** surfaces large flagged transfers with unchanged origin balances and destination balance arithmetic mismatches.

## Limitations

- A rule match is a lead for review, not proof of fraud or money laundering.
- Exact amount matching and limited time windows can miss activity that changes amount, routing, or timing.
- The chain query includes only transactions labeled fraudulent and may produce many paths on a large dataset.
- Balance arithmetic can have legitimate exceptions in the simulation. Interpret mismatches in the context of transaction type and dataset semantics.
- Results and query performance depend on the dataset variant, import order, database version, indexes, and query plan.

## Results

Add dataset metadata and actual query outputs from `results/sample_outputs.md` here. Avoid reporting unverified numbers.

## PDF export

This Markdown is ready to copy into a document editor or convert with a Markdown-to-PDF tool. Review page breaks, tables, and code references after export.
