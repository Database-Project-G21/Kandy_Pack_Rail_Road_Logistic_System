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
CREATE PROCEDURE public.assignordertotrip(IN p_order_id character varying, IN p_preferred_trip_id character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'Use CALL assign_order_to_trips(order_id, route_id, preferred_trip_id); the route is required.';
END $$;
CREATE PROCEDURE public.kp_create_dispatch(IN p_id character varying, IN p_truck character varying, IN p_route character varying, IN p_driver character varying, IN p_assistant character varying, IN p_start timestamp without time zone, IN p_end timestamp without time zone, IN p_orders character varying[])
    LANGUAGE plpgsql
    AS $$
DECLARE oid varchar;
BEGIN
 IF p_orders IS NULL OR cardinality(p_orders)=0 THEN RAISE EXCEPTION 'Select at least one order.' USING ERRCODE='23514'; END IF;
 IF p_start < clock_timestamp() AT TIME ZONE 'Asia/Colombo' THEN RAISE EXCEPTION 'New dispatch must start in the future.' USING ERRCODE='23514'; END IF;
 PERFORM order_id FROM public.customer_order WHERE order_id=ANY(p_orders) ORDER BY order_id FOR UPDATE;
 INSERT INTO public.truck_dispatch VALUES(p_id,p_truck,p_route,p_driver,p_assistant,p_start,p_end);
 FOR oid IN SELECT DISTINCT unnest(p_orders) ORDER BY 1 LOOP
  INSERT INTO public.order_dispatch(order_id,dispatch_id) VALUES(oid,p_id);
 END LOOP;
END $$;
