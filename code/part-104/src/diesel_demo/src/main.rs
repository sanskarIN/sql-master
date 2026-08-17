use anyhow::{Context, Result};
use diesel::{connection::SimpleConnection, prelude::*, sql_query, sql_types::{BigInt, Text}, sqlite::SqliteConnection};

#[derive(Debug, QueryableByName)]
struct NoteRow {
    #[diesel(sql_type = BigInt)] note_id: i64,
    #[diesel(sql_type = Text)] title: String,
    #[diesel(sql_type = BigInt)] version: i64,
}

fn main() -> Result<()> {
    let mut conn = SqliteConnection::establish("notes_diesel.db").context("open Diesel SQLite connection")?;
    conn.batch_execute("PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 3000; PRAGMA journal_mode = WAL; CREATE TABLE IF NOT EXISTS notes(note_id INTEGER PRIMARY KEY,title TEXT NOT NULL,body TEXT NOT NULL DEFAULT '',version INTEGER NOT NULL DEFAULT 1,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);")?;
    let rows: Vec<NoteRow> = sql_query("SELECT note_id, title, version FROM notes ORDER BY updated_at DESC, note_id DESC LIMIT 20").load(&mut conn)?;
    for row in rows { println!("{} | {} | v{}", row.note_id, row.title, row.version); }
    Ok(())
}
