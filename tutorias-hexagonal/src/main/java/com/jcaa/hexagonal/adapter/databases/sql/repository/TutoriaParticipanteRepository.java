package com.jcaa.hexagonal.adapter.databases.sql.repository;

import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaParticipanteEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TutoriaParticipanteRepository extends JpaRepository<TutoriaParticipanteEntity, Integer> {
    List<TutoriaParticipanteEntity> findByTutoriaId(String tutoriaId);
    List<TutoriaParticipanteEntity> findByEstudianteId(String estudianteId);
    boolean existsByTutoriaIdAndEstudianteId(String tutoriaId, String estudianteId);
}
