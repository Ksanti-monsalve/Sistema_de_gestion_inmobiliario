-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Script: Particiones de Tablas (CORREGIDO)
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql
-- ============================================================
--
--  CORRECCIÓN Error 1506:
--  MySQL NO soporta FOREIGN KEYS en tablas particionadas.
--  Solución: eliminar las FKs de las tablas a particionar
--  ANTES de aplicar la partición. La integridad referencial
--  queda garantizada por los Stored Procedures y Triggers.
--
--  TABLAS PARTICIONADAS (6):
--  1. Pagos              → RANGE por YEAR(Fecha_Pago)
--  2. ReportePagos       → RANGE por YEAR(Fecha_Reporte)
--  3. AuditoriaContrato  → RANGE por YEAR(Fecha_Hora)
--  4. AuditoriaPropiedad → RANGE por YEAR(Fecha_Hora)
--  5. Logs_Cambios       → RANGE por YEAR(Fecha_Cambio)
--  6. Logs_Errores       → RANGE por YEAR(Fecha_Error)
-- ============================================================

USE inmobiliaria_db;

-- ============================================================
-- PARTE 1: PAGOS
-- ============================================================

-- Paso 1: Eliminar FKs (requerido por MySQL antes de particionar)
ALTER TABLE Pagos
    DROP FOREIGN KEY fk_pagos_contrato,
    DROP FOREIGN KEY fk_pagos_estadopago;

-- Paso 2: Ampliar PK para incluir la columna de partición
--         MySQL exige que la columna de partición sea parte de la PK
ALTER TABLE Pagos
    DROP PRIMARY KEY,
    ADD  PRIMARY KEY (Pago_ID, Fecha_Pago);

-- Paso 3: Aplicar partición RANGE por año
ALTER TABLE Pagos
    PARTITION BY RANGE (YEAR(Fecha_Pago)) (
        PARTITION p_pagos_2022   VALUES LESS THAN (2023),
        PARTITION p_pagos_2023   VALUES LESS THAN (2024),
        PARTITION p_pagos_2024   VALUES LESS THAN (2025),
        PARTITION p_pagos_2025   VALUES LESS THAN (2026),
        PARTITION p_pagos_2026   VALUES LESS THAN (2027),
        PARTITION p_pagos_futuro VALUES LESS THAN MAXVALUE
    );

-- ============================================================
-- PARTE 2: REPORTE PAGOS
-- ============================================================

ALTER TABLE ReportePagos
    DROP FOREIGN KEY fk_reportepagos_contrato;

ALTER TABLE ReportePagos
    DROP PRIMARY KEY,
    ADD  PRIMARY KEY (Reporte_ID, Fecha_Reporte);

ALTER TABLE ReportePagos
    PARTITION BY RANGE (YEAR(Fecha_Reporte)) (
        PARTITION p_reporte_2022   VALUES LESS THAN (2023),
        PARTITION p_reporte_2023   VALUES LESS THAN (2024),
        PARTITION p_reporte_2024   VALUES LESS THAN (2025),
        PARTITION p_reporte_2025   VALUES LESS THAN (2026),
        PARTITION p_reporte_2026   VALUES LESS THAN (2027),
        PARTITION p_reporte_futuro VALUES LESS THAN MAXVALUE
    );

-- ============================================================
-- PARTE 3: AUDITORIA CONTRATO
-- ============================================================

ALTER TABLE AuditoriaContrato
    DROP FOREIGN KEY fk_auditcontrato_contrato,
    DROP FOREIGN KEY fk_auditcontrato_usuario;

ALTER TABLE AuditoriaContrato
    DROP PRIMARY KEY,
    ADD  PRIMARY KEY (AuditCon_ID, Fecha_Hora);

ALTER TABLE AuditoriaContrato
    PARTITION BY RANGE (YEAR(Fecha_Hora)) (
        PARTITION p_auditcon_2022   VALUES LESS THAN (2023),
        PARTITION p_auditcon_2023   VALUES LESS THAN (2024),
        PARTITION p_auditcon_2024   VALUES LESS THAN (2025),
        PARTITION p_auditcon_2025   VALUES LESS THAN (2026),
        PARTITION p_auditcon_2026   VALUES LESS THAN (2027),
        PARTITION p_auditcon_futuro VALUES LESS THAN MAXVALUE
    );

