# KandyPack database setup

This baseline creates the application schema in an empty PostgreSQL database.
It contains seven SQL files and does not import historical or seed records.

## File order

1. 01_enums.sql - native order status and staff role types
2. 02_tables_and_indexes.sql - tables, keys, and indexes
3. 03_functions.sql - calculation functions
4. 04_procedures.sql - allocation and dispatch procedures
5. 05_views_and_reports.sql - reporting views
6. 06_foreign_keys.sql - foreign key relationships
7. 07_triggers.sql - trigger functions and bindings

## Load into Neon

Configure SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, and
SPRING_DATASOURCE_PASSWORD in kandypackbackend/.env.

With Docker Desktop running, execute from the project root:

    powershell -ExecutionPolicy Bypass -File .\database\migrate-neon.ps1

The script refuses a database whose public schema already contains tables.
It reads credentials from the private backend environment file.

Alternatively, use PostgreSQL psql from this directory:

    psql -X -f .\run_all.psql

Configure your PostgreSQL connection environment variables beforehand.

The runner executes all seven files in one transaction and stops on errors.
Run the baseline once against an empty database.
Do not also import the historical full SQL snapshots.
Use psql rather than pasting the runner into a browser SQL editor.

## Application data

This baseline does not create initial cities, products, accounts, routes,
stores, trains, or other reference records. Populate those separately before
using workflows that depend on them.
