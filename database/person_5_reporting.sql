-- =========================================================
-- Kandypack Rail & Road Logistics System
-- Person 5: Reporting Views and Indexes
-- Depends on the existing core schema.
-- Run only after the core schema has been created.
-- =========================================================

-- 1. Order reporting view
-- Provides customer details alongside order information.
CREATE OR REPLACE VIEW public.v_order_report AS
SELECT
    co.order_id,
    co.customer_id,
    c.customer_name,
    c.email AS customer_email,
    co.amount,
    co.placement_date,
    co.delivery_date,
    co.status
FROM public.customer_order AS co
JOIN public.customer AS c
    ON c.customer_id = co.customer_id;

-- 2. Order status summary view
-- Useful for staff dashboard reporting.
CREATE OR REPLACE VIEW public.v_order_status_summary AS
SELECT
    status,
    COUNT(*) AS order_count,
    COALESCE(SUM(amount), 0) AS total_order_value,
    COALESCE(AVG(amount), 0) AS average_order_value
FROM public.customer_order
GROUP BY status;

-- 3. Monthly order summary view
-- Summarizes orders and order value by placement month.
CREATE OR REPLACE VIEW public.v_monthly_order_summary AS
SELECT
    DATE_TRUNC('month', placement_date)::date AS order_month,
    COUNT(*) AS order_count,
    COALESCE(SUM(amount), 0) AS total_order_value,
    COALESCE(AVG(amount), 0) AS average_order_value
FROM public.customer_order
GROUP BY DATE_TRUNC('month', placement_date)::date;

-- 4. Indexes for common reporting and lookup operations.
-- Do not create these if equivalent indexes already exist.
CREATE INDEX IF NOT EXISTS idx_customer_order_placement_date
    ON public.customer_order (placement_date);

CREATE INDEX IF NOT EXISTS idx_customer_order_delivery_date
    ON public.customer_order (delivery_date);

CREATE INDEX IF NOT EXISTS idx_customer_order_status
    ON public.customer_order (status);

CREATE INDEX IF NOT EXISTS idx_customer_order_customer_id
    ON public.customer_order (customer_id);

-- =========================================================
-- Sample reporting queries
-- =========================================================

-- A. All orders with customer details
SELECT *
FROM public.v_order_report
ORDER BY placement_date DESC;

-- B. Order counts and value by status
SELECT *
FROM public.v_order_status_summary
ORDER BY status;

-- C. Monthly order performance
SELECT *
FROM public.v_monthly_order_summary
ORDER BY order_month DESC;

-- D. Orders scheduled for delivery today or earlier
-- Review pending statuses before using this as an overdue metric.
SELECT *
FROM public.v_order_report
WHERE delivery_date <= CURRENT_DATE
  AND LOWER(status) NOT IN ('delivered', 'cancelled')
ORDER BY delivery_date;