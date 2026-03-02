-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Script: Optimización de Consultas e Índices (CORREGIDO v3)
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql
-- ============================================================

USE inmobiliaria_db;

-- ============================================================
-- PARTE 0: PROCEDURE AUXILIAR PARA CREAR ÍNDICE SOLO SI
--          NO EXISTE (evita error si se ejecuta 2 veces)
-- ============================================================

DROP PROCEDURE IF EXISTS _create_index_if_not_exists;

DELIMITER $$
CREATE PROCEDURE _create_index_if_not_exists(
    IN p_tabla  VARCHAR(100),
    IN p_indice VARCHAR(100),
    IN p_sql    TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM   INFORMATION_SCHEMA.STATISTICS
        WHERE  TABLE_SCHEMA = DATABASE()
          AND  TABLE_NAME   = p_tabla
          AND  INDEX_NAME   = p_indice
    ) THEN
        SET @ddl = p_sql;
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSE
        SELECT CONCAT('INFO: Índice ya existe → ', p_tabla, '.', p_indice) AS mensaje;
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- PARTE 1: ÍNDICES ADICIONALES DE OPTIMIZACIÓN
-- NOTA: Los índices sobre FK ya existen automáticamente:
--   Propiedad    → EstadoP_ID, TipoP_ID, Barrio_ID  (por FK)
--   Contratos    → Cliente_ID, Agente_ID, Propiedad_ID (por FK)
--   Pagos        → Contrato_ID, EstadoPago_ID          (por FK)
--   ContratoArriendo → Contrato_ID                     (por FK)
--   ContratoVenta    → Contrato_ID                     (por FK)
-- Solo se agregan índices sobre columnas SIN FK
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- TABLA: Propiedad
-- FK ya cubre: EstadoP_ID, TipoP_ID, Barrio_ID
-- NUEVO: precio (ORDER BY en búsquedas de rango de precio)
-- NUEVO: compuesto TipoP_ID + EstadoP_ID (filtros combinados)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'Propiedad', 'idx_propiedad_precio',
    'CREATE INDEX idx_propiedad_precio ON Propiedad(Precio_Propiedad)'
);

CALL _create_index_if_not_exists(
    'Propiedad', 'idx_propiedad_tipo_estado',
    'CREATE INDEX idx_propiedad_tipo_estado ON Propiedad(TipoP_ID, EstadoP_ID)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: Contratos
-- FK ya cubre: Cliente_ID, Agente_ID, Propiedad_ID
-- NUEVO: Tipo_Contrato (filtros WHERE Tipo = 'Arriendo'/'Venta')
-- NUEVO: Fecha_Contrato (ORDER BY, rangos de fechas)
-- NUEVO: compuesto Tipo_Contrato + Agente_ID
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'Contratos', 'idx_contratos_tipo',
    'CREATE INDEX idx_contratos_tipo ON Contratos(Tipo_Contrato)'
);

CALL _create_index_if_not_exists(
    'Contratos', 'idx_contratos_fecha',
    'CREATE INDEX idx_contratos_fecha ON Contratos(Fecha_Contrato)'
);

CALL _create_index_if_not_exists(
    'Contratos', 'idx_contratos_tipo_agente',
    'CREATE INDEX idx_contratos_tipo_agente ON Contratos(Tipo_Contrato, Agente_ID)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: Pagos
-- FK ya cubre: Contrato_ID, EstadoPago_ID
-- NUEVO: Fecha_Pago (ORDER BY, reportes por período)
-- NUEVO: compuesto Contrato_ID + EstadoPago_ID (UDF + evento)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'Pagos', 'idx_pagos_fecha',
    'CREATE INDEX idx_pagos_fecha ON Pagos(Fecha_Pago)'
);

