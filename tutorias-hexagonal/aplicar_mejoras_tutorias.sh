#!/usr/bin/env bash
set -e
ROOT="$(pwd)"
echo "Aplicando mejoras en $ROOT ..."

# 1) TutoriaService: agregar findByIds (y reuse crearTutoria para save)
cat > src/main/java/com/jcaa/hexagonal/core/service/TutoriaService.java <<'JAVA'
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
JAVA

# 2) TutoriaParticipanteRepository: agregar findByEstudianteId
cat > src/main/java/com/jcaa/hexagonal/adapter/databases/sql/repository/TutoriaParticipanteRepository.java <<'JAVA'
package com.jcaa.hexagonal.adapter.databases.sql.repository;

import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaParticipanteEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TutoriaParticipanteRepository extends JpaRepository<TutoriaParticipanteEntity, Integer> {
    List<TutoriaParticipanteEntity> findByTutoriaId(String tutoriaId);
    List<TutoriaParticipanteEntity> findByEstudianteId(String estudianteId);
    boolean existsByTutoriaIdAndEstudianteId(String tutoriaId, String estudianteId);
}
JAVA

# 3) TutoriaController: editar/crear con restricciones por rol y endpoints para participantes y listar "mine"
cat > src/main/java/com/jcaa/hexagonal/entrypoint/rest/v1/TutoriaController.java <<'JAVA'
package com.jcaa.hexagonal.entrypoint.rest.v1;

import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaEntity;
import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaParticipanteEntity;
import com.jcaa.hexagonal.adapter.databases.sql.entity.UserEntity;
import com.jcaa.hexagonal.core.service.TutoriaService;
import com.jcaa.hexagonal.core.service.TutoriaParticipanteService;
import com.jcaa.hexagonal.core.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/tutorias")
public class TutoriaController {
    private final TutoriaService service;
    private final UserService userService;
    private final TutoriaParticipanteService participanteService;

    public TutoriaController(TutoriaService s, UserService userService, TutoriaParticipanteService participanteService){
        this.service = s;
        this.userService = userService;
        this.participanteService = participanteService;
    }

    @GetMapping
    public ResponseEntity<List<TutoriaEntity>> listar(){ return ResponseEntity.ok(service.listar()); }

