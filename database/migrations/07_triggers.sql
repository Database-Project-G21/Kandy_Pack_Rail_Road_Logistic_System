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
CREATE FUNCTION public.kp_cancel_reservations() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
        UPDATE public.order_trip_item SET reservation_active = false
        WHERE order_id = NEW.order_id AND reservation_active;
    END IF;
    RETURN NEW;
END $$;
CREATE FUNCTION public.kp_check_order_dispatch() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE o public.customer_order; d public.truck_dispatch; ready timestamp; truck_capacity numeric; used numeric;
BEGIN
 IF TG_OP <> 'INSERT' THEN RAISE EXCEPTION 'Order delivery assignments are immutable.' USING ERRCODE='23514'; END IF;
 UPDATE public.kp_roster_mutex SET revision=revision+1 WHERE id=1;
 SELECT * INTO o FROM public.customer_order WHERE order_id=NEW.order_id FOR UPDATE;
 SELECT * INTO d FROM public.truck_dispatch WHERE dispatch_id=NEW.dispatch_id FOR UPDATE;
 IF o.order_id IS NULL OR d.dispatch_id IS NULL THEN RAISE EXCEPTION 'Order or dispatch not found.' USING ERRCODE='23503'; END IF;
 IF o.status<>'scheduled' THEN RAISE EXCEPTION 'Only a scheduled order can be assigned to a truck.' USING ERRCODE='23514'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.order_trip_item WHERE order_id=o.order_id AND reservation_active)
 OR EXISTS(SELECT 1 FROM public.order_item oi WHERE oi.order_id=o.order_id AND oi.quantity <>
    COALESCE((SELECT sum(a.quantity) FROM public.order_trip_item a WHERE a.order_id=oi.order_id AND a.product_id=oi.product_id AND a.reservation_active),0))
 OR EXISTS(SELECT 1 FROM public.order_travel WHERE order_id=o.order_id AND route_id<>d.route_id) THEN
  RAISE EXCEPTION 'Order must be fully allocated to this delivery route.' USING ERRCODE='23514';
 END IF;
 SELECT max(ts.arrival_datetime) INTO ready FROM public.order_trip_item a JOIN public.train_schedule ts USING(trip_id)
 WHERE a.order_id=o.order_id AND a.reservation_active;
 IF d.start_time<ready OR d.end_time>=o.delivery_date+interval '1 day' THEN
  RAISE EXCEPTION 'Delivery must start after all train arrivals and finish by the delivery date.' USING ERRCODE='23514';
 END IF;
 SELECT t.capacity INTO truck_capacity FROM public.truck t WHERE t.truck_id=d.truck_id;
 SELECT COALESCE(sum(a.quantity*a.space_per_unit),0) INTO used FROM public.order_trip_item a
 WHERE a.reservation_active AND (a.order_id=o.order_id OR a.order_id IN (SELECT order_id FROM public.order_dispatch WHERE dispatch_id=d.dispatch_id));
 IF used>truck_capacity THEN RAISE EXCEPTION 'Selected orders exceed truck capacity.' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE FUNCTION public.kp_check_roster() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE w timestamp; hours numeric; limit_hours integer; who text; person text;