CALL _create_index_if_not_exists(
    'Pagos', 'idx_pagos_contrato_estado',
    'CREATE INDEX idx_pagos_contrato_estado ON Pagos(Contrato_ID, EstadoPago_ID)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: ContratoArriendo
-- FK ya cubre: Contrato_ID
-- NUEVO: compuesto Fecha_Inicio + Fecha_Fin (vigencias)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'ContratoArriendo', 'idx_contrarriendo_fechas',
    'CREATE INDEX idx_contrarriendo_fechas ON ContratoArriendo(Fecha_Inicio, Fecha_Fin)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: ContratoVenta
-- FK ya cubre: Contrato_ID
-- NUEVO: Precio_Venta (ORDER BY en reportes de ventas)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'ContratoVenta', 'idx_contraventa_precio',
    'CREATE INDEX idx_contraventa_precio ON ContratoVenta(Precio_Venta)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: AuditoriaPropiedad
-- FK ya cubre: Propiedad_ID, Usuario_ID
-- NUEVO: Fecha_Hora (ORDER BY DESC en vistas de auditoría)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'AuditoriaPropiedad', 'idx_auditprop_fecha',
    'CREATE INDEX idx_auditprop_fecha ON AuditoriaPropiedad(Fecha_Hora)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: AuditoriaContrato
-- FK ya cubre: Contrato_ID, Usuario_ID
-- NUEVO: Fecha_Hora (ORDER BY DESC en vistas de auditoría)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'AuditoriaContrato', 'idx_auditcont_fecha',
    'CREATE INDEX idx_auditcont_fecha ON AuditoriaContrato(Fecha_Hora)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: ReportePagos
-- FK ya cubre: Contrato_ID
-- NUEVO: Periodo (WHERE Periodo = '2024-05' en el evento)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'ReportePagos', 'idx_reporte_periodo',
    'CREATE INDEX idx_reporte_periodo ON ReportePagos(Periodo)'
);

-- ────────────────────────────────────────────────────────────
-- TABLA: Barrio
-- FK ya cubre: Ciudad_ID
-- (No se agregan índices adicionales)
-- ────────────────────────────────────────────────────────────

-- ────────────────────────────────────────────────────────────
-- TABLA: Personas
-- NUEVO: Email (búsquedas de login y validación de duplicados)
-- ────────────────────────────────────────────────────────────
CALL _create_index_if_not_exists(
    'Personas', 'idx_personas_email',
    'CREATE INDEX idx_personas_email ON Personas(Email)'
);

-- Limpiar procedure auxiliar
DROP PROCEDURE IF EXISTS _create_index_if_not_exists;

-- ============================================================
-- PARTE 2: VERIFICAR ÍNDICES (adicionales + FK automáticos)
-- ============================================================

SELECT '== ÍNDICES TABLA Propiedad ==' AS info;
SHOW INDEX FROM Propiedad;

SELECT '== ÍNDICES TABLA Contratos ==' AS info;
SHOW INDEX FROM Contratos;

SELECT '== ÍNDICES TABLA Pagos ==' AS info;
SHOW INDEX FROM Pagos;

-- ============================================================
-- PARTE 3: CONSULTAS CON EXPLAIN
-- ============================================================

-- ── 3.1 Propiedades disponibles por tipo ─────────────────────
EXPLAIN
SELECT
    p.Propiedad_ID, p.Direccion,
    tp.Descripcion  AS Tipo,
    b.Nombre_Barrio AS Barrio,
    c.Nombre_Ciudad AS Ciudad,
    p.Precio_Propiedad
FROM   Propiedad       p
JOIN   TipoPropiedad   tp ON tp.TipoP_ID   = p.TipoP_ID
JOIN   EstadoPropiedad ep ON ep.EstadoP_ID = p.EstadoP_ID
JOIN   Barrio           b ON  b.Barrio_ID  = p.Barrio_ID
JOIN   Ciudad           c ON  c.Ciudad_ID  = b.Ciudad_ID
WHERE  p.EstadoP_ID = 'EP-01'
  AND  p.TipoP_ID   = 'TP-01';

