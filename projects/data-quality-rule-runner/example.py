import sqlite3
from quality_runner import Rule, run_rules, all_passed

db = sqlite3.connect(":memory:")
db.executescript("""
CREATE TABLE order_line(order_id INTEGER, quantity INTEGER NOT NULL);
INSERT INTO order_line VALUES (1, 2), (2, 1);
""")

rules = [
    Rule("positive_quantity", "SELECT * FROM order_line WHERE quantity <= 0"),
    Rule("order_id_present", "SELECT * FROM order_line WHERE order_id IS NULL"),
]

results = run_rules(db, rules)
for result in results:
    print(result)
raise SystemExit(0 if all_passed(results) else 1)
