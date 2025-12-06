package com.jcaa.hexagonal.entrypoint.rest.v1;

import com.jcaa.hexagonal.adapter.databases.sql.entity.UserEntity;
import com.jcaa.hexagonal.core.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService s){ this.userService = s; }

    @GetMapping("/me")
    public ResponseEntity<?> miPerfil(org.springframework.security.core.Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String id = auth.getName();
        var opt = userService.buscarPorId(id);
        if(opt.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Usuario no encontrado"));
        var u = opt.get();
        u.setPassword(null);
        return ResponseEntity.ok(u);
    }

    @GetMapping
    public ResponseEntity<List<UserEntity>> listar(@RequestParam(name="role", required=false) String role){
        List<UserEntity> lista;
        if(role == null || role.isBlank()){
            lista = userService.listarTodos();
        } else {
            lista = userService.listarPorRol(role);
        }
        lista.forEach(u -> u.setPassword(null));
        return ResponseEntity.ok(lista);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> obtener(@PathVariable String id){
        var opt = userService.buscarPorId(id);
        if(opt.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","No encontrado"));
        var u = opt.get();
        u.setPassword(null);
        return ResponseEntity.ok(u);
    }

    @PostMapping
    public ResponseEntity<?> crear(@RequestBody UserEntity u){
        
        String role = u.getRole();
        if(role == null || (!role.equals("student") && !role.equals("teacher"))){
            u.setRole("student");
        }
        var creado = userService.crearUsuario(u);
        creado.setPassword(null);
        return ResponseEntity.ok(creado);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> actualizar(@PathVariable String id, @RequestBody UserEntity cambios){
        
        cambios.setRole(null);
        var actualizado = userService.actualizarUsuario(id, cambios);
        if(actualizado == null) return ResponseEntity.status(404).body(Map.of("error","Usuario no encontrado"));
        actualizado.setPassword(null);
        return ResponseEntity.ok(actualizado);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> borrar(@PathVariable String id){
        boolean ok = userService.eliminarUsuario(id);
        if(!ok) return ResponseEntity.status(404).body(Map.of("error","Usuario no encontrado"));
        return ResponseEntity.ok(Map.of("ok",true));
    }
}
