package com.kandypack.kandypackbackend.controller;

import com.kandypack.kandypackbackend.entity.TrainSchedule;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

@RestController
@RequestMapping("/api/trains")
public class TrainScheduleController {

    @Autowired
    private TrainScheduleRepo trainScheduleRepo;

    @Autowired private org.springframework.jdbc.core.JdbcTemplate jdbc;
    @GetMapping("/options")
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('ADMIN','DISPATCHER')")
    public java.util.Map<String,Object> options(){return java.util.Map.of(
        "trains",jdbc.queryForList("SELECT train_id,size FROM train ORDER BY train_id"),
        "stores",jdbc.queryForList("SELECT s.store_id,s.city_id,c.city_name FROM store s JOIN city c USING(city_id) ORDER BY s.store_id"));}
    public record TripRequest(@jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Size(max=10) String trainId,
      @jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Size(max=10) String storeId,
      @jakarta.validation.constraints.NotNull java.time.LocalDateTime departure,
      @jakarta.validation.constraints.NotNull java.time.LocalDateTime arrival,
      @jakarta.validation.constraints.NotNull @jakarta.validation.constraints.DecimalMin("0.01") java.math.BigDecimal capacity) {}
    @PostMapping
    @org.springframework.security.access.prepost.PreAuthorize("hasAnyRole('ADMIN','DISPATCHER')")
    @org.springframework.transaction.annotation.Transactional
    public java.util.Map<String,String> create(@jakarta.validation.Valid @RequestBody TripRequest r){
      if(!r.departure().isAfter(java.time.LocalDateTime.now(java.time.ZoneId.of("Asia/Colombo"))))throw new IllegalArgumentException("Departure must be in the future");
      if(!r.arrival().isAfter(r.departure()))throw new IllegalArgumentException("Arrival must follow departure");
      String id="TRP"+java.util.UUID.randomUUID().toString().replace("-", "").substring(0,7).toUpperCase();
      int count=jdbc.update("""
        INSERT INTO train_schedule(trip_id,city_id,departure_datetime,arrival_datetime,train_id,store_id,available_capacity,allocated_capacity)
        SELECT ?,city_id,?,?,?,?,?,? FROM store WHERE store_id=?
        """,id,r.departure(),r.arrival(),r.trainId(),r.storeId(),r.capacity(),r.capacity(),r.storeId());
      if(count!=1)throw new IllegalArgumentException("Destination store not found");
      return java.util.Map.of("tripId",id);
    }

    @GetMapping
    public List<TrainSchedule> getAllTrips() {
        return trainScheduleRepo.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<TrainSchedule> getTripById(@PathVariable String id) {
        return trainScheduleRepo.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}

interface TrainScheduleRepo extends JpaRepository<TrainSchedule, String> {
}