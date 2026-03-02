-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Stored Procedure 1: Registrar contrato de arriendo
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql + triggers
-- ============================================================

USE inmobiliaria_db;

DROP PROCEDURE IF EXISTS sp_registrar_contrato_arriendo;

DELIMITER $$

CREATE PROCEDURE sp_registrar_contrato_arriendo(
    IN  p_contrato_id  VARCHAR(10),    -- ej: 'CON-008'
    IN  p_fecha        DATE,           -- ej: '2024-07-01'
    IN  p_cliente_id   VARCHAR(10),    -- ej: 'CLI-01'
    IN  p_agente_id    VARCHAR(10),    -- ej: 'AGE-01'
    IN  p_propiedad_id VARCHAR(10),    -- ej: 'PROP-05'
    IN  p_valor_mens   DECIMAL(12,2),  -- ej: 1500000.00
    IN  p_fecha_inicio DATE,           -- ej: '2024-07-01'
    IN  p_fecha_fin    DATE,           -- ej: '2025-07-01'
    OUT p_resultado    VARCHAR(200)    -- mensaje de resultado
)
-- ┌─────────────────────────────────────────────────────────┐
-- │  CORRECCIÓN Error 1308: LEAVE necesita etiqueta         │
-- │  Se agrega proc_label al BEGIN y END del procedure      │
-- └─────────────────────────────────────────────────────────┘
proc_label: BEGIN

    DECLARE v_estado_prop  VARCHAR(10) DEFAULT '';
    DECLARE v_contrarr_id  VARCHAR(10) DEFAULT '';
    DECLARE v_pago_id      VARCHAR(10) DEFAULT '';
    DECLARE v_count        INT         DEFAULT 0;

    -- Handler: captura cualquier error SQL y hace rollback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'ERROR: Fallo en el registro. Se revirtieron los cambios.';
        INSERT INTO Logs_Errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'SQLEXCEPTION', 'sp_registrar_contrato_arriendo',
                CONCAT('Contrato: ', p_contrato_id,
                       ' | Propiedad: ', p_propiedad_id));
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
                                 ' no disponible. Estado actual: ', v_estado_prop);
        LEAVE proc_label;
    END IF;

    -- ── Validación 2: cliente existe ──────────────────────────────
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

    -- ── Validación 4: valor mensual mayor a 0 ────────────────────
    IF p_valor_mens <= 0 THEN
        ROLLBACK;
        SET p_resultado = 'ERROR: El valor mensual debe ser mayor a $0.';
        LEAVE proc_label;
    END IF;

    -- ── Paso 1: INSERT en Contratos ───────────────────────────────
    -- El trigger trg_nuevo_contrato se dispara automáticamente:
    --   → Registra en AuditoriaContrato
    --   → Cambia estado propiedad a EP-02 (Arrendada)
    --   → Registra en Logs_Cambios
    INSERT INTO Contratos (
        Contrato_ID,   Fecha_Contrato, Tipo_Contrato,
        Cliente_ID,    Agente_ID,      Propiedad_ID
    )
    VALUES (
        p_contrato_id, p_fecha,       'Arriendo',
        p_cliente_id,  p_agente_id,   p_propiedad_id
    );

    -- ── Paso 2: Generar ID único para ContratoArriendo ────────────
    -- UNIX_TIMESTAMP(NOW(6)) evita subquery sobre la tabla destino
    SET v_contrarr_id = CONCAT('CA-', RIGHT(UNIX_TIMESTAMP(NOW(6)), 4));

    -- ── Paso 3: INSERT en ContratoArriendo ───────────────────────
    INSERT INTO ContratoArriendo (
        ContrArr_ID,   Contrato_ID,
        Valor_Mensual, Fecha_Inicio, Fecha_Fin
    )
    VALUES (
        v_contrarr_id, p_contrato_id,
        p_valor_mens,  p_fecha_inicio, p_fecha_fin
    );

    -- ── Paso 4: Crear primer pago como Pendiente (EPG-02) ─────────
    SET v_pago_id = CONCAT('PAG', RIGHT(UNIX_TIMESTAMP(NOW(6)), 5));

    INSERT INTO Pagos (
        Pago_ID,      Contrato_ID,   Fecha_Pago,
        Monto_Pago,   EstadoPago_ID
    )
    VALUES (
        v_pago_id,    p_contrato_id, p_fecha_inicio,
        p_valor_mens, 'EPG-02'
    );

    COMMIT;

    SET p_resultado = CONCAT(
        'OK: Contrato ', p_contrato_id, ' registrado.',
        ' | ContratoArriendo: ', v_contrarr_id,
        ' | Valor mensual: $',   FORMAT(p_valor_mens, 0),
        ' | Vigencia: ',         p_fecha_inicio, ' al ', p_fecha_fin
    );

END proc_label$$

DELIMITER ;



DROP PROCEDURE IF EXISTS _test_sp_arriendo;

DELIMITER $$
CREATE PROCEDURE _test_sp_arriendo()
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

    -- Primera propiedad disponible (EP-01)
    SELECT Propiedad_ID INTO v_propiedad_id
    FROM   Propiedad
    WHERE  EstadoP_ID = 'EP-01'
    LIMIT  1;

    IF v_propiedad_id IS NULL THEN
        SELECT 'ERROR: No hay propiedades disponibles para la prueba.' AS resultado;
    ELSE
        SELECT CONCAT('Probando → Contrato: ', v_contrato_id,
                      ' | Propiedad: ',        v_propiedad_id) AS info_prueba;

        CALL sp_registrar_contrato_arriendo(
            v_contrato_id, CURDATE(),
            'CLI-01', 'AGE-01', v_propiedad_id,
            950000.00, CURDATE(),
            DATE_ADD(CURDATE(), INTERVAL 1 YEAR),
            v_resultado
        );

        SELECT v_resultado AS resultado;

        SELECT 'CONTRATO' AS info;
        SELECT * FROM Contratos WHERE Contrato_ID = v_contrato_id;

        SELECT 'DETALLE ARRIENDO' AS info;
        SELECT * FROM ContratoArriendo WHERE Contrato_ID = v_contrato_id;

        SELECT 'PRIMER PAGO' AS info;
        SELECT * FROM Pagos WHERE Contrato_ID = v_contrato_id;

        SELECT 'AUDITORIA' AS info;
        SELECT * FROM AuditoriaContrato WHERE Contrato_ID = v_contrato_id;
    END IF;
END$$
DELIMITER ;

CALL _test_sp_arriendo();
DROP PROCEDURE IF EXISTS _test_sp_arriendo;