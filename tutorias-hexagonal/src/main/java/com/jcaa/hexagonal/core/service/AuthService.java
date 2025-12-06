package com.jcaa.hexagonal.core.service;

import com.jcaa.hexagonal.adapter.databases.sql.entity.PasswordResetEntity;
import com.jcaa.hexagonal.adapter.databases.sql.entity.UserEntity;
import com.jcaa.hexagonal.adapter.databases.sql.repository.PasswordResetRepository;
import com.jcaa.hexagonal.adapter.databases.sql.repository.UserRepository;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;
import java.util.UUID;

@Service
public class AuthService {
    private final UserRepository userRepo;
    private final PasswordResetRepository resetRepo;
    private final Key key;
    private final long expirationMs;

    public AuthService(UserRepository userRepo,
                       PasswordResetRepository resetRepo,
                       @Value("${jwt.secret}") String jwtSecret,
                       @Value("${jwt.expiration.ms}") long expirationMs){
        this.userRepo = userRepo;
        this.resetRepo = resetRepo;
        this.key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
        this.expirationMs = expirationMs;
    }

    public String generarToken(UserEntity user){
        Date ahora = new Date();
        Date exp = new Date(ahora.getTime() + expirationMs);
        return Jwts.builder()
                .setSubject(user.getId())
                .claim("email", user.getEmail())
                .setIssuedAt(ahora)
                .setExpiration(exp)
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    public Jws<Claims> validarToken(String token){
        return Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
    }

    public PasswordResetEntity crearPasswordReset(UserEntity user, long minutosValidez){
        PasswordResetEntity pr = new PasswordResetEntity();
        pr.setUserId(user.getId());
        pr.setToken(UUID.randomUUID().toString());
        pr.setExpiresAt(LocalDateTime.now().plusMinutes(minutosValidez));
        return resetRepo.save(pr);
    }

    public PasswordResetEntity buscarResetPorToken(String token){
        return resetRepo.findByToken(token).orElse(null);
    }
}
