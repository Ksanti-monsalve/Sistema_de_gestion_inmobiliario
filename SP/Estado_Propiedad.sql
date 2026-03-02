-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Stored Procedure 3: Cambiar estado de una propiedad
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql + trg_1_cambio_estado_propiedad.sql
-- ============================================================

USE inmobiliaria_db;

DROP PROCEDURE IF EXISTS sp_cambiar_estado_propiedad;

DELIMITER $$

CREATE PROCEDURE sp_cambiar_estado_propiedad(
    IN  p_propiedad_id  VARCHAR(10),  -- ej: 'PROP-05'
    IN  p_nuevo_estado  VARCHAR(10),  -- ej: 'EP-01', 'EP-02', 'EP-03'
    OUT p_resultado     VARCHAR(200)  -- mensaje de resultado
)
proc_label: BEGIN

    DECLARE v_estado_actual VARCHAR(10)  DEFAULT '';
    DECLARE v_desc_anterior VARCHAR(50)  DEFAULT '';
    DECLARE v_desc_nuevo    VARCHAR(50)  DEFAULT '';

    -- Handler: captura errores y hace rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: Falló el cambio de estado. Se revirtieron los cambios.';
        INSERT INTO Logs_Errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'SQLEXCEPTION', 'sp_cambiar_estado_propiedad',
                CONCAT('Propiedad: ', p_propiedad_id,
                       ' | Nuevo estado solicitado: ', p_nuevo_estado));
    END;

    START TRANSACTION;

    -- Validación 1: la propiedad existe
    SELECT EstadoP_ID
    INTO   v_estado_actual
    FROM   Propiedad
    WHERE  Propiedad_ID = p_propiedad_id;

    IF v_estado_actual IS NULL THEN
        ROLLBACK;
        SET p_resultado = CONCAT('ERROR: La propiedad ', p_propiedad_id, ' no existe.');
        LEAVE proc_label;
    END IF;

    -- Validación 2: el nuevo estado existe en el catálogo
    IF NOT EXISTS (SELECT 1 FROM EstadoPropiedad WHERE EstadoP_ID = p_nuevo_estado) THEN
        ROLLBACK;
        SET p_resultado = CONCAT('ERROR: El estado ', p_nuevo_estado,
                                 ' no existe. Estados válidos: EP-01, EP-02, EP-03.');
        LEAVE proc_label;
    END IF;

    -- Validación 3: el estado nuevo es diferente al actual
    IF v_estado_actual = p_nuevo_estado THEN
        ROLLBACK;
        SET p_resultado = CONCAT('ADVERTENCIA: La propiedad ', p_propiedad_id,
                                 ' ya tiene el estado ', p_nuevo_estado, '. No se realizaron cambios.');
        LEAVE proc_label;
    END IF;

    -- Obtener descripciones para el mensaje de resultado
    SELECT Descripcion INTO v_desc_anterior
    FROM   EstadoPropiedad WHERE EstadoP_ID = v_estado_actual;

    SELECT Descripcion INTO v_desc_nuevo
    FROM   EstadoPropiedad WHERE EstadoP_ID = p_nuevo_estado;

    -- Ejecutar el UPDATE
    -- El trigger trg_cambio_estado_propiedad se dispara aquí automáticamente:
    --   → Registra en AuditoriaPropiedad
    --   → Registra en Logs_Cambios
    UPDATE Propiedad
    SET    EstadoP_ID = p_nuevo_estado
    WHERE  Propiedad_ID = p_propiedad_id;

    COMMIT;

    SET p_resultado = CONCAT(
        'OK: Estado de propiedad ', p_propiedad_id, ' actualizado.',
        ' | Anterior: ', v_desc_anterior,
        ' (', v_estado_actual, ')',
        ' → Nuevo: ', v_desc_nuevo,
        ' (', p_nuevo_estado, ')'
    );

END proc_label$$

DELIMITER ;

-- ============================================================
-- PRUEBA DEL PROCEDURE
-- ============================================================

SET @resultado = '';

-- Cambio válido: PROP-05 Disponible → Arrendada
CALL sp_cambiar_estado_propiedad('PROP-05', 'EP-02', @resultado);
SELECT @resultado AS resultado_cambio_valido;

-- Intento de cambio al mismo estado → advertencia
CALL sp_cambiar_estado_propiedad('PROP-05', 'EP-02', @resultado);
SELECT @resultado AS resultado_mismo_estado;

-- Propiedad inexistente → error
CALL sp_cambiar_estado_propiedad('PROP-99', 'EP-01', @resultado);
SELECT @resultado AS resultado_prop_inexistente;

-- Estado inexistente → error
CALL sp_cambiar_estado_propiedad('PROP-05', 'EP-99', @resultado);
SELECT @resultado AS resultado_estado_invalido;

-- Verificar estado actual de PROP-05
SELECT p.Propiedad_ID,
       p.Direccion,
       ep.Descripcion AS estado_actual
FROM   Propiedad       p
JOIN   EstadoPropiedad ep ON ep.EstadoP_ID = p.EstadoP_ID
WHERE  p.Propiedad_ID = 'PROP-05';

-- Verificar historial de auditoría de PROP-05
SELECT *
FROM   AuditoriaPropiedad
WHERE  Propiedad_ID = 'PROP-05'
ORDER BY Fecha_Hora DESC;