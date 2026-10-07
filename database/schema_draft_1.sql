BEGIN;

-- First draft: Base logistics entities
CREATE TABLE public.city (
    city_id character varying(10) NOT NULL,
    city_name character varying(50) NOT NULL,
    has_rail_station boolean DEFAULT false NOT NULL
);

CREATE TABLE public.store (
    store_id character varying(10) NOT NULL,
    city_id character varying(10) NOT NULL
);

CREATE TABLE public.product (
    product_id character varying(10) NOT NULL,
    product_name character varying(100) NOT NULL,
    space_consumption numeric(6,2) NOT NULL,
    price numeric(10,2) NOT NULL
);

CREATE TABLE public.train (
    train_id character varying(10) NOT NULL,
    size numeric(8,2) NOT NULL,
    capacity_per_product numeric(8,2) NOT NULL
);

CREATE TABLE public.truck (
    truck_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    plate_number character varying(20) NOT NULL,
    capacity numeric(8,2) NOT NULL
);

COMMIT;