BEGIN
 UPDATE public.kp_roster_mutex SET revision=revision+1 WHERE id=1;
 IF TG_OP <> 'INSERT' THEN
  IF EXISTS(SELECT 1 FROM public.order_dispatch WHERE dispatch_id=OLD.dispatch_id) THEN
   RAISE EXCEPTION 'A dispatch linked to orders cannot be edited or deleted.' USING ERRCODE='23514';
  END IF;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 END IF;
 IF NEW.end_time<=NEW.start_time THEN RAISE EXCEPTION 'End time must follow start time.' USING ERRCODE='23514'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.truck t JOIN public.route r ON r.store_id=t.store_id
    WHERE t.truck_id=NEW.truck_id AND r.route_id=NEW.route_id
      AND NEW.end_time-NEW.start_time <= r.max_delivery_time * interval '1 hour') THEN
  RAISE EXCEPTION 'Truck must belong to the route store; duration must fit the route maximum.' USING ERRCODE='23514';
 END IF;
 IF EXISTS(SELECT 1 FROM public.truck_dispatch d WHERE d.dispatch_id<>NEW.dispatch_id
    AND (d.truck_id=NEW.truck_id OR d.driver_id=NEW.driver_id OR d.assistant_id=NEW.assistant_id)
    AND NEW.start_time<d.end_time AND NEW.end_time>d.start_time) THEN
  RAISE EXCEPTION 'Truck, driver or assistant has an overlapping delivery.' USING ERRCODE='23514';
 END IF;
 IF EXISTS(SELECT 1 FROM public.truck_dispatch d WHERE d.dispatch_id<>NEW.dispatch_id AND d.driver_id=NEW.driver_id
    AND NEW.start_time < d.end_time + interval '1 hour' AND NEW.end_time + interval '1 hour' > d.start_time) THEN
  RAISE EXCEPTION 'Driver needs at least a one-hour break between deliveries.' USING ERRCODE='23514';
 END IF;
 IF EXISTS(WITH s AS (
    SELECT dispatch_id,start_time,end_time FROM public.truck_dispatch WHERE assistant_id=NEW.assistant_id AND dispatch_id<>NEW.dispatch_id
    UNION ALL SELECT NEW.dispatch_id,NEW.start_time,NEW.end_time
  ), triples AS (
    SELECT *, lag(dispatch_id) OVER q AS prev_id, lag(dispatch_id,2) OVER q AS prev2_id,
      lag(end_time) OVER q AS prev_end, lag(start_time) OVER q AS prev_start,
      lag(end_time,2) OVER q AS prev2_end FROM s WINDOW q AS (ORDER BY start_time,dispatch_id)
  ) SELECT 1 FROM triples WHERE NEW.dispatch_id IN (dispatch_id,prev_id,prev2_id)
    AND start_time<prev_end+interval '1 hour' AND prev_start<prev2_end+interval '1 hour') THEN
  RAISE EXCEPTION 'Assistant needs a one-hour break after at most two consecutive routes.' USING ERRCODE='23514';
 END IF;
 FOREACH who IN ARRAY ARRAY['driver','assistant'] LOOP
  person:=CASE WHEN who='driver' THEN NEW.driver_id ELSE NEW.assistant_id END;
  limit_hours:=CASE WHEN who='driver' THEN 40 ELSE 60 END;
  FOR w IN SELECT generate_series(date_trunc('week',NEW.start_time), date_trunc('week',NEW.end_time-interval '1 microsecond'),interval '1 week') LOOP
   SELECT COALESCE(SUM(EXTRACT(epoch FROM (LEAST(d.end_time,w+interval '1 week')-GREATEST(d.start_time,w)))/3600),0)
   INTO hours FROM public.truck_dispatch d WHERE d.dispatch_id<>NEW.dispatch_id
    AND (CASE WHEN who='driver' THEN d.driver_id ELSE d.assistant_id END)=person
    AND d.start_time<w+interval '1 week' AND d.end_time>w;
   hours:=hours+EXTRACT(epoch FROM (LEAST(NEW.end_time,w+interval '1 week')-GREATEST(NEW.start_time,w)))/3600;
   IF hours>limit_hours THEN RAISE EXCEPTION '% exceeds % hours for week %.',who,limit_hours,w::date USING ERRCODE='23514'; END IF;
  END LOOP;
 END LOOP;
 RETURN NEW;
