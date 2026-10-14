package com.kandypack.kandypackbackend.controller;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/dispatches")
@PreAuthorize("hasAnyRole('ADMIN','DISPATCHER')")
public class DispatchController {
    private final JdbcTemplate jdbc;
    public DispatchController(JdbcTemplate jdbc) { this.jdbc=jdbc; }

    @GetMapping
    public List<Map<String,Object>> all() {
        return jdbc.queryForList("""
            SELECT d.*, dr.driver_name, a.assistant_name, t.plate_number,
             (SELECT string_agg(od.order_id, ', ' ORDER BY od.order_id) FROM order_dispatch od WHERE od.dispatch_id=d.dispatch_id) AS orders
            FROM truck_dispatch d JOIN driver dr USING(driver_id) JOIN assistant a USING(assistant_id)
            JOIN truck t USING(truck_id) ORDER BY start_time DESC,dispatch_id
            """);
    }
    @GetMapping("/options")
    public Map<String,Object> options() {
        return Map.of("trucks",jdbc.queryForList("SELECT truck_id,store_id,plate_number,capacity FROM truck ORDER BY truck_id"),
            "drivers",jdbc.queryForList("SELECT driver_id,driver_name FROM driver ORDER BY driver_id"),
            "assistants",jdbc.queryForList("SELECT assistant_id,assistant_name FROM assistant ORDER BY assistant_id"),
            "routes",jdbc.queryForList("SELECT route_id,store_id,city,coverage_area,max_delivery_time FROM route ORDER BY route_id"),
            "orders",jdbc.queryForList("""
              SELECT o.order_id,o.delivery_date,min(ot.route_id) AS route_id,max(ts.arrival_datetime) AS ready_at,
                 sum(a.quantity*a.space_per_unit) AS required_space
              FROM customer_order o JOIN order_trip_item a USING(order_id)
              JOIN order_travel ot ON ot.order_id=a.order_id AND ot.trip_id=a.trip_id
              JOIN train_schedule ts ON ts.trip_id=a.trip_id
              WHERE o.status='scheduled' AND a.reservation_active
                AND NOT EXISTS(SELECT 1 FROM order_dispatch od WHERE od.order_id=o.order_id)
              GROUP BY o.order_id,o.delivery_date HAVING count(DISTINCT ot.route_id)=1
              ORDER BY o.delivery_date,o.order_id
              """));
    }
    public record DispatchRequest(@NotBlank @Size(max=10) String truckId,@NotBlank @Size(max=10) String routeId,
        @NotBlank @Size(max=10) String driverId,@NotBlank @Size(max=10) String assistantId,
        @NotNull LocalDateTime startTime,@NotNull LocalDateTime endTime,
        @NotEmpty @Size(max=100) List<@NotBlank @Size(max=10) String> orderIds) {}

    @PostMapping
    @Transactional
    public Map<String,String> create(@Valid @RequestBody DispatchRequest r) {
        String id="DSP"+UUID.randomUUID().toString().replace("-", "").substring(0,7).toUpperCase();
        String placeholders=String.join(",",Collections.nCopies(r.orderIds().size(),"CAST(? AS varchar)"));
        List<Object> args=new ArrayList<>(List.of(id,r.truckId(),r.routeId(),r.driverId(),r.assistantId(),r.startTime(),r.endTime()));
        args.addAll(r.orderIds());
        jdbc.update("CALL kp_create_dispatch(CAST(? AS varchar),CAST(? AS varchar),CAST(? AS varchar),CAST(? AS varchar),CAST(? AS varchar),CAST(? AS timestamp),CAST(? AS timestamp),ARRAY["+placeholders+"]::varchar[])",args.toArray());
        return Map.of("dispatchId",id,"message","Truck and crew assigned. Mark orders dispatched when the truck leaves.");
    }
}
