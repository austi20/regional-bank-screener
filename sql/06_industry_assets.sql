-- Does my summed industry assets match the FDIC's own total each quarter?
SELECT
    REPDTE,
    COUNT(*) AS banks,
    ROUND(SUM(ASSET) / 1000000.0, 1) AS total_assets_billions
FROM financials
GROUP BY REPDTE
ORDER BY REPDTE;
