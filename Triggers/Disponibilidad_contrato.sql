-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Stored Procedure 4: Registrar contrato de venta
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql + triggers + fn_calcular_comision
-- ============================================================

USE inmobiliaria_db;

DROP PROCEDURE IF EXISTS sp_registrar_contrato_venta;

DELIMITER $$

CREATE PROCEDURE sp_registrar_contrato_venta(
    IN  p_contrato_id   VARCHAR(10),    -- ej: 'CON-010'
    IN  p_fecha         DATE,           -- ej: '2024-08-01'
    IN  p_cliente_id    VARCHAR(10),    -- ej: 'CLI-03'
    IN  p_agente_id     VARCHAR(10),    -- ej: 'AGE-02'
    IN  p_propiedad_id  VARCHAR(10),    -- ej: 'PROP-05'
    IN  p_precio_venta  DECIMAL(15,2),  -- ej: 250000000.00
    IN  p_fecha_escrit  DATE,           -- ej: '2024-08-15' (puede ser NULL)
    OUT p_resultado     VARCHAR(200)    -- mensaje de resultado
)
proc_label: BEGIN

    DECLARE v_estado_prop   VARCHAR(10)    DEFAULT '';
    DECLARE v_comision_pct  DECIMAL(5,2)   DEFAULT 0;
    DECLARE v_comision_val  DECIMAL(15,2)  DEFAULT 0;
    DECLARE v_contrventa_id VARCHAR(10)    DEFAULT '';
    DECLARE v_count         INT            DEFAULT 0;

    -- Handler: captura cualquier error SQL y hace rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: Fallo en el registro de venta. Se revirtieron los cambios.';
        INSERT INTO Logs_Errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'SQLEXCEPTION', 'sp_registrar_contrato_venta',
                CONCAT('Contrato: ', p_contrato_id,
                       ' | Propiedad: ', p_propiedad_id,
                       ' | Precio: ',    p_precio_venta));
    END;

    START TRANSACTION;

    -- ── Validación 1: propiedad existe y está Disponible (EP-01) ──
    SELECT EstadoP_ID INTO v_estado_prop
    FROM   Propiedad
    WHERE  Propiedad_ID = p_propiedad_id;

    IF v_estado_prop IS NULL THEN
        ROLLBACK;
        SET p_resultado = CONCAT('ERROR: La propiedad ', p_propiedad_id, ' no existe.');
        LEAVE proc_label;
    END IF;

    IF v_estado_prop <> 'EP-01' THEN
        ROLLBACK;
        SET p_resultado = CONCAT('ERROR: Propiedad ', p_propiedad_id,
                                 ' no disponible para venta. Estado actual: ',
                                 v_estado_prop);
        LEAVE proc_label;
    END IF;

    -- ── Validación 2: cliente existe ─────────────────────────────
    SELECT COUNT(*) INTO v_count FROM Clientes WHERE Cliente_ID = p_cliente_id;
    IF v_count = 0 THEN
        ROLLBACK;
        SET p_resultado = CONCAT('ERROR: El cliente ', p_cliente_id, ' no existe.');
        LEAVE proc_label;
    END IF;

    -- ── Validación 3: agente existe ───────────────────────────────
    SELECT COUNT(*) INTO v_count FROM Agentes WHERE Agente_ID = p_agente_id;
    IF v_count = 0 THEN
        ROLLBACK;
        SET p_resultado = CONCAT('ERROR: El agente ', p_agente_id, ' no existe.');
        LEAVE proc_label;
    END IF;

    -- ── Validación 4: precio de venta mayor a 0 ───────────────────
    IF p_precio_venta <= 0 THEN
        ROLLBACK;
        SET p_resultado = 'ERROR: El precio de venta debe ser mayor a $0.';
        LEAVE proc_label;
    END IF;

    -- ── Paso 1: Obtener porcentaje de comisión del agente ─────────
    SELECT Comision_Pct INTO v_comision_pct
    FROM   Agentes
    WHERE  Agente_ID = p_agente_id;

    -- Calcular comisión: Precio_Venta × (Comision_Pct / 100)
    SET v_comision_val = ROUND(p_precio_venta * (v_comision_pct / 100), 2);

    -- ── Paso 2: INSERT en Contratos ───────────────────────────────
    -- El trigger trg_nuevo_contrato se dispara automáticamente:
    --   → Registra en AuditoriaContrato
    --   → Cambia estado propiedad a EP-03 (Vendida)
    --   → Registra en Logs_Cambios
    INSERT INTO Contratos (
        Contrato_ID,   Fecha_Contrato, Tipo_Contrato,
        Cliente_ID,    Agente_ID,      Propiedad_ID
    )
    VALUES (
        p_contrato_id, p_fecha,       'Venta',
        p_cliente_id,  p_agente_id,   p_propiedad_id
    );

    -- ── Paso 3: Generar ID único para ContratoVenta ───────────────
    SET v_contrventa_id = CONCAT('CV-', RIGHT(UNIX_TIMESTAMP(NOW(6)), 4));

    -- ── Paso 4: INSERT en ContratoVenta ──────────────────────────
    INSERT INTO ContratoVenta (
        ContrVenta_ID,   Contrato_ID,
        Precio_Venta,    Comision_Venta,  Fecha_Escritura
    )
    VALUES (
        v_contrventa_id, p_contrato_id,
        p_precio_venta,  v_comision_val,  p_fecha_escrit
    );

    -- ── Paso 5: Registrar el pago único de la comisión ───────────
    -- En una venta el pago corresponde al valor de la comisión
    -- del agente, registrado como pagado (EPG-01)
    INSERT INTO Pagos (
        Pago_ID,
        Contrato_ID,
        Fecha_Pago,
        Monto_Pago,
        EstadoPago_ID
    )
    VALUES (
        CONCAT('PAG', RIGHT(UNIX_TIMESTAMP(NOW(6)), 5)),
        p_contrato_id,
        IFNULL(p_fecha_escrit, p_fecha),
        v_comision_val,
        'EPG-01'    -- Pagado: la comisión se registra al cerrar la venta
    );

    COMMIT;

    SET p_resultado = CONCAT(
        'OK: Contrato de venta ', p_contrato_id, ' registrado.',
        ' | ContratoVenta: ',     v_contrventa_id,
        ' | Precio venta: $',     FORMAT(p_precio_venta, 0),
        ' | Comisión agente (',   v_comision_pct, '%): $',
                                  FORMAT(v_comision_val, 0),
        ' | Propiedad: ',         p_propiedad_id, ' → EP-03 (Vendida)'
    );

