DROP DATABASE IF EXISTS biblioteca;
DROP DATABASE
DROP ROLE IF EXISTS admin_biblio;
DROP ROLE
DROP ROLE IF EXISTS usuario_biblio;
DROP ROLE
DROP ROLE IF EXISTS lectores;
DROP ROLE

CREATE DATABASE biblioteca;
CREATE DATABASE
\c biblioteca
Ahora est� conectado a la base de datos �biblioteca� con el usuario �postgres�.


CREATE ROLE admin_biblio WITH LOGIN SUPERUSER PASSWORD 'admin123';
CREATE ROLE
CREATE ROLE usuario_biblio WITH LOGIN PASSWORD 'user123';
CREATE ROLE
CREATE ROLE lectores;
CREATE ROLE

GRANT lectores TO usuario_biblio;
GRANT ROLE

GRANT USAGE ON SCHEMA public TO lectores;
GRANT
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lectores;
GRANT
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO lectores;
ALTER DEFAULT PRIVILEGES

SELECT rolname, rolsuper, rolcanlogin 
FROM pg_roles 
WHERE rolname IN ('admin_biblio', 'usuario_biblio', 'lectores');
    rolname     | rolsuper | rolcanlogin 
----------------+----------+-------------
 admin_biblio   | t        | t
 usuario_biblio | f        | t
 lectores       | f        | f
(3 filas)


ALTER ROLE usuario_biblio WITH PASSWORD 'nueva_pass_456';
ALTER ROLE

REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM usuario_biblio;
REVOKE
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE DELETE ON TABLES FROM usuario_biblio;
ALTER DEFAULT PRIVILEGES

CREATE TABLE autores (
    id_autor SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nacionalidad VARCHAR(50)
);
CREATE TABLE

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
CREATE TABLE

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
CREATE TABLE

INSERT INTO autores (nombre, nacionalidad) VALUES
('Gabriel García Márquez', 'Colombiana'),
('J.K. Rowling', 'Británica'),
('George Orwell', 'Británica'),
('Isabel Allende', 'Chilena'),
('Julio Cortázar', 'Argentina');
INSERT 0 5

INSERT INTO libros (titulo, año_publicacion, id_autor) VALUES
('Cien años de soledad', 1967, 1),
('El coronel no tiene quien le escriba', 1961, 1),
('Harry Potter y la piedra filosofal', 1997, 2),
('1984', 1949, 3),
('Rebelión en la granja', 1945, 3),
('La casa de los espíritus', 1982, 4),
('Rayuela', 1963, 5),
('Bestiario', 1951, 5);
INSERT 0 8

INSERT INTO prestamos (id_libro, fecha_prestamo, fecha_devolucion, usuario_prestatario) VALUES
(1, '2026-09-01', '2026-09-15', 'Carlos Perez'),
(2, '2026-09-10', NULL, 'Ana Gomez'),
(4, '2026-09-12', '2026-09-20', 'Luis Ruiz'),
(4, '2026-09-22', NULL, 'Marta Sanchez'),
(7, '2026-09-25', NULL, 'Carlos Perez');
INSERT 0 5

SELECT l.titulo, a.nombre AS autor
FROM libros l
JOIN autores a ON l.id_autor = a.id_autor;
                titulo                |         autor          
--------------------------------------+------------------------
 Cien años de soledad                 | Gabriel García Márquez
 El coronel no tiene quien le escriba | Gabriel García Márquez
 Harry Potter y la piedra filosofal   | J.K. Rowling
 1984                                 | George Orwell
 Rebelión en la granja                | George Orwell
 La casa de los espíritus             | Isabel Allende
 Rayuela                              | Julio Cortázar
 Bestiario                            | Julio Cortázar
(8 filas)


SELECT * FROM prestamos WHERE fecha_devolucion IS NULL;
 id_prestamo | id_libro | fecha_prestamo | fecha_devolucion | usuario_prestatario 
-------------+----------+----------------+------------------+---------------------
           2 |        2 | 2026-09-10     |                  | Ana Gomez
           4 |        4 | 2026-09-22     |                  | Marta Sanchez
           5 |        7 | 2026-09-25     |                  | Carlos Perez
(3 filas)


SELECT a.nombre, COUNT(l.id_libro) AS total_libros
FROM autores a
JOIN libros l ON a.id_autor = l.id_autor
GROUP BY a.id_autor, a.nombre
HAVING COUNT(l.id_libro) > 1;
         nombre         | total_libros 
------------------------+--------------
 George Orwell          |            2
 Julio Cortázar         |            2
 Gabriel García Márquez |            2
(3 filas)


SELECT COUNT(*) AS total_prestamos FROM prestamos;
 total_prestamos 
-----------------
               5
(1 fila)


SELECT usuario_prestatario, COUNT(*) AS libros_prestados
FROM prestamos
GROUP BY usuario_prestatario;
 usuario_prestatario | libros_prestados 
---------------------+------------------
 Ana Gomez           |                1
 Marta Sanchez       |                1
 Luis Ruiz           |                1
 Carlos Perez        |                2
(4 filas)


UPDATE prestamos 
SET fecha_devolucion = CURRENT_DATE 
WHERE id_prestamo = 2;
UPDATE 1

DELETE FROM libros WHERE id_libro = 4;
DELETE 1

SELECT * FROM prestamos;
 id_prestamo | id_libro | fecha_prestamo | fecha_devolucion | usuario_prestatario 
-------------+----------+----------------+------------------+---------------------
           1 |        1 | 2026-09-01     | 2026-09-15       | Carlos Perez
           5 |        7 | 2026-09-25     |                  | Carlos Perez
           2 |        2 | 2026-09-10     | 2026-09-30       | Ana Gomez
(3 filas)


CREATE VIEW vista_libros_prestados AS
SELECT l.titulo, a.nombre AS autor, p.usuario_prestatario
FROM prestamos p
JOIN libros l ON p.id_libro = l.id_libro
JOIN autores a ON l.id_autor = a.id_autor;
CREATE VIEW

REVOKE ALL ON vista_libros_prestados FROM public;
REVOKE
REVOKE ALL ON vista_libros_prestados FROM lectores;
REVOKE
GRANT SELECT ON vista_libros_prestados TO usuario_biblio;
GRANT

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
CREATE FUNCTION

SELECT * FROM obtener_libros_autor('Julio Cortázar');
  titulo   | año_publicacion 
-----------+-----------------
 Rayuela   |            1963
 Bestiario |            1951
(2 filas)


SELECT l.titulo, COUNT(p.id_prestamo) AS veces_prestado
FROM libros l
JOIN prestamos p ON l.id_libro = p.id_libro
GROUP BY l.id_libro, l.titulo
ORDER BY veces_prestado DESC
LIMIT 3;
                titulo                | veces_prestado 
--------------------------------------+----------------
 El coronel no tiene quien le escriba |              1
 Rayuela                              |              1
 Cien años de soledad                 |              1
(3 filas)


\copy libros TO 'libros_exportados.csv' WITH CSV HEADER;
COPY 7

\copy autores(nombre, nacionalidad) FROM 'autores_nuevos.csv' WITH CSV HEADER;
COPY 2

SELECT * FROM autores;
 id_autor |         nombre         | nacionalidad 
----------+------------------------+--------------
        1 | Gabriel García Márquez | Colombiana
        2 | J.K. Rowling           | Británica
        3 | George Orwell          | Británica
        4 | Isabel Allende         | Chilena
        5 | Julio Cortázar         | Argentina
        6 | Miguel de Cervantes    | Española
        7 | Fiódor Dostoyevski     | Rusa
(7 filas)