END $$;
CREATE FUNCTION public.kp_delivery_status_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE d public.truck_dispatch;
BEGIN
 IF NEW.status IS NOT DISTINCT FROM OLD.status THEN RETURN NEW; END IF;
 SELECT td.* INTO d FROM public.order_dispatch od JOIN public.truck_dispatch td USING(dispatch_id) WHERE od.order_id=NEW.order_id;
 IF NEW.status='dispatched' AND d.dispatch_id IS NULL THEN RAISE EXCEPTION 'Assign a truck and crew in Delivery planning first.' USING ERRCODE='23514'; END IF;
 IF NEW.status='dispatched' AND d.start_time > clock_timestamp() AT TIME ZONE 'Asia/Colombo' THEN RAISE EXCEPTION 'The planned truck departure time has not arrived.' USING ERRCODE='23514'; END IF;
 IF NEW.status='cancelled' AND d.dispatch_id IS NOT NULL THEN RAISE EXCEPTION 'An order with a confirmed truck assignment cannot be cancelled.' USING ERRCODE='23514'; END IF;
 IF NEW.status='delivered' AND d.dispatch_id IS NULL AND NOT EXISTS(SELECT 1 FROM public.kp_legacy_fulfilment WHERE order_id=NEW.order_id) THEN
  RAISE EXCEPTION 'Order has no delivery assignment.' USING ERRCODE='23514';
 END IF;
 RETURN NEW;
END $$;
CREATE FUNCTION public.kp_new_trip_capacity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.allocated_capacity IS NULL THEN
        NEW.allocated_capacity := NEW.available_capacity;
    END IF;
    RETURN NEW;
END $$;
CREATE FUNCTION public.kp_order_status_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status IS NOT DISTINCT FROM OLD.status THEN RETURN NEW; END IF;
    IF NOT ((OLD.status = 'placed' AND NEW.status IN ('scheduled','cancelled'))
        OR (OLD.status = 'scheduled' AND NEW.status IN ('dispatched','cancelled'))
        OR (OLD.status = 'dispatched' AND NEW.status = 'delivered')) THEN
        RAISE EXCEPTION 'Invalid order status transition: % -> %.', OLD.status, NEW.status USING ERRCODE = '23514';
    END IF;
    IF NEW.status = 'scheduled' THEN
        IF NOT EXISTS (SELECT 1 FROM public.order_item WHERE order_id = NEW.order_id)
           OR EXISTS (SELECT 1 FROM public.order_item oi WHERE oi.order_id = NEW.order_id AND oi.quantity <>
             COALESCE((SELECT sum(a.quantity) FROM public.order_trip_item a
                       WHERE a.order_id = oi.order_id AND a.product_id = oi.product_id AND a.reservation_active),0)) THEN
            RAISE EXCEPTION 'An order must be fully allocated before it is scheduled.' USING ERRCODE = '23514';
        END IF;
    END IF;
    IF NEW.status = 'cancelled' THEN
        PERFORM s.store_id FROM public.store s
        WHERE s.store_id IN (SELECT ts.store_id FROM public.order_trip_item a
            JOIN public.train_schedule ts USING (trip_id) WHERE a.order_id = NEW.order_id AND a.reservation_active)
        ORDER BY s.store_id FOR UPDATE;
        PERFORM ts.trip_id FROM public.train_schedule ts
        WHERE ts.trip_id IN (SELECT trip_id FROM public.order_trip_item WHERE order_id = NEW.order_id AND reservation_active)
        ORDER BY ts.departure_datetime, ts.trip_id FOR UPDATE;
        IF EXISTS (SELECT 1 FROM public.order_trip_item a JOIN public.train_schedule ts USING (trip_id)
                   WHERE a.order_id = NEW.order_id AND a.reservation_active
                   AND ts.departure_datetime <= (clock_timestamp() AT TIME ZONE 'Asia/Colombo')) THEN
            RAISE EXCEPTION 'Cannot release an order after a reserved train has departed.' USING ERRCODE = '23514';
        END IF;
    END IF;
    RETURN NEW;
