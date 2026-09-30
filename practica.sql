DROP DATABASE IF EXISTS biblioteca;
DROP ROLE IF EXISTS admin_biblio;
DROP ROLE IF EXISTS usuario_biblio;
DROP ROLE IF EXISTS lectores;

CREATE DATABASE biblioteca;
\c biblioteca


CREATE ROLE admin_biblio WITH LOGIN SUPERUSER PASSWORD 'admin123';
CREATE ROLE usuario_biblio WITH LOGIN PASSWORD 'user123';
CREATE ROLE lectores;

GRANT lectores TO usuario_biblio;

GRANT USAGE ON SCHEMA public TO lectores;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lectores;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO lectores;

SELECT rolname, rolsuper, rolcanlogin 
FROM pg_roles 
WHERE rolname IN ('admin_biblio', 'usuario_biblio', 'lectores');

ALTER ROLE usuario_biblio WITH PASSWORD 'nueva_pass_456';

REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM usuario_biblio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE DELETE ON TABLES FROM usuario_biblio;

CREATE TABLE autores (
    id_autor SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nacionalidad VARCHAR(50)
);

CREATE TABLE libros (
    id_libro SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    año_publicacion INT,
    id_autor INT,
    CONSTRAINT fk_autor
        FOREIGN KEY(id_autor) 
        REFERENCES autores(id_autor)
        ON DELETE CASCADE
);

CREATE TABLE prestamos (
    id_prestamo SERIAL PRIMARY KEY,
    id_libro INT,
    fecha_prestamo DATE NOT NULL,
    fecha_devolucion DATE,
    usuario_prestatario VARCHAR(100) NOT NULL,
    CONSTRAINT fk_libro
        FOREIGN KEY(id_libro)
        REFERENCES libros(id_libro)
        ON DELETE CASCADE
);

INSERT INTO autores (nombre, nacionalidad) VALUES
('Gabriel García Márquez', 'Colombiana'),
('J.K. Rowling', 'Británica'),
('George Orwell', 'Británica'),
('Isabel Allende', 'Chilena'),
('Julio Cortázar', 'Argentina');

INSERT INTO libros (titulo, año_publicacion, id_autor) VALUES
('Cien años de soledad', 1967, 1),
('El coronel no tiene quien le escriba', 1961, 1),
('Harry Potter y la piedra filosofal', 1997, 2),
('1984', 1949, 3),
('Rebelión en la granja', 1945, 3),
('La casa de los espíritus', 1982, 4),
('Rayuela', 1963, 5),
('Bestiario', 1951, 5);

INSERT INTO prestamos (id_libro, fecha_prestamo, fecha_devolucion, usuario_prestatario) VALUES
(1, '2026-09-01', '2026-09-15', 'Carlos Perez'),
(2, '2026-09-10', NULL, 'Ana Gomez'),
(4, '2026-09-12', '2026-09-20', 'Luis Ruiz'),
(4, '2026-09-22', NULL, 'Marta Sanchez'),
(7, '2026-09-25', NULL, 'Carlos Perez');

SELECT l.titulo, a.nombre AS autor
FROM libros l
JOIN autores a ON l.id_autor = a.id_autor;

SELECT * FROM prestamos WHERE fecha_devolucion IS NULL;

SELECT a.nombre, COUNT(l.id_libro) AS total_libros
FROM autores a
JOIN libros l ON a.id_autor = l.id_autor
GROUP BY a.id_autor, a.nombre
HAVING COUNT(l.id_libro) > 1;

SELECT COUNT(*) AS total_prestamos FROM prestamos;

SELECT usuario_prestatario, COUNT(*) AS libros_prestados
FROM prestamos
GROUP BY usuario_prestatario;

UPDATE prestamos 
SET fecha_devolucion = CURRENT_DATE 
WHERE id_prestamo = 2;

DELETE FROM libros WHERE id_libro = 4;

SELECT * FROM prestamos;

CREATE VIEW vista_libros_prestados AS
SELECT l.titulo, a.nombre AS autor, p.usuario_prestatario
FROM prestamos p
JOIN libros l ON p.id_libro = l.id_libro
JOIN autores a ON l.id_autor = a.id_autor;

REVOKE ALL ON vista_libros_prestados FROM public;
REVOKE ALL ON vista_libros_prestados FROM lectores;
GRANT SELECT ON vista_libros_prestados TO usuario_biblio;

CREATE FUNCTION obtener_libros_autor(nombre_autor VARCHAR)
RETURNS TABLE(titulo VARCHAR, año_publicacion INT) AS $$
BEGIN
    RETURN QUERY 
    SELECT l.titulo, l.año_publicacion 
    FROM libros l
    JOIN autores a ON l.id_autor = a.id_autor
    WHERE a.nombre = nombre_autor;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM obtener_libros_autor('Julio Cortázar');

SELECT l.titulo, COUNT(p.id_prestamo) AS veces_prestado
FROM libros l
JOIN prestamos p ON l.id_libro = p.id_libro
GROUP BY l.id_libro, l.titulo
ORDER BY veces_prestado DESC
LIMIT 3;

\copy libros TO 'libros_exportados.csv' WITH CSV HEADER;

\copy autores(nombre, nacionalidad) FROM 'autores_nuevos.csv' WITH CSV HEADER;

SELECT * FROM autores;