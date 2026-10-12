-- How have median ROA and margin moved for each size peer group over time?
-- Feeds the PivotTable, since a PivotTable cannot take a median itself.
WITH numbered AS (
    SELECT
        REPDTE, peer_group, ROA, NIMY,
        ROW_NUMBER() OVER (PARTITION BY REPDTE, peer_group ORDER BY ROA) AS roa_n,
        ROW_NUMBER() OVER (PARTITION BY REPDTE, peer_group ORDER BY NIMY) AS nim_n,
        COUNT(*) OVER (PARTITION BY REPDTE, peer_group) AS total
    FROM peer_ranks
)
SELECT
    REPDTE, peer_group,
    MAX(total) AS banks,
    ROUND(AVG(CASE WHEN roa_n IN ((total + 1) / 2, (total + 2) / 2) THEN ROA END), 3) AS median_roa,
    ROUND(AVG(CASE WHEN nim_n IN ((total + 1) / 2, (total + 2) / 2) THEN NIMY END), 3) AS median_nim
FROM numbered
GROUP BY REPDTE, peer_group
ORDER BY REPDTE, peer_group;
