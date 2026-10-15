# Person 3 — Database & JPA Lead

**Scope:** Relational DDL schema, foreign key constraints, JPA entities, transactional locking, seed data

**Stack:** PostgreSQL 17, Spring Data JPA / Hibernate, Java 21+

---

## 1. Relational DDL Schema

Implemented all 14 tables matching the finalized ER diagram:

`CITY`, `PRODUCT`, `CUSTOMER`, `DRIVER`, `ASSISTANT`, `TRAIN`, `STORE`, `TRUCK`, `ROUTE`, `TRAIN_SCHEDULE`, `CUSTOMER_ORDER`, `ORDER_ITEM`, `ORDER_TRAVEL`, `TRUCK_DISPATCH`

File: `database/kandypack_postgresql.sql`

### Design decisions (deviating from the original team spec, with reasoning)

- **Removed `DRIVER.route_id` and `ASSISTANT.route_id`** — drivers/assistants are assigned per-trip via `TRUCK_DISPATCH`, not permanently tied to a single route. Keeping a separate `route_id` on these tables would create two conflicting sources of truth.
- **`available_capacity` lives only on `TRAIN_SCHEDULE`, not on `TRAIN`** — cargo capacity is allocated per trip, not per physical train, since the same train runs multiple trips with independent capacity each time.
- **Added a `CITY` lookup table** — replaces scattered free-text city fields (previously on `STORE`, `CUSTOMER`, `TRAIN_SCHEDULE`), enforcing the six-rail-city rule via foreign key rather than a loose `CHECK` constraint.

## 2. Constraints & Integrity

- Primary keys on all 14 tables (including composite PKs on `ORDER_ITEM` and `ORDER_TRAVEL`)
- Foreign key constraints enforcing all table relationships
- `CHECK` constraints:
  - 7-day minimum order lead time (`chk_delivery_lead_time`)
  - Order status domain (`placed`, `scheduled`, `dispatched`, `delivered`, `cancelled`)
  - Positive quantity, non-negative price/amount
  - Logical time ordering (train schedule arrival > departure, dispatch end > start)
  - Non-negative train capacity
  - Weekly hour upper bounds (driver ≤ 40, assistant ≤ 60)

## 3. Spring Data JPA Layer

Full set of 14 `@Entity` classes (16 files total — two composite-key tables required a separate `@Embeddable` ID class each) in `com.kandypack.kandypackbackend.entity`:

- Simple entities: `Product`, `City`, `Driver`, `Assistant`, `Train`
- Entities with `@ManyToOne` / `@JoinColumn` foreign key mappings: `Customer`, `Store`, `Truck`, `Route`, `TrainSchedule`, `CustomerOrder`, `TruckDispatch`
- Composite-key entities (using `@EmbeddedId` + `@MapsId`): `OrderItem` (with `OrderItemId`), `OrderTravel` (with `OrderTravelId`)

All entities verified against the live PostgreSQL schema using `spring.jpa.hibernate.ddl-auto=validate` — confirms every Java class exactly matches its corresponding table (column names, types, keys) with zero mismatches.

## 4. Transactional Locking (Concurrency Control)

Implemented pessimistic row-level locking to prevent race conditions when concurrent requests attempt to book the same train capacity.

**Files:**
- `repository/TrainScheduleRepository.java` — `@Lock(LockModeType.PESSIMISTIC_WRITE)` query, generates `SELECT ... FOR UPDATE` at the database level
- `service/OrderAssignmentService.java` — `@Transactional` method wrapping the lock-check-update sequence, guaranteeing atomicity

This ensures two simultaneous booking attempts on the same train trip cannot both succeed and oversell capacity.

## 5. Seed Data

Populated the database with:
- 7 cities, 6 stores, 10 routes, 15 products, 20 customers
- 8 drivers, 8 assistants, 8 trucks
- 3 trains, 12 train trips with defined capacities
- **40 customer orders**, each with 1–3 items, all satisfying the 7-day lead-time rule
- 40 order-to-trip/route assignments
- 15 truck dispatches, spread across dates to satisfy roster constraints

File: `database/kandypack_populate_data_postgresql.sql`

---

## Verification

- All entities confirmed via successful Spring Boot startup with `ddl-auto=validate` (zero schema mismatches)
- Locking repository confirmed registered: `Found 1 JPA repository interface` in application logs
- All 6 required business reports (quarterly sales, top items, city/route breakdown, driver/assistant hours, truck usage, customer order history) tested and returning correct results against the seeded dataset
