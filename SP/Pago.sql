    -- ============================================================
    --  SISTEMA DE GESTIÓN INMOBILIARIA
    --  Stored Procedure 2: Registrar pago de arriendo
    --  Motor: MySQL 8.0+
    --  Prerrequisito: modelo_fisico.sql + funciones_udf_v2.sql
    -- ============================================================

    USE inmobiliaria_db;

    DROP PROCEDURE IF EXISTS sp_registrar_pago;

    DELIMITER $$

    CREATE PROCEDURE sp_registrar_pago(
        IN  p_pago_id      VARCHAR(10),   -- ej: 'PAG-010'
        IN  p_contrato_id  VARCHAR(10),   -- ej: 'CON-001'
        IN  p_fecha_pago   DATE,          -- ej: '2024-07-01'
        IN  p_monto        DECIMAL(12,2), -- ej: 800000.00
        OUT p_resultado    VARCHAR(200)   -- mensaje de resultado
    )
    proc_label: BEGIN

        DECLARE v_tipo         VARCHAR(10)   DEFAULT '';
        DECLARE v_valor_mens   DECIMAL(12,2) DEFAULT 0;
        DECLARE v_estado_pago  VARCHAR(10)   DEFAULT '';
        DECLARE v_deuda_previa DECIMAL(15,2) DEFAULT 0;

        -- Handler: captura errores y hace rollback
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET p_resultado = 'ERROR: Falló el registro del pago. Se revirtieron los cambios.';
            INSERT INTO Logs_Errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
            VALUES (NOW(), 'SQLEXCEPTION', 'sp_registrar_pago',
                    CONCAT('Pago: ', p_pago_id, ' | Contrato: ', p_contrato_id));
        END;

        START TRANSACTION;

        -- Validación 1: el contrato existe y es de tipo Arriendo
        SELECT Tipo_Contrato
        INTO   v_tipo
        FROM   Contratos
        WHERE  Contrato_ID = p_contrato_id;

        IF v_tipo IS NULL THEN
            ROLLBACK;
            SET p_resultado = CONCAT('ERROR: El contrato ', p_contrato_id, ' no existe.');
            LEAVE proc_label;
        END IF;

        IF v_tipo <> 'Arriendo' THEN
            ROLLBACK;
            SET p_resultado = CONCAT('ERROR: El contrato ', p_contrato_id,
                                    ' es de tipo Venta. Los pagos solo aplican a arriendos.');
            LEAVE proc_label;
        END IF;

        -- Validación 2: monto debe ser mayor a 0
        IF p_monto <= 0 THEN
            ROLLBACK;
            SET p_resultado = 'ERROR: El monto del pago debe ser mayor a $0.';
            LEAVE proc_label;
        END IF;

        -- Obtener valor mensual del contrato
        SELECT Valor_Mensual
        INTO   v_valor_mens
        FROM   ContratoArriendo
        WHERE  Contrato_ID = p_contrato_id;

        -- Determinar estado del pago según monto recibido
        SET v_estado_pago = CASE
            WHEN p_monto >= v_valor_mens THEN 'EPG-01'  -- Pagado completo
            ELSE                              'EPG-02'  -- Pendiente (pago parcial)
        END;

        -- Deuda previa para incluir en el log
        SET v_deuda_previa = fn_calcular_deuda_pendiente(p_contrato_id);

        -- Insertar el pago
        INSERT INTO Pagos (
            Pago_ID,      Contrato_ID,
            Fecha_Pago,   Monto_Pago,  EstadoPago_ID
        )
        VALUES (
            p_pago_id,    p_contrato_id,
            p_fecha_pago, p_monto,     v_estado_pago
        );

        -- Registrar en Logs_Cambios
        INSERT INTO Logs_Cambios (
            Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion
        )
        VALUES (
            NOW(),
            'INSERT - Nuevo pago',
            'Tabla: Pagos | SP: sp_registrar_pago',
            CONCAT(
                'Pago: ',          p_pago_id,
                ' | Contrato: ',   p_contrato_id,
                ' | Monto: $',     FORMAT(p_monto, 0),
                ' | Valor mens: $',FORMAT(v_valor_mens, 0),
                ' | Estado: ',     v_estado_pago,
                ' | Deuda previa: $', FORMAT(v_deuda_previa, 0)
            )
        );

        COMMIT;

        SET p_resultado = CONCAT(
            'OK: Pago ', p_pago_id, ' registrado.',
            ' | Contrato: ',  p_contrato_id,
            ' | Monto: $',    FORMAT(p_monto, 0),
            ' | Estado: ',    v_estado_pago,
            ' | Deuda pendiente actual: $',
                FORMAT(fn_calcular_deuda_pendiente(p_contrato_id), 0)
        );

    END proc_label$$

    DELIMITER ;

    -- ============================================================
    -- PRUEBA DEL PROCEDURE
    -- ============================================================

    SET @resultado = '';

    -- Pago completo para CON-001 (valor mensual $800,000)
    CALL sp_registrar_pago('PAG-010', 'CON-001', CURDATE(), 800000.00, @resultado);
    SELECT @resultado AS resultado_pago_completo;

    -- Pago parcial para CON-003 (valor mensual $1,200,000)
    CALL sp_registrar_pago('PAG-011', 'CON-003', CURDATE(), 600000.00, @resultado);
    SELECT @resultado AS resultado_pago_parcial;

    -- Intento en contrato de Venta → debe fallar
    CALL sp_registrar_pago('PAG-012', 'CON-002', CURDATE(), 500000.00, @resultado);
    SELECT @resultado AS resultado_contrato_venta;

    -- Verificar pagos registrados
    SELECT p.Pago_ID, p.Contrato_ID, p.Fecha_Pago,
        p.Monto_Pago, ep.Descripcion AS estado
    FROM   Pagos      p
    JOIN   EstadoPago ep ON ep.EstadoPago_ID = p.EstadoPago_ID
    WHERE  p.Pago_ID IN ('PAG-010', 'PAG-011');

    -- Verificar deuda después de pagos
    SELECT fn_calcular_deuda_pendiente('CON-001') AS deuda_CON001;
    SELECT fn_calcular_deuda_pendiente('CON-003') AS deuda_CON003;