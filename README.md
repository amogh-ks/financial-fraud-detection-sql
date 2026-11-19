# Banking Fraud Detection & Anomaly Analysis (PaySim)

A PostgreSQL SQL project for exploring fraud patterns in the PaySim mobile-money transaction dataset. The analysis focuses on fraud distribution, timing, transfer-to-cash-out liquidation, multi-hop transfer chains, account draining and structuring, mule accounts, and ledger/flag anomalies.

> **Dataset note:** This project assumes the PaySim CSV has been loaded into the `transactions` table using the column order and types in [`sql/01_schema_setup.sql`](sql/01_schema_setup.sql). Confirm the source dataset's headers and ordering before importing.

## Repository contents

- `sql/01_schema_setup.sql` — table definition, import command, and indexes.
- `sql/02_fraud_analysis.sql` — seven fraud-analysis queries.
- `results/sample_outputs.md` — results template; populate it after running against the dataset. No findings are fabricated here.
- `docs/fraud_analysis_report.md` — printable report text that can be exported to PDF.
- `docs/presentation_outline.md` — slide-by-slide presentation content to use in PowerPoint or another slide editor.

## Quick start

1. Download the PaySim CSV from its authorized source and place it at `data/PS_20174392719_1491204439457_log.csv` (or update the import path in the schema script).
2. In `sql/01_schema_setup.sql`, run the `CREATE TABLE` statement, then execute the `\copy` command from `psql` with the correct file path. The CSV columns must be in the table's defined order; PostgreSQL's CSV header option skips the header row but does not map columns by header name.
3. Run `sql/02_fraud_analysis.sql` in `psql` or a PostgreSQL client. The recursive chain query and account-level aggregations may be expensive on the full dataset.
4. Record measured results and query environment in `results/sample_outputs.md`.

```sh
psql -d your_database -f sql/01_schema_setup.sql
psql -d your_database -f sql/02_fraud_analysis.sql
```

The `\copy` line is a `psql` client command, not standalone SQL; execute it from `psql` if your client does not process it when reading a file.

## Analysis guide

| Section | SQL technique | Purpose |
|---|---|---|
| 0. Indexes | B-tree indexes | Supports common type/step filters, account lookups, joins, and partitions. Actual performance depends on the query plan and data. |
| 1. Executive overview | `GROUP BY`, conditional `SUM` | Compares transaction counts, confirmed fraud, system flags, fraud rates, and fraud amount by type. |
| 2. Timing | Modulo and aggregation | Shows fraud rates by hour-of-day bucket (`step % 24`) for transfers and cash-outs. |
| 3. Two-step liquidation | Self-join | Finds same-amount transfer/cash-out pairs through the destination account within zero or one step. |
| 4. Transfer chains | Recursive CTE | Follows subsequent fraudulent transfers and reports hop depth. |
| 5. Draining and structuring | Window frames | Finds transactions that reduce an origin balance to zero and clusters of small transactions within a five-step range. |
| 6. Mule candidates | Grouping and `HAVING` | Finds destinations with multiple origin accounts and at least one confirmed fraud transaction. |
| 7. Ledger/flag audits | CTEs and `UNION ALL` | Reports large flagged transfers with unchanged sender balances and destination balance arithmetic mismatches. |

## Interpretation and caveats

- PaySim's `step` is a simulation time unit; this analysis treats 24 steps as a day and one step as an hour, as commonly interpreted for this dataset. Validate this assumption for your data variant.
- A matching transfer and cash-out is a candidate pattern, not proof of fraud. The exact-amount and one-step conditions can miss laundering behavior that changes amount or timing.
- Recursive results can grow rapidly. They trace only rows marked `isfraud = 1` and `type = 'TRANSFER'`; they are not a general all-account flow graph.
- The structuring window is defined over `step` and includes rows sharing a step. `RANGE` support and behavior depend on the database; this script targets PostgreSQL-compatible behavior.
- `isflaggedfraud` is a system flag and should not be treated as equivalent to confirmed fraud (`isfraud`).
- Query results depend on dataset version, database engine, import correctness, and column types. The indexes help selected access patterns but do not guarantee a particular speedup.
