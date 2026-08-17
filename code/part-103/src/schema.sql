PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS schema_migrations (
    version       INTEGER PRIMARY KEY,
    applied_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notes (
    note_id       INTEGER PRIMARY KEY,
    title         TEXT NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 120),
    body          TEXT NOT NULL DEFAULT '',
    version       INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
    created_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS ix_notes_updated_note
    ON notes(updated_at DESC, note_id DESC);
