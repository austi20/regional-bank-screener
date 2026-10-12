-- Which $10B to $100B banks lost the most deposits from 2022Q4 to 2023Q2?
-- Peer group is as of 2022Q4, before the run.
SELECT
    a.CERT, a.NAME, a.STALP,
    ROUND(a.ASSET / 1000000.0, 1) AS assets_billions_2022q4,
    ROUND(a.DEP / 1000000.0, 1) AS dep_billions_2022q4,
    ROUND(b.DEP / 1000000.0, 1) AS dep_billions_2023q2,
    ROUND(100.0 * (b.DEP - a.DEP) / a.DEP, 1) AS dep_change_pct
FROM bank_quarters AS a
JOIN bank_quarters AS b ON b.CERT = a.CERT AND b.REPDTE = '20230630'
WHERE a.REPDTE = '20221231'
  AND a.peer_group = '3 $10B to $100B'
ORDER BY dep_change_pct ASC
LIMIT 15;