-- ── 3.2 Arriendos con pagos pendientes ───────────────────────
EXPLAIN
SELECT
    c.Contrato_ID,
    ca.Valor_Mensual,
    COUNT(p.Pago_ID) AS Meses_Pendientes
FROM   Contratos        c
JOIN   ContratoArriendo ca ON ca.Contrato_ID = c.Contrato_ID
JOIN   Pagos             p ON  p.Contrato_ID = c.Contrato_ID
WHERE  c.Tipo_Contrato   = 'Arriendo'
  AND  p.EstadoPago_ID  IN ('EPG-02','EPG-03')
GROUP BY c.Contrato_ID, ca.Valor_Mensual;

-- ── 3.3 Comisiones por agente ─────────────────────────────────
EXPLAIN
SELECT
    a.Agente_ID,
    CONCAT(pe.Nombre,' ',pe.Apellido) AS Agente,
    COUNT(c.Contrato_ID)              AS Total_Ventas,
    SUM(cv.Precio_Venta)              AS Total_Vendido,
    SUM(cv.Comision_Venta)            AS Total_Comisiones
FROM   Agentes        a
JOIN   Personas       pe ON pe.Persona_ID   = a.Persona_ID
JOIN   Contratos       c ON  c.Agente_ID    = a.Agente_ID
                         AND c.Tipo_Contrato = 'Venta'
JOIN   ContratoVenta  cv ON cv.Contrato_ID  = c.Contrato_ID
GROUP BY a.Agente_ID, pe.Nombre, pe.Apellido
ORDER BY Total_Comisiones DESC;

-- ── 3.4 Historial de pagos por cliente ───────────────────────
EXPLAIN
SELECT
    pg.Pago_ID, pg.Fecha_Pago, pg.Monto_Pago,
    ep.Descripcion AS Estado_Pago,
    pr.Direccion   AS Propiedad
FROM   Pagos        pg
JOIN   EstadoPago   ep ON ep.EstadoPago_ID = pg.EstadoPago_ID
JOIN   Contratos     c ON  c.Contrato_ID   = pg.Contrato_ID
JOIN   Propiedad    pr ON pr.Propiedad_ID  = c.Propiedad_ID
WHERE  c.Cliente_ID = 'CLI-01'
ORDER BY pg.Fecha_Pago DESC;

-- ── 3.5 Auditoría por rango de fechas ────────────────────────
EXPLAIN
SELECT 'Propiedad' AS Tipo, ap.Propiedad_ID AS Entidad,
       ap.Estado_Anterior, ap.Estado_Nuevo, ap.Fecha_Hora
FROM   AuditoriaPropiedad ap
WHERE  ap.Fecha_Hora BETWEEN '2024-01-01' AND '2024-12-31'
UNION ALL
SELECT 'Contrato', ac.Contrato_ID,
       ac.Evento, '', ac.Fecha_Hora
FROM   AuditoriaContrato ac
WHERE  ac.Fecha_Hora BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY Fecha_Hora DESC;

-- ============================================================
-- PARTE 4: CONSULTAS REALES OPTIMIZADAS
-- ============================================================

-- ── 4.1 Propiedades disponibles por precio ───────────────────
SELECT
    p.Propiedad_ID,
    tp.Descripcion          AS Tipo,
    p.Direccion,
    b.Nombre_Barrio         AS Barrio,
    c.Nombre_Ciudad         AS Ciudad,
    p.Precio_Propiedad
FROM   Propiedad       p
JOIN   TipoPropiedad   tp ON tp.TipoP_ID  = p.TipoP_ID
JOIN   Barrio           b ON  b.Barrio_ID = p.Barrio_ID
JOIN   Ciudad           c ON  c.Ciudad_ID = b.Ciudad_ID
WHERE  p.EstadoP_ID = 'EP-01'
ORDER BY p.Precio_Propiedad ASC;

