-- How did deposits, margin and bad loans move versus last quarter and last year?
-- LAG over rows would skip a missing quarter, so every lag checks the quarter counter.
DROP VIEW IF EXISTS changes;
CREATE VIEW changes AS
WITH lagged AS (
    SELECT
        CERT, REPDTE, qidx, DEP, NIMY, NCLNLSR,
        LAG(qidx, 1) OVER w AS q1_idx,
        LAG(qidx, 2) OVER w AS q2_idx,
        LAG(qidx, 4) OVER w AS q4_idx,
        LAG(NCLNLSR, 1) OVER w AS ncl_q1,
        LAG(NCLNLSR, 2) OVER w AS ncl_q2,
        LAG(NCLNLSR, 4) OVER w AS ncl_q4,
        LAG(DEP, 4) OVER w AS dep_q4,
        LAG(NIMY, 4) OVER w AS nim_q4
    FROM bank_quarters
    WINDOW w AS (PARTITION BY CERT ORDER BY qidx)
)
SELECT
    CERT, REPDTE, qidx,
    CASE WHEN q4_idx = qidx - 4 AND dep_q4 > 0
         THEN 100.0 * (DEP - dep_q4) / dep_q4 END AS dep_yoy_pct,
    CASE WHEN q4_idx = qidx - 4 THEN NIMY - nim_q4 END AS nim_yoy_chg,
    CASE WHEN q1_idx = qidx - 1 THEN NCLNLSR - ncl_q1 END AS ncl_qoq_chg,
    CASE WHEN q4_idx = qidx - 4 THEN NCLNLSR - ncl_q4 END AS ncl_yoy_chg,
    -- 1 only if noncurrent loans rose two quarters running with no gap
    CASE WHEN q1_idx = qidx - 1 AND q2_idx = qidx - 2
              AND NCLNLSR > ncl_q1 AND ncl_q1 > ncl_q2
         THEN 1 ELSE 0 END AS ncl_rising_2q
FROM lagged;
