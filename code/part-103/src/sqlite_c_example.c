#include <sqlite3.h>
#include <stdio.h>
#include <stdlib.h>

static void die(sqlite3 *db, const char *operation, int rc) {
    fprintf(stderr, "%s failed (rc=%d, extended=%d): %s\n", operation, rc,
            db ? sqlite3_extended_errcode(db) : rc,
            db ? sqlite3_errmsg(db) : sqlite3_errstr(rc));
    if (db) sqlite3_close(db);
    exit(EXIT_FAILURE);
}

static void exec_trusted(sqlite3 *db, const char *sql) {
    char *error = NULL;
    int rc = sqlite3_exec(db, sql, NULL, NULL, &error);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "trusted SQL failed: %s\n", error ? error : "unknown error");
        sqlite3_free(error);
        die(db, "sqlite3_exec", rc);
    }
}

int main(void) {
    sqlite3 *db = NULL;
    int flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX;
    int rc = sqlite3_open_v2("notes.db", &db, flags, NULL);
    if (rc != SQLITE_OK) die(db, "sqlite3_open_v2", rc);
    sqlite3_extended_result_codes(db, 1);
    sqlite3_busy_timeout(db, 3000);
    exec_trusted(db, "PRAGMA foreign_keys = ON;");
    exec_trusted(db, "PRAGMA journal_mode = WAL;");
    exec_trusted(db, "CREATE TABLE IF NOT EXISTS notes(note_id INTEGER PRIMARY KEY,title TEXT NOT NULL,body TEXT NOT NULL DEFAULT '',version INTEGER NOT NULL DEFAULT 1,updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);");
    sqlite3_close(db);
    return EXIT_SUCCESS;
}
