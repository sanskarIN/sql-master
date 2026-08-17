# Checksum and Relay Notes

Official store: **https://ramsandesh.gumroad.com**

Checksums are useful only when the published bytes match the bytes used to generate the manifest. The following exceptions are intentionally documented.

## Parts 110–111

During the first browseable-source import, promotional Gumroad text was appended to some source documentation before the repository adopted an exact-source-first policy. Their historical `SHA256SUMS.txt` files may therefore differ for those modified documentation files even though the executable code/tests were validated.

Do not interpret a documentation-only hash difference as proof that the SQL/Python package failed its tests. For a future release, regenerate a current checksum manifest from the final published tree or restore the byte-identical original documentation first.

## Part 111 correction

A relayed identifier in `sql/04_receiving_counts_security.sql` was corrected from `purchase_order_order_line_id` to `purchase_order_line_id` in a dedicated fix commit. Any checksum generated before that fix is historical rather than current.

## Parts 119–120 long CSV files

The GitHub connector's text relay truncated the original long CSV payloads. To avoid publishing a silently truncated file:

- Part 119 uses a relay-safe 72-case bank satisfying the package's row-count/identity contract.
- Part 120 uses a relay-safe 120-question bank with 120 unique IDs across exactly 12 categories.

These relay-safe files are intentionally not claimed to be byte-identical to the original local CSVs. Replace them with the originals if a direct binary/file transfer route becomes available, then rerun the package tests and regenerate checksums.
