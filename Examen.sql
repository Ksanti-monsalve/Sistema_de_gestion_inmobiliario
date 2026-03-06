-- ============================================================
-- CONSULTAS SQL PARA ANÁLISIS DE PROPIEDADES
-- ============================================================

-- Consulta 1: Precio promedio, máximo y mínimo de propiedades por ciudad
SELECT 
    c.Nombre_Ciudad AS Ciudad,
    AVG(p.Precio_Propiedad) AS Precio_Promedio,
    MAX(p.Precio_Propiedad) AS Precio_Maximo,
    MIN(p.Precio_Propiedad) AS Precio_Minimo
FROM propiedad p
INNER JOIN barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN ciudad c ON b.Ciudad_ID = c.Ciudad_ID
GROUP BY c.Ciudad_ID, c.Nombre_Ciudad
ORDER BY c.Nombre_Ciudad;

-- ============================================================
-- Consulta 2: Propiedades disponibles para arriendo con precio entre 800000 y 2000000
SELECT 
    p.Propiedad_ID,
    p.Direccion,
    p.Precio_Propiedad,
    ep.Descripcion AS Estado,
    tp.Descripcion AS Tipo_Propiedad
FROM propiedad p
INNER JOIN estadopropiedad ep ON p.EstadoP_ID = ep.EstadoP_ID
INNER JOIN tipopropiedad tp ON p.TipoP_ID = tp.TipoP_ID
WHERE p.EstadoP_ID = 'EP001'  -- Disponible
    AND p.Precio_Propiedad BETWEEN 800000 AND 2000000
ORDER BY p.Precio_Propiedad;

-- ============================================================
-- Consulta 3: Propiedades que incluyen la palabra "Parque" en su dirección
SELECT 
    p.Propiedad_ID,
    p.Direccion,
    p.Precio_Propiedad,
    b.Nombre_Barrio,
    c.Nombre_Ciudad
FROM propiedad p
INNER JOIN barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN ciudad c ON b.Ciudad_ID = c.Ciudad_ID
WHERE p.Direccion LIKE '%Parque%';

-- ============================================================
-- Consulta 4: Nombre del agente, cantidad de propiedades y ciudad principal
SELECT 
    per.Nombre AS Nombre_Agente,
    per.Apellido AS Apellido_Agente,
    COUNT(DISTINCT con.Propiedad_ID) AS Cantidad_Propiedades,
    (SELECT c2.Nombre_Ciudad 
     FROM contratos con2 
     INNER JOIN propiedad prop2 ON con2.Propiedad_ID = prop2.Propiedad_ID
     INNER JOIN barrio bar2 ON prop2.Barrio_ID = bar2.Barrio_ID
     INNER JOIN ciudad c2 ON bar2.Ciudad_ID = c2.Ciudad_ID
     WHERE con2.Agente_ID = con.Agente_ID
     GROUP BY c2.Ciudad_ID
     ORDER BY COUNT(*) DESC
     LIMIT 1) AS Ciudad_Principal
FROM agentes age
INNER JOIN personas per ON age.Persona_ID = per.Persona_ID
LEFT JOIN contratos con ON age.Agente_ID = con.Agente_ID
GROUP BY age.Agente_ID, per.Nombre, per.Apellido
ORDER BY Cantidad_Propiedades DESC;

-- ============================================================
-- Consulta 5: Las 5 propiedades más costosas que ya fueron arrendadas con su cliente
SELECT 
    p.Propiedad_ID,
    p.Direccion,
    p.Precio_Propiedad,
    per.Nombre AS Nombre_Cliente,
    per.Apellido AS Apellido_Cliente,
    con.Fecha_Contrato,
    con.Tipo_Contrato
FROM propiedad p
INNER JOIN contratos con ON p.Propiedad_ID = con.Propiedad_ID
INNER JOIN clientes cli ON con.Cliente_ID = cli.Cliente_ID
INNER JOIN personas per ON cli.Persona_ID = per.Persona_ID
WHERE con.Tipo_Contrato = 'arriendo'
ORDER BY p.Precio_Propiedad DESC
LIMIT 5;

