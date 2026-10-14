-- Review database only. Fixtures are always rolled back, including on failure.
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path TO public;
DO $$ BEGIN IF current_database()<>'kandypack_review' THEN RAISE EXCEPTION 'Run checks only on kandypack_review'; END IF; END $$;
CREATE FUNCTION pg_temp.expect_failure(statement text, expected text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE caught boolean:=false;
BEGIN
 BEGIN EXECUTE statement; EXCEPTION WHEN OTHERS THEN
  IF position(expected IN SQLERRM)=0 THEN RAISE; END IF;
  caught:=true;
 END;
 IF NOT caught THEN RAISE EXCEPTION 'Expected failure did not happen: %',statement; END IF;
END $$;
INSERT INTO store VALUES('QASTORE','CMB');
INSERT INTO route VALUES('QAROUTE','QASTORE','Colombo','QA area',24);
INSERT INTO truck VALUES('QATRUCK','QASTORE','QA ONLY',100);
INSERT INTO driver(driver_id,driver_name) VALUES('QADR1','QA driver 1'),('QADR2','QA driver 2'),('QADR3','QA driver 3');
INSERT INTO assistant(assistant_id,assistant_name) VALUES('QAAS1','QA assistant 1'),('QAAS2','QA assistant 2');
INSERT INTO truck_dispatch VALUES('QAD1','QATRUCK','QAROUTE','QADR1','QAAS1','2030-01-07 08:00','2030-01-07 10:00');
SELECT pg_temp.expect_failure($q$INSERT INTO truck_dispatch VALUES('QAD2','QATRUCK','QAROUTE','QADR2','QAAS2','2030-01-07 09:00','2030-01-07 11:00')$q$,'overlapping');
SELECT pg_temp.expect_failure($q$INSERT INTO truck_dispatch VALUES('QAD2','QATRUCK','QAROUTE','QADR1','QAAS2','2030-01-07 10:00','2030-01-07 11:00')$q$,'one-hour');
INSERT INTO truck_dispatch VALUES('QAD2','QATRUCK','QAROUTE','QADR2','QAAS1','2030-01-07 10:00','2030-01-07 12:00');
SELECT pg_temp.expect_failure($q$INSERT INTO truck_dispatch VALUES('QAD3','QATRUCK','QAROUTE','QADR3','QAAS1','2030-01-07 12:00','2030-01-07 14:00')$q$,'two consecutive');
SELECT pg_temp.expect_failure($q$UPDATE truck_dispatch SET start_time='2030-01-07 09:00' WHERE dispatch_id='QAD2'$q$,'overlapping');
INSERT INTO truck_dispatch VALUES('QACROSS','QATRUCK','QAROUTE','QADR3','QAAS2','2030-01-20 23:00','2030-01-21 02:00');
DO $$ BEGIN
 IF (SELECT total_hours FROM view_weekly_crew_hours WHERE person_id='QADR3' AND week_start='2030-01-14')<>1
 OR (SELECT total_hours FROM view_weekly_crew_hours WHERE person_id='QADR3' AND week_start='2030-01-21')<>2 THEN RAISE EXCEPTION 'Cross-week split failed'; END IF;
END $$;
SELECT count(*) FROM view_quarterly_sales;
SELECT count(*) FROM view_top_items_quarter;
SELECT count(*) FROM view_city_route_sales;
SELECT count(*) FROM view_weekly_crew_hours;
SELECT count(*) FROM view_truck_utilization;
SELECT count(*) FROM view_customer_delivery_history;
ROLLBACK;
\echo PASS: review regression checks passed; all QA records rolled back.
