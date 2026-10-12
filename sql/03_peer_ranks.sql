-- Where does each bank sit against banks its own size, each quarter?
-- Banks under $100M are left out: their ratios swing too much to rank on.
DROP VIEW IF EXISTS peer_ranks;
CREATE VIEW peer_ranks AS
SELECT
    CERT, REPDTE, NAME, STALP, peer_group, ASSET, ROA, NIMY, EEFFR, NCLNLSR,
    COUNT(*) OVER (PARTITION BY REPDTE, peer_group) AS peer_size,
    RANK() OVER (PARTITION BY REPDTE, peer_group ORDER BY ROA DESC) AS roa_rank,
    RANK() OVER (PARTITION BY REPDTE, peer_group ORDER BY EEFFR ASC) AS eff_rank,
    RANK() OVER (PARTITION BY REPDTE, peer_group ORDER BY NCLNLSR ASC) AS ncl_rank,
    -- decile 1 = lowest margin in the peer group
    NTILE(10) OVER (PARTITION BY REPDTE, peer_group ORDER BY NIMY ASC) AS nim_decile
FROM bank_quarters
WHERE ASSET >= 100000;
