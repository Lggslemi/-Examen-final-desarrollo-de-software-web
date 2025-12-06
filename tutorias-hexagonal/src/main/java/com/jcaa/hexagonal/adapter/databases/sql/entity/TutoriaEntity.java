package com.jcaa.hexagonal.adapter.databases.sql.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "tutorias")
public class TutoriaEntity {
    @Id
    @Column(length = 36)
    private String id;

    @Column(nullable = false)
    private LocalDate fecha;

    @Column(name = "fecha_programada")
    private LocalDate fechaProgramada;

    @Column(name = "hora_inicio")
    private LocalTime horaInicio;

    @Column(name = "hora_fin")
    private LocalTime horaFin;

    @Column(name = "docente_id", length = 36, nullable = true)
    private String docenteId;

    @Column(name = "estudiante_id", length = 36, nullable = true)
    private String estudianteId;

    private String universidad;
    private String carrera;
    private String asignatura;

    @Column(columnDefinition = "TEXT")
    private String tematica;

    @Column(columnDefinition = "TEXT")
    private String compromisos;

    @Column(name = "es_grupal")
    private Boolean esGrupal = false;

    private String lugar;

    @Column(name = "created_at")
    private java.time.LocalDateTime createdAt;

    @Column(name = "updated_at")
    private java.time.LocalDateTime updatedAt;

    public TutoriaEntity() {
        this.id = java.util.UUID.randomUUID().toString();
        this.createdAt = java.time.LocalDateTime.now();
        this.updatedAt = java.time.LocalDateTime.now();
    }

    // getters y setters
    public String getId(){return id;}
    public void setId(String id){this.id=id;}
    public java.time.LocalDate getFecha(){return fecha;}
    public void setFecha(java.time.LocalDate fecha){this.fecha=fecha;}
    public java.time.LocalDate getFechaProgramada(){return fechaProgramada;}
    public void setFechaProgramada(java.time.LocalDate f){this.fechaProgramada=f;}
    public java.time.LocalTime getHoraInicio(){return horaInicio;}
    public void setHoraInicio(java.time.LocalTime h){this.horaInicio=h;}
    public java.time.LocalTime getHoraFin(){return horaFin;}
    public void setHoraFin(java.time.LocalTime h){this.horaFin=h;}
    public String getDocenteId(){return docenteId;}
    public void setDocenteId(String d){this.docenteId=d;}
    public String getEstudianteId(){return estudianteId;}
    public void setEstudianteId(String e){this.estudianteId=e;}
    public String getUniversidad(){return universidad;}
    public void setUniversidad(String u){this.universidad=u;}
    public String getCarrera(){return carrera;}
    public void setCarrera(String c){this.carrera=c;}
    public String getAsignatura(){return asignatura;}
    public void setAsignatura(String a){this.asignatura=a;}
    public String getTematica(){return tematica;}
    public void setTematica(String t){this.tematica=t;}
    public String getCompromisos(){return compromisos;}
    public void setCompromisos(String c){this.compromisos=c;}
    public Boolean getEsGrupal(){return esGrupal;}
    public void setEsGrupal(Boolean e){this.esGrupal=e;}
    public String getLugar(){return lugar;}
    public void setLugar(String l){this.lugar=l;}
    public java.time.LocalDateTime getCreatedAt(){return createdAt;}
    public void setCreatedAt(java.time.LocalDateTime t){this.createdAt=t;}
    public java.time.LocalDateTime getUpdatedAt(){return updatedAt;}
    public void setUpdatedAt(java.time.LocalDateTime t){this.updatedAt=t;}
}
