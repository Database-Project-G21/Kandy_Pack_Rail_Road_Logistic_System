package com.kandypack.kandypackbackend.controller;

import com.kandypack.kandypackbackend.entity.City;
import com.kandypack.kandypackbackend.repository.CustomerRepo;
import com.kandypack.kandypackbackend.repository.StaffUserRepo;
import com.kandypack.kandypackbackend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.kandypack.kandypackbackend.entity.Customer;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;



@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private CustomerRepo customerRepo;

    @Autowired
    private CityRepo cityRepo;

    @Autowired
    private StaffUserRepo staffUserRepo;

    @Autowired
    private JwtUtil jwtUtil;

    private final BCryptPasswordEncoder encoder =
            new BCryptPasswordEncoder();

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody SignupRequest request) {

        City city = cityRepo.findById(request.getCityId())
                .orElse(null);

        if (city == null) {
            return ResponseEntity.badRequest().body("Invalid city ID");
        }

        Customer customer = new Customer();
        customer.setCustomerId(
                "CUST" + UUID.randomUUID()
                        .toString()
                        .substring(0, 6)
                        .toUpperCase()
        );
        customer.setCustomerName(request.getCustomerName());
        customer.setDeliveryAddress(request.getDeliveryAddress());
        customer.setPhoneNumber(request.getPhoneNumber());
        customer.setEmail(request.getEmail());
        customer.setCity(city);
        customer.setPassword(encoder.encode(request.getPassword()));

        customerRepo.save(customer);

        String token =
                jwtUtil.generateToken(customer.getCustomerId(), "CUSTOMER");

        Map<String, String> response = new HashMap<>();
        response.put("token", token);
        response.put("customerId", customer.getCustomerId());
        response.put("role", "CUSTOMER");

        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {

        Customer customer =
                customerRepo.findByEmail(request.getEmail()).orElse(null);

        if (customer != null &&
                encoder.matches(
                        request.getPassword(),
                        customer.getPassword()
                )) {

            String token =
                    jwtUtil.generateToken(
                            customer.getCustomerId(),
                            "CUSTOMER"
                    );

            Map<String, String> response = new HashMap<>();
            response.put("token", token);
            response.put("customerId", customer.getCustomerId());
            response.put("role", "CUSTOMER");

            return ResponseEntity.ok(response);
        }

        return ResponseEntity
                .status(401)
                .body("Invalid email or password");
    }

    public static class SignupRequest {
        private String customerName;
        private String deliveryAddress;
        private String phoneNumber;
        private String email;
        private String cityId;
        private String password;

        public String getCustomerName() {
            return customerName;
        }

        public void setCustomerName(String customerName) {
            this.customerName = customerName;
        }

        public String getDeliveryAddress() {
            return deliveryAddress;
        }

        public void setDeliveryAddress(String deliveryAddress) {
            this.deliveryAddress = deliveryAddress;
        }

        public String getPhoneNumber() {
            return phoneNumber;
        }

        public void setPhoneNumber(String phoneNumber) {
            this.phoneNumber = phoneNumber;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getCityId() {
            return cityId;
        }

        public void setCityId(String cityId) {
            this.cityId = cityId;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }
    }

    public static class LoginRequest {
        private String email;
        private String password;

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }

        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }
    }
}

interface CityRepo extends JpaRepository<City, String> {
}