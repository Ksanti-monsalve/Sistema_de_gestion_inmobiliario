

USE inmobiliaria_db;

DROP FUNCTION IF EXISTS fn_calcular_comision;

DELIMITER $$

CREATE FUNCTION fn_calcular_comision(p_contrato_id VARCHAR(10))
RETURNS DECIMAL(15,2)
READS SQL DATA
COMMENT 'Calcula la comisión del agente para un contrato de venta'
BEGIN
    DECLARE v_precio_venta   DECIMAL(15,2) DEFAULT 0;
    DECLARE v_comision_pct   DECIMAL(5,2)  DEFAULT 0;
    DECLARE v_tipo           VARCHAR(10)   DEFAULT '';

    -- Verificar que el contrato existe y es tipo Venta
    SELECT Tipo_Contrato
    INTO   v_tipo
    FROM   Contratos
    WHERE  Contrato_ID = p_contrato_id;

    -- Si no existe o no es Venta retorna 0
    IF v_tipo <> 'Venta' OR v_tipo IS NULL THEN
        RETURN 0.00;
    END IF;

    -- Obtener precio de venta y porcentaje de comisión del agente
    SELECT cv.Precio_Venta,
           a.Comision_Pct
    INTO   v_precio_venta,
           v_comision_pct
    FROM   Contratos      c
    JOIN   ContratoVenta  cv ON cv.Contrato_ID = c.Contrato_ID
    JOIN   Agentes         a ON  a.Agente_ID   = c.Agente_ID
    WHERE  c.Contrato_ID = p_contrato_id;

    RETURN IFNULL(ROUND(v_precio_venta * (v_comision_pct / 100), 2), 0.00);
END$$

DELIMITER ;



SELECT fn_calcular_comision('CON-002') AS comision_CON002;
SELECT fn_calcular_comision('CON-004') AS comision_CON004;
SELECT fn_calcular_comision('CON-006') AS comision_CON006;
SELECT fn_calcular_comision('CON-001') AS comision_CON001_arriendo;

-- Consulta completa de todas las ventas con su comisión
SELECT
    c.Contrato_ID,
    c.Fecha_Contrato,
    CONCAT(per.Nombre, ' ', per.Apellido) AS agente,
    a.Comision_Pct                        AS porcentaje_comision,
    cv.Precio_Venta,
    fn_calcular_comision(c.Contrato_ID)   AS comision_calculada
FROM   Contratos     c
JOIN   ContratoVenta cv  ON cv.Contrato_ID = c.Contrato_ID
JOIN   Agentes        a  ON  a.Agente_ID   = c.Agente_ID
JOIN   Personas      per ON per.Persona_ID = a.Persona_ID
WHERE  c.Tipo_Contrato = 'Venta'
ORDER BY c.Contrato_ID;