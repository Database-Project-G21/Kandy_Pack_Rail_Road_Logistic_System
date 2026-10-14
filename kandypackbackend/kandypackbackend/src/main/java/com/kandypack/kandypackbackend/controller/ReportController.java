package com.kandypack.kandypackbackend.controller;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.time.DayOfWeek;
import java.util.*;

@RestController
@RequestMapping("/api/reports")
@PreAuthorize("hasAnyRole('ADMIN','DISPATCHER')")
public class ReportController {
 private final JdbcTemplate jdbc;
 public ReportController(JdbcTemplate jdbc){this.jdbc=jdbc;}
 @GetMapping("/{report}")
 public List<Map<String,Object>> report(@PathVariable String report,
   @RequestParam(defaultValue="2026") int year,@RequestParam(defaultValue="1") int quarter,
   @RequestParam(defaultValue="1") int month,@RequestParam(required=false) @org.springframework.format.annotation.DateTimeFormat(iso=org.springframework.format.annotation.DateTimeFormat.ISO.DATE) LocalDate week,
   @RequestParam(defaultValue="") String customerId) {
  if(year<2000 || year>2100 || quarter<1 || quarter>4 || month<1 || month>12)throw new IllegalArgumentException("Invalid year, quarter or month");
  return switch(report){
   case "quarterly" -> jdbc.queryForList("SELECT * FROM view_quarterly_sales WHERE sales_year=? AND sales_quarter=?",year,quarter);
   case "top-items" -> jdbc.queryForList("SELECT * FROM view_top_items_quarter WHERE sales_year=? AND sales_quarter=? ORDER BY quantity DESC,product_id",year,quarter);
   case "city-routes" -> jdbc.queryForList("SELECT * FROM view_city_route_sales ORDER BY city_name,route_id");
   case "crew-hours" -> jdbc.queryForList("SELECT * FROM view_weekly_crew_hours WHERE week_start=? ORDER BY role,person_id",
       (week==null?LocalDate.now(java.time.ZoneId.of("Asia/Colombo")):week).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)));
   case "truck-usage" -> jdbc.queryForList("""
     SELECT t.truck_id,t.plate_number,count(d.dispatch_id) AS total_trips,
       round(COALESCE(sum(extract(epoch FROM (LEAST(d.end_time,?::timestamp)-GREATEST(d.start_time,?::timestamp)))/3600),0),2) AS total_hours_operated
     FROM truck t LEFT JOIN truck_dispatch d ON t.truck_id=d.truck_id AND d.start_time<?::timestamp AND d.end_time>?::timestamp
     GROUP BY t.truck_id,t.plate_number ORDER BY t.truck_id
     """,LocalDate.of(year,month,1).plusMonths(1).atStartOfDay(),LocalDate.of(year,month,1).atStartOfDay(),
        LocalDate.of(year,month,1).plusMonths(1).atStartOfDay(),LocalDate.of(year,month,1).atStartOfDay());
   case "history" -> customerId.isBlank()?jdbc.queryForList("SELECT * FROM view_customer_delivery_history ORDER BY placement_date DESC,order_id"):
     jdbc.queryForList("SELECT * FROM view_customer_delivery_history WHERE customer_id=? ORDER BY placement_date DESC,order_id",customerId);
   default -> throw new IllegalArgumentException("Unknown report");
  };
 }
}
