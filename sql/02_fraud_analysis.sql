-- ============================================================================
-- BANKING FRAUD DETECTION & ANOMALY ANALYSIS (PAYSIM DATASET)
-- PostgreSQL-compatible SQL. Run sections independently as needed.
-- ============================================================================

-- ============================================================================
-- 1. EXECUTIVE OVERVIEW: FRAUD DISTRIBUTION BY TRANSACTION TYPE
-- ============================================================================
SELECT
    type,
    COUNT(*) AS total_transactions,
    SUM(isfraud) AS confirmed_frauds,
    SUM(isflaggedfraud) AS system_flagged_frauds,
    ROUND(100.0 * SUM(isfraud) / NULLIF(COUNT(*), 0), 4) AS fraud_rate_pct,
    SUM(CASE WHEN isfraud = 1 THEN amount ELSE 0 END) AS total_fraud_loss
FROM transactions
GROUP BY type
ORDER BY confirmed_frauds DESC;


-- ============================================================================
-- 2. TIME-OF-DAY VULNERABILITY ANALYSIS (HOURLY FRAUD SPIKES)
-- Assumes 24 steps per day and that step is hour-like.
-- ============================================================================
SELECT
    (step % 24) AS hour_of_day,
    COUNT(*) AS total_txns,
    SUM(isfraud) AS fraud_txns,
    ROUND(100.0 * SUM(isfraud) / NULLIF(COUNT(*), 0), 3) AS fraud_rate_pct
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY (step % 24)
ORDER BY fraud_rate_pct DESC;


-- ============================================================================
-- 3. THE "TRANSFER -> CASH_OUT" TWO-STEP LIQUIDATION PATTERN
-- Same amount, same intermediary account, within 0-1 steps.
-- ============================================================================
SELECT
    t1.step AS transfer_step,
    t2.step AS cashout_step,
    t1.nameorig AS victim_account,
    t1.namedest AS mule_account,
    t1.amount,
    t1.isfraud AS transfer_fraud,
    t2.isfraud AS cashout_fraud
FROM transactions t1
JOIN transactions t2
    ON t1.namedest = t2.nameorig
    AND t1.amount = t2.amount
    AND t2.step BETWEEN t1.step AND t1.step + 1
WHERE t1.type = 'TRANSFER'
  AND t2.type = 'CASH_OUT';


-- ============================================================================
-- 4. RECURSIVE MONEY-LAUNDERING CHAINS (MULTI-HOP FRAUDULENT TRANSFERS)
-- Restrict or add a maximum hop depth for large datasets if needed.
-- ============================================================================
WITH RECURSIVE fraud_chain AS (
    -- Anchor: starting fraudulent transfer
    SELECT
        nameorig AS initial_account,
        namedest AS next_account,
        step,
        amount,
        newbalanceorig,
        1 AS hop_depth
    FROM transactions
    WHERE isfraud = 1
      AND type = 'TRANSFER'

    UNION ALL

    -- Recursive member: follow later fraudulent transfers from next account
    SELECT
        fc.initial_account,
        t.namedest,
        t.step,
        t.amount,
        t.newbalanceorig,
        fc.hop_depth + 1
    FROM fraud_chain fc
    JOIN transactions t
        ON fc.next_account = t.nameorig
        AND fc.step < t.step
    WHERE t.isfraud = 1
      AND t.type = 'TRANSFER'
)
SELECT *
FROM fraud_chain
ORDER BY hop_depth DESC, initial_account, step;


-- ============================================================================
-- 5. ACCOUNT DRAINING & SMALL-TRANSFER STRUCTURING ("SMURFING")
-- RANGE frame uses the numeric step difference; rows at the same step are peers.
-- ============================================================================
WITH structuring_check AS (
    SELECT
        nameorig,
        namedest,
        type,
        step,
        amount,
        oldbalanceorg,
        newbalanceorig,
        isfraud,
        COUNT(*) OVER (
            PARTITION BY nameorig
            ORDER BY step
            RANGE BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS txns_in_5hr_window,
        SUM(amount) OVER (
            PARTITION BY nameorig
            ORDER BY step
            RANGE BETWEEN 5 PRECEDING AND CURRENT ROW
        ) AS total_amount_in_window
    FROM transactions
    WHERE type IN ('TRANSFER', 'CASH_OUT')
)
SELECT *
FROM structuring_check
WHERE
    (oldbalanceorg > 0 AND newbalanceorig = 0)
    OR
    (amount <= 200000 AND txns_in_5hr_window >= 3)
ORDER BY total_amount_in_window DESC;


-- ============================================================================
-- 6. MULE ACCOUNT IDENTIFICATION (DESTINATION AGGREGATION)
-- ============================================================================
SELECT
    namedest AS mule_account,
    COUNT(DISTINCT nameorig) AS unique_victims,
    COUNT(*) AS incoming_txns,
    SUM(amount) AS total_stolen_received,
    SUM(isfraud) AS confirmed_fraud_count
FROM transactions
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY namedest
HAVING COUNT(DISTINCT nameorig) > 1
   AND SUM(isfraud) > 0
ORDER BY total_stolen_received DESC;


-- ============================================================================
-- 7. LEDGER & SYSTEM FLAG ANOMALIES
-- ============================================================================
WITH large_transfers AS (
    SELECT nameorig, step, amount
    FROM transactions
    WHERE type = 'TRANSFER'
      AND amount > 500000
),
no_balance_change AS (
    SELECT nameorig, step, oldbalanceorg, newbalanceorig
    FROM transactions
    WHERE oldbalanceorg = newbalanceorig
),
flagged_transactions AS (
    SELECT nameorig, step
    FROM transactions
    WHERE isflaggedfraud = 1
),
dest_ledger_mismatch AS (
    SELECT nameorig, namedest, step, amount, oldbalancedest, newbalancedest
    FROM transactions
    WHERE type IN ('TRANSFER', 'CASH_OUT')
      AND (oldbalancedest + amount) <> newbalancedest
)
-- Query 7A: large flagged transfers where sender balance did not change
SELECT
    lt.nameorig,
    lt.step,
    lt.amount,
    'Flagged & Frozen Sender Balance' AS anomaly_type
FROM large_transfers lt
JOIN no_balance_change nbc
    ON lt.nameorig = nbc.nameorig AND lt.step = nbc.step
JOIN flagged_transactions ft
    ON lt.nameorig = ft.nameorig AND lt.step = ft.step

UNION ALL

-- Query 7B: destination balance arithmetic mismatch
SELECT
    nameorig,
    step,
    amount,
    'Destination Balance Math Mismatch' AS anomaly_type
FROM dest_ledger_mismatch
LIMIT 1000;
