-- Which banks fail all three tests in the latest quarter?
-- Deposits down year over year, noncurrent loans up two quarters running,
-- and net interest margin in the bottom decile of the bank's size peer group.
WITH latest AS (
    SELECT MAX(REPDTE) AS repdte FROM financials
),
deposits_down AS (
    SELECT c.CERT FROM changes AS c, latest
    WHERE c.REPDTE = latest.repdte AND c.dep_yoy_pct < 0
),
bad_loans_rising AS (
    SELECT c.CERT FROM changes AS c, latest
    WHERE c.REPDTE = latest.repdte AND c.ncl_rising_2q = 1
),
thin_margin AS (
    SELECT p.CERT FROM peer_ranks AS p, latest
    WHERE p.REPDTE = latest.repdte AND p.nim_decile = 1
)
SELECT
    p.CERT, p.NAME, p.STALP, p.peer_group,
    ROUND(p.ASSET / 1000.0, 0) AS assets_millions,
    ROUND(c.dep_yoy_pct, 2) AS dep_yoy_pct,
    ROUND(p.NCLNLSR, 2) AS noncurrent_loans_pct,
    ROUND(c.ncl_yoy_chg, 2) AS ncl_yoy_chg,
    ROUND(p.NIMY, 2) AS nim_pct,
    ROUND(p.ROA, 2) AS roa_pct,
    ROUND(r.roa_4q, 2) AS roa_4q_avg,
    p.roa_rank, p.peer_size
FROM peer_ranks AS p
JOIN latest ON p.REPDTE = latest.repdte
JOIN changes AS c ON c.CERT = p.CERT AND c.REPDTE = p.REPDTE
JOIN rolling_roa AS r ON r.CERT = p.CERT AND r.REPDTE = p.REPDTE
WHERE p.CERT IN (SELECT CERT FROM deposits_down)
  AND p.CERT IN (SELECT CERT FROM bad_loans_rising)
  AND p.CERT IN (SELECT CERT FROM thin_margin)
ORDER BY p.peer_group DESC, p.ASSET DESC;