-- ── 4.2 Arriendos con deuda pendiente ────────────────────────
SELECT
    c.Contrato_ID,
    CONCAT(per.Nombre,' ',per.Apellido) AS Cliente,
    per.Telefono,
    pr.Direccion                        AS Propiedad,
    ca.Valor_Mensual,
    COUNT(p.Pago_ID)                    AS Meses_Pendientes,
    COUNT(p.Pago_ID) * ca.Valor_Mensual AS Deuda_Total
FROM   Contratos        c
JOIN   ContratoArriendo ca  ON ca.Contrato_ID  = c.Contrato_ID
JOIN   Pagos             p  ON  p.Contrato_ID  = c.Contrato_ID
JOIN   Propiedad        pr  ON pr.Propiedad_ID = c.Propiedad_ID
JOIN   Clientes         cl  ON cl.Cliente_ID   = c.Cliente_ID
JOIN   Personas        per  ON per.Persona_ID  = cl.Persona_ID
WHERE  c.Tipo_Contrato   = 'Arriendo'
  AND  p.EstadoPago_ID  IN ('EPG-02','EPG-03')
GROUP BY
    c.Contrato_ID, per.Nombre, per.Apellido,
    per.Telefono, pr.Direccion, ca.Valor_Mensual
HAVING COUNT(p.Pago_ID) > 0
ORDER BY Deuda_Total DESC;

-- ── 4.3 Ranking de agentes por comisiones ────────────────────
SELECT
    a.Agente_ID,
    CONCAT(pe.Nombre,' ',pe.Apellido)              AS Agente,
    a.Comision_Pct                                 AS Porcentaje,
    COUNT(c.Contrato_ID)                           AS Total_Contratos,
    SUM(CASE WHEN c.Tipo_Contrato='Venta' THEN 1 ELSE 0 END) AS Ventas,
    IFNULL(SUM(cv.Comision_Venta), 0)              AS Total_Comisiones
FROM   Agentes         a
JOIN   Personas        pe ON pe.Persona_ID   = a.Persona_ID
LEFT JOIN Contratos     c ON  c.Agente_ID    = a.Agente_ID
LEFT JOIN ContratoVenta cv ON cv.Contrato_ID = c.Contrato_ID
GROUP BY a.Agente_ID, pe.Nombre, pe.Apellido, a.Comision_Pct
ORDER BY Total_Comisiones DESC;

-- ── 4.4 Resumen del portafolio por tipo ──────────────────────
SELECT
    tp.Descripcion                     AS Tipo_Propiedad,
    COUNT(p.Propiedad_ID)              AS Total,
    SUM(p.EstadoP_ID = 'EP-01')        AS Disponibles,
    SUM(p.EstadoP_ID = 'EP-02')        AS Arrendadas,
    SUM(p.EstadoP_ID = 'EP-03')        AS Vendidas,
    FORMAT(AVG(p.Precio_Propiedad), 0) AS Precio_Promedio,
    FORMAT(MIN(p.Precio_Propiedad), 0) AS Precio_Minimo,
    FORMAT(MAX(p.Precio_Propiedad), 0) AS Precio_Maximo
FROM   Propiedad     p
JOIN   TipoPropiedad tp ON tp.TipoP_ID = p.TipoP_ID
GROUP BY tp.Descripcion
ORDER BY tp.Descripcion;

-- ============================================================
-- PARTE 5: RESUMEN FINAL DE TODOS LOS ÍNDICES
-- ============================================================

SELECT
    TABLE_NAME   AS Tabla,
    INDEX_NAME   AS Indice,
    COLUMN_NAME  AS Columna,
    NON_UNIQUE   AS No_Unico,
    SEQ_IN_INDEX AS Posicion
FROM   INFORMATION_SCHEMA.STATISTICS
WHERE  TABLE_SCHEMA = 'inmobiliaria_db'
  AND  INDEX_NAME  != 'PRIMARY'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================