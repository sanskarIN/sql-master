use anyhow::{Context, Result};
use sqlx::{sqlite::{SqliteConnectOptions, SqlitePoolOptions}, ConnectOptions, Row};
use std::{str::FromStr, time::Duration};

#[tokio::main]
async fn main() -> Result<()> {
    let options = SqliteConnectOptions::from_str("sqlite://notes_sqlx.db")?.create_if_missing(true).foreign_keys(true).busy_timeout(Duration::from_secs(3)).journal_mode(sqlx::sqlite::SqliteJournalMode::Wal).disable_statement_logging();
    let pool = SqlitePoolOptions::new().max_connections(4).acquire_timeout(Duration::from_secs(2)).connect_with(options).await.context("connect SQLite pool")?;
    sqlx::migrate!().run(&pool).await.context("apply migrations")?;
    let rows = sqlx::query("SELECT note_id, title, version FROM notes ORDER BY updated_at DESC, note_id DESC LIMIT ?1").bind(20_i64).fetch_all(&pool).await?;
    for row in rows { println!("{} | {} | v{}", row.get::<i64,_>("note_id"), row.get::<String,_>("title"), row.get::<i64,_>("version")); }
    pool.close().await;
    Ok(())
}
