# Changes and requirements review

## Included

- An `order_dispatch` table links each whole order to one truck dispatch. Multiple orders can share a dispatch.
- Truck assignment validates scheduled status, full train allocation, route, last train arrival, deadline, and truck capacity. Creation is one database transaction.
- Roster validation covers INSERT and UPDATE (old triggers only covered INSERT), overlaps, breaks, driver 40-hour and assistant 60-hour weekly limits. Week-crossing schedules are apportioned between weeks.
- Roster writes update a common mutex row to serialize changes. This prioritizes correctness for a small coursework system over high-volume scheduling throughput. Native concurrent-session verification is still required.
- Linked dispatches and their order links are immutable in this first version. They cannot yet be rescheduled or unassigned. Cancellation after confirmed truck assignment is rejected.
- An order cannot become Dispatched without a linked truck and crew, or before planned departure. The existing status-transition and train cancellation rules remain.
- Existing dispatched/delivered orders are recorded in `kp_legacy_fulfilment`; no historical truck links are invented. Previously dispatched legacy orders can still finish as Delivered.
- All 16 original tables retain their existing row values during migration. New tables/views/functions/triggers are added; obsolete roster triggers are replaced. Historical crew counter fields remain for schema compatibility, but reports no longer rely on them.
- Six report choices: quarterly sales value/units, most ordered products per quarter, city/route sales, weekly crew hours, monthly truck activity, customer delivery history. Sales use recorded line prices and exclude cancelled orders. City/route sales retains split-aware allocations.
- Staff pages for truck/crew planning, future train creation and reports. Current branding and customer storefront remain.
- Future trip creation checks destination store, train size and overlapping train schedules. Trips with allocation history cannot be rescheduled. Existing allocated trips retain normal capacity reservation/release updates.
- Customer history includes recorded truck/route/planned delivery times.
- Customer detail access limited to its owner or Admin; new staff endpoints limited to Admin/Dispatcher.
- CSV cells quote commas/newlines/quotes and prefix spreadsheet formula-like text.
- Null order items fail validation. Frontend login/signup respect the configured API base URL, allowing isolated testing.
- JWT can use an environment-provided stable secret. Without one, the original ephemeral local behavior remains; a restart invalidates sessions. Review setup provides a stable secret.
- Database password moved out of the application-properties fallback. Your original Docker DB_PASSWORD setting continues to supply it when eventually promoted.
- Springdoc updated from the Boot-3 series 2.8.5 to the Boot-4 series 3.1.1. Docker wrapper handles Windows CRLF and executable permission.

## Explicit domain assumptions for the viva

1. All schedule timestamps represent Sri Lanka local time. Weeks run Monday 00:00 to the next Monday.
2. The brief does not define a break length for "consecutive". This implementation assumes a gap of at least one hour ends consecutive work. Drivers require it after each route; assistants after at most two. Explain and confirm this interpretation with your lecturer.
3. Truck capacity and product space consumption use the same normalized cargo-space unit. The brief explicitly defines train consumption but does not define truck units; confirm your EER/report uses the same assumption.
4. One whole order waits at the destination store for its final train portion, then travels on one truck. An order too large for one truck is rejected by truck planning. Multi-truck splitting is not implemented.
5. A route is chosen by its coverage-area label and destination city. Address-to-area matching is a user/staff responsibility. There is no geocoder or automatic street-address validation; do not claim otherwise in the presentation.
6. Crew-hour reports show scheduled hours, not recorded attendance or actual driving. Truck activity is booked hours/trips, not a utilization percentage against a shift calendar.
7. Sales reports represent non-cancelled orders using placement date, not cash collected or accounting revenue recognition.
8. Actual train routing/return journeys are managed by the railway. This database records each allocated cargo trip and prevents overlapping bookings for the same train; it does not optimize railway circulation.
9. A booked dispatch's end time reserves its truck and crew for the whole planned route. Actual arrival timestamps and detailed stop-by-stop tracking are not implemented.

## Verification status after PC promotion

On 14 October 2026, Malith supplied successful backend and frontend Docker build output, a migration COMMIT, and matching before/after fingerprints of all 16 original business tables. He reported successful customer login/history, Admin report display/CSV download, and Dispatcher planning/trip lists in the original localhost:3000 app. He also reported that review-app truck assignment worked with valid inputs.

These are specific build, database-preservation and user-reported smoke checks, not proof of every requirement. Native concurrent transactions, all six report results, all negative rules through the live API, and a fresh installation from the merged repository still need independent verification. Java integration tests were not run in the assistant environment.

Remaining implementation limitations: no dispatch rescheduling/unassignment; no multiple-truck splitting of a single order; address coverage is selected manually; scheduled hours are not actual attendance. Update the EER diagram and report for the new tables. Fresh-install staff provisioning and a sanitized demo seed require separate work. Some timestamp displays currently use raw UTC-style API strings; compare the displayed time with the entered Sri Lanka local time before relying on it in a demonstration.

The private live database dump is excluded. Do not publish passwords, account hashes or customer details. Configuration requires a database password supplied through the environment. JWT_SECRET is optional for local compatibility but a stable secret is needed to retain sessions across restarts.
