-- Kandypack cumulative snapshot: Person 3 (Persons 1 through 3).
-- Restore ONLY into a NEW EMPTY database with psql -v ON_ERROR_STOP=1 -f this_file.sql
-- These are alternative full snapshots, NOT sequential migrations.
-- Persons 1-4 contain schema only; Person 5 includes the original demo data.

--
-- PostgreSQL database dump
--


-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


BEGIN;

-- ===== Person 1 additions =====
--
-- Name: assistant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assistant (
    assistant_id character varying(10) NOT NULL,
    assistant_name character varying(100) NOT NULL,
    weekly_hours_logged numeric(5,2) DEFAULT 0 NOT NULL
);


--
-- Name: city; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.city (
    city_id character varying(10) NOT NULL,
    city_name character varying(50) NOT NULL,
    has_rail_station boolean DEFAULT false NOT NULL
);


--
-- Name: customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer (
    customer_id character varying(10) NOT NULL,
    customer_name character varying(100) NOT NULL,
    delivery_address character varying(255) NOT NULL,
    phone_number character varying(15) NOT NULL,
    email character varying(100),
    city_id character varying(10) NOT NULL,
    password character varying(255) NOT NULL
);


--
-- Name: customer_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_order (
    order_id character varying(10) NOT NULL,
    customer_id character varying(10) NOT NULL,
    amount numeric(10,2) DEFAULT 0 NOT NULL,
    placement_date date NOT NULL,
    delivery_date date NOT NULL,
    status character varying(20) DEFAULT 'placed'::character varying NOT NULL
);


--
-- Name: driver; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.driver (
    driver_id character varying(10) NOT NULL,
    driver_name character varying(100) NOT NULL,
    weekly_hours_logged numeric(5,2) DEFAULT 0 NOT NULL
);


--
-- Name: order_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_item (
    order_id character varying(10) NOT NULL,
    product_id character varying(10) NOT NULL,
    quantity integer NOT NULL,
    price numeric(10,2) NOT NULL
);


--
-- Name: order_travel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_travel (
    order_id character varying(10) NOT NULL,
    trip_id character varying(10) NOT NULL,
    route_id character varying(10) NOT NULL
);


--
-- Name: order_trip_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.order_trip_item (
    order_id character varying(10) NOT NULL,
    trip_id character varying(10) NOT NULL,
    product_id character varying(10) NOT NULL,
    quantity integer NOT NULL,
    space_per_unit numeric(6,2) NOT NULL,
    reservation_active boolean DEFAULT true NOT NULL
);


--
-- Name: product; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product (
    product_id character varying(10) NOT NULL,
    product_name character varying(100) NOT NULL,
    space_consumption numeric(6,2) NOT NULL,
    price numeric(10,2) NOT NULL
);


--
-- Name: route; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.route (
    route_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    city character varying(50) NOT NULL,
    coverage_area character varying(255) NOT NULL,
    max_delivery_time numeric(5,2) NOT NULL
);


--
-- Name: staff_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff_user (
    staff_id character varying(10) NOT NULL,
    staff_name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    role character varying(20) NOT NULL
);


--
-- Name: store; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store (
    store_id character varying(10) NOT NULL,
    city_id character varying(10) NOT NULL
);


--
-- Name: train; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.train (
    train_id character varying(10) NOT NULL,
    size numeric(8,2) NOT NULL,
    capacity_per_product numeric(8,2) NOT NULL
);


--
-- Name: train_schedule; Type: TABLE; Schema: public; Owner: -
--

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


--
-- Name: truck; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.truck (
    truck_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    plate_number character varying(20) NOT NULL,
    capacity numeric(8,2) NOT NULL
);


--
-- Name: truck_dispatch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.truck_dispatch (
    dispatch_id character varying(10) NOT NULL,
    truck_id character varying(10) NOT NULL,
    route_id character varying(10) NOT NULL,
    driver_id character varying(10) NOT NULL,
    assistant_id character varying(10) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL
);


--
-- Name: assistant assistant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assistant
    ADD CONSTRAINT assistant_pkey PRIMARY KEY (assistant_id);


--
-- Name: city city_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (city_id);


