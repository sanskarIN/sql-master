use anyhow::{Context, Result};
use rusqlite::{params, Connection, OptionalExtension, TransactionBehavior};
use uuid::Uuid;

fn main() -> Result<()> {
    let mut conn = Connection::open("notes_rusqlite.db").context("open SQLite database")?;
    conn.busy_timeout(std::time::Duration::from_secs(3))?;
    conn.execute_batch("PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL; CREATE TABLE IF NOT EXISTS notes(note_id INTEGER PRIMARY KEY,title TEXT NOT NULL,body TEXT NOT NULL DEFAULT '',version INTEGER NOT NULL DEFAULT 1,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);")?;
    let tx = conn.transaction_with_behavior(TransactionBehavior::Immediate)?;
    let note_id: i64 = tx.query_row("INSERT INTO notes(title, body) VALUES(?1, ?2) RETURNING note_id", params!["Rust ownership at the data boundary", "Bind values and keep transactions short."], |row| row.get(0))?;
    tx.commit()?;
    let row: Option<(String, i64)> = conn.query_row("SELECT title, version FROM notes WHERE note_id = ?1", [note_id], |row| Ok((row.get(0)?, row.get(1)?))).optional()?;
    if let Some((title, version)) = row { println!("{note_id} | {title} | v{version}"); }
    let _ = Uuid::new_v4();
    Ok(())
}
