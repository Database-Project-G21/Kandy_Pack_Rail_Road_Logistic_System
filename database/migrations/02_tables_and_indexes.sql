CREATE TABLE public.assistant (
    assistant_id character varying(10) NOT NULL,
    assistant_name character varying(100) NOT NULL,
    weekly_hours_logged numeric(5,2) DEFAULT 0 NOT NULL,
    CONSTRAINT assistant_weekly_hours_logged_check CHECK ((weekly_hours_logged <= 60.00))
);
ALTER TABLE ONLY public.assistant
    ADD CONSTRAINT assistant_pkey PRIMARY KEY (assistant_id);
CREATE TABLE public.city (
    city_id character varying(10) NOT NULL,
    city_name character varying(50) NOT NULL,
    has_rail_station boolean DEFAULT false NOT NULL
);
ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (city_id);
CREATE TABLE public.customer (
    customer_id character varying(10) NOT NULL,
    customer_name character varying(100) NOT NULL,
    delivery_address character varying(255) NOT NULL,
    phone_number character varying(15) NOT NULL,
    email character varying(100),
    city_id character varying(10) NOT NULL,
    password character varying(255) NOT NULL
);
ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);
ALTER TABLE ONLY public.customer
    ADD CONSTRAINT uq_customer_email UNIQUE (email);
CREATE INDEX idx_customer_city ON public.customer USING btree (city_id);
CREATE TABLE public.customer_order (
    order_id character varying(10) NOT NULL,
    customer_id character varying(10) NOT NULL,
    amount numeric(10,2) DEFAULT 0 NOT NULL,
    placement_date date NOT NULL,
    delivery_date date NOT NULL,
    status public.order_status DEFAULT 'placed'::public.order_status NOT NULL,
    CONSTRAINT chk_delivery_lead_time CHECK ((delivery_date >= (placement_date + '7 days'::interval))),
    CONSTRAINT customer_order_amount_check CHECK ((amount >= (0)::numeric))
);
ALTER TABLE ONLY public.customer_order
    ADD CONSTRAINT customer_order_pkey PRIMARY KEY (order_id);
CREATE INDEX idx_customer_order_customer ON public.customer_order USING btree (customer_id);
CREATE INDEX idx_customer_order_dates ON public.customer_order USING btree (placement_date, delivery_date);
CREATE TABLE public.driver (
    driver_id character varying(10) NOT NULL,
    driver_name character varying(100) NOT NULL,
    weekly_hours_logged numeric(5,2) DEFAULT 0 NOT NULL,
    CONSTRAINT driver_weekly_hours_logged_check CHECK ((weekly_hours_logged <= 40.00))
);
ALTER TABLE ONLY public.driver
    ADD CONSTRAINT driver_pkey PRIMARY KEY (driver_id);
CREATE TABLE public.kp_legacy_fulfilment (
    order_id character varying(10) NOT NULL
);
ALTER TABLE ONLY public.kp_legacy_fulfilment
    ADD CONSTRAINT kp_legacy_fulfilment_pkey PRIMARY KEY (order_id);
