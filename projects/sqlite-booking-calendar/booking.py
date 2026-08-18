from __future__ import annotations
import sqlite3
from pathlib import Path

SCHEMA = Path(__file__).with_name("schema.sql")

def connect(path=":memory:"):
    db = sqlite3.connect(path)
    db.execute("PRAGMA foreign_keys = ON")
    db.executescript(SCHEMA.read_text(encoding="utf-8"))
    return db

def add_resource(db, name):
    cur = db.execute("INSERT INTO resource(name) VALUES(?)", (name,))
    db.commit()
    return cur.lastrowid

def overlaps(db, resource_id, starts_at, ends_at):
    row = db.execute(
        "SELECT 1 FROM booking WHERE resource_id=? "
        "AND starts_at < ? AND ? < ends_at LIMIT 1",
        (resource_id, ends_at, starts_at),
    ).fetchone()
    return row is not None

def create_booking(db, resource_id, starts_at, ends_at):
    if starts_at >= ends_at:
        raise ValueError("starts_at must be before ends_at")
    with db:
        if overlaps(db, resource_id, starts_at, ends_at):
            raise ValueError("booking overlaps an existing interval")
        cur = db.execute(
            "INSERT INTO booking(resource_id,starts_at,ends_at) VALUES(?,?,?)",
            (resource_id, starts_at, ends_at),
        )
    return cur.lastrowid
