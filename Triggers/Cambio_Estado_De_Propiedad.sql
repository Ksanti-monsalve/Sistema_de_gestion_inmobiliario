-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Trigger 1 de 2: Cambio de estado de una propiedad
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql
-- ============================================================

USE inmobiliaria_db;

DROP TRIGGER IF EXISTS trg_cambio_estado_propiedad;

DELIMITER $$

CREATE TRIGGER trg_cambio_estado_propiedad
AFTER UPDATE ON Propiedad
FOR EACH ROW
BEGIN

    -- Solo actúa si el estado realmente cambió
    IF OLD.EstadoP_ID <> NEW.EstadoP_ID THEN

        -- Variables locales para evitar subqueries problemáticas
        -- MySQL no permite SELECT COUNT(*) sobre la misma tabla
        -- que recibe el INSERT dentro de un trigger (Error 1064)
        DECLARE v_audit_id    VARCHAR(10);
        DECLARE v_desc_ant    VARCHAR(50);
        DECLARE v_desc_new    VARCHAR(50);
        DECLARE v_usuario     VARCHAR(10);

        SET v_audit_id = CONCAT('AUD',
                            RIGHT(UNIX_TIMESTAMP(NOW(6)), 5));

        SELECT Descripcion INTO v_desc_ant
        FROM   EstadoPropiedad WHERE EstadoP_ID = OLD.EstadoP_ID;

        SELECT Descripcion INTO v_desc_new
        FROM   EstadoPropiedad WHERE EstadoP_ID = NEW.EstadoP_ID;

        SELECT Usuario_ID INTO v_usuario
        FROM   UsuarioSistema LIMIT 1;

        SET v_usuario = IFNULL(v_usuario, 'USR001');

        -- Registrar en AuditoriaPropiedad
        INSERT INTO AuditoriaPropiedad (
            Audit_ID,
            Propiedad_ID,
            Estado_Anterior,
            Estado_Nuevo,
            Fecha_Cambio,
            Usuario_ID,
            Fecha_Hora
        )
        VALUES (
            v_audit_id,
            NEW.Propiedad_ID,
            v_desc_ant,
            v_desc_new,
            CURDATE(),
            v_usuario,
            NOW()
        );

        -- Registrar en Logs_Cambios
        INSERT INTO Logs_Cambios (
            Fecha_Cambio,
            Nombre_Cambio,
            Lugar_Cambio,
            Descripcion
        )
        VALUES (
            NOW(),
            'UPDATE - EstadoP_ID',
            'Tabla: Propiedad | Trigger: trg_cambio_estado_propiedad',
            CONCAT(
                'Propiedad: ', NEW.Propiedad_ID,
                ' | Dirección: ', NEW.Direccion,
                ' | Estado anterior: ', v_desc_ant,
                ' → Estado nuevo: ',    v_desc_new
            )
        );

    END IF;

END$$

DELIMITER ;

-- ============================================================
-- PRUEBA DEL TRIGGER
-- ============================================================

-- Estado actual de PROP-05 antes del cambio: EP-01 (Disponible)
SELECT p.Propiedad_ID,
       p.Direccion,
       ep.Descripcion AS estado_actual
FROM   Propiedad       p
JOIN   EstadoPropiedad ep ON ep.EstadoP_ID = p.EstadoP_ID
WHERE  p.Propiedad_ID = 'PROP-05';

-- Ejecutar cambio de estado → debe disparar el trigger
UPDATE Propiedad
SET    EstadoP_ID = 'EP-02'       -- Disponible → Arrendada
WHERE  Propiedad_ID = 'PROP-05';

-- Verificar que se registró en AuditoriaPropiedad
SELECT *
FROM   AuditoriaPropiedad
WHERE  Propiedad_ID = 'PROP-05'
ORDER BY Fecha_Hora DESC;

-- Verificar que se registró en Logs_Cambios
SELECT *
FROM   Logs_Cambios
ORDER BY Fecha_Cambio DESC
LIMIT  3;