    @GetMapping("/{id}")
    public ResponseEntity<?> obtener(@PathVariable String id){
        Optional<TutoriaEntity> opt = service.buscarPorId(id);
        return opt.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.status(404).body(Map.of("error","No encontrado")));
    }

    // Listar tutorias "mías": si teacher -> las creadas por mí; si student -> las donde estoy inscrito
    @GetMapping("/mine")
    public ResponseEntity<?> misTutorias(Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String myId = auth.getName();
        var optUser = userService.buscarPorId(myId);
        if(optUser.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Usuario no encontrado"));
        UserEntity me = optUser.get();
        if("teacher".equals(me.getRole())){
            List<TutoriaEntity> creadas = service.listar().stream()
                    .filter(t -> myId.equals(t.getDocenteId()))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(creadas);
        } else {
            // student -> buscar participaciones
            List<TutoriaParticipanteEntity> parts = participanteService.listarPorEstudiante(myId);
            List<String> ids = parts.stream().map(TutoriaParticipanteEntity::getTutoriaId).collect(Collectors.toList());
            List<TutoriaEntity> tutorias = ids.isEmpty() ? List.of() : service.findByIds(ids);
            return ResponseEntity.ok(tutorias);
        }
    }

    // Crear tutoria: solo teacher autenticado puede crear; el docente será el usuario autenticado (no se permite crear a nombre de otro)
    @PostMapping
    public ResponseEntity<?> crear(@RequestBody TutoriaEntity t, Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String myId = auth.getName();
        var optUser = userService.buscarPorId(myId);
        if(optUser.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Usuario no encontrado"));
        UserEntity me = optUser.get();
        if(!"teacher".equals(me.getRole())){
            return ResponseEntity.status(403).body(Map.of("error","Solo usuarios con role 'teacher' pueden crear tutorias"));
        }
        // forzar docenteId = usuario autenticado
        t.setDocenteId(myId);
        // normalizar cadena vacía a null
        if(t.getEstudianteId() != null && t.getEstudianteId().trim().isEmpty()) t.setEstudianteId(null);
        TutoriaEntity creado = service.crearTutoria(t);
        return ResponseEntity.ok(creado);
    }

    // Editar tutoria: solo el teacher que la creó puede editar
    @PutMapping("/{id}")
    public ResponseEntity<?> editar(@PathVariable String id, @RequestBody TutoriaEntity cambios, Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String myId = auth.getName();
        var opt = service.buscarPorId(id);
        if(opt.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Tutoria no encontrada"));
        TutoriaEntity t = opt.get();
        if(t.getDocenteId() == null || !t.getDocenteId().equals(myId)){
            return ResponseEntity.status(403).body(Map.of("error","Solo el docente creador puede editar esta tutoria"));
        }
        // aplicar cambios permitidos (no permitimos cambiar docenteId)
        if(cambios.getFecha() != null) t.setFecha(cambios.getFecha());
        if(cambios.getFechaProgramada() != null) t.setFechaProgramada(cambios.getFechaProgramada());
        if(cambios.getHoraInicio() != null) t.setHoraInicio(cambios.getHoraInicio());
        if(cambios.getHoraFin() != null) t.setHoraFin(cambios.getHoraFin());
        if(cambios.getUniversidad() != null) t.setUniversidad(cambios.getUniversidad());
        if(cambios.getCarrera() != null) t.setCarrera(cambios.getCarrera());
        if(cambios.getAsignatura() != null) t.setAsignatura(cambios.getAsignatura());
        if(cambios.getTematica() != null) t.setTematica(cambios.getTematica());
        if(cambios.getCompromisos() != null) t.setCompromisos(cambios.getCompromisos());
        if(cambios.getEsGrupal() != null) t.setEsGrupal(cambios.getEsGrupal());
        if(cambios.getLugar() != null) t.setLugar(cambios.getLugar());

        t.setUpdatedAt(java.time.LocalDateTime.now());
        TutoriaEntity saved = service.crearTutoria(t);
        return ResponseEntity.ok(saved);
    }

    // Inscribirse a una tutoria (student se inscribe a sí mismo)
    @PostMapping("/{id}/enroll")
    public ResponseEntity<?> enroll(@PathVariable String id, Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String myId = auth.getName();
        var optUser = userService.buscarPorId(myId);
        if(optUser.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Usuario no encontrado"));
        UserEntity me = optUser.get();
        if(!"student".equals(me.getRole())) return ResponseEntity.status(403).body(Map.of("error","Solo estudiantes pueden inscribirse"));
        var optTut = service.buscarPorId(id);
        if(optTut.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Tutoria no encontrada"));
        // evitar duplicados
        if(participanteService.estaInscrito(id, myId)){
            return ResponseEntity.badRequest().body(Map.of("error","Ya estás inscrito en esta tutoria"));
        }
        TutoriaParticipanteEntity p = new TutoriaParticipanteEntity();
        p.setTutoriaId(id);
        p.setEstudianteId(myId);
        TutoriaParticipanteEntity creado = participanteService.agregarParticipante(p);
        return ResponseEntity.ok(creado);
    }

    // Profesor (dueño) agrega participante (pasa estudianteId en body)
    @PostMapping("/{id}/add-participant")
    public ResponseEntity<?> addParticipant(@PathVariable String id, @RequestBody Map<String,String> body, Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String myId = auth.getName();
        var optTut = service.buscarPorId(id);
        if(optTut.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Tutoria no encontrada"));
        TutoriaEntity t = optTut.get();
        if(t.getDocenteId() == null || !t.getDocenteId().equals(myId)) {
            return ResponseEntity.status(403).body(Map.of("error","Solo el docente creador puede agregar participantes"));
        }
        String estudianteId = body.get("estudianteId");
        if(estudianteId == null || estudianteId.trim().isEmpty()) return ResponseEntity.badRequest().body(Map.of("error","estudianteId requerido"));
        var optEst = userService.buscarPorId(estudianteId);
        if(optEst.isEmpty()) return ResponseEntity.badRequest().body(Map.of("error","estudiante_id no existe"));
        // opcional: exigir role student
        if(!"student".equals(optEst.get().getRole())) return ResponseEntity.badRequest().body(Map.of("error","El usuario no es estudiante"));

        if(participanteService.estaInscrito(id, estudianteId)){
            return ResponseEntity.badRequest().body(Map.of("error","Estudiante ya inscrito"));
        }

        TutoriaParticipanteEntity p = new TutoriaParticipanteEntity();
        p.setTutoriaId(id);
        p.setEstudianteId(estudianteId);
        TutoriaParticipanteEntity creado = participanteService.agregarParticipante(p);
        return ResponseEntity.ok(creado);
    }

    // eliminar participante (puede hacerlo el profesor dueño o el propio estudiante)
    @DeleteMapping("/{id}/participants/{participantId}")
    public ResponseEntity<?> removeParticipant(@PathVariable String id, @PathVariable Integer participantId, Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String myId = auth.getName();
        var optPart = participanteService.buscarPorId(participantId);
        if(optPart.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Participante no encontrado"));
        TutoriaParticipanteEntity p = optPart.get();
        if(!p.getTutoriaId().equals(id)) return ResponseEntity.badRequest().body(Map.of("error","Participante no pertenece a la tutoria"));
        var optTut = service.buscarPorId(id);
        if(optTut.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Tutoria no encontrada"));
        TutoriaEntity t = optTut.get();
        // permitir si soy dueño (docente) o si soy el estudiante (auto-eliminar)
        if(myId.equals(p.getEstudianteId()) || (t.getDocenteId()!=null && t.getDocenteId().equals(myId))){
            participanteService.eliminar(participantId);
            return ResponseEntity.ok(Map.of("ok",true));
        } else {
            return ResponseEntity.status(403).body(Map.of("error","No autorizado"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> borrar(@PathVariable String id, Authentication auth){
        if(auth == null) return ResponseEntity.status(401).body(Map.of("error","No autenticado"));
        String myId = auth.getName();
        var optTut = service.buscarPorId(id);
        if(optTut.isEmpty()) return ResponseEntity.status(404).body(Map.of("error","Tutoria no encontrada"));
        TutoriaEntity t = optTut.get();
        if(t.getDocenteId() == null || !t.getDocenteId().equals(myId)){
            return ResponseEntity.status(403).body(Map.of("error","Solo el docente creador puede eliminar esta tutoria"));
        }
        service.eliminar(id);
        return ResponseEntity.ok(Map.of("ok",true));
    }
}
JAVA

# 4) TutoriaParticipanteService: agregar buscarPorId, listarPorEstudiante, estaInscrito
cat > src/main/java/com/jcaa/hexagonal/core/service/TutoriaParticipanteService.java <<'JAVA'
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
JAVA

# 5) UserController: impedir cambios de role via endpoint (quitamos cambiarRol y evitamos que PUT actualice role)
cat > src/main/java/com/jcaa/hexagonal/entrypoint/rest/v1/UserController.java <<'JAVA'
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
        // role por defecto student si no viene; validar role
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
        // No permitimos cambiar role vía PUT para evitar elevación de privilegios.
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
JAVA

echo "Cambios aplicados. Ahora reinicia la app (se recomienda detener mvn si está corriendo y volver a arrancar)."
