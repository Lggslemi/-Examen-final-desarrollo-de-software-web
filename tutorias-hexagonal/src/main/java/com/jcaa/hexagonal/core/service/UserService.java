package com.jcaa.hexagonal.core.service;

import com.jcaa.hexagonal.adapter.databases.sql.entity.UserEntity;
import com.jcaa.hexagonal.adapter.databases.sql.repository.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.List;

@Service
public class UserService {
    private final UserRepository repo;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public UserService(UserRepository repo) {
        this.repo = repo;
    }

    public UserEntity crearUsuario(UserEntity u){
        // si vienen campos null, se asume que el caller los puso
        u.setPassword(encoder.encode(u.getPassword()));
        return repo.save(u);
    }

    public Optional<UserEntity> buscarPorEmail(String email){
        return repo.findByEmail(email);
    }

    public Optional<UserEntity> buscarPorId(String id){
        return repo.findById(id);
    }

    public boolean verificarPassword(String raw, String hash){
        return encoder.matches(raw, hash);
    }

    public List<UserEntity> listarTodos(){
        return repo.findAll();
    }

    public List<UserEntity> listarPorRol(String role){
        return repo.findByRole(role);
    }

    public UserEntity actualizarUsuario(String id, UserEntity cambios){
        var opt = repo.findById(id);
        if(opt.isEmpty()) return null;
        var u = opt.get();
        if(cambios.getName() != null) u.setName(cambios.getName());
        if(cambios.getEmail() != null) u.setEmail(cambios.getEmail());
        if(cambios.getPassword() != null && !cambios.getPassword().isEmpty()){
            u.setPassword(encoder.encode(cambios.getPassword()));
        }
        if(cambios.getRole() != null) u.setRole(cambios.getRole());
        if(cambios.getIsActive() != null) u.setIsActive(cambios.getIsActive());
        u.setUpdatedAt(java.time.LocalDateTime.now());
        return repo.save(u);
    }

    public boolean eliminarUsuario(String id){
        if(!repo.existsById(id)) return false;
        repo.deleteById(id);
        return true;
    }
}
