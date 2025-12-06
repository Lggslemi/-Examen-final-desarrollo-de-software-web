package com.jcaa.hexagonal.core.service;

import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaParticipanteEntity;
import com.jcaa.hexagonal.adapter.databases.sql.repository.TutoriaParticipanteRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class TutoriaParticipanteService {
    private final TutoriaParticipanteRepository repo;

    public TutoriaParticipanteService(TutoriaParticipanteRepository repo){ this.repo = repo; }

    public TutoriaParticipanteEntity agregarParticipante(TutoriaParticipanteEntity p){ return repo.save(p); }
    public List<TutoriaParticipanteEntity> listarPorTutoria(String tutoriaId){ return repo.findByTutoriaId(tutoriaId); }
    public List<TutoriaParticipanteEntity> listarPorEstudiante(String estudianteId){ return repo.findByEstudianteId(estudianteId); }
    public Optional<TutoriaParticipanteEntity> buscarPorId(Integer id){ return repo.findById(id); }
    public void eliminar(Integer id){ repo.deleteById(id); }
    public boolean estaInscrito(String tutoriaId, String estudianteId){ return repo.existsByTutoriaIdAndEstudianteId(tutoriaId, estudianteId); }
}
