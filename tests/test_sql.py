import sqlite3

import pytest

from src.load import DB_PATH
from src.run_sql import OUTPUT_DIR, main


@pytest.fixture(scope="module")
def conn():
    main()
    connection = sqlite3.connect(DB_PATH)
    yield connection
    connection.close()


def test_all_exports_written(conn):
    names = {p.name for p in OUTPUT_DIR.glob("*.csv")}
    assert "05_stress_screen.csv" in names
    assert "10_peer_comps.csv" in names


def test_skipped_quarter_gives_null_change(conn):
    # CERT 18342 skipped 2026Q1, so 2026Q2 has no prior quarter to compare
    row = conn.execute(
        "SELECT ncl_qoq_chg, ncl_rising_2q FROM changes "
        "WHERE CERT = 18342 AND REPDTE = '20260630'"
    ).fetchone()
    assert row == (None, 0)


def test_stress_screen_has_no_duplicate_banks(conn):
    with open(OUTPUT_DIR / "05_stress_screen.csv") as f:
        certs = [line.split(",")[0] for line in f.readlines()[1:]]
    assert len(certs) == len(set(certs))


def test_median_matches_plain_python(conn):
    values = sorted(r[0] for r in conn.execute(
        "SELECT ROA FROM peer_ranks WHERE REPDTE = '20260630' "
        "AND peer_group = '3 $10B to $100B'"))
    mid = len(values) // 2
    expected = values[mid] if len(values) % 2 else (values[mid - 1] + values[mid]) / 2
    with open(OUTPUT_DIR / "09_peer_medians.csv") as f:
        rows = [line.strip().split(",") for line in f]
    match = [r for r in rows if r[0] == "20260630" and r[1] == "3 $10B to $100B"]
    assert float(match[0][3]) == pytest.approx(expected, abs=0.001)
