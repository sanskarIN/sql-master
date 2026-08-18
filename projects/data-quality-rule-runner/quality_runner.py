from __future__ import annotations
import sqlite3
from dataclasses import dataclass

@dataclass(frozen=True)
class Rule:
    name: str
    sql: str

def run_rules(conn: sqlite3.Connection, rules: list[Rule]):
    results = []
    for rule in rules:
        rows = conn.execute(rule.sql).fetchall()
        results.append({"name": rule.name, "passed": len(rows) == 0, "violations": len(rows)})
    return results

def all_passed(results):
    return all(r["passed"] for r in results)