CREATE TABLE public.kp_migration (
    version text NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE ONLY public.kp_migration
    ADD CONSTRAINT kp_migration_pkey PRIMARY KEY (version);
CREATE TABLE public.kp_roster_mutex (
    id integer NOT NULL,
    revision bigint NOT NULL,
    CONSTRAINT kp_roster_mutex_id_check CHECK ((id = 1))
);
ALTER TABLE ONLY public.kp_roster_mutex
    ADD CONSTRAINT kp_roster_mutex_pkey PRIMARY KEY (id);
CREATE TABLE public.order_dispatch (
    order_id character varying(10) NOT NULL,
    dispatch_id character varying(10) NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL
);
ALTER TABLE ONLY public.order_dispatch
    ADD CONSTRAINT order_dispatch_pkey PRIMARY KEY (order_id);
CREATE INDEX idx_order_dispatch_dispatch ON public.order_dispatch USING btree (dispatch_id);
CREATE TABLE public.order_item (
    order_id character varying(10) NOT NULL,
    product_id character varying(10) NOT NULL,
    quantity integer NOT NULL,
    price numeric(10,2) NOT NULL,
    CONSTRAINT order_item_price_check CHECK ((price >= (0)::numeric)),
    CONSTRAINT order_item_quantity_check CHECK ((quantity > 0))
);
ALTER TABLE ONLY public.order_item
    ADD CONSTRAINT order_item_pkey PRIMARY KEY (order_id, product_id);
CREATE INDEX idx_order_item_product ON public.order_item USING btree (product_id);
CREATE TABLE public.order_travel (
    order_id character varying(10) NOT NULL,
    trip_id character varying(10) NOT NULL,
    route_id character varying(10) NOT NULL
);
ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_pkey PRIMARY KEY (order_id, trip_id);
CREATE INDEX idx_order_travel_route ON public.order_travel USING btree (route_id);
CREATE INDEX idx_order_travel_trip ON public.order_travel USING btree (trip_id);
CREATE TABLE public.order_trip_item (
    order_id character varying(10) NOT NULL,
    trip_id character varying(10) NOT NULL,
    product_id character varying(10) NOT NULL,
    quantity integer NOT NULL,
    space_per_unit numeric(6,2) NOT NULL,
    reservation_active boolean DEFAULT true NOT NULL,
    CONSTRAINT order_trip_item_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT order_trip_item_space_per_unit_check CHECK ((space_per_unit > (0)::numeric))
);
ALTER TABLE ONLY public.order_trip_item
    ADD CONSTRAINT order_trip_item_pkey PRIMARY KEY (order_id, trip_id, product_id);
CREATE INDEX idx_order_trip_item_trip ON public.order_trip_item USING btree (trip_id);
CREATE TABLE public.product (
    product_id character varying(10) NOT NULL,
    product_name character varying(100) NOT NULL,
    space_consumption numeric(6,2) NOT NULL,
    price numeric(10,2) NOT NULL,
    CONSTRAINT product_price_check CHECK ((price >= (0)::numeric)),
    CONSTRAINT product_space_consumption_check CHECK ((space_consumption > (0)::numeric))
);
ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (product_id);
CREATE TABLE public.route (
    route_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    city character varying(50) NOT NULL,
    coverage_area character varying(255) NOT NULL,
    max_delivery_time numeric(5,2) NOT NULL,
    CONSTRAINT route_max_delivery_time_check CHECK ((max_delivery_time > (0)::numeric))
);
ALTER TABLE ONLY public.route
    ADD CONSTRAINT route_pkey PRIMARY KEY (route_id);
CREATE INDEX idx_route_store ON public.route USING btree (store_id);
CREATE TABLE public.staff_user (
    staff_id character varying(10) NOT NULL,
    staff_name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    role public.staff_role NOT NULL
);
ALTER TABLE ONLY public.staff_user
    ADD CONSTRAINT staff_user_email_key UNIQUE (email);
ALTER TABLE ONLY public.staff_user
    ADD CONSTRAINT staff_user_pkey PRIMARY KEY (staff_id);
CREATE TABLE public.store (
    store_id character varying(10) NOT NULL,
    city_id character varying(10) NOT NULL
);
ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_pkey PRIMARY KEY (store_id);
CREATE INDEX idx_store_city ON public.store USING btree (city_id);
CREATE TABLE public.train (
    train_id character varying(10) NOT NULL,
    size numeric(8,2) NOT NULL,
    capacity_per_product numeric(8,2) NOT NULL
);
ALTER TABLE ONLY public.train
    ADD CONSTRAINT train_pkey PRIMARY KEY (train_id);
CREATE TABLE public.train_schedule (
    trip_id character varying(10) NOT NULL,
    city_id character varying(10) NOT NULL,
    departure_datetime timestamp without time zone NOT NULL,
    arrival_datetime timestamp without time zone NOT NULL,
    train_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    available_capacity numeric(8,2) NOT NULL,
    allocated_capacity numeric(10,2) NOT NULL,
    CONSTRAINT chk_train_times CHECK ((arrival_datetime > departure_datetime)),
    CONSTRAINT chk_trip_capacity_bounds CHECK (((allocated_capacity >= (0)::numeric) AND (available_capacity <= allocated_capacity))),
    CONSTRAINT train_schedule_available_capacity_check CHECK ((available_capacity >= (0)::numeric))
);
ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_pkey PRIMARY KEY (trip_id);
CREATE INDEX idx_train_schedule_store_departure ON public.train_schedule USING btree (store_id, departure_datetime, trip_id);
CREATE TABLE public.truck (
    truck_id character varying(10) NOT NULL,
    store_id character varying(10) NOT NULL,
    plate_number character varying(20) NOT NULL,
    capacity numeric(8,2) NOT NULL
);
ALTER TABLE ONLY public.truck
    ADD CONSTRAINT truck_pkey PRIMARY KEY (truck_id);
CREATE TABLE public.truck_dispatch (
    dispatch_id character varying(10) NOT NULL,
    truck_id character varying(10) NOT NULL,
    route_id character varying(10) NOT NULL,
    driver_id character varying(10) NOT NULL,
    assistant_id character varying(10) NOT NULL,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    CONSTRAINT chk_dispatch_times CHECK ((end_time > start_time))
);
ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_pkey PRIMARY KEY (dispatch_id);
CREATE INDEX idx_dispatch_assistant ON public.truck_dispatch USING btree (assistant_id);
CREATE INDEX idx_dispatch_driver ON public.truck_dispatch USING btree (driver_id);
CREATE INDEX idx_dispatch_start_time ON public.truck_dispatch USING btree (start_time);
CREATE INDEX idx_dispatch_truck ON public.truck_dispatch USING btree (truck_id);