END $$;
CREATE FUNCTION public.kp_reserve_train_space() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_status public.order_status;
    v_order_qty integer;
    v_assigned_qty bigint;
    v_space numeric;
    v_delivery date;
    v_customer_city varchar(10);
    v_route_store varchar(10);
    v_route_city varchar(10);
    v_max_hours numeric;
    v_trip public.train_schedule%ROWTYPE;
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Keep allocation history. Cancel an eligible order to release its reservation.' USING ERRCODE = '23514';
    END IF;

    SELECT co.status, co.delivery_date, c.city_id
    INTO v_status, v_delivery, v_customer_city
    FROM public.customer_order co JOIN public.customer c USING (customer_id)
    WHERE co.order_id = NEW.order_id FOR UPDATE OF co;

    IF TG_OP = 'UPDATE' THEN
        IF ROW(NEW.order_id, NEW.trip_id, NEW.product_id, NEW.quantity, NEW.space_per_unit)
           IS DISTINCT FROM ROW(OLD.order_id, OLD.trip_id, OLD.product_id, OLD.quantity, OLD.space_per_unit)
           OR OLD.reservation_active = false OR NEW.reservation_active = true
           OR v_status <> 'cancelled' THEN
            RAISE EXCEPTION 'Allocation rows are immutable; only cancellation can release reservations.' USING ERRCODE = '23514';
        END IF;
        UPDATE public.train_schedule
        SET available_capacity = available_capacity + OLD.quantity * OLD.space_per_unit
        WHERE trip_id = OLD.trip_id;
        RETURN NEW;
    END IF;

    IF v_status IS DISTINCT FROM 'placed' OR NOT NEW.reservation_active THEN
        RAISE EXCEPTION 'Only a placed order can receive new train allocations.' USING ERRCODE = '23514';
    END IF;

    SELECT oi.quantity, p.space_consumption INTO v_order_qty, NEW.space_per_unit
    FROM public.order_item oi JOIN public.product p USING (product_id)
    WHERE oi.order_id = NEW.order_id AND oi.product_id = NEW.product_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order item does not exist.' USING ERRCODE = '23514';
    END IF;
    SELECT COALESCE(sum(quantity),0) INTO v_assigned_qty
    FROM public.order_trip_item WHERE order_id = NEW.order_id AND product_id = NEW.product_id;
    IF NEW.quantity + v_assigned_qty > v_order_qty THEN
        RAISE EXCEPTION 'Allocated quantity exceeds the ordered quantity.' USING ERRCODE = '23514';
    END IF;

    SELECT r.store_id, s.city_id, r.max_delivery_time
    INTO v_route_store, v_route_city, v_max_hours
    FROM public.order_travel ot JOIN public.route r USING (route_id)
    JOIN public.store s ON s.store_id = r.store_id
    WHERE ot.order_id = NEW.order_id AND ot.trip_id = NEW.trip_id;
    SELECT * INTO v_trip FROM public.train_schedule WHERE trip_id = NEW.trip_id FOR UPDATE;
    IF v_route_store IS NULL OR v_trip.trip_id IS NULL
       OR v_route_store <> v_trip.store_id OR v_route_city <> v_trip.city_id
       OR v_customer_city <> v_route_city THEN
        RAISE EXCEPTION 'Customer, route, store and trip destination must match.' USING ERRCODE = '23514';
    END IF;
    IF v_trip.departure_datetime <= (clock_timestamp() AT TIME ZONE 'Asia/Colombo')
       OR v_trip.arrival_datetime + v_max_hours * interval '1 hour' >= (v_delivery + 1)::timestamp THEN
        RAISE EXCEPTION 'Trip must be in the future and allow delivery by the requested date.' USING ERRCODE = '23514';
    END IF;
    v_space := NEW.quantity * NEW.space_per_unit;
    UPDATE public.train_schedule SET available_capacity = available_capacity - v_space
    WHERE trip_id = NEW.trip_id AND available_capacity >= v_space;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Insufficient capacity for the requested allocation.' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END $$;
