# Apply the 14 October update

This is an incremental update to the existing Kandypack repository, not a complete application or a new database seed. Keep the existing files not listed in this package. The main repository must already contain the matching current application and 16-table schema, including order_trip_item and the train allocation changes.

## Team integration

Each person starts from current main, uses their own branch, copies only their assigned files into the exact repository-relative paths, reviews the diff and creates a pull request. Person 3 (Malith) uses the malith branch. If a branch is behind main, update it before editing. Check newer repository edits before replacing a file; these files match the tested PC update, not a freshly audited GitHub main.

Do not upload the Person-N folder, files-to-upload wrapper, or ZIP as application source. Open files-to-upload and copy its CONTENTS to the repository root. For example, Person-3/files-to-upload/kandypackbackend/... becomes kandypackbackend/... in the repository.

Persons 3 and 4 share DTO/service dependencies, and the new pages use the new backend endpoints and schema. All changes must be integrated before the final build and functional checks. There is no promise that main builds at every intermediate merge. Prefer an integration branch for the five PRs; if using main directly, complete the merges before attempting the final demo. Everyone with repository permission can merge their own PR after review. Do not bypass required checks or overwrite conflicts blindly.

## Existing database upgrade

Person 4 adds database/03_dispatch_reporting.sql ONCE. Person 3 reviews foreign keys and order_dispatch relationships; Person 5 reviews reporting views. This SQL is NOT one of the old cumulative person_1 ... person_5 SQL snapshots. Do not replace the original seed file with it.

Back up the database and source before upgrading. Build the combined code first, stop the original backend/frontend during migration, record original-table fingerprints, apply migration with ON_ERROR_STOP=1, then compare fingerprints. Malith has already done this successfully on his original PC database: DO NOT APPLY IT AGAIN THERE.

On a teammate's existing matching database, after making a backup and stopping application writers, from the repository root:

    docker compose cp database/checks/data-fingerprint.sql postgres-db:/tmp/data-fingerprint.sql
    docker compose exec -T postgres-db psql -X -U postgres -d kandypack -At -v ON_ERROR_STOP=1 -f /tmp/data-fingerprint.sql > data-before.txt
    docker compose cp database/03_dispatch_reporting.sql postgres-db:/tmp/03_dispatch_reporting.sql
    docker compose exec -T postgres-db psql -X -U postgres -d kandypack -v ON_ERROR_STOP=1 -f /tmp/03_dispatch_reporting.sql
    docker compose exec -T postgres-db psql -X -U postgres -d kandypack -At -v ON_ERROR_STOP=1 -f /tmp/data-fingerprint.sql > data-after.txt

Commands assume user postgres, database kandypack and service postgres-db. If the team's Compose differs, adapt the names first. Stop on any error. Compare with `fc data-before.txt data-after.txt` in Windows CMD. Expected migration result: COMMIT; expected comparison: no differences. Keep outputs private and outside the commit. The regression SQL is for a separate kandypack_review test database only, not the live database.

Then start the combined application with docker compose up -d --no-deps backend frontend, inspect logs, log in again, and verify customer history, reports/CSV, train scheduling and dispatch planning. Test order creation, cancellation/capacity restoration and status rules on an isolated database as well.

## Fresh installations

A GitHub upload does not migrate anyone's existing Docker volume. PostgreSQL initialization SQL normally runs only when the data volume is first initialized. This bundle alone cannot bootstrap an empty database: it needs the baseline seed first, then migration 03. Person 5 must integrate that order into the team's fresh-install setup and verify it on a separate new test volume. Never use down -v against the working project to force initialization.

Use a sanitized demo seed and documented account provisioning; do not upload Malith's live dump. Existing passwords are preserved on his original database; this update does not create a public default Admin password. Do not replace production Compose with compose.review.yml.

## Configuration

The supplied frontend Dockerfile defaults NEXT_PUBLIC_API_URL to http://localhost:8081. Rebuild with the appropriate public API URL for any different deployment. CORS_ALLOWED_ORIGINS defaults to http://localhost:3000. application.properties requires DB_PASSWORD in the environment and defaults DB_HOST to localhost and DB_USERNAME to postgres. In Docker, DB_HOST should be postgres-db. Preserve the existing Compose volume and connection settings. Confirm Sri Lanka time handling and displayed schedule times during integration testing.
