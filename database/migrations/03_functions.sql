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
