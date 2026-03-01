

DELIMITER $$

CREATE TRIGGER trg_after_update_estado_pago
AFTER UPDATE ON pagos
FOR EACH ROW
BEGIN
    -- Manejador de errores: si algo falla, registra en logs_errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (
            Fecha_Error,
            Nombre_Error,
            Lugar_Error,
            Detalle
        )
        VALUES (
            NOW(),
            'ERROR EN TRIGGER: trg_after_update_estado_pago',
            'Tabla: pagos | Trigger: AFTER UPDATE',
            CONCAT('Pago_ID: ', NEW.Pago_ID,
                   ' | Contrato_ID: ', NEW.Contrato_ID,
                   ' | Estado anterior: ', OLD.EstadoPago_ID,
                   ' | Estado nuevo: ', NEW.EstadoPago_ID)
        );
    END;

    -- Solo actúa si el estado del pago realmente cambió
    IF OLD.EstadoPago_ID <> NEW.EstadoPago_ID THEN

        -- Registrar en logs_cambios
        INSERT INTO logs_cambios (
            Fecha_Cambio,
            Nombre_Cambio,
            Lugar_Cambio,
            Descripcion
        )
        VALUES (
            NOW(),
            'CAMBIO ESTADO PAGO',
            'Tabla: pagos | Trigger: trg_after_update_estado_pago',
            CONCAT('Pago_ID: ', NEW.Pago_ID,
                   ' | Contrato_ID: ', NEW.Contrato_ID,
                   ' | Monto: $', NEW.Monto_Pago,
                   ' | Estado anterior: ', OLD.EstadoPago_ID,
                   ' | Estado nuevo: ', NEW.EstadoPago_ID,
                   ' | Usuario: ', COALESCE(@usuario_actual, 'SISTEMA'))
        );

    END IF;
END$$

DELIMITER ;

SET @usuario_actual = 'USR-01';
UPDATE pagos SET EstadoPago_ID = 'EPG-01' WHERE Pago_ID = 'PAG-003';
 SELECT * FROM logs_cambios ORDER BY Log_ID DESC LIMIT 1;