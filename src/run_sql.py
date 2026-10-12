import csv
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "data" / "banks.db"
SQL_DIR = ROOT / "sql"
OUTPUT_DIR = ROOT / "output"


def run_file(conn, path):
    text = path.read_text()
    # view files define views, the rest are queries to export
    if "CREATE VIEW" in text:
        conn.executescript(text)
        print(f"{path.name}: view created")
        return
    cursor = conn.execute(text)
    columns = [col[0] for col in cursor.description]
    rows = cursor.fetchall()
    out_path = OUTPUT_DIR / f"{path.stem}.csv"
    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(columns)
        writer.writerows(rows)
    print(f"{path.name}: {len(rows)} rows -> output/{out_path.name}")


def main():
    OUTPUT_DIR.mkdir(exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    for path in sorted(SQL_DIR.glob("*.sql")):
        run_file(conn, path)
    conn.close()


if __name__ == "__main__":
    main()
