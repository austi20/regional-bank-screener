# Regional Bank Health Screener

[![tests](https://github.com/austi20/regional-bank-screener/actions/workflows/tests.yml/badge.svg)](https://github.com/austi20/regional-bank-screener/actions/workflows/tests.yml)

My FOMC event study asked whether regional bank stocks react to Fed announcements. This project asks a different question: which US banks look stressed on their own fundamentals, and does that show up before the headlines?

The screen itself is not built yet. So far this repo holds the part everything else depends on: a SQLite database of FDIC call report data for every US bank, 2019Q1 to 2026Q2, plus an audit of what is wrong with it. The SQL screen and an Excel workbook for a non technical reader come next.

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
- The institutions table is current as of the pull. A bank's name or active flag is today's, not the flag it had in 2019.

## Next

SQL for peer groups by asset size, rolling averages, a stress screen, and a check of the March 2023 deposit losses. Then an Excel watchlist built by hand from the query output.
