-- Which size peer group is each bank in, each quarter? (ASSET is in thousands)
DROP VIEW IF EXISTS bank_quarters;
CREATE VIEW bank_quarters AS
SELECT
    f.CERT,
    f.REPDTE,
    -- quarter counter, so a skipped quarter shows up as a gap of 2
    CAST(substr(f.REPDTE, 1, 4) AS INTEGER) * 4
        + (CAST(substr(f.REPDTE, 5, 2) AS INTEGER) + 2) / 3 AS qidx,
    CASE
        WHEN f.ASSET < 1000000 THEN '1 under $1B'
        WHEN f.ASSET < 10000000 THEN '2 $1B to $10B'
        WHEN f.ASSET < 100000000 THEN '3 $10B to $100B'
        ELSE '4 over $100B'
    END AS peer_group,
    i.NAME,
    i.STALP,
    f.ASSET, f.DEP, f.EQ, f.LNLSNET,
    f.ROA, f.ROE, f.NIMY, f.EEFFR, f.NCLNLSR
FROM financials AS f
LEFT JOIN institutions AS i ON i.CERT = f.CERT;
