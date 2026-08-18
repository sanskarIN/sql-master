from __future__ import annotations
import re

KNOWN = ["Seq Scan", "Index Scan", "Index Only Scan", "Bitmap Heap Scan", "Nested Loop", "Hash Join", "Merge Join", "Sort", "Aggregate"]

def analyze(text: str):
    counts = {k: len(re.findall(re.escape(k), text, re.I)) for k in KNOWN}
    warnings = []
    if counts["Seq Scan"]:
        warnings.append("Sequential scan present: verify table size and selectivity before adding an index.")
    if "external merge" in text.lower() or "disk:" in text.lower():
        warnings.append("Sort spilled to disk: review work_mem, row width, and sort volume.")
    if counts["Nested Loop"] and re.search(r"rows=\d{4,}", text):
        warnings.append("Nested loop with large row estimates: verify join cardinality and indexes.")
    return {"counts": {k:v for k,v in counts.items() if v}, "warnings": warnings}