CREATE FUNCTION public.kp_validate_trip() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF TG_OP='UPDATE' THEN
  IF ROW(NEW.train_id,NEW.city_id,NEW.store_id,NEW.departure_datetime,NEW.arrival_datetime,NEW.allocated_capacity)
    IS NOT DISTINCT FROM ROW(OLD.train_id,OLD.city_id,OLD.store_id,OLD.departure_datetime,OLD.arrival_datetime,OLD.allocated_capacity) THEN RETURN NEW; END IF;
  IF EXISTS(SELECT 1 FROM public.order_trip_item WHERE trip_id=OLD.trip_id) THEN RAISE EXCEPTION 'A train trip with order allocations cannot be rescheduled.' USING ERRCODE='23514'; END IF;
 END IF;
 PERFORM train_id FROM public.train WHERE train_id=NEW.train_id FOR UPDATE;
 IF NOT EXISTS(SELECT 1 FROM public.store WHERE store_id=NEW.store_id AND city_id=NEW.city_id) THEN RAISE EXCEPTION 'Store must belong to the destination city.' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM public.train WHERE train_id=NEW.train_id AND size<NEW.allocated_capacity) THEN RAISE EXCEPTION 'Allocated cargo capacity exceeds train size.' USING ERRCODE='23514'; END IF;
 IF EXISTS(SELECT 1 FROM public.train_schedule WHERE trip_id<>NEW.trip_id AND train_id=NEW.train_id
    AND departure_datetime<NEW.arrival_datetime AND arrival_datetime>NEW.departure_datetime) THEN RAISE EXCEPTION 'Train has an overlapping trip.' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END $$;
CREATE FUNCTION public.trg_fn_assistant_max_consecutive() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    consecutive_count INT;
BEGIN
    SELECT COUNT(*) INTO consecutive_count
    FROM TRUCK_DISPATCH
    WHERE assistant_id = NEW.assistant_id
    AND end_time >= NEW.start_time - INTERVAL '12 hours';

    IF consecutive_count >= 2 THEN
        RAISE EXCEPTION 'Assistant cannot exceed 2 consecutive route assignments';
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_assistant_no_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflict_count INT;
BEGIN
    SELECT COUNT(*) INTO conflict_count
    FROM TRUCK_DISPATCH
    WHERE assistant_id = NEW.assistant_id
    AND NEW.start_time < end_time
    AND NEW.end_time > start_time;

    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'Assistant already has an overlapping dispatch';
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_assistant_weekly_hours() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_hours DECIMAL(6,2);
BEGIN
    SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600), 0)
    INTO total_hours
    FROM TRUCK_DISPATCH
    WHERE assistant_id = NEW.assistant_id
    AND date_trunc('week', start_time) = date_trunc('week', NEW.start_time);

    IF total_hours + (EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 3600) > 60 THEN
        RAISE EXCEPTION 'Assistant weekly hour limit (60 hrs) exceeded';
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_deduct_capacity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    needed_space DECIMAL(10,2);
    remaining_space DECIMAL(10,2);
