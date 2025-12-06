#!/usr/bin/env bash
set -e
ROOT="$(pwd)"
# busca frontend en ../tutorias-frontend o ./tutorias-frontend
if [ -d "${ROOT}/../tutorias-frontend" ]; then
  FRONT="${ROOT}/../tutorias-frontend"
elif [ -d "${ROOT}/tutorias-frontend" ]; then
  FRONT="${ROOT}/tutorias-frontend"
else
  echo "No encuentro la carpeta tutorias-frontend en ../ ni en ./"
  exit 1
fi
echo "Actualizando frontend en: $FRONT"
cd "$FRONT"

# asegurar src existe
mkdir -p src/pages src/components

# App.jsx -> maneja currentUser (consulta /api/v1/users/me) y rutas simples
cat > src/App.jsx <<'JSX'
import React, { useEffect, useState } from "react";
import UsersPage from "./pages/UsersPage";
import TutoriasPage from "./pages/TutoriasPage";
import AuthPage from "./pages/AuthPage";
import MyTutoriasPage from "./pages/MyTutoriasPage";

export default function App(){
  const [route, setRoute] = useState("auth");
  const [token, setToken] = useState(localStorage.getItem("token"));
  const [currentUser, setCurrentUser] = useState(JSON.parse(localStorage.getItem("user") || "null"));

  useEffect(()=>{
    if(token && !currentUser){
      // obtener perfil
      fetch("http://localhost:8080/api/v1/users/me", {
        headers: { Authorization: "Bearer " + token }
      }).then(r => {
        if(r.ok) return r.json();
        throw new Error("No autorizado");
      }).then(j => {
        setCurrentUser(j);
        localStorage.setItem("user", JSON.stringify(j));
      }).catch(e => {
        console.log("Perfil no disponible", e);
        setToken(null);
        setCurrentUser(null);
        localStorage.removeItem("token");
        localStorage.removeItem("user");
      });
    }
  }, [token]);

  function onLogin(token, user){
    setToken(token);
    setCurrentUser(user);
    localStorage.setItem("token", token);
    localStorage.setItem("user", JSON.stringify(user));
  }
  function logout(){
    setToken(null);
    setCurrentUser(null);
    localStorage.removeItem("token");
    localStorage.removeItem("user");
  }

  return (
    <div className="container">
      <header>
        <h2>Tutorias - Frontend (demo)</h2>
        <nav style={{marginBottom:8}}>
          <button onClick={() => setRoute("auth")}>Auth</button>
          <button onClick={() => setRoute("users")}>Users</button>
          <button onClick={() => setRoute("tutorias")}>Todas Tutorías</button>
          <button onClick={() => setRoute("mine")}>Mis Tutorías</button>
        </nav>
        <div style={{display:"flex", justifyContent:"space-between", alignItems:"center"}}>
          <div>
            {currentUser ? <><strong>{currentUser.name}</strong> ({currentUser.role})</> : <em>No autenticado</em>}
          </div>
          <div>
            {token ? <button onClick={logout}>Logout</button> : null}
          </div>
        </div>
      </header>

      {!token && route !== "auth" && <div style={{marginBottom:8,color:"#b00"}}>Debes iniciar sesión para ciertas operaciones</div>}

      {route === "auth" && <AuthPage onLogin={onLogin} />}
      {route === "users" && <UsersPage token={token} />}
      {route === "tutorias" && <TutoriasPage token={token} currentUser={currentUser} />}
      {route === "mine" && <MyTutoriasPage token={token} currentUser={currentUser} />}
    </div>
  );
}
JSX

# AuthPage: role select on register, fetch profile after login
cat > src/pages/AuthPage.jsx <<'JSX'
import React, { useState } from "react";

const API = "http://localhost:8080/api/v1";

