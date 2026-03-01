-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Vista 3 de 3: Deuda de Arriendos y Comisiones de Agentes
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql + funciones_udf_v2.sql
-- ============================================================

USE inmobiliaria_db;

DROP VIEW IF EXISTS v_deuda_arriendos;
DROP VIEW IF EXISTS v_comisiones_agentes;

-- ============================================================
-- VISTA 3A: v_deuda_arriendos
-- Muestra la deuda pendiente de cada contrato de arriendo
-- Usa la UDF fn_calcular_deuda_pendiente()
-- ============================================================

CREATE VIEW v_deuda_arriendos AS
SELECT
    c.Contrato_ID,
    c.Fecha_Contrato,
    -- Propiedad
    p.Direccion                               AS Propiedad,
    tp.Descripcion                            AS Tipo_Propiedad,
    ci.Nombre_Ciudad                          AS Ciudad,
    -- Cliente
    CONCAT(pcl.Nombre, ' ', pcl.Apellido)     AS Nombre_Cliente,
    pcl.Telefono                              AS Tel_Cliente,
    -- Agente
    CONCAT(pag.Nombre, ' ', pag.Apellido)     AS Nombre_Agente,
    -- Detalle financiero
    ca.Valor_Mensual,
    ca.Fecha_Inicio,
    ca.Fecha_Fin,
    -- Pagos por estado
    SUM(CASE WHEN pg.EstadoPago_ID = 'EPG-01' THEN 1 ELSE 0 END) AS Pagos_Completados,
    SUM(CASE WHEN pg.EstadoPago_ID = 'EPG-02' THEN 1 ELSE 0 END) AS Pagos_Pendientes,
    SUM(CASE WHEN pg.EstadoPago_ID = 'EPG-03' THEN 1 ELSE 0 END) AS Pagos_Vencidos,
    -- Montos
    IFNULL(SUM(pg.Monto_Pago), 0)             AS Total_Recaudado,
    fn_calcular_deuda_pendiente(c.Contrato_ID) AS Deuda_Pendiente
FROM   Contratos        c
JOIN   ContratoArriendo ca  ON ca.Contrato_ID  = c.Contrato_ID
JOIN   Pagos            pg  ON pg.Contrato_ID  = c.Contrato_ID
JOIN   Propiedad         p  ON  p.Propiedad_ID = c.Propiedad_ID
JOIN   TipoPropiedad    tp  ON tp.TipoP_ID     = p.TipoP_ID
JOIN   Barrio            b  ON  b.Barrio_ID    = p.Barrio_ID
JOIN   Ciudad           ci  ON ci.Ciudad_ID    = b.Ciudad_ID
JOIN   Clientes         cl  ON cl.Cliente_ID   = c.Cliente_ID
JOIN   Personas         pcl ON pcl.Persona_ID  = cl.Persona_ID
JOIN   Agentes          ag  ON ag.Agente_ID    = c.Agente_ID
JOIN   Personas         pag ON pag.Persona_ID  = ag.Persona_ID
WHERE  c.Tipo_Contrato = 'Arriendo'
GROUP BY
    c.Contrato_ID, c.Fecha_Contrato,
    p.Direccion, tp.Descripcion, ci.Nombre_Ciudad,
    pcl.Nombre, pcl.Apellido, pcl.Telefono,
    pag.Nombre, pag.Apellido,
    ca.Valor_Mensual, ca.Fecha_Inicio, ca.Fecha_Fin;

-- ============================================================
-- VISTA 3B: v_comisiones_agentes
-- Muestra las comisiones generadas por cada agente en ventas
-- Usa la UDF fn_calcular_comision()
-- ============================================================

CREATE VIEW v_comisiones_agentes AS
SELECT
    ag.Agente_ID,
    CONCAT(pag.Nombre, ' ', pag.Apellido)     AS Nombre_Agente,
    pag.Email                                 AS Email_Agente,
    ag.Comision_Pct                           AS Porcentaje_Comision,
    -- Totales generales
    COUNT(c.Contrato_ID)                      AS Total_Contratos,
    SUM(CASE WHEN c.Tipo_Contrato = 'Arriendo' THEN 1 ELSE 0 END) AS Total_Arriendos,
    SUM(CASE WHEN c.Tipo_Contrato = 'Venta'    THEN 1 ELSE 0 END) AS Total_Ventas,
    -- Montos de ventas
    IFNULL(SUM(cv.Precio_Venta), 0)           AS Monto_Total_Ventas,
    -- Comisiones
    IFNULL(SUM(cv.Comision_Venta), 0)         AS Comision_Registrada,
    IFNULL(SUM(fn_calcular_comision(c.Contrato_ID)), 0) AS Comision_Calculada
FROM   Agentes        ag
JOIN   Personas       pag ON pag.Persona_ID  = ag.Persona_ID
LEFT JOIN Contratos     c ON   c.Agente_ID   = ag.Agente_ID
LEFT JOIN ContratoVenta cv ON  cv.Contrato_ID = c.Contrato_ID
                           AND c.Tipo_Contrato = 'Venta'
GROUP BY
    ag.Agente_ID, pag.Nombre, pag.Apellido,
    pag.Email, ag.Comision_Pct;

-- ============================================================
-- PRUEBAS
-- ============================================================

-- Deuda de todos los arriendos
SELECT * FROM v_deuda_arriendos;

-- Solo arriendos con deuda pendiente
SELECT * FROM v_deuda_arriendos
WHERE  Deuda_Pendiente > 0
ORDER BY Deuda_Pendiente DESC;

-- Comisiones de todos los agentes
SELECT * FROM v_comisiones_agentes;

-- Ranking de agentes por comisión calculada
SELECT * FROM v_comisiones_agentes
ORDER BY Comision_Calculada DESC;