-- How does the median Michigan bank compare to the median US bank, each quarter?
-- SQLite has no MEDIAN, so rank the rows and average the middle one or two.
WITH scoped AS (
    SELECT REPDTE, 'US' AS scope, ROA, NIMY FROM peer_ranks
    UNION ALL
    SELECT REPDTE, 'MI' AS scope, ROA, NIMY FROM peer_ranks WHERE STALP = 'MI'
),
numbered AS (
    SELECT
        REPDTE, scope, ROA, NIMY,
        ROW_NUMBER() OVER (PARTITION BY REPDTE, scope ORDER BY ROA) AS roa_n,
        ROW_NUMBER() OVER (PARTITION BY REPDTE, scope ORDER BY NIMY) AS nim_n,
        COUNT(*) OVER (PARTITION BY REPDTE, scope) AS total
    FROM scoped
)
SELECT
    REPDTE, scope,
    MAX(total) AS banks,
    ROUND(AVG(CASE WHEN roa_n IN ((total + 1) / 2, (total + 2) / 2) THEN ROA END), 3) AS median_roa,
    ROUND(AVG(CASE WHEN nim_n IN ((total + 1) / 2, (total + 2) / 2) THEN NIMY END), 3) AS median_nim
FROM numbered
GROUP BY REPDTE, scope
ORDER BY REPDTE, scope;
