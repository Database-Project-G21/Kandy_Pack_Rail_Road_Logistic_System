\# Kandypack Rail \& Road Logistics System



\## Overview



Kandypack is a logistics management system for coordinating customer orders and rail and road transportation.



\## Technology Stack



\- Frontend: Next.js, React, TypeScript

\- Backend: Java, Spring Boot

\- Database: PostgreSQL

\- Deployment: Docker and Docker Compose



\## Prerequisites



\- Docker Desktop with the Linux container engine enabled

\- Git



\## Environment Setup



1\. Copy `.env.example` to `.env`.

2\. Set `POSTGRES\_PASSWORD` in `.env` to a strong local password.

3\. Keep `.env` private and do not commit it to Git.



\## Running the Application



From the repository root, run:



```bash

docker compose up --build

```



Access the services at:



\- Frontend: http://localhost:3000

\- Backend: http://localhost:8081



\## Database Reporting



Person 5's reporting SQL is in `database/person\_5\_reporting.sql`.



It defines the following views:



\- `v\_order\_report` — combines orders with customer information.

\- `v\_order\_status\_summary` — summarizes order counts and values by status.

\- `v\_monthly\_order\_summary` — summarizes order performance by month.



The file also creates indexes for order placement date, delivery date, status, and customer ID.



Apply the reporting SQL only after the core database schema has been initialized:



```bash

psql -U postgres -d kandypack -v ON\_ERROR\_STOP=1 -f database/person\_5\_reporting.sql

```



\## Important Database Notes



\- The core schema snapshot is `database/kandypack\_updated.sql`.

\- PostgreSQL's initialization scripts run only when the data directory is initialized for the first time.

\- Back up existing database data before making schema changes.

\- Do not use production credentials in development configuration.



\## Person 5 Contributions



\- Reporting views and SQL queries

\- Indexes for common reporting operations

\- Docker Compose and deployment configuration

\- Project setup documentation
