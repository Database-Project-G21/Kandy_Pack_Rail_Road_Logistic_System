package com.kandypack.kandypackbackend.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    private final SecretKey key;
    public JwtUtil(@org.springframework.beans.factory.annotation.Value("${JWT_SECRET:}") String secret) {
        if (secret.isBlank()) {
            // Backward-compatible local fallback; configure JWT_SECRET for stable sessions.
            key = Jwts.SIG.HS256.key().build();
        } else {
            byte[] bytes=secret.getBytes(java.nio.charset.StandardCharsets.UTF_8);
            if(bytes.length<32)throw new IllegalArgumentException("JWT_SECRET must contain at least 32 UTF-8 bytes");
            key=Keys.hmacShaKeyFor(bytes);
        }
    }
    private final long EXPIRATION_MS = 1000 * 60 * 60 * 24; // 24 hours

    public String generateToken(String id, String role) {
        return Jwts.builder()
                .subject(id)
                .claim("role", role)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + EXPIRATION_MS))
                .signWith(key)
                .compact();
    }

    public String extractId(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .getSubject();
    }

    public String extractRole(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload()
                .get("role", String.class);
    }

    public boolean isTokenValid(String token) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}