--
-- Name: customer_order customer_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_order
    ADD CONSTRAINT customer_order_pkey PRIMARY KEY (order_id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- Name: driver driver_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.driver
    ADD CONSTRAINT driver_pkey PRIMARY KEY (driver_id);


--
-- Name: order_item order_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_item
    ADD CONSTRAINT order_item_pkey PRIMARY KEY (order_id, product_id);


--
-- Name: order_travel order_travel_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_pkey PRIMARY KEY (order_id, trip_id);


--
-- Name: order_trip_item order_trip_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_trip_item
    ADD CONSTRAINT order_trip_item_pkey PRIMARY KEY (order_id, trip_id, product_id);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (product_id);


--
-- Name: route route_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route
    ADD CONSTRAINT route_pkey PRIMARY KEY (route_id);


--
-- Name: staff_user staff_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_user
    ADD CONSTRAINT staff_user_pkey PRIMARY KEY (staff_id);


--
-- Name: store store_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_pkey PRIMARY KEY (store_id);


--
-- Name: train train_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.train
    ADD CONSTRAINT train_pkey PRIMARY KEY (train_id);


--
-- Name: train_schedule train_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_pkey PRIMARY KEY (trip_id);


--
-- Name: truck_dispatch truck_dispatch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_pkey PRIMARY KEY (dispatch_id);


--
-- Name: truck truck_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck
    ADD CONSTRAINT truck_pkey PRIMARY KEY (truck_id);



-- ===== Person 2 additions =====
ALTER TABLE ONLY public.staff_user ADD CONSTRAINT staff_user_role_check CHECK (((role)::text = ANY (ARRAY[('ADMIN'::character varying)::text, ('DISPATCHER'::character varying)::text, ('STORE_MANAGER'::character varying)::text, ('DRIVER'::character varying)::text])));

--
-- Name: staff_user staff_user_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff_user
    ADD CONSTRAINT staff_user_email_key UNIQUE (email);


--
-- Name: customer uq_customer_email; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT uq_customer_email UNIQUE (email);



-- ===== Person 3 additions =====
ALTER TABLE ONLY public.assistant ADD CONSTRAINT assistant_weekly_hours_logged_check CHECK ((weekly_hours_logged <= 60.00));

ALTER TABLE ONLY public.customer_order ADD CONSTRAINT chk_delivery_lead_time CHECK ((delivery_date >= (placement_date + '7 days'::interval)));

ALTER TABLE ONLY public.customer_order ADD CONSTRAINT customer_order_amount_check CHECK ((amount >= (0)::numeric));

ALTER TABLE ONLY public.customer_order ADD CONSTRAINT customer_order_status_check CHECK (((status)::text = ANY (ARRAY[('placed'::character varying)::text, ('scheduled'::character varying)::text, ('dispatched'::character varying)::text, ('delivered'::character varying)::text, ('cancelled'::character varying)::text])));

ALTER TABLE ONLY public.driver ADD CONSTRAINT driver_weekly_hours_logged_check CHECK ((weekly_hours_logged <= 40.00));

ALTER TABLE ONLY public.order_item ADD CONSTRAINT order_item_price_check CHECK ((price >= (0)::numeric));

ALTER TABLE ONLY public.order_item ADD CONSTRAINT order_item_quantity_check CHECK ((quantity > 0));

ALTER TABLE ONLY public.order_trip_item ADD CONSTRAINT order_trip_item_quantity_check CHECK ((quantity > 0));

ALTER TABLE ONLY public.order_trip_item ADD CONSTRAINT order_trip_item_space_per_unit_check CHECK ((space_per_unit > (0)::numeric));

ALTER TABLE ONLY public.product ADD CONSTRAINT product_price_check CHECK ((price >= (0)::numeric));

ALTER TABLE ONLY public.product ADD CONSTRAINT product_space_consumption_check CHECK ((space_consumption > (0)::numeric));

ALTER TABLE ONLY public.route ADD CONSTRAINT route_max_delivery_time_check CHECK ((max_delivery_time > (0)::numeric));

ALTER TABLE ONLY public.train_schedule ADD CONSTRAINT chk_train_times CHECK ((arrival_datetime > departure_datetime));

ALTER TABLE ONLY public.train_schedule ADD CONSTRAINT chk_trip_capacity_bounds CHECK (((allocated_capacity >= (0)::numeric) AND (available_capacity <= allocated_capacity)));

ALTER TABLE ONLY public.train_schedule ADD CONSTRAINT train_schedule_available_capacity_check CHECK ((available_capacity >= (0)::numeric));

ALTER TABLE ONLY public.truck_dispatch ADD CONSTRAINT chk_dispatch_times CHECK ((end_time > start_time));

--
-- Name: customer customer_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);


--
-- Name: customer_order customer_order_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_order
    ADD CONSTRAINT customer_order_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);


--
-- Name: order_item order_item_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_item
    ADD CONSTRAINT order_item_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.customer_order(order_id);


--
-- Name: order_item order_item_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_item
    ADD CONSTRAINT order_item_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);


--
-- Name: order_travel order_travel_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.customer_order(order_id);


