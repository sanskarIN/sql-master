PRAGMA foreign_keys = ON;

CREATE TABLE resource(
  resource_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE booking(
  booking_id INTEGER PRIMARY KEY,
  resource_id INTEGER NOT NULL REFERENCES resource(resource_id),
  starts_at TEXT NOT NULL,
  ends_at TEXT NOT NULL,
  CHECK (starts_at < ends_at)
);

CREATE INDEX ix_booking_resource_time
ON booking(resource_id, starts_at, ends_at);
