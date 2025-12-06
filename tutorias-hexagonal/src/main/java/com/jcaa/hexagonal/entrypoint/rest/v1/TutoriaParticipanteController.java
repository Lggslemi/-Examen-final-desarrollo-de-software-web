package com.jcaa.hexagonal.entrypoint.rest.v1;

import com.jcaa.hexagonal.adapter.databases.sql.entity.TutoriaParticipanteEntity;
import com.jcaa.hexagonal.core.service.TutoriaParticipanteService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/participantes")
public class TutoriaParticipanteController {
    private final TutoriaParticipanteService service;

    public TutoriaParticipanteController(TutoriaParticipanteService s){ this.service = s; }

    @PostMapping
    public ResponseEntity<?> agregar(@RequestBody TutoriaParticipanteEntity p){
        var creado = service.agregarParticipante(p);
        return ResponseEntity.ok(creado);
    }

    @GetMapping("/tutoria/{tutoriaId}")
    public ResponseEntity<List<TutoriaParticipanteEntity>> listarPorTutoria(@PathVariable String tutoriaId){
        return ResponseEntity.ok(service.listarPorTutoria(tutoriaId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> borrar(@PathVariable Integer id){
        service.eliminar(id);
        return ResponseEntity.ok(Map.of("ok",true));
    }
}
