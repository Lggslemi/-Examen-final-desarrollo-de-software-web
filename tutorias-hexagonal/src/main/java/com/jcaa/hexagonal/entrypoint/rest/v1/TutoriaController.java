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
        if (opt.isPresent()) {
            return ResponseEntity.ok(opt.get());
        } else {
            return ResponseEntity.status(404).body(Map.of("error","No encontrado"));
        }
    }

    
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
           
            List<TutoriaParticipanteEntity> parts = participanteService.listarPorEstudiante(myId);
            List<String> ids = parts.stream().map(TutoriaParticipanteEntity::getTutoriaId).collect(Collectors.toList());
            List<TutoriaEntity> tutorias = ids.isEmpty() ? List.of() : service.findByIds(ids);
            return ResponseEntity.ok(tutorias);
        }
    }

    
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
        
        if(participanteService.estaInscrito(id, myId)){
            return ResponseEntity.badRequest().body(Map.of("error","Ya estás inscrito en esta tutoria"));
        }
        TutoriaParticipanteEntity p = new TutoriaParticipanteEntity();
        p.setTutoriaId(id);
        p.setEstudianteId(myId);
        TutoriaParticipanteEntity creado = participanteService.agregarParticipante(p);
        return ResponseEntity.ok(creado);
    }

    
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
