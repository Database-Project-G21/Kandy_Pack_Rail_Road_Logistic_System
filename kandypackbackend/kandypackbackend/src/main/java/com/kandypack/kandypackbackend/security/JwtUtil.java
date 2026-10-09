package com.kandypack.kandypackbackend.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    private final SecretKey key =
            Keys.secretKeyFor(io.jsonwebtoken.SignatureAlgorithm.HS256);

    private final long EXPIRATION_MS =
            1000 * 60 * 60 * 24;

    public String generateToken(String id, String role) {
        return Jwts.builder()
                .subject(id)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + EXPIRATION_MS))
                .signWith(key)
                .compact();
    }
}