# Person 4 — DB Automation Lead (PL/pgSQL Engine)

**Scope:** Train capacity rollover procedure, truck dispatch conflict trigger, consecutive rostering rules

**Stack:** PostgreSQL 17, PL/pgSQL (triggers, functions, stored procedures)

---

## 1. Train Cargo Allocation & Rollover Procedure

**`AssignOrderToTrip(order_id, preferred_trip_id)`**

Calculates an order's total space consumption (`quantity × space_consumption` across all order items) and attempts to assign it to the preferred train trip. If that trip lacks sufficient remaining capacity, automatically searches for the next available trip to the same destination city with a later departure time and enough capacity, and assigns the order there instead.

File: `database/kandypack_postgresql.sql` (Section 3: Stored Procedure)

**Tested scenarios:**
- Order fits on preferred trip → assigned directly, capacity deducted
- Order exceeds preferred trip's capacity → correctly rolled over to the next available trip, capacity deducted from the new trip instead
- No trip has sufficient capacity → raises a clear exception rather than silently failing

## 2. Truck Dispatch Conflict Triggers

Implemented as three separate, independently tested triggers (rather than one combined trigger) for clearer isolation and debugging:

- **`trg_driver_no_overlap`** — blocks a new dispatch if the same driver already has an overlapping time window
- **`trg_assistant_no_overlap`** — same check for assistants
- **`trg_truck_no_overlap`** — same check for trucks

All three fire `BEFORE INSERT ON TRUCK_DISPATCH` and raise an exception on conflict.

## 3. Consecutive Rostering Rules

- **`trg_driver_no_consecutive`** — a driver cannot be assigned a new dispatch starting within 1 hour of their previous dispatch ending (enforces "no two consecutive deliveries," with a 1-hour minimum break as a documented assumption)
- **`trg_assistant_max_consecutive`** — an assistant cannot be assigned a 3rd dispatch if they already have 2 dispatches ending within a 12-hour window before the new one starts (enforces "maximum two consecutive routes")

## 4. Duty Hour Enforcement

- **`trg_driver_weekly_hours`** — blocks a new dispatch if it would push the driver's total hours for that ISO calendar week over 40
- **`trg_assistant_weekly_hours`** — same check for assistants, capped at 60
- **`trg_update_driver_hours`** — `AFTER INSERT` trigger that automatically increments `weekly_hours_logged` on both `DRIVER` and `ASSISTANT` once a dispatch is successfully created, keeping the hour totals continuously accurate for reporting

---

## Full Trigger/Procedure Inventory

| Name | Type | Fires On | Purpose |
|---|---|---|---|
| `trg_deduct_capacity` | Trigger | `BEFORE INSERT ON ORDER_TRAVEL` | Deducts train trip capacity, rejects if insufficient |
| `AssignOrderToTrip` | Procedure | Called manually / by application | Overflow rollover to next available trip |
| `trg_driver_no_overlap` | Trigger | `BEFORE INSERT ON TRUCK_DISPATCH` | Prevents driver double-booking |
| `trg_assistant_no_overlap` | Trigger | `BEFORE INSERT ON TRUCK_DISPATCH` | Prevents assistant double-booking |
| `trg_truck_no_overlap` | Trigger | `BEFORE INSERT ON TRUCK_DISPATCH` | Prevents truck double-booking |
| `trg_driver_no_consecutive` | Trigger | `BEFORE INSERT ON TRUCK_DISPATCH` | Enforces no consecutive driver trips |
| `trg_assistant_max_consecutive` | Trigger | `BEFORE INSERT ON TRUCK_DISPATCH` | Enforces max 2 consecutive assistant trips |
| `trg_driver_weekly_hours` | Trigger | `BEFORE INSERT ON TRUCK_DISPATCH` | Enforces 40hr/week driver cap |
| `trg_assistant_weekly_hours` | Trigger | `BEFORE INSERT ON TRUCK_DISPATCH` | Enforces 60hr/week assistant cap |
| `trg_update_driver_hours` | Trigger | `AFTER INSERT ON TRUCK_DISPATCH` | Auto-updates logged hours |

## Verification

Every trigger and the procedure were individually tested with both a passing case (valid insert succeeds) and a deliberately violating case (invalid insert correctly rejected with a clear exception message), using live data against the seeded 40-order dataset. One implementation bug was found and fixed during testing (a stale test row had caused a false negative on the truck no-overlap trigger) — resolved by tracing actual table contents rather than assuming trigger logic was at fault.
