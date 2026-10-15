CREATE VIEW public.view_city_route_sales AS
 SELECT c.city_name,
    r.route_id,
    r.coverage_area,
    count(DISTINCT co.order_id) AS orders_count,
    sum(((a.quantity)::numeric * oi.price)) AS route_revenue
   FROM ((((((public.customer_order co
     JOIN public.order_trip_item a USING (order_id))
     JOIN public.order_item oi ON ((((oi.order_id)::text = (a.order_id)::text) AND ((oi.product_id)::text = (a.product_id)::text))))
     JOIN public.order_travel ot ON ((((ot.order_id)::text = (a.order_id)::text) AND ((ot.trip_id)::text = (a.trip_id)::text))))
     JOIN public.route r USING (route_id))
     JOIN public.store s ON (((s.store_id)::text = (r.store_id)::text)))
     JOIN public.city c ON (((c.city_id)::text = (s.city_id)::text)))
  WHERE (((co.status)::text <> 'cancelled'::text) AND a.reservation_active)
  GROUP BY c.city_name, r.route_id, r.coverage_area
  ORDER BY c.city_name, (sum(((a.quantity)::numeric * oi.price))) DESC;
CREATE VIEW public.view_customer_delivery_history AS
 SELECT o.order_id,
    o.customer_id,
    c.customer_name,
    o.placement_date,
    o.delivery_date,
    o.status,
    o.amount,
    d.dispatch_id,
    d.truck_id,
    d.driver_id,
    d.assistant_id,
    d.start_time,
    d.end_time,
    COALESCE(( SELECT string_agg(DISTINCT (t.trip_id)::text, ', '::text ORDER BY (t.trip_id)::text) AS string_agg
           FROM public.order_travel t
          WHERE ((t.order_id)::text = (o.order_id)::text)), ''::text) AS train_trips,
    COALESCE(( SELECT string_agg(DISTINCT (t.route_id)::text, ', '::text ORDER BY (t.route_id)::text) AS string_agg
           FROM public.order_travel t
          WHERE ((t.order_id)::text = (o.order_id)::text)), ''::text) AS routes
   FROM (((public.customer_order o
     JOIN public.customer c USING (customer_id))
     LEFT JOIN public.order_dispatch od USING (order_id))
     LEFT JOIN public.truck_dispatch d USING (dispatch_id));
CREATE VIEW public.view_weekly_crew_hours AS
 WITH spans AS (
         SELECT d_1.dispatch_id,
            d_1.truck_id,
            d_1.route_id,
            d_1.driver_id,
            d_1.assistant_id,
            d_1.start_time,
            d_1.end_time,
            w.w AS week_start,
            (EXTRACT(epoch FROM (LEAST(d_1.end_time, (w.w + '7 days'::interval)) - GREATEST(d_1.start_time, w.w))) / (3600)::numeric) AS hours
           FROM (public.truck_dispatch d_1
             CROSS JOIN LATERAL generate_series(date_trunc('week'::text, d_1.start_time), date_trunc('week'::text, (d_1.end_time - '00:00:00.000001'::interval)), '7 days'::interval) w(w))
        ), crew AS (
         SELECT 'Driver'::text AS role,
            spans.driver_id AS person_id,
            spans.week_start,
            spans.hours
           FROM spans
        UNION ALL
         SELECT 'Assistant'::text,
            spans.assistant_id,
            spans.week_start,
            spans.hours
           FROM spans
        )
 SELECT c.role,
    c.person_id,
    COALESCE(d.driver_name, a.assistant_name) AS name,
    (c.week_start)::date AS week_start,
    round(sum(c.hours), 2) AS total_hours
   FROM ((crew c
     LEFT JOIN public.driver d ON (((c.role = 'Driver'::text) AND ((d.driver_id)::text = (c.person_id)::text))))
     LEFT JOIN public.assistant a ON (((c.role = 'Assistant'::text) AND ((a.assistant_id)::text = (c.person_id)::text))))
  GROUP BY c.role, c.person_id, COALESCE(d.driver_name, a.assistant_name), ((c.week_start)::date);
CREATE VIEW public.view_driver_assistant_hours AS
 SELECT 'Driver'::text AS role,
    d.driver_id AS person_id,
    d.driver_name AS name,
    (COALESCE(( SELECT v.total_hours
           FROM public.view_weekly_crew_hours v
          WHERE ((v.role = 'Driver'::text) AND ((v.person_id)::text = (d.driver_id)::text) AND (v.week_start = (date_trunc('week'::text, (now() AT TIME ZONE 'Asia/Colombo'::text)))::date))), (0)::numeric))::numeric(5,2) AS total_hours
   FROM public.driver d
UNION ALL
 SELECT 'Assistant'::text AS role,
    a.assistant_id AS person_id,
    a.assistant_name AS name,
    (COALESCE(( SELECT v.total_hours
           FROM public.view_weekly_crew_hours v
          WHERE ((v.role = 'Assistant'::text) AND ((v.person_id)::text = (a.assistant_id)::text) AND (v.week_start = (date_trunc('week'::text, (now() AT TIME ZONE 'Asia/Colombo'::text)))::date))), (0)::numeric))::numeric(5,2) AS total_hours
   FROM public.assistant a;
CREATE VIEW public.view_quarterly_sales AS
 SELECT EXTRACT(year FROM co.placement_date) AS sales_year,
    EXTRACT(quarter FROM co.placement_date) AS sales_quarter,
    count(DISTINCT co.order_id) AS total_orders,
    sum(oi.quantity) AS total_units_sold,
    sum(((oi.quantity)::numeric * oi.price)) AS total_revenue
   FROM (public.customer_order co
     JOIN public.order_item oi ON (((co.order_id)::text = (oi.order_id)::text)))
  WHERE ((co.status)::text <> 'cancelled'::text)
  GROUP BY (EXTRACT(year FROM co.placement_date)), (EXTRACT(quarter FROM co.placement_date))
  ORDER BY (EXTRACT(year FROM co.placement_date)) DESC, (EXTRACT(quarter FROM co.placement_date)) DESC;
CREATE VIEW public.view_top_items_quarter AS
 SELECT (EXTRACT(year FROM o.placement_date))::integer AS sales_year,
    (EXTRACT(quarter FROM o.placement_date))::integer AS sales_quarter,
    i.product_id,
    p.product_name,
    sum(i.quantity) AS quantity,
    sum(((i.quantity)::numeric * i.price)) AS value
   FROM ((public.customer_order o
     JOIN public.order_item i USING (order_id))
     JOIN public.product p USING (product_id))
  WHERE ((o.status)::text <> 'cancelled'::text)
  GROUP BY ((EXTRACT(year FROM o.placement_date))::integer), ((EXTRACT(quarter FROM o.placement_date))::integer), i.product_id, p.product_name;
CREATE VIEW public.view_truck_utilization AS
 SELECT t.truck_id,
    t.plate_number,
    EXTRACT(year FROM td.start_time) AS year,
    EXTRACT(month FROM td.start_time) AS month,
    count(td.dispatch_id) AS total_trips,
    round(sum((EXTRACT(epoch FROM (td.end_time - td.start_time)) / (3600)::numeric)), 2) AS total_hours_operated
   FROM (public.truck t
     LEFT JOIN public.truck_dispatch td ON (((t.truck_id)::text = (td.truck_id)::text)))
  GROUP BY t.truck_id, t.plate_number, (EXTRACT(year FROM td.start_time)), (EXTRACT(month FROM td.start_time))
  ORDER BY t.truck_id, (EXTRACT(year FROM td.start_time)), (EXTRACT(month FROM td.start_time));
