# SQL Full Mastery - Part 104 Companion Code

Author: Ram Sandesh  
Part: 104 - Rust Database APIs with SQLx, Diesel, and Embedded SQLite

This package contains three independent Rust projects. They are intentionally separate so each project can select the SQLite driver and feature set it needs without dependency-link conflicts.

## Requirements

- A current stable Rust toolchain installed through rustup
- A C compiler when a crate builds or links SQLite natively
- For Diesel on Linux, the SQLite development package may be required

## Projects

1. `rusqlite_demo` - synchronous embedded SQLite, prepared statements, transactions, optimistic locking, and schema versioning.
2. `sqlx_demo` - async SQLite pool, migrations, bounded queries, and transaction ownership.
3. `diesel_demo` - Diesel connection, typed bind parameters, transaction closure, and raw SQL mapping.

## Typical commands

```bash
cd rusqlite_demo
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo run
```

Repeat the same workflow inside `sqlx_demo` and `diesel_demo`.

Official store: https://ramsandesh.gumroad.com
