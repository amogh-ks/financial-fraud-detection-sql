-- ============================================================================
-- PAYSim TRANSACTIONS: TABLE SETUP, IMPORT, AND INDEXES (PostgreSQL)
-- ============================================================================

-- Columns are lowercase for convenient unquoted PostgreSQL references.
-- Ensure the CSV column order matches this list before importing.
CREATE TABLE IF NOT EXISTS transactions (
    step             INTEGER NOT NULL,
    type             TEXT NOT NULL,
    amount           NUMERIC(20, 2) NOT NULL,
    nameorig         TEXT NOT NULL,
    oldbalanceorg    NUMERIC(20, 2) NOT NULL,
    newbalanceorig   NUMERIC(20, 2) NOT NULL,
    namedest         TEXT NOT NULL,
    oldbalancedest   NUMERIC(20, 2) NOT NULL,
    newbalancedest   NUMERIC(20, 2) NOT NULL,
    isfraud          SMALLINT NOT NULL,
    isflaggedfraud   SMALLINT NOT NULL
);

-- Run in psql; adjust the path to the downloaded PaySim CSV.
-- The CSV header row is skipped, but CSV header names are not matched by name.
\copy transactions (step, type, amount, nameorig, oldbalanceorg, newbalanceorig, namedest, oldbalancedest, newbalancedest, isfraud, isflaggedfraud) FROM 'data/PS_20174392719_1491204439457_log.csv' WITH (FORMAT csv, HEADER true)

-- Indexes used by filters, self-joins, and account-level analysis.
-- Index creation can take time and consume disk space on the full dataset.
CREATE INDEX IF NOT EXISTS idx_txns_type_step ON transactions(type, step);
CREATE INDEX IF NOT EXISTS idx_txns_nameorig ON transactions(nameorig);
CREATE INDEX IF NOT EXISTS idx_txns_namedest ON transactions(namedest);

-- Refresh planner statistics after loading and indexing.
ANALYZE transactions;