export default function AuthPage({ onLogin }){
  const [mode, setMode] = useState("login");
  const [form, setForm] = useState({name:"", email:"", password:"", role:"student"});

  async function submit(e){
    e.preventDefault();
    try {
      if(mode === "login"){
        const res = await fetch(API + "/auth/login", {
          method:"POST",
          headers: {"Content-Type":"application/json"},
          body: JSON.stringify({email: form.email, password: form.password})
        });
        const j = await res.json();
        if(res.ok && j.token){
          // obtener perfil
          const profileRes = await fetch(API + "/users/me", { headers: { Authorization: "Bearer "+j.token }});
          const profile = profileRes.ok ? await profileRes.json() : null;
          localStorage.setItem("token", j.token);
          localStorage.setItem("user", JSON.stringify(profile));
          onLogin && onLogin(j.token, profile);
          alert("Login correcto");
        } else {
          alert("Error: " + JSON.stringify(j));
        }
      } else {
        // register
        const res = await fetch(API + "/users", {
          method:"POST",
          headers: {"Content-Type":"application/json"},
          body: JSON.stringify({name:form.name, email: form.email, password: form.password, role: form.role})
        });
        const j = await res.json();
        if(res.ok){
          alert("Usuario creado. Haz login.");
          setMode("login");
        } else {
          alert("Error: " + JSON.stringify(j));
        }
      }
    } catch(err){
      alert("Error de red: " + err.message);
    }
  }

  return (
    <div>
      <h3>{mode === "login" ? "Login" : "Registrar"}</h3>
      <form onSubmit={submit}>
        {mode === "register" && <>
          <label>Nombre</label>
          <input value={form.name} onChange={e=>setForm({...form, name:e.target.value})} />
        </>}
        <label>Email</label>
        <input value={form.email} onChange={e=>setForm({...form, email:e.target.value})} />
        <label>Password</label>
        <input type="password" value={form.password} onChange={e=>setForm({...form, password:e.target.value})} />

        {mode === "register" && <>
          <label>Role</label>
          <select value={form.role} onChange={e=>setForm({...form, role:e.target.value})}>
            <option value="student">Student</option>
            <option value="teacher">Teacher</option>
          </select>
          <div style={{fontSize:12, color:"#666"}}>El role se establece al registrarse y no puede cambiarse desde el frontend.</div>
        </>}

        <div style={{marginTop:8}}>
          <button type="submit">{mode === "login" ? "Ingresar" : "Registrar"}</button>
          <button type="button" onClick={()=>setMode(mode==="login"?"register":"login")} style={{marginLeft:8}}>
            {mode==="login"?"Crear cuenta":"Ir a login"}
          </button>
        </div>
      </form>
    </div>
  );
}
JSX

# UsersPage: solo listar, sin cambiar role
cat > src/pages/UsersPage.jsx <<'JSX'
import React, { useEffect, useState } from "react";

