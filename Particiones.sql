-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Script: Partición de la tabla ReportePagos
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql
-- ============================================================

USE inmobiliaria_db;


DROP PROCEDURE IF EXISTS _drop_fk_if_exists;

DELIMITER $$
CREATE PROCEDURE _drop_fk_if_exists(
    IN p_tabla      VARCHAR(100),
    IN p_constraint VARCHAR(100)
)
BEGIN
    IF EXISTS (
        SELECT 1
        FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS
        WHERE  TABLE_SCHEMA    = DATABASE()
          AND  TABLE_NAME      = p_tabla
          AND  CONSTRAINT_NAME = p_constraint
          AND  CONSTRAINT_TYPE = 'FOREIGN KEY'
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_tabla,
                          '` DROP FOREIGN KEY `', p_constraint, '`');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('OK: FK eliminada → ', p_constraint) AS resultado;
    ELSE
        SELECT CONCAT('INFO: FK no existe, se omite → ', p_constraint) AS resultado;
    END IF;
END$$
DELIMITER ;

CALL _drop_fk_if_exists('ReportePagos', 'fk_reportepagos_contrato');

DROP PROCEDURE IF EXISTS _drop_fk_if_exists;

-- ============================================================
-- PASO 2: AMPLIAR LA PRIMARY KEY PARA INCLUIR Fecha_Reporte
-- ============================================================

ALTER TABLE ReportePagos
    DROP PRIMARY KEY,
    ADD  PRIMARY KEY (Reporte_ID, Fecha_Reporte);

-- ============================================================
-- PASO 3: CREAR PARTICIÓN RANGE POR AÑO DE Fecha_Reporte
-- Cada partición agrupa todos los reportes de un año.
-- El evento mensual inserta aquí cada día 1 del mes.
-- p_reporte_futuro captura cualquier año posterior a 2026.
-- ============================================================

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
-- VERIFICACIÓN: confirmar particiones creadas
-- ============================================================

SELECT '== PARTICIONES DE LA TABLA ReportePagos ==' AS info;

SELECT
    PARTITION_NAME        AS Particion,
    PARTITION_METHOD      AS Metodo,
    PARTITION_DESCRIPTION AS Limite,
    TABLE_ROWS            AS Filas_Estimadas
FROM   INFORMATION_SCHEMA.PARTITIONS
WHERE  TABLE_SCHEMA   = 'inmobiliaria_db'
  AND  TABLE_NAME     = 'ReportePagos'
  AND  PARTITION_NAME IS NOT NULL
ORDER BY PARTITION_ORDINAL_POSITION;

-- ============================================================
-- PRUEBA DE PARTITION PRUNING CON EXPLAIN
-- La columna "partitions" debe mostrar solo p_reporte_2024
-- cuando se filtra por ese año
-- ============================================================

SELECT '== EXPLAIN filtro por año 2024 ==' AS info;
EXPLAIN SELECT *
FROM   ReportePagos
WHERE  Fecha_Reporte BETWEEN '2024-01-01' AND '2024-12-31';

SELECT '== EXPLAIN filtro por periodo específico ==' AS info;
EXPLAIN SELECT *
FROM   ReportePagos
WHERE  Periodo       = '2024-05'
  AND  Fecha_Reporte BETWEEN '2024-01-01' AND '2024-12-31';

-- ============================================================
-- MANTENIMIENTO FUTURO (comandos comentados)
-- ============================================================

-- Agregar partición para 2027 (ejecutar en enero 2027):
-- ALTER TABLE ReportePagos REORGANIZE PARTITION p_reporte_futuro INTO (
--     PARTITION p_reporte_2027   VALUES LESS THAN (2028),
--     PARTITION p_reporte_futuro VALUES LESS THAN MAXVALUE
-- );

-- Purgar reportes del año 2022 (más rápido que DELETE):
-- ALTER TABLE ReportePagos DROP PARTITION p_reporte_2022;

-- Ver filas y tamaño por partición:
-- SELECT PARTITION_NAME,
--        TABLE_ROWS,
--        ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS MB
-- FROM   INFORMATION_SCHEMA.PARTITIONS
-- WHERE  TABLE_SCHEMA = 'inmobiliaria_db'
--   AND  TABLE_NAME   = 'ReportePagos'
--   AND  PARTITION_NAME IS NOT NULL;

