import sqlite3

import pytest

from src.load import DB_PATH, quarter_end_dates


@pytest.fixture
def conn():
    connection = sqlite3.connect(DB_PATH)
    yield connection
    connection.close()


def test_cert_repdte_is_unique(conn):
    duplicates = conn.execute(
        "SELECT CERT, REPDTE, COUNT(*) FROM financials "
        "GROUP BY CERT, REPDTE HAVING COUNT(*) > 1"
    ).fetchall()
    assert duplicates == []


def test_quarter_counts(conn):
    expected = quarter_end_dates()
    loaded = [row[0] for row in conn.execute(
        "SELECT DISTINCT REPDTE FROM financials ORDER BY REPDTE")]
    assert loaded == expected

    # no bank can have more quarters than exist
    most = conn.execute(
        "SELECT MAX(n) FROM (SELECT COUNT(*) AS n FROM financials GROUP BY CERT)"
    ).fetchone()[0]
    assert most == len(expected)
