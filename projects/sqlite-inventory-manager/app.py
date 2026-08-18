from __future__ import annotations
import sqlite3
from pathlib import Path

SCHEMA = Path(__file__).with_name("schema.sql")

def connect(path=":memory:"):
    conn = sqlite3.connect(path)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(SCHEMA.read_text(encoding="utf-8"))
    return conn

def add_product(conn, sku, name, reorder_level=0):
    cur = conn.execute(
        "INSERT INTO product(sku,name,reorder_level) VALUES(?,?,?)",
        (sku, name, reorder_level),
    )
    conn.commit()
    return cur.lastrowid

def adjust_stock(conn, product_id, delta, reason):
    if delta == 0:
        raise ValueError("delta must be non-zero")
    with conn:
        conn.execute(
            "INSERT INTO stock_ledger(product_id,quantity_delta,reason) VALUES(?,?,?)",
            (product_id, delta, reason),
        )

def stock(conn, product_id):
    row = conn.execute(
        "SELECT quantity FROM current_stock WHERE product_id=?", (product_id,)
    ).fetchone()
    return 0 if row is None else row[0]

def reorder_report(conn):
    return conn.execute(
        "SELECT sku,name,quantity,reorder_level FROM current_stock "
        "WHERE quantity <= reorder_level ORDER BY sku"
    ).fetchall()

if __name__ == "__main__":
    db = connect("inventory.db")
    print("SQLite Inventory Manager ready.")
