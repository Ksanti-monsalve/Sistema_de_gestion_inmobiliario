

USE inmobiliaria_db;

DROP TRIGGER IF EXISTS trg_cambio_estado_propiedad;

DELIMITER $$

CREATE TRIGGER trg_cambio_estado_propiedad
AFTER UPDATE ON Propiedad
FOR EACH ROW
BEGIN

    -- Solo actúa si el estado realmente cambió
    IF OLD.EstadoP_ID <> NEW.EstadoP_ID THEN

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
            CONCAT('AUD-',
                   LPAD(
                       (SELECT COUNT(*) + 1 FROM AuditoriaPropiedad),
                   3, '0')),
            NEW.Propiedad_ID,
            -- Descripción del estado anterior
            (SELECT Descripcion FROM EstadoPropiedad
             WHERE  EstadoP_ID = OLD.EstadoP_ID),
            -- Descripción del estado nuevo
            (SELECT Descripcion FROM EstadoPropiedad
             WHERE  EstadoP_ID = NEW.EstadoP_ID),
            CURDATE(),
            -- Usuario de sistema activo (primer usuario encontrado si no hay sesión)
            IFNULL(
                (SELECT Usuario_ID FROM UsuarioSistema LIMIT 1),
                'USR-01'
            ),
            NOW()
        );

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
                ' | Estado anterior: ',
                    (SELECT Descripcion FROM EstadoPropiedad
                     WHERE  EstadoP_ID = OLD.EstadoP_ID),
                ' → Estado nuevo: ',
                    (SELECT Descripcion FROM EstadoPropiedad
                     WHERE  EstadoP_ID = NEW.EstadoP_ID)
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