--
-- Name: order_travel order_travel_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.route(route_id);


--
-- Name: order_travel order_travel_trip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.train_schedule(trip_id);


--
-- Name: order_trip_item order_trip_item_order_id_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_trip_item
    ADD CONSTRAINT order_trip_item_order_id_product_id_fkey FOREIGN KEY (order_id, product_id) REFERENCES public.order_item(order_id, product_id);


--
-- Name: order_trip_item order_trip_item_order_id_trip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.order_trip_item
    ADD CONSTRAINT order_trip_item_order_id_trip_id_fkey FOREIGN KEY (order_id, trip_id) REFERENCES public.order_travel(order_id, trip_id);


--
-- Name: route route_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.route
    ADD CONSTRAINT route_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.store(store_id);


--
-- Name: store store_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);


--
-- Name: train_schedule train_schedule_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);


--
-- Name: train_schedule train_schedule_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.store(store_id);


--
-- Name: train_schedule train_schedule_train_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_train_id_fkey FOREIGN KEY (train_id) REFERENCES public.train(train_id);


--
-- Name: truck_dispatch truck_dispatch_assistant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_assistant_id_fkey FOREIGN KEY (assistant_id) REFERENCES public.assistant(assistant_id);


--
-- Name: truck_dispatch truck_dispatch_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.driver(driver_id);


--
-- Name: truck_dispatch truck_dispatch_route_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.route(route_id);


--
-- Name: truck_dispatch truck_dispatch_truck_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.truck(truck_id);


--
-- Name: truck truck_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.truck
    ADD CONSTRAINT truck_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.store(store_id);


-- Assigning orders to trips

CREATE PROCEDURE public.assign_order_to_trips(IN p_order_id character varying, IN p_route_id character varying, IN p_preferred_trip_id character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_order public.customer_order%ROWTYPE;
    v_route public.route%ROWTYPE;
    v_city varchar(10);
    v_customer_city varchar(10);
    v_earliest timestamp := clock_timestamp() AT TIME ZONE 'Asia/Colombo';
    v_preferred public.train_schedule%ROWTYPE;
    v_trip record;
    v_item record;
    v_available numeric;
    v_take integer;
BEGIN
    SELECT * INTO v_order FROM public.customer_order WHERE order_id = p_order_id FOR UPDATE;
    IF NOT FOUND OR v_order.status <> 'placed' THEN
        RAISE EXCEPTION 'Order not found or is not available for scheduling.' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (SELECT 1 FROM public.order_travel WHERE order_id = p_order_id) THEN
        RAISE EXCEPTION 'Order already has allocations; rescheduling is not supported by this operation.' USING ERRCODE = '23514';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.order_item WHERE order_id = p_order_id) THEN
        RAISE EXCEPTION 'Order must have at least one item.' USING ERRCODE = '23514';
    END IF;
    SELECT * INTO v_route FROM public.route WHERE route_id = p_route_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Route not found.' USING ERRCODE = '23514';
    END IF;
    -- Serialize allocations for this destination; lock trips in a stable chronological order.
    SELECT city_id INTO v_city FROM public.store WHERE store_id = v_route.store_id FOR UPDATE;
    SELECT city_id INTO v_customer_city FROM public.customer WHERE customer_id = v_order.customer_id;
    IF v_customer_city <> v_city THEN
        RAISE EXCEPTION 'Select a route in the customer delivery city.' USING ERRCODE = '23514';
    END IF;

    IF NULLIF(trim(p_preferred_trip_id), '') IS NOT NULL THEN
        SELECT * INTO v_preferred FROM public.train_schedule WHERE trip_id = p_preferred_trip_id;
        IF NOT FOUND OR v_preferred.store_id <> v_route.store_id OR v_preferred.city_id <> v_city
           OR v_preferred.departure_datetime <= v_earliest THEN
            RAISE EXCEPTION 'Preferred trip is missing, has already departed, or serves a different destination.' USING ERRCODE = '23514';
        END IF;
        v_earliest := v_preferred.departure_datetime;
    END IF;

    FOR v_trip IN
        SELECT ts.* FROM public.train_schedule ts
        WHERE ts.store_id = v_route.store_id AND ts.city_id = v_city
          AND ts.departure_datetime >= v_earliest
          AND ts.departure_datetime > (clock_timestamp() AT TIME ZONE 'Asia/Colombo')
          AND ts.arrival_datetime + v_route.max_delivery_time * interval '1 hour'
              < (v_order.delivery_date + 1)::timestamp
        ORDER BY ts.departure_datetime, ts.trip_id FOR UPDATE OF ts
    LOOP
        FOR v_item IN
            SELECT oi.product_id, p.space_consumption,
                   oi.quantity - COALESCE((SELECT sum(a.quantity) FROM public.order_trip_item a
                     WHERE a.order_id = oi.order_id AND a.product_id = oi.product_id),0) AS remaining
            FROM public.order_item oi JOIN public.product p USING (product_id)
            WHERE oi.order_id = p_order_id
            ORDER BY p.space_consumption DESC, oi.product_id
        LOOP
            SELECT available_capacity INTO v_available FROM public.train_schedule WHERE trip_id = v_trip.trip_id;
            v_take := LEAST(v_item.remaining, floor(v_available / v_item.space_consumption))::integer;
            IF v_take > 0 THEN
                INSERT INTO public.order_travel(order_id, trip_id, route_id)
                VALUES (p_order_id, v_trip.trip_id, p_route_id) ON CONFLICT DO NOTHING;
                INSERT INTO public.order_trip_item(order_id, trip_id, product_id, quantity, space_per_unit)
                VALUES (p_order_id, v_trip.trip_id, v_item.product_id, v_take, v_item.space_consumption);
            END IF;
        END LOOP;
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.order_item oi WHERE oi.order_id = p_order_id AND oi.quantity <>
            COALESCE((SELECT sum(a.quantity) FROM public.order_trip_item a
                      WHERE a.order_id = oi.order_id AND a.product_id = oi.product_id),0)
        );
    END LOOP;

    IF EXISTS (
        SELECT 1 FROM public.order_item oi WHERE oi.order_id = p_order_id AND oi.quantity <>
        COALESCE((SELECT sum(a.quantity) FROM public.order_trip_item a
                  WHERE a.order_id = oi.order_id AND a.product_id = oi.product_id),0)
    ) THEN
        RAISE EXCEPTION 'Not enough suitable train capacity before the delivery date. Choose a later date or add future trips.' USING ERRCODE = '23514';
    END IF;
    UPDATE public.customer_order SET status = 'scheduled' WHERE order_id = p_order_id;
