package com.jcaa.hexagonal.adapter.databases.sql.repository;

import com.jcaa.hexagonal.adapter.databases.sql.entity.PasswordResetEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface PasswordResetRepository extends JpaRepository<PasswordResetEntity, Integer> {
    Optional<PasswordResetEntity> findByToken(String token);
}
