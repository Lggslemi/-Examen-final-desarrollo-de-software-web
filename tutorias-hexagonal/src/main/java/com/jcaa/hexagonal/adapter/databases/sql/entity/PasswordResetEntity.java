package com.jcaa.hexagonal.adapter.databases.sql.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "password_resets")
public class PasswordResetEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "user_id", length = 36)
    private String userId;

    @Column(length = 255)
    private String token;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public PasswordResetEntity(){
        this.createdAt = LocalDateTime.now();
    }

    public Integer getId(){return id;}
    public void setId(Integer id){this.id=id;}
    public String getUserId(){return userId;}
    public void setUserId(String u){this.userId=u;}
    public String getToken(){return token;}
    public void setToken(String t){this.token=t;}
    public LocalDateTime getExpiresAt(){return expiresAt;}
    public void setExpiresAt(LocalDateTime e){this.expiresAt=e;}
    public LocalDateTime getCreatedAt(){return createdAt;}
    public void setCreatedAt(LocalDateTime c){this.createdAt=c;}
}
