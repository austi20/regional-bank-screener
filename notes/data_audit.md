# Data audit, FDIC call report load

Run on 2026-10-08 against `data/banks.db`, built by `python src/load.py` (about 80 seconds). Source: FDIC BankFind Suite API, `/financials` and `/institutions`. Numbers below come straight from queries on that database.

## What loaded

| Table | Rows | Notes |
|---|---|---|
| `financials` | 144,827 | 5,511 distinct CERTs, 30 quarters (2019Q1 to 2026Q2) |
| `institutions` | 27,835 | every institution FDIC lists, active or not |

Rows per quarter fall steadily from 5,428 (2019Q1) to 4,313 (2026Q2). That is consolidation, not a load problem: each quarter's count matches the API's own `meta.total` for that REPDTE.

## Banks entering and leaving

- 4,231 banks report in all 30 quarters.
- 83 first appear after 2019Q1 (new charters, or institutions that started filing).
- 1,198 stop reporting before 2026Q2 (mergers, failures, charter conversions).
- The institutions table marks 1,225 of the CERTs in `financials` as inactive. 41 of those inactive CERTs still filed for 2026Q2, so their closure came after June 30. 2 CERTs marked active did not file for 2026Q2. I have not looked up why.
- Inactive banks stay in the database on purpose. Dropping them would make every historical comparison look healthier than it was.

## Gaps and joins

- One bank (CERT 18342) has a hole: it filed 29 of the 30 quarters and skipped 2026Q1. Any LAG query has to be written with that in mind, because LAG over rows would silently compare 2025Q4 to 2026Q2 for that bank.
- 68 CERTs (1,565 financials rows) have no row in `institutions`. I checked CERT 58339 against the API directly and got zero matches, so this is a gap at the source, not a bug in my load. The largest of these is CERT 58339 at $27.5B in assets. Queries that need a name or state must use a LEFT JOIN or these banks vanish.

## Missing values

| Column | NULL rows |
|---|---|
| EQ | 510 |
| ROE | 654 |
| ASSET, DEP, LNLSNET, ROA, NIMY, EEFFR, NCLNLSR | 0 |

## Units

- ASSET, DEP, EQ and LNLSNET are in thousands of dollars. Largest value is CERT 628 at 4,091,315,000 in 2026Q2, which is $4.09 trillion, so the thousands claim holds.
- Summed 2026Q2 assets are 26,753,048,556 thousand, about $26.75 trillion. Session 2 compares this to the FDIC Quarterly Banking Profile total.
- ROA, ROE, NIMY, EEFFR and NCLNLSR are already percentages, not fractions.

## Outliers to handle in the SQL

- 626 rows have |ROA| above 25 (60 distinct banks). 625 of them are banks under $10B. The one exception is a $27.5B bank in 2020Q1 (CERT 17266, ROA -26). I have not looked into why the small ones are extreme. Rank within peer groups and do not trust raw ratios.
- 127 rows have NIMY above 20 or below -5. 121 rows have EEFFR above 1,000 or below -100.
- 79 rows have deposits above assets. The largest is CERT 12013 in 2022, about $1.57B deposits against $1.55B assets. I have not checked the cause. Left in for now.
- The ratios are year to date annualized. Average ROA for banks over $100M in assets in 2025 runs 1.08 (Q1), 1.15 (Q2), 1.19 (Q3), 1.20 (Q4). A Q1 to Q2 "improvement" is partly that accounting, so YoY comparisons are safer than QoQ.

## Not checked yet

- Why 2 active CERTs skipped 2026Q2.
- Whether any 2019 to 2021 filings were restated after the original report.