BEGIN
    SELECT SUM(oi.quantity * p.space_consumption)
    INTO needed_space
    FROM ORDER_ITEM oi
    JOIN PRODUCT p ON oi.product_id = p.product_id
    WHERE oi.order_id = NEW.order_id;

    SELECT available_capacity INTO remaining_space
    FROM TRAIN_SCHEDULE
    WHERE trip_id = NEW.trip_id;

    IF needed_space > remaining_space THEN
        RAISE EXCEPTION 'Order exceeds available train capacity for this trip';
    ELSE
        UPDATE TRAIN_SCHEDULE
        SET available_capacity = available_capacity - needed_space
        WHERE trip_id = NEW.trip_id;
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_driver_no_consecutive() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    last_end TIMESTAMP;
BEGIN
    SELECT MAX(end_time) INTO last_end
    FROM TRUCK_DISPATCH
    WHERE driver_id = NEW.driver_id;

    IF last_end IS NOT NULL AND NEW.start_time <= last_end + INTERVAL '1 hour' THEN
        RAISE EXCEPTION 'Driver cannot be assigned two consecutive deliveries without a break';
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_driver_no_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflict_count INT;
BEGIN
    SELECT COUNT(*) INTO conflict_count
    FROM TRUCK_DISPATCH
    WHERE driver_id = NEW.driver_id
    AND NEW.start_time < end_time
    AND NEW.end_time > start_time;

    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'Driver already has an overlapping dispatch';
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_driver_weekly_hours() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_hours DECIMAL(6,2);
BEGIN
    SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600), 0)
    INTO total_hours
    FROM TRUCK_DISPATCH
    WHERE driver_id = NEW.driver_id
    AND date_trunc('week', start_time) = date_trunc('week', NEW.start_time);

    IF total_hours + (EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 3600) > 40 THEN
        RAISE EXCEPTION 'Driver weekly hour limit (40 hrs) exceeded';
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_truck_no_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    conflict_count INT;
BEGIN
    SELECT COUNT(*) INTO conflict_count
    FROM TRUCK_DISPATCH
    WHERE truck_id = NEW.truck_id
    AND NEW.start_time < end_time
    AND NEW.end_time > start_time;

    IF conflict_count > 0 THEN
        RAISE EXCEPTION 'Truck already has an overlapping dispatch';
    END IF;

    RETURN NEW;
END;
$$;
CREATE FUNCTION public.trg_fn_update_hours() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE DRIVER
    SET weekly_hours_logged = weekly_hours_logged + (EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 3600)
    WHERE driver_id = NEW.driver_id;

    UPDATE ASSISTANT
    SET weekly_hours_logged = weekly_hours_logged + (EXTRACT(EPOCH FROM (NEW.end_time - NEW.start_time)) / 3600)
    WHERE assistant_id = NEW.assistant_id;

    RETURN NEW;
END;
$$;
CREATE TRIGGER kp_booked_item_guard BEFORE INSERT OR DELETE OR UPDATE ON public.order_item FOR EACH ROW EXECUTE FUNCTION public.kp_booked_item_guard();
CREATE TRIGGER kp_booked_travel_guard BEFORE DELETE OR UPDATE ON public.order_travel FOR EACH ROW EXECUTE FUNCTION public.kp_booked_travel_guard();
CREATE TRIGGER kp_cancel_reservations AFTER UPDATE OF status ON public.customer_order FOR EACH ROW EXECUTE FUNCTION public.kp_cancel_reservations();
CREATE TRIGGER kp_check_order_dispatch BEFORE INSERT OR DELETE OR UPDATE ON public.order_dispatch FOR EACH ROW EXECUTE FUNCTION public.kp_check_order_dispatch();
CREATE TRIGGER kp_check_roster BEFORE INSERT OR DELETE OR UPDATE ON public.truck_dispatch FOR EACH ROW EXECUTE FUNCTION public.kp_check_roster();
CREATE TRIGGER kp_delivery_status_guard BEFORE UPDATE OF status ON public.customer_order FOR EACH ROW EXECUTE FUNCTION public.kp_delivery_status_guard();
CREATE TRIGGER kp_new_trip_capacity BEFORE INSERT ON public.train_schedule FOR EACH ROW EXECUTE FUNCTION public.kp_new_trip_capacity();
CREATE TRIGGER kp_order_status_guard BEFORE UPDATE OF status ON public.customer_order FOR EACH ROW EXECUTE FUNCTION public.kp_order_status_guard();
CREATE TRIGGER kp_reserve_train_space BEFORE INSERT OR DELETE OR UPDATE ON public.order_trip_item FOR EACH ROW EXECUTE FUNCTION public.kp_reserve_train_space();
CREATE TRIGGER kp_validate_trip BEFORE INSERT OR UPDATE ON public.train_schedule FOR EACH ROW EXECUTE FUNCTION public.kp_validate_trip();
