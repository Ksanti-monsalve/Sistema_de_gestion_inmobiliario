

USE inmobiliaria_db;

DROP FUNCTION IF EXISTS fn_total_disponibles_por_tipo;

DELIMITER $$

CREATE FUNCTION fn_total_disponibles_por_tipo(p_tipo_id VARCHAR(10))
RETURNS INT
READS SQL DATA
COMMENT 'Retorna el total de propiedades disponibles para un tipo dado'
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
    INTO   v_total
    FROM   Propiedad
    WHERE  TipoP_ID   = p_tipo_id
      AND  EstadoP_ID = 'EP-01';

    RETURN v_total;
END$$

DELIMITER ;

-- ============================================================
-- PRUEBAS
-- ============================================================


SELECT fn_total_disponibles_por_tipo('TP-01') AS disponibles_apartamento;
SELECT fn_total_disponibles_por_tipo('TP-02') AS disponibles_casa;
SELECT fn_total_disponibles_por_tipo('TP-03') AS disponibles_local;


SELECT
    tp.TipoP_ID,
    tp.Descripcion                              AS tipo_propiedad,
    fn_total_disponibles_por_tipo(tp.TipoP_ID)  AS propiedades_disponibles
FROM   TipoPropiedad tp
ORDER BY tp.Descripcion;