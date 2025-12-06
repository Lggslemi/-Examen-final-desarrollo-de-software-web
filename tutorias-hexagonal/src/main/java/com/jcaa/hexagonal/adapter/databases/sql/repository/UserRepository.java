package com.jcaa.hexagonal.adapter.databases.sql.repository;

import com.jcaa.hexagonal.adapter.databases.sql.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.List;

public interface UserRepository extends JpaRepository<UserEntity, String> {
    Optional<UserEntity> findByEmail(String email);
    List<UserEntity> findByRole(String role);
}
