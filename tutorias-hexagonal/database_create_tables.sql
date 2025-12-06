-- Ejecuta esto en tu MariaDB / MySQL (ajusta nombres/charset si necesitas)
CREATE DATABASE IF NOT EXISTS tutorias_luiggi_7502120036 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tutorias_luiggi_7502120036;

CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'student',
  is_active TINYINT(1) DEFAULT 1,
  created_at DATETIME,
  updated_at DATETIME
);

CREATE TABLE IF NOT EXISTS tutorias (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  fecha DATE NOT NULL,
  fecha_programada DATE,
  hora_inicio TIME,
  hora_fin TIME,
  docente_id VARCHAR(36),
  estudiante_id VARCHAR(36),
  universidad VARCHAR(255),
  carrera VARCHAR(255),
  asignatura VARCHAR(255),
  tematica TEXT,
  compromisos TEXT,
  es_grupal TINYINT(1) DEFAULT 0,
  lugar VARCHAR(255),
  created_at DATETIME,
  updated_at DATETIME
);

CREATE TABLE IF NOT EXISTS tutoria_participantes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tutoria_id VARCHAR(36),
  estudiante_id VARCHAR(36),
  created_at DATETIME
);

CREATE TABLE IF NOT EXISTS password_resets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(36),
  token VARCHAR(255),
  expires_at DATETIME,
  created_at DATETIME
);
