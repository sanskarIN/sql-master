from __future__ import annotations
import re
from dataclasses import dataclass

@dataclass(frozen=True)
class Finding:
    code: str
    message: str

def audit(sql: str):
    findings = []
    if re.search(r"SELECT\s+\*", sql, re.I):
        findings.append(Finding("SELECT_STAR", "Prefer explicit projection in stable production queries."))
    for m in re.finditer(r"CREATE\s+TABLE\s+([\w.]+)\s*\((.*?)\);", sql, re.I | re.S):
        table, body = m.group(1), m.group(2)
        if not re.search(r"PRIMARY\s+KEY", body, re.I):
            findings.append(Finding("NO_PK", f"{table}: no visible PRIMARY KEY."))
        if re.search(r"\b(price|amount|total)\w*\s+(REAL|FLOAT|DOUBLE)\b", body, re.I):
            findings.append(Finding("FLOAT_MONEY", f"{table}: money-like column uses floating point."))
    return findings

def summarize(sql: str):
    return [f"{f.code}: {f.message}" for f in audit(sql)]
