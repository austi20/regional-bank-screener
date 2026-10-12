-- Is a bank's return on assets trending down once one quarter's noise is smoothed out?
-- Only filled when the four quarters in the frame are consecutive.
DROP VIEW IF EXISTS rolling_roa;
CREATE VIEW rolling_roa AS
WITH framed AS (
    SELECT
        CERT, REPDTE, qidx,
        AVG(ROA) OVER w AS roa_4q,
        COUNT(*) OVER w AS n_quarters,
        MIN(qidx) OVER w AS first_qidx
    FROM bank_quarters
    WINDOW w AS (PARTITION BY CERT ORDER BY qidx
                 ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)
)
SELECT CERT, REPDTE, qidx,
       CASE WHEN n_quarters = 4 AND first_qidx = qidx - 3 THEN roa_4q END AS roa_4q
FROM framed;