export default function UsersPage({ token }){
  const [users, setUsers] = useState([]);
  async function load(){
    const res = await fetch("http://localhost:8080/api/v1/users", { headers: token ? { Authorization: "Bearer "+token } : {} });
    if(res.ok){
      const j = await res.json();
      setUsers(j);
    } else {
      setUsers([]);
    }
  }
  useEffect(()=>{ load(); }, []);

  return (
    <div>
      <h3>Usuarios</h3>
      <table className="table">
        <thead><tr><th>Nombre</th><th>Email</th><th>Role</th></tr></thead>
        <tbody>
          {users.map(u => (
            <tr key={u.id}>
              <td>{u.name}</td>
              <td>{u.email}</td>
              <td>{u.role}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
JSX

# MyTutoriasPage: lista tutorias "mias"
cat > src/pages/MyTutoriasPage.jsx <<'JSX'
import React, { useEffect, useState } from "react";

export default function MyTutoriasPage({ token, currentUser }){
  const [tutorias, setTutorias] = useState([]);
  async function load(){
    if(!token) { setTutorias([]); return; }
    const res = await fetch("http://localhost:8080/api/v1/tutorias/mine", {
      headers: { Authorization: "Bearer "+token }
    });
    if(res.ok){
      setTutorias(await res.json());
    } else {
      setTutorias([]);
    }
  }
  useEffect(()=>{ load(); }, [token]);

  return (
    <div>
      <h3>Mis Tutorías</h3>
      {!token && <div>Inicia sesión para ver tus tutorías.</div>}
      <table className="table">
        <thead><tr><th>Fecha</th><th>Asignatura</th><th>Docente</th><th>Acciones</th></tr></thead>
        <tbody>
          {tutorias.map(t => (
            <tr key={t.id}>
              <td>{t.fecha}</td>
              <td>{t.asignatura}</td>
              <td>{t.docenteId}</td>
              <td>
                <span style={{color:"#666"}}>Ver en "Todas Tutorías" para acciones</span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
JSX

# TutoriasPage: listar, enroll, editar (solo teacher creador), gestionar participantes
cat > src/pages/TutoriasPage.jsx <<'JSX'
import React, { useEffect, useState } from "react";

export default function TutoriasPage({ token, currentUser }){
  const [tutorias, setTutorias] = useState([]);
  const [expanded, setExpanded] = useState(null); // id currently expanded (show participants & edit)
  const [editId, setEditId] = useState(null);
  const [form, setForm] = useState({});
  const [participantsMap, setParticipantsMap] = useState({});

  function authHeader(){
    return token ? { Authorization: "Bearer "+token } : {};
  }

  async function load(){
    const res = await fetch("http://localhost:8080/api/v1/tutorias", { headers: authHeader() });
    if(res.ok){
      const j = await res.json();
      setTutorias(j);
    } else {
      setTutorias([]);
    }
  }

  useEffect(()=>{ load(); }, []);

  async function loadParticipants(tutoriaId){
    const res = await fetch(`http://localhost:8080/api/v1/participantes/tutoria/${tutoriaId}`, { headers: authHeader() });
    if(res.ok){
      const j = await res.json();
      setParticipantsMap(prev => ({...prev, [tutoriaId]: j}));
    } else {
      setParticipantsMap(prev => ({...prev, [tutoriaId]: []}));
    }
  }

  function toggleExpand(id){
    setExpanded(expanded===id? null : id);
    if(expanded !== id) loadParticipants(id);
  }

  async function enroll(id){
    if(!token){ alert("Inicia sesión como estudiante"); return; }
    const res = await fetch(`http://localhost:8080/api/v1/tutorias/${id}/enroll`, {
      method:"POST", headers: { ...authHeader(), "Content-Type":"application/json" }
    });
    const j = await res.json();
    if(res.ok){ alert("Inscrito"); loadParticipants(id); }
    else alert("Error: "+JSON.stringify(j));
  }

  async function addParticipant(id){
    const estudianteId = prompt("ID del estudiante a añadir:");
    if(!estudianteId) return;
    const res = await fetch(`http://localhost:8080/api/v1/tutorias/${id}/add-participant`, {
      method:"POST", headers: { ...authHeader(), "Content-Type":"application/json" },
      body: JSON.stringify({ estudianteId })
    });
    const j = await res.json();
    if(res.ok){ alert("Estudiante añadido"); loadParticipants(id); }
    else alert("Error: "+JSON.stringify(j));
  }

  async function removeParticipant(tutId, participantId){
    if(!confirm("Eliminar participante?")) return;
    const res = await fetch(`http://localhost:8080/api/v1/tutorias/${tutId}/participants/${participantId}`, {
      method:"DELETE", headers: authHeader()
    });
    if(res.ok){ alert("Eliminado"); loadParticipants(tutId); }
    else { const j = await res.json(); alert("Error: "+JSON.stringify(j)); }
  }

  function startEdit(t){
    setEditId(t.id);
    setForm({
      fecha: t.fecha || "",
      fechaProgramada: t.fechaProgramada || "",
      horaInicio: t.horaInicio || "",
      horaFin: t.horaFin || "",
      asignatura: t.asignatura || "",
      tematica: t.tematica || "",
      lugar: t.lugar || ""
    });
  }

  async function saveEdit(id){
    const res = await fetch(`http://localhost:8080/api/v1/tutorias/${id}`, {
      method:"PUT", headers: { ...authHeader(), "Content-Type":"application/json" },
      body: JSON.stringify(form)
    });
    const j = await res.json();
    if(res.ok){ alert("Guardado"); setEditId(null); load(); }
    else alert("Error: "+JSON.stringify(j));
  }

  async function deleteTutoria(id){
    if(!confirm("Eliminar tutoria?")) return;
    const res = await fetch(`http://localhost:8080/api/v1/tutorias/${id}`, {
      method:"DELETE", headers: authHeader()
    });
    if(res.ok){ alert("Eliminada"); load(); }
    else { const j = await res.json(); alert("Error: "+JSON.stringify(j)); }
  }

  return (
    <div>
      <h3>Tutorías</h3>
      <table className="table">
        <thead><tr><th>Fecha</th><th>Asignatura</th><th>Docente</th><th>Acciones</th></tr></thead>
        <tbody>
          {tutorias.map(t => (
            <React.Fragment key={t.id}>
            <tr>
              <td>{t.fecha}</td>
              <td>{t.asignatura}</td>
              <td>{t.docenteId}</td>
              <td>
                <button onClick={()=>toggleExpand(t.id)}>{expanded===t.id?"Cerrar":"Ver"}</button>
                {currentUser && currentUser.role === "student" && <button onClick={()=>enroll(t.id)} style={{marginLeft:6}}>Inscribirme</button>}
                {currentUser && currentUser.role === "teacher" && currentUser.id === t.docenteId && <>
                  <button onClick={()=>startEdit(t)} style={{marginLeft:6}}>Editar</button>
                  <button onClick={()=>addParticipant(t.id)} style={{marginLeft:6}}>Añadir participante</button>
                  <button onClick={()=>deleteTutoria(t.id)} style={{marginLeft:6}}>Borrar</button>
                </>}
              </td>
            </tr>

            {expanded === t.id && (
              <tr>
                <td colSpan="4">
                  <div style={{display:"flex", gap:20}}>
                    <div style={{flex:1}}>
                      <h4>Detalles</h4>
                      <div><strong>Temática:</strong> {t.tematica}</div>
                      <div><strong>Lugar:</strong> {t.lugar}</div>
                      <div><strong>Horario:</strong> {t.horaInicio} - {t.horaFin}</div>
                    </div>

                    <div style={{flex:1}}>
                      <h4>Participantes</h4>
                      <table className="table">
                        <thead><tr><th>Id</th><th>EstudianteId</th><th>Acción</th></tr></thead>
                        <tbody>
                          {(participantsMap[t.id] || []).map(p => (
                            <tr key={p.id}>
                              <td>{p.id}</td>
                              <td>{p.estudianteId}</td>
                              <td>
                                {/* permitir borrar si soy profesor creador o soy el inscrito */}
                                {(currentUser && (currentUser.id === p.estudianteId || (currentUser.role==="teacher" && currentUser.id===t.docenteId))) ?
                                  <button onClick={()=>removeParticipant(t.id, p.id)}>Eliminar</button>
                                  : <span style={{color:"#666"}}>-</span>
                                }
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>

                    {editId === t.id && (
                      <div style={{flex:1}}>
                        <h4>Editar</h4>
                        <label>Asignatura</label>
                        <input value={form.asignatura||""} onChange={e=>setForm({...form, asignatura:e.target.value})} />
                        <label>Fecha</label>
                        <input type="date" value={form.fecha||""} onChange={e=>setForm({...form, fecha:e.target.value})} />
                        <label>Hora inicio</label>
                        <input value={form.horaInicio||""} onChange={e=>setForm({...form, horaInicio:e.target.value})} />
                        <label>Hora fin</label>
                        <input value={form.horaFin||""} onChange={e=>setForm({...form, horaFin:e.target.value})} />
                        <label>Temática</label>
                        <textarea value={form.tematica||""} onChange={e=>setForm({...form, tematica:e.target.value})} />
                        <div style={{marginTop:8}}>
                          <button onClick={()=>saveEdit(t.id)}>Guardar</button>
                          <button onClick={()=>setEditId(null)} style={{marginLeft:8}}>Cancelar</button>
                        </div>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            )}
            </React.Fragment>
          ))}
        </tbody>
      </table>
    </div>
  );
}
JSX

echo "Archivos frontend actualizados. Ejecuta en el frontend:"
echo "  cd $FRONT"
echo "  npm install"
echo "  npm run dev"
