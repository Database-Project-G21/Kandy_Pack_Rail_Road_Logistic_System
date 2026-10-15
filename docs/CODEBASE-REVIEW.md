# Codebase review — 15 October 2026

## Integration fixes applied

- Backend is directly in `kandypackbackend/`; no duplicate project nesting remains.
- Root Docker Compose passes `NEXT_PUBLIC_API_URL=http://localhost:18081` at frontend build time, matching its published backend port. Local frontend `.env` remains configured for a standalone backend on port 8081. If running `npm run dev` against the Docker backend, use port 18081 in that frontend environment instead.
- Fresh Docker databases use `database/migrations/run_all.psql` via `database/docker-init.sql`. The previously referenced `kandypack_latest.sql` lacks the current allocation/dispatch tables, procedures, and native enum baseline.
- PostgreSQL has a readiness check; backend startup waits for it.
- Backend loads its local `.env` as an optional properties file, with explicit bindings for its existing `SPRING_DATASOURCE_*` keys. OS environment variables still take precedence. Run Maven from the backend directory.
- Added Docker ignore files to exclude dependencies, generated output, Git metadata, and local environment files. Added backend environment files to Git ignore rules.

## Verified

- Frontend ESLint and standalone TypeScript checks passed.
- Frontend production build passed, including all nine application routes and the generated not-found route. The build required child-process access outside the sandbox.
- All five existing backend tests passed, none skipped, against a disposable PostgreSQL 18.6 container initialized through the new Docker initialization file. This covers application startup/schema validation, native enum reads/writes, cancellation triggers, invalid enum rejection, and report status serialization. Test changes were transactional and rolled back.
- Root `docker compose config --quiet` passed.
- Existing running frontend `/login`, backend `/api/products`, and `/api/routes` returned HTTP 200. CORS allowed `http://localhost:3000`. Orders, dispatch options, and train options rejected unauthenticated requests with HTTP 403.
- Reviewed frontend API calls against controller paths, request DTOs, response DTOs, role restrictions, and database procedure/view references. No missing frontend endpoint mapping was found.

## Remaining findings

1. **Configured database is missing the baseline.** With the backend's existing `.env` loaded, startup reaches the configured database but Hibernate reports `Schema validation: missing table [assistant]`. Select the intended database and initialize an empty database using the documented baseline before running this backend against it. No existing database was initialized or altered during this review.
2. **Old backend Compose file removed during cleanup.** It used PostgreSQL 17, duplicated container names, and did not initialize the required schema. Use the root Compose file.
3. **Old SQL snapshots are not the current baseline.** Both `kandypack_latest.sql` and `database/kandypack_current_full.sql` lack the native enum definitions present in the numbered migrations. Keep them as historical snapshots only.
4. **JWT sessions reset on backend restart without `JWT_SECRET`.** Root Compose does not supply a stable secret; `JwtUtil` generates a new key when none is configured. Configure a private stable value of at least 32 UTF-8 bytes if sessions must survive restarts.
5. **Account validation is incomplete.** Login/signup request classes do not have Bean Validation constraints or `@Valid`; malformed direct API requests can produce server errors, and password strength is not enforced by the backend.
6. **Database credentials are hardcoded in the root Compose file.** Move them to private deployment environment configuration before sharing this file.
7. **Only the frontend has a Git repository in this workspace.** Backend, database, and root Compose changes are outside that repository; include them in your intended source-control arrangement.

## Cleanup completed

At the user's request, removed `1/`, `backup-before-update/`, frontend `app.zip` and `public.zip`, the obsolete backend `docker-compose.yml`, and the five unreferenced starter SVGs (`file`, `globe`, `next`, `vercel`, `window`). Root Docker Compose configuration validation passed afterward. Source code, database snapshots, dependencies, IDE settings, and project tooling were retained.

The following table records the original review inventory; the items listed above have since been removed.

| Path | Finding / action |
| --- | --- |
| `1/` | Empty directory; can be removed. |
| `kandypack-frontend/app.zip` | Archived source; unused by the application. Keep outside active source if still needed. |
| `kandypack-frontend/public.zip` | Archived assets; unused by the application. Keep outside active source if still needed. |
| `backup-before-update/` | Multiple historical source/database backups. Not needed at runtime; archive outside the project after confirming retention needs. |
| `kandypack-frontend/public/{file,globe,next,vercel,window}.svg` | Starter assets with no references in current application source; removal candidates. |
| `kandypackbackend/docker-compose.yml` | Obsolete alternate configuration; see finding above. |
| `kandypackbackend/.idea/` | Local IntelliJ settings; optional locally and excluded from Docker builds. |
| `kandypackbackend/target/`, `kandypack-frontend/.next/`, `*.tsbuildinfo` | Generated build/test/cache output; regenerable and ignored. |
| `kandypack-frontend/node_modules/` | Installed dependencies needed for local commands; regenerate with `npm ci` if intentionally clearing them. |

Keep Maven wrappers and `.mvn/`, package lockfile, framework configuration, `AGENTS.md`, `CLAUDE.md`, database migrations, and referenced product/brand assets. These are tooling, source, or runtime resources.

## Limits and applying the fixes

Cleanup removed the archives, backups, unused starter assets, and obsolete configuration listed above. Application source and existing database volumes were retained. Existing application containers were not rebuilt or restarted, so their smoke-check results describe the previously deployed images. Rebuild them to apply source and build-argument changes. Database initialization runs only for an empty PostgreSQL data directory; it does not upgrade an existing volume. Do not delete an existing volume to apply this change without a data migration/backup plan.

Authenticated browser journeys such as signup, placing an order, creating a trip, and creating a dispatch were reviewed in source but were not exercised end to end. Passing builds and the five current tests do not establish that every business workflow is correct.
