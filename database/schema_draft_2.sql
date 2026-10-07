BEGIN;

-- Second draft: Users, Routing, and Schedules
CREATE TABLE public.assistant (
    assistant_id character varying(10) NOT NULL,
    assistant_name character varying(100) NOT NULL,
    weekly_hours_logged numeric(5,2) DEFAULT 0 NOT NULL
);

CREATE TABLE public.driver (
    driver_id character varying(10) NOT NULL,
    driver_name character varying(100) NOT NULL,
    weekly_hours_logged numeric(5,2) DEFAULT 0 NOT NULL
);

CREATE TABLE public.staff_user (
    staff_id character varying(10) NOT NULL,
    staff_name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    role character varying(20) NOT NULL
);

CREATE TABLE public.customer (
    customer_id character varying(10) NOT NULL,
    customer_name character varying(100) NOT NULL,
    delivery_address character varying(255) NOT NULL,
    phone_number character varying(15) NOT NULL,
    email character varying(100),
    city_id character varying(10) NOT NULL,
    password character varying(255) NOT NULL
);

CREATE TABLE public.route (
    route_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    city character varying(50) NOT NULL,
    coverage_area character varying(255) NOT NULL,
    max_delivery_time numeric(5,2) NOT NULL
);

CREATE TABLE public.train_schedule (
    trip_id character varying(10) NOT NULL,
    city_id character varying(10) NOT NULL,
    departure_datetime timestamp without time zone NOT NULL,
    arrival_datetime timestamp without time zone NOT NULL,
    train_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    available_capacity numeric(8,2) NOT NULL,
    allocated_capacity numeric(10,2) NOT NULL
);

COMMIT;