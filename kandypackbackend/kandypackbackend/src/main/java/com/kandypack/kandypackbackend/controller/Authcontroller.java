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
}

interface CityRepo extends JpaRepository<City, String> {
}