-- ============================================================
-- PARTE 4: AUDITORIA PROPIEDAD
-- ============================================================

ALTER TABLE AuditoriaPropiedad
    DROP FOREIGN KEY fk_auditprop_propiedad,
    DROP FOREIGN KEY fk_auditprop_usuario;

ALTER TABLE AuditoriaPropiedad
    DROP PRIMARY KEY,
    ADD  PRIMARY KEY (Audit_ID, Fecha_Hora);

ALTER TABLE AuditoriaPropiedad
    PARTITION BY RANGE (YEAR(Fecha_Hora)) (
        PARTITION p_auditprop_2022   VALUES LESS THAN (2023),
        PARTITION p_auditprop_2023   VALUES LESS THAN (2024),
        PARTITION p_auditprop_2024   VALUES LESS THAN (2025),
        PARTITION p_auditprop_2025   VALUES LESS THAN (2026),
        PARTITION p_auditprop_2026   VALUES LESS THAN (2027),
        PARTITION p_auditprop_futuro VALUES LESS THAN MAXVALUE
    );

-- ============================================================
-- PARTE 5: LOGS_CAMBIOS
-- (No tiene FKs — solo se ajusta la PK)
-- ============================================================

ALTER TABLE Logs_Cambios
    DROP PRIMARY KEY,
    ADD  PRIMARY KEY (Log_ID, Fecha_Cambio);

ALTER TABLE Logs_Cambios
    PARTITION BY RANGE (YEAR(Fecha_Cambio)) (
        PARTITION p_logscam_2022   VALUES LESS THAN (2023),
        PARTITION p_logscam_2023   VALUES LESS THAN (2024),
        PARTITION p_logscam_2024   VALUES LESS THAN (2025),
        PARTITION p_logscam_2025   VALUES LESS THAN (2026),
        PARTITION p_logscam_2026   VALUES LESS THAN (2027),
        PARTITION p_logscam_futuro VALUES LESS THAN MAXVALUE
    );

-- ============================================================
-- PARTE 6: LOGS_ERRORES
-- (No tiene FKs — solo se ajusta la PK)
-- ============================================================

ALTER TABLE Logs_Errores
    DROP PRIMARY KEY,
    ADD  PRIMARY KEY (Log_ID, Fecha_Error);

ALTER TABLE Logs_Errores
    PARTITION BY RANGE (YEAR(Fecha_Error)) (
        PARTITION p_logserr_2022   VALUES LESS THAN (2023),
        PARTITION p_logserr_2023   VALUES LESS THAN (2024),
        PARTITION p_logserr_2024   VALUES LESS THAN (2025),
        PARTITION p_logserr_2025   VALUES LESS THAN (2026),
        PARTITION p_logserr_2026   VALUES LESS THAN (2027),
        PARTITION p_logserr_futuro VALUES LESS THAN MAXVALUE
    );

-- ============================================================
-- PARTE 7: VERIFICACIÓN DE PARTICIONES CREADAS
-- ============================================================

SELECT '== PARTICIONES CREADAS ==' AS info;

SELECT
    TABLE_NAME             AS Tabla,
    PARTITION_NAME         AS Particion,
    PARTITION_METHOD       AS Metodo,
    PARTITION_DESCRIPTION  AS Limite,
    TABLE_ROWS             AS Filas_Estimadas
FROM   INFORMATION_SCHEMA.PARTITIONS
WHERE  TABLE_SCHEMA   = 'inmobiliaria_db'
  AND  PARTITION_NAME IS NOT NULL
ORDER BY TABLE_NAME, PARTITION_ORDINAL_POSITION;

-- ============================================================
-- PARTE 8: PRUEBA DE PARTITION PRUNING CON EXPLAIN
-- La columna "partitions" muestra qué particiones se escanean.
-- Con filtro de año solo debe aparecer UNA partición.
-- ============================================================

