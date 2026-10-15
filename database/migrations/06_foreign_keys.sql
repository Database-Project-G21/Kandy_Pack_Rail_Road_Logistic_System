ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);
ALTER TABLE ONLY public.customer_order
    ADD CONSTRAINT customer_order_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id);
ALTER TABLE ONLY public.kp_legacy_fulfilment
    ADD CONSTRAINT kp_legacy_fulfilment_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.customer_order(order_id);
ALTER TABLE ONLY public.order_dispatch
    ADD CONSTRAINT order_dispatch_dispatch_id_fkey FOREIGN KEY (dispatch_id) REFERENCES public.truck_dispatch(dispatch_id);
ALTER TABLE ONLY public.order_dispatch
    ADD CONSTRAINT order_dispatch_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.customer_order(order_id);
ALTER TABLE ONLY public.order_item
    ADD CONSTRAINT order_item_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.customer_order(order_id);
ALTER TABLE ONLY public.order_item
    ADD CONSTRAINT order_item_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.product(product_id);
ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.customer_order(order_id);
ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.route(route_id);
ALTER TABLE ONLY public.order_travel
    ADD CONSTRAINT order_travel_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.train_schedule(trip_id);
ALTER TABLE ONLY public.order_trip_item
    ADD CONSTRAINT order_trip_item_order_id_product_id_fkey FOREIGN KEY (order_id, product_id) REFERENCES public.order_item(order_id, product_id);
ALTER TABLE ONLY public.order_trip_item
    ADD CONSTRAINT order_trip_item_order_id_trip_id_fkey FOREIGN KEY (order_id, trip_id) REFERENCES public.order_travel(order_id, trip_id);
ALTER TABLE ONLY public.route
    ADD CONSTRAINT route_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.store(store_id);
ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);
ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city(city_id);
ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.store(store_id);
ALTER TABLE ONLY public.train_schedule
    ADD CONSTRAINT train_schedule_train_id_fkey FOREIGN KEY (train_id) REFERENCES public.train(train_id);
ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_assistant_id_fkey FOREIGN KEY (assistant_id) REFERENCES public.assistant(assistant_id);
ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.driver(driver_id);
ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_route_id_fkey FOREIGN KEY (route_id) REFERENCES public.route(route_id);
ALTER TABLE ONLY public.truck_dispatch
    ADD CONSTRAINT truck_dispatch_truck_id_fkey FOREIGN KEY (truck_id) REFERENCES public.truck(truck_id);
ALTER TABLE ONLY public.truck
    ADD CONSTRAINT truck_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.store(store_id);
