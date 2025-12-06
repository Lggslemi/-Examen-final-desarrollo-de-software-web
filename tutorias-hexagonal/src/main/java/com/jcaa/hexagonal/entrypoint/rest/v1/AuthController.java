package com.jcaa.hexagonal.entrypoint.rest.v1;

import com.jcaa.hexagonal.adapter.databases.sql.entity.PasswordResetEntity;
import com.jcaa.hexagonal.adapter.databases.sql.entity.UserEntity;
import com.jcaa.hexagonal.core.service.AuthService;
import com.jcaa.hexagonal.core.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final UserService userService;
    private final AuthService authService;

    public AuthController(UserService userService, AuthService authService){
        this.userService = userService;
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> registrar(@RequestBody Map<String,String> body){
        UserEntity u = new UserEntity();
        u.setName(body.get("name"));
        u.setEmail(body.get("email"));
        u.setPassword(body.get("password"));
        userService.crearUsuario(u);
        return ResponseEntity.ok(Map.of("ok", true, "id", u.getId()));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String,String> body){
        var opt = userService.buscarPorEmail(body.get("email"));
        if(opt.isEmpty()) return ResponseEntity.status(401).body(Map.of("error","Credenciales inválidas"));
        var user = opt.get();
        if(!userService.verificarPassword(body.get("password"), user.getPassword())){
            return ResponseEntity.status(401).body(Map.of("error","Credenciales inválidas"));
        }
        String token = authService.generarToken(user);
        return ResponseEntity.ok(Map.of("token", token));
    }

    @PostMapping("/forgot")
    public ResponseEntity<?> recordarContrasena(@RequestBody Map<String,String> body){
        var email = body.get("email");
        var opt = userService.buscarPorEmail(email);
        if(opt.isEmpty()) return ResponseEntity.badRequest().body(Map.of("error","Usuario no encontrado"));
        UserEntity u = opt.get();
        PasswordResetEntity pr = authService.crearPasswordReset(u, 60); // 60 minutos
        
        return ResponseEntity.ok(Map.of("mensaje","Token generado (en la vida real se enviaría por email)","token", pr.getToken()));
    }

    @PostMapping("/reset")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String,String> body){
        String token = body.get("token");
        String nueva = body.get("password");
        var pr = authService.buscarResetPorToken(token);
        if(pr == null) return ResponseEntity.badRequest().body(Map.of("error","Token inválido"));
        if(pr.getExpiresAt().isBefore(java.time.LocalDateTime.now())) return ResponseEntity.badRequest().body(Map.of("error","Token expirado"));
        var opt = userService.buscarPorId(pr.getUserId());
        if(opt.isEmpty()) return ResponseEntity.badRequest().body(Map.of("error","Usuario no encontrado"));
        var user = opt.get();
        user.setPassword(nueva);
        userService.crearUsuario(user); 
        return ResponseEntity.ok(Map.of("ok",true));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(){
        
        return ResponseEntity.ok(Map.of("ok",true, "mensaje","Desconexión realizada (borra el token en el cliente)"));
    }
}
