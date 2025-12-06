package com.jcaa.hexagonal.adapter.databases.sql.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tutoria_participantes")
public class TutoriaParticipanteEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "tutoria_id", length = 36)
    private String tutoriaId;

    @Column(name = "estudiante_id", length = 36)
    private String estudianteId;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public TutoriaParticipanteEntity(){
        this.createdAt = LocalDateTime.now();
    }

    public Integer getId(){return id;}
    public void setId(Integer id){this.id=id;}
    public String getTutoriaId(){return tutoriaId;}
    public void setTutoriaId(String t){this.tutoriaId=t;}
    public String getEstudianteId(){return estudianteId;}
    public void setEstudianteId(String e){this.estudianteId=e;}
    public LocalDateTime getCreatedAt(){return createdAt;}
    public void setCreatedAt(LocalDateTime c){this.createdAt=c;}
}
