package com.jcaa.hexagonal.adapter.databases.sql.repository;

import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TutoriaRepository extends JpaRepository<TutoriaEntity, String> {
}