END proc_label$$

DELIMITER ;

-- ============================================================
-- PRUEBA: libera automáticamente una propiedad si no hay
--         ninguna disponible, luego ejecuta el SP de venta
-- ============================================================

DROP PROCEDURE IF EXISTS _test_sp_venta;

DELIMITER $$
CREATE PROCEDURE _test_sp_venta()
BEGIN
    DECLARE v_contrato_id  VARCHAR(10);
    DECLARE v_propiedad_id VARCHAR(10);
    DECLARE v_max_num      INT;
    DECLARE v_resultado    VARCHAR(200);

    -- Siguiente Contrato_ID libre
    SELECT IFNULL(MAX(CAST(SUBSTRING(Contrato_ID, 5) AS UNSIGNED)), 6) + 1
    INTO   v_max_num
    FROM   Contratos
    WHERE  Contrato_ID REGEXP '^CON-[0-9]+$';

    SET v_contrato_id = CONCAT('CON-', LPAD(v_max_num, 3, '0'));

    -- Buscar propiedad disponible (EP-01)
    SELECT Propiedad_ID INTO v_propiedad_id
    FROM   Propiedad
    WHERE  EstadoP_ID = 'EP-01'
    LIMIT  1;

    -- Si no hay ninguna disponible → liberar la primera propiedad
    IF v_propiedad_id IS NULL THEN
        SELECT Propiedad_ID INTO v_propiedad_id
        FROM   Propiedad
        LIMIT  1;

        UPDATE Propiedad
        SET    EstadoP_ID = 'EP-01'
        WHERE  Propiedad_ID = v_propiedad_id;

        SELECT CONCAT('INFO: No había disponibles. Se liberó ',
                      v_propiedad_id, ' → EP-01 para la prueba.') AS aviso;
    END IF;

    SELECT CONCAT('Probando → Contrato: ', v_contrato_id,
                  ' | Propiedad: ',        v_propiedad_id) AS info_prueba;

    CALL sp_registrar_contrato_venta(
        v_contrato_id,
        CURDATE(),
        'CLI-03',
        'AGE-02',
        v_propiedad_id,
        280000000.00,
        DATE_ADD(CURDATE(), INTERVAL 15 DAY),
        v_resultado
    );

    SELECT v_resultado AS resultado;

    SELECT 'CONTRATO' AS info;
    SELECT * FROM Contratos WHERE Contrato_ID = v_contrato_id;

    SELECT 'DETALLE VENTA' AS info;
    SELECT * FROM ContratoVenta WHERE Contrato_ID = v_contrato_id;

    SELECT 'PAGO COMISIÓN' AS info;
    SELECT p.Pago_ID, p.Monto_Pago, ep.Descripcion AS Estado
    FROM   Pagos      p
    JOIN   EstadoPago ep ON ep.EstadoPago_ID = p.EstadoPago_ID
    WHERE  p.Contrato_ID = v_contrato_id;

    SELECT 'ESTADO PROPIEDAD (debe ser EP-03 Vendida)' AS info;
    SELECT p.Propiedad_ID, ep.Descripcion AS Estado
    FROM   Propiedad       p
    JOIN   EstadoPropiedad ep ON ep.EstadoP_ID = p.EstadoP_ID
    WHERE  p.Propiedad_ID = v_propiedad_id;

    SELECT 'AUDITORIA CONTRATO' AS info;
    SELECT * FROM AuditoriaContrato WHERE Contrato_ID = v_contrato_id;

    SELECT 'COMISIÓN CALCULADA CON UDF' AS info;
    SELECT fn_calcular_comision(v_contrato_id) AS comision_udf;

END$$
DELIMITER ;

CALL _test_sp_venta();
DROP PROCEDURE IF EXISTS _test_sp_venta;