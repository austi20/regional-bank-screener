import sqlite3
from pathlib import Path

import requests

BASE_URL = "https://api.fdic.gov/banks"
DB_PATH = Path(__file__).resolve().parent.parent / "data" / "banks.db"
PAGE_SIZE = 10000
FIRST_YEAR = 2019
LAST_QUARTER_END = "20260630"

FINANCIAL_FIELDS = ["CERT", "REPDTE", "ASSET", "DEP", "EQ", "LNLSNET",
                    "ROA", "ROE", "NIMY", "EEFFR", "NCLNLSR"]
INSTITUTION_FIELDS = ["CERT", "NAME", "STALP", "ACTIVE", "CHARTER_CLASS", "BKCLASS"]

QUARTER_ENDS = ["0331", "0630", "0930", "1231"]


def quarter_end_dates():
    dates = []
    year = FIRST_YEAR
    while True:
        for suffix in QUARTER_ENDS:
            date = f"{year}{suffix}"
            if date > LAST_QUARTER_END:
                return dates
            dates.append(date)
        year += 1


def fetch_all(endpoint, fields, filters=""):
    rows = []
    offset = 0
    while True:
        params = {"fields": ",".join(fields), "limit": PAGE_SIZE,
                  "offset": offset}
        if filters:
            params["filters"] = filters
        response = requests.get(f"{BASE_URL}/{endpoint}", params=params, timeout=60)
        response.raise_for_status()
        body = response.json()
        page = [item["data"] for item in body["data"]]
        rows.extend(page)
        offset += PAGE_SIZE
        if offset >= body["meta"]["total"]:
            return rows


def build_database(conn):
    # drop first so a rerun rebuilds from scratch
    conn.execute("DROP TABLE IF EXISTS financials")
    conn.execute("DROP TABLE IF EXISTS institutions")
    conn.execute("""
        CREATE TABLE financials (
            CERT INTEGER NOT NULL,
            REPDTE TEXT NOT NULL,
            ASSET INTEGER,
            DEP INTEGER,
            EQ INTEGER,
            LNLSNET INTEGER,
            ROA REAL,
            ROE REAL,
            NIMY REAL,
            EEFFR REAL,
            NCLNLSR REAL,
            PRIMARY KEY (CERT, REPDTE)
        )""")
    conn.execute("""
        CREATE TABLE institutions (
            CERT INTEGER PRIMARY KEY,
            NAME TEXT,
            STALP TEXT,
            ACTIVE INTEGER,
            CHARTER_CLASS TEXT,
            BKCLASS TEXT
        )""")


def insert_rows(conn, table, fields, rows):
    placeholders = ",".join("?" for _ in fields)
    sql = f"INSERT INTO {table} ({','.join(fields)}) VALUES ({placeholders})"
    conn.executemany(sql, [[row.get(f) for f in fields] for row in rows])


def main():
    DB_PATH.parent.mkdir(exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    build_database(conn)

    for date in quarter_end_dates():
        rows = fetch_all("financials", FINANCIAL_FIELDS, f"REPDTE:{date}")
        insert_rows(conn, "financials", FINANCIAL_FIELDS, rows)
        print(f"{date}: {len(rows)} rows")

    # all institutions, active or not, so failed banks stay joinable
    institutions = fetch_all("institutions", INSTITUTION_FIELDS)
    insert_rows(conn, "institutions", INSTITUTION_FIELDS, institutions)
    print(f"institutions: {len(institutions)} rows")

    conn.commit()
    conn.close()


if __name__ == "__main__":
    main()
