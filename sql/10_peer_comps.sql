-- Latest quarter, every ranked bank, so Excel can XLOOKUP a CERT to its peer standing.
SELECT
    CERT, NAME, STALP, peer_group,
    ROUND(ASSET / 1000.0, 0) AS assets_millions,
    ROUND(ROA, 2) AS roa_pct,
    ROUND(NIMY, 2) AS nim_pct,
    ROUND(EEFFR, 1) AS efficiency_ratio,
    ROUND(NCLNLSR, 2) AS noncurrent_loans_pct,
    roa_rank, eff_rank, ncl_rank, nim_decile, peer_size
FROM peer_ranks
WHERE REPDTE = (SELECT MAX(REPDTE) FROM financials)
ORDER BY peer_group DESC, ASSET DESC;
