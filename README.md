# Regional Bank Health Screener

[![tests](https://github.com/austi20/regional-bank-screener/actions/workflows/tests.yml/badge.svg)](https://github.com/austi20/regional-bank-screener/actions/workflows/tests.yml)

My FOMC event study asked whether regional bank stocks react to Fed announcements. This project asks a different question: which US banks look stressed on their own fundamentals, and does that show up before the headlines?

The screen is built in SQL on a SQLite database of FDIC call report data for every US bank, 2019Q1 to 2026Q2. In 2026Q2 it flags 21 of 3,729 banks with at least $100M in assets. An Excel workbook for a non technical reader is still to come.

## What I found

A bank is flagged if all three hold in 2026Q2: deposits down year over year, noncurrent loans up two quarters in a row, and net interest margin in the bottom decile of its asset size peer group.

- 21 banks pass. 6 are in the $1B to $10B group (of 902 banks) and 15 are under $1B (of 2,662). None are in the $10B to $100B group (133 banks) or the over $100B group (32 banks).
- I expected one peer group to look clearly weaker. It does not. The two groups with any flags are flagged at about the same rate, 0.7% and 0.6%.
- Some flags are probably bad data, not stress. CERT 12013 has a negative margin and an ROA of -1.45, and it is the bank with deposits above assets in the audit. CERT 6078 has an ROA of -3.96. A cleaner example is Bogota Savings Bank (NJ, $872M): deposits down 9.5% in a year and noncurrent loans at 4.3%.
- The March 2023 check ranks banks that began 2022Q4 at $10B to $100B by deposit change to 2023Q2. Silvergate is first at -85%. Bank of America California and two Charles Schwab banks also fall 12% to 38%, which looks like transfers inside their parent groups, not runs. I have not confirmed that.
- Median ROA in 2026Q2 is 1.23 for Michigan's 65 ranked banks against 1.25 for the 3,729 nationally.

## The queries

All in `sql/`, each with a one line business question at the top. Views first, then queries that export to `output/`.

| File | Question |
|---|---|
| 01 to 04 | Views: size peer groups, QoQ and YoY changes, peer ranks, rolling 4 quarter ROA |
| 05 | Which banks fail all three stress tests in the latest quarter |
| 06 | Summed industry assets per quarter |
| 07 | Biggest deposit losers in the $10B to $100B group, 2022Q4 to 2023Q2 |
| 08 | Median Michigan bank against the median US bank |
| 09 | Median ROA and margin by peer group and quarter |
| 10 | Latest quarter, every ranked bank, with its peer ranks |

Every lag checks that the earlier row is really the prior quarter, so a bank that skipped a quarter gets NULL, not a wrong comparison. Banks under $100M are left out of the ranks because their ratios swing too much.

## What the data looks like

- 144,827 bank quarter rows, 5,511 banks, 30 quarters.
- The number of reporting banks fell from 5,428 in 2019Q1 to 4,313 in 2026Q2. 4,231 banks report in all 30 quarters, 1,198 stop reporting before the end (mergers, failures, charter changes), and 83 start after 2019Q1.
- Summed assets for 2026Q2 are about $26.75 trillion.

Full audit with the problems I found: [notes/data_audit.md](notes/data_audit.md). The ones that will change how the SQL gets written:

- 68 banks, including one with $27.5B in assets, have no record in the FDIC institutions table, so name and state joins drop them unless the join is a LEFT JOIN.
- One bank (CERT 18342) skipped 2026Q1. A plain LAG over its rows would compare 2025Q4 to 2026Q2 without warning.
- Ratios like ROA are year to date annualized. Average ROA for banks over $100M in 2025 runs 1.08 in Q1 and 1.20 in Q4, so quarter over quarter changes partly reflect accounting, not performance.
- 626 rows have an ROA beyond plus or minus 25. 625 are banks under $10B. I have not yet worked out why.

## The data

Source: the [FDIC BankFind Suite API](https://api.fdic.gov/banks/docs), free and no key. I pull two endpoints:

- `/financials` for `CERT, REPDTE, ASSET, DEP, EQ, LNLSNET, ROA, ROE, NIMY, EEFFR, NCLNLSR`, one request series per quarter end.
- `/institutions` for name, state, charter class and active flag, joined on `CERT`.

Dollar fields are in thousands. Failed and merged banks are kept, because dropping them would make every historical comparison look healthier than it was.

## How to run it

```
pip install -r requirements.txt
python src/load.py
python src/run_sql.py
python -m pytest
```

`run_sql.py` builds the views in `sql/` and writes each query to `output/*.csv`.

`load.py` takes about 80 seconds, drops and rebuilds `data/banks.db`, and is safe to rerun. The database is not committed. The two tests check that (CERT, REPDTE) is unique and that all 30 quarters loaded.

## What would break this

- Call reports are quarterly and arrive about two months late. They say nothing about stress inside a quarter.
- FDIC defines the ratios, and I use them as given.
- The institutions table is current as of the pull. A bank's name or active flag is today's, not the flag it had in 2019. Rerunning `load.py` can rename a bank in the committed CSVs.
- The screen flags 21 banks on three thresholds I chose. I did not test how the list changes if they move.
- My 2026Q2 data has 4,313 banks. The FDIC's Quarterly Banking Profile counts 4,238 insured institutions. I have not found the cause of the 75 bank gap, and I have not compared my summed assets to the profile's total.

## Next

An Excel watchlist built by hand from `output/05_stress_screen.csv`, with a PivotTable on `output/09_peer_medians.csv` and an XLOOKUP sheet on `output/10_peer_comps.csv`. Then find the 75 bank gap against the FDIC count.
