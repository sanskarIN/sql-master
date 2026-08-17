# Architecture Decisions

## 1. Authoritative state

`bookings` records business state, while `booking_allocations` records the resource-time claim. An active booking must have an active allocation. The GiST exclusion constraint is the final database guard against overlapping active claims.

## 2. Half-open intervals

All occupied intervals use `[start, end)`. A booking ending at 10:30 does not conflict with one beginning at 10:30. Mixed boundary conventions are forbidden.

## 3. UTC facts and local rules

Instants are stored as `timestamptz`. Weekly schedules are local wall-clock rules tied to the pool's IANA time-zone name. Slot generation must resolve daylight-saving gaps and folds explicitly, then persist UTC instants plus the display zone used.

## 4. Holds

A hold is an active allocation with an expiry. Expiry workers transition both booking and allocation state. Booking creation releases already-expired holds before candidate selection, but the exclusion constraint still decides the final race.

## 5. Idempotency

Every externally retried command has `(tenant_id, idempotency_key)` identity and a canonical request hash. The same key plus the same hash replays the stored result; the same key plus a different hash is a conflict.

## 6. Concurrency

Candidate resources are selected in stable `resource_id` order and locked with `FOR UPDATE SKIP LOCKED`. Commands lock the booking before changing state. Deadlock/serialization failures are retried only when the whole command is idempotent.

## 7. Capacity and overbooking

The companion schema models one allocatable row per exclusive unit. Capacity pools are represented by multiple resources. Overbooking is an explicit policy that adds controlled synthetic units or uses a separate capacity ledger; it never disables overlap protection silently.

## 8. Derived effects

Notifications, search, analytics, and external calendar sync are driven by the transactional outbox. They are replayable and reconciled against booking events.
