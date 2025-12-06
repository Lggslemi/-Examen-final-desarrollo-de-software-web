package com.jcaa.hexagonal.core.service;

import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaEntity;
import com.jcaa.hexagonal.adapter.databases.sql.repository.TutoriaRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class TutoriaService {
    private final TutoriaRepository repo;

    public TutoriaService(TutoriaRepository repo){
        this.repo = repo;
    }

    public TutoriaEntity crearTutoria(TutoriaEntity t){ return repo.save(t); }
    public List<TutoriaEntity> listar(){ return repo.findAll(); }
    public Optional<TutoriaEntity> buscarPorId(String id){ return repo.findById(id); }
    public void eliminar(String id){ repo.deleteById(id); }

    public List<TutoriaEntity> findByIds(List<String> ids){
        return repo.findAllById(ids);
    }
}
