
USE inmobiliaria_db;

DROP FUNCTION IF EXISTS fn_calcular_deuda_pendiente;

DELIMITER $$

CREATE FUNCTION fn_calcular_deuda_pendiente(p_contrato_id VARCHAR(10))
RETURNS DECIMAL(15,2)
READS SQL DATA
COMMENT 'Calcula la deuda total pendiente de un contrato de arriendo'
BEGIN
    DECLARE v_valor_mensual DECIMAL(12,2) DEFAULT 0;
    DECLARE v_meses_deuda   INT           DEFAULT 0;
    DECLARE v_tipo          VARCHAR(10)   DEFAULT '';


    SELECT Tipo_Contrato
    INTO   v_tipo
    FROM   Contratos
    WHERE  Contrato_ID = p_contrato_id;


    IF v_tipo <> 'Arriendo' OR v_tipo IS NULL THEN
        RETURN 0.00;
    END IF;


    SELECT ca.Valor_Mensual
    INTO   v_valor_mensual
    FROM   ContratoArriendo ca
    WHERE  ca.Contrato_ID = p_contrato_id;


    SELECT COUNT(*)
    INTO   v_meses_deuda
    FROM   Pagos p
    WHERE  p.Contrato_ID   = p_contrato_id
      AND  p.EstadoPago_ID IN ('EPG-02', 'EPG-03');

    RETURN IFNULL(v_meses_deuda * v_valor_mensual, 0.00);
END$$

DELIMITER ;

-- ============================================================
-- PRUEBAS
-- ============================================================

SELECT fn_calcular_deuda_pendiente('CON-001') AS deuda_CON001;
SELECT fn_calcular_deuda_pendiente('CON-003') AS deuda_CON003;
SELECT fn_calcular_deuda_pendiente('CON-005') AS deuda_CON005;
SELECT fn_calcular_deuda_pendiente('CON-002') AS deuda_CON002_venta;

-- Consulta completa de arriendos con deuda pendiente
SELECT
    c.Contrato_ID,
    CONCAT(per.Nombre, ' ', per.Apellido)      AS cliente,
    pr.Direccion                               AS propiedad,
    ca.Valor_Mensual,
    ca.Fecha_Inicio,
    ca.Fecha_Fin,
    fn_calcular_deuda_pendiente(c.Contrato_ID) AS deuda_pendiente
FROM   Contratos        c
JOIN   ContratoArriendo ca  ON ca.Contrato_ID  = c.Contrato_ID
JOIN   Clientes         cl  ON cl.Cliente_ID   = c.Cliente_ID
JOIN   Personas         per ON per.Persona_ID  = cl.Persona_ID
JOIN   Propiedad        pr  ON pr.Propiedad_ID = c.Propiedad_ID
WHERE  c.Tipo_Contrato = 'Arriendo'
HAVING deuda_pendiente > 0
ORDER BY deuda_pendiente DESC;