SELECT '== EXPLAIN Pagos 2024 (debe usar solo p_pagos_2024) ==' AS info;
EXPLAIN SELECT * FROM Pagos
WHERE  Fecha_Pago BETWEEN '2024-01-01' AND '2024-12-31';

SELECT '== EXPLAIN ReportePagos 2024 ==' AS info;
EXPLAIN SELECT * FROM ReportePagos
WHERE  Fecha_Reporte BETWEEN '2024-01-01' AND '2024-12-31';

SELECT '== EXPLAIN AuditoriaContrato 2024 ==' AS info;
EXPLAIN SELECT * FROM AuditoriaContrato
WHERE  Fecha_Hora BETWEEN '2024-01-01' AND '2024-12-31';

SELECT '== EXPLAIN AuditoriaPropiedad 2024 ==' AS info;
EXPLAIN SELECT * FROM AuditoriaPropiedad
WHERE  Fecha_Hora BETWEEN '2024-01-01' AND '2024-12-31';

SELECT '== EXPLAIN Logs_Cambios 2024 ==' AS info;
EXPLAIN SELECT * FROM Logs_Cambios
WHERE  Fecha_Cambio BETWEEN '2024-01-01' AND '2024-12-31';

SELECT '== EXPLAIN Logs_Errores 2024 ==' AS info;
EXPLAIN SELECT * FROM Logs_Errores
WHERE  Fecha_Error BETWEEN '2024-01-01' AND '2024-12-31';

-- ============================================================
-- PARTE 9: MANTENIMIENTO FUTURO (comandos comentados)
-- ============================================================

-- Agregar año 2027 a todas las tablas (ejecutar en enero 2027):
-- ALTER TABLE Pagos REORGANIZE PARTITION p_pagos_futuro INTO (
--     PARTITION p_pagos_2027   VALUES LESS THAN (2028),
--     PARTITION p_pagos_futuro VALUES LESS THAN MAXVALUE
-- );
-- ALTER TABLE ReportePagos REORGANIZE PARTITION p_reporte_futuro INTO (
--     PARTITION p_reporte_2027   VALUES LESS THAN (2028),
--     PARTITION p_reporte_futuro VALUES LESS THAN MAXVALUE
-- );
-- ALTER TABLE AuditoriaContrato REORGANIZE PARTITION p_auditcon_futuro INTO (
--     PARTITION p_auditcon_2027   VALUES LESS THAN (2028),
--     PARTITION p_auditcon_futuro VALUES LESS THAN MAXVALUE
-- );
-- ALTER TABLE AuditoriaPropiedad REORGANIZE PARTITION p_auditprop_futuro INTO (
--     PARTITION p_auditprop_2027   VALUES LESS THAN (2028),
--     PARTITION p_auditprop_futuro VALUES LESS THAN MAXVALUE
-- );
-- ALTER TABLE Logs_Cambios REORGANIZE PARTITION p_logscam_futuro INTO (
--     PARTITION p_logscam_2027   VALUES LESS THAN (2028),
--     PARTITION p_logscam_futuro VALUES LESS THAN MAXVALUE
-- );
-- ALTER TABLE Logs_Errores REORGANIZE PARTITION p_logserr_futuro INTO (
--     PARTITION p_logserr_2027   VALUES LESS THAN (2028),
--     PARTITION p_logserr_futuro VALUES LESS THAN MAXVALUE
-- );

-- Purgar año entero eliminando la partición (más rápido que DELETE):
-- ALTER TABLE Logs_Errores  DROP PARTITION p_logserr_2022;
-- ALTER TABLE Logs_Cambios  DROP PARTITION p_logscam_2022;
-- ALTER TABLE AuditoriaContrato  DROP PARTITION p_auditcon_2022;
-- ALTER TABLE AuditoriaPropiedad DROP PARTITION p_auditprop_2022;

-- Ver tamaño en MB de cada partición:
-- SELECT TABLE_NAME, PARTITION_NAME,
--        ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS MB
-- FROM   INFORMATION_SCHEMA.PARTITIONS
-- WHERE  TABLE_SCHEMA = 'inmobiliaria_db'
--   AND  PARTITION_NAME IS NOT NULL
-- ORDER BY TABLE_NAME, PARTITION_ORDINAL_POSITION;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================