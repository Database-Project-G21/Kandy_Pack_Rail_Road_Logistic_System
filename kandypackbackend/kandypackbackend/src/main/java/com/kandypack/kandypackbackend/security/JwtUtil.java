package com.kandypack.kandypackbackend.security;

import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;

@Component
public class JwtUtil {

    private final SecretKey key =
            Keys.secretKeyFor(io.jsonwebtoken.SignatureAlgorithm.HS256);

    private final long EXPIRATION_MS =
            1000 * 60 * 60 * 24; // 24 hours
}