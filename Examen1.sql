-- =============================================================================================================================
-- 1 CONSULTA ; Mostrar el precio promedio, máximo y mínimo de las propiedades agrupadas por ciudad (AVG, MAX, MIN, GROUP BY).
-- =============================================================================================================================

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

-- =============================================================================================================================
-- 2 CONSULTA ; Listar las propiedades disponibles para arriendo cuyo precio esté entre 800000 y 2000000 (BETWEEN, WHERE, AND).
--==============================================================================================================================

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

-- =======================================================================================================
--3 CONSULTA ; Mostrar las propiedades que incluyen la palabra “Parque” en su dirección (LIKE '%Parque%').
-- =======================================================================================================