END $$;

--
-- Name: assignordertotrip(character varying, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.assignordertotrip(IN p_order_id character varying, IN p_preferred_trip_id character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'Use CALL assign_order_to_trips(order_id, route_id, preferred_trip_id); the route is required.';
END $$;


--
-- Name: calculateorderspace(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculateorderspace(p_order_id character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_space DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(oi.quantity * p.space_consumption), 0)
    INTO v_total_space
    FROM ORDER_ITEM oi
    JOIN PRODUCT p ON oi.product_id = p.product_id
    WHERE oi.order_id = p_order_id;

    RETURN v_total_space;
END;
$$;


--
-- Name: calculateordertotal(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculateordertotal(p_order_id character varying) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(quantity * price), 0)
    INTO v_total
    FROM ORDER_ITEM
    WHERE order_id = p_order_id;

    RETURN v_total;
END;
$$;


--
-- Name: getdriverweeklyhours(character varying, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.getdriverweeklyhours(p_driver_id character varying, p_reference_date date) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_hours DECIMAL(6,2);
BEGIN
    SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600), 0)
    INTO v_total_hours
    FROM TRUCK_DISPATCH
    WHERE driver_id = p_driver_id
    AND date_trunc('week', start_time) = date_trunc('week', p_reference_date::timestamp);

    RETURN v_total_hours;
END;
$$;
--
-- Name: kp_booked_item_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.kp_booked_item_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE v_order_id varchar(10);
BEGIN
    IF TG_OP = 'INSERT' THEN v_order_id := NEW.order_id; ELSE v_order_id := OLD.order_id; END IF;
    PERFORM 1 FROM public.customer_order WHERE order_id = v_order_id FOR UPDATE;
    IF EXISTS (SELECT 1 FROM public.order_trip_item WHERE order_id = v_order_id) THEN
        RAISE EXCEPTION 'Booked order items cannot be edited; create a new order instead.' USING ERRCODE = '23514';
    END IF;
    IF TG_OP = 'UPDATE' AND NEW.order_id <> OLD.order_id THEN
        RAISE EXCEPTION 'Moving items between orders is not supported.' USING ERRCODE = '23514';
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END $$;

--
-- Name: kp_booked_travel_guard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.kp_booked_travel_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.order_trip_item
               WHERE order_id = OLD.order_id AND trip_id = OLD.trip_id) THEN
        RAISE EXCEPTION 'Booked travel records cannot be edited; create a new order instead.' USING ERRCODE = '23514';
    END IF;
    IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
    RETURN NEW;
END $$;

COMMIT;