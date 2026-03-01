
USE inmobiliaria_db;

DROP VIEW IF EXISTS v_propiedades_disponibles;

CREATE VIEW v_propiedades_disponibles AS
SELECT
    p.Propiedad_ID,
    p.Direccion,
    tp.Descripcion                          AS Tipo_Propiedad,
    ep.Descripcion                          AS Estado,
    b.Nombre_Barrio                         AS Barrio,
    c.Nombre_Ciudad                         AS Ciudad,
    c.Departamento,
    p.Precio_Propiedad
FROM   Propiedad       p
JOIN   TipoPropiedad   tp ON tp.TipoP_ID   = p.TipoP_ID
JOIN   EstadoPropiedad ep ON ep.EstadoP_ID = p.EstadoP_ID
JOIN   Barrio           b ON  b.Barrio_ID  = p.Barrio_ID
JOIN   Ciudad           c ON  c.Ciudad_ID  = b.Ciudad_ID
WHERE  p.EstadoP_ID = 'EP-01';

-- ============================================================
-- PRUEBAS
-- ============================================================

-- Todas las propiedades disponibles
SELECT * FROM v_propiedades_disponibles;

-- Filtrar por tipo
SELECT * FROM v_propiedades_disponibles WHERE Tipo_Propiedad = 'Apartamento';

-- Ordenar por precio
SELECT * FROM v_propiedades_disponibles ORDER BY Precio_Propiedad ASC;