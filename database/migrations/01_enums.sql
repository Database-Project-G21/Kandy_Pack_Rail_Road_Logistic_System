CREATE TYPE public.order_status AS ENUM (
    'placed',
    'scheduled',
    'dispatched',
    'delivered',
    'cancelled'
);

CREATE TYPE public.staff_role AS ENUM (
    'ADMIN',
    'DISPATCHER',
    'STORE_MANAGER',
    'DRIVER'
);
