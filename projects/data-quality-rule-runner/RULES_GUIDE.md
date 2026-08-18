# Rule Design Guide

Write each rule as a query that returns **only violating rows**.

Good examples:
- duplicate natural keys
- negative quantities
- orphaned foreign-key-like values
- invalid date ranges
- impossible status combinations

Keep expensive full-table rules scheduled appropriately for the dataset size.
