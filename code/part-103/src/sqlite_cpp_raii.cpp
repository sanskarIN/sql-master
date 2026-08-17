#include <sqlite3.h>
#include <iostream>
#include <stdexcept>
#include <string>

class Database {
    sqlite3* db_{};
public:
    explicit Database(const char* path) {
        int rc = sqlite3_open_v2(path, &db_, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nullptr);
        if (rc != SQLITE_OK) throw std::runtime_error(db_ ? sqlite3_errmsg(db_) : sqlite3_errstr(rc));
        sqlite3_busy_timeout(db_, 3000);
    }
    ~Database() { if (db_) sqlite3_close_v2(db_); }
    sqlite3* get() const noexcept { return db_; }
};

int main() try {
    Database db("notes_cpp.db");
    std::cout << "SQLite database opened safely.\n";
    return 0;
} catch (const std::exception& ex) {
    std::cerr << "fatal: " << ex.what() << '\n';
    return 1;
}
