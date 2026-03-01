
USE inmobiliaria_db;

-- ============================================================
-- ACTIVAR EL SCHEDULER
-- ============================================================

SET GLOBAL event_scheduler = ON;


DROP EVENT IF EXISTS evt_reporte_mensual_pagos_pendientes;

DELIMITER $$

CREATE EVENT evt_reporte_mensual_pagos_pendientes
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(NOW(), '%Y-%m-01 00:00:00'))
DO
BEGIN


    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO Logs_Errores (
            Fecha_Error,
            Nombre_Error,
            Lugar_Error,
            Detalle
        )
        VALUES (
            NOW(),
            'ERROR EN EVENTO: evt_reporte_mensual_pagos_pendientes',
            'Evento programado mensual',
            CONCAT('Error al generar reporte del periodo: ',
                   DATE_FORMAT(CURDATE(), '%Y-%m'))
        );
    END;

    -- ----------------------------------------------------------
    -- PASO 1: Eliminar registros del periodo actual
    -- ----------------------------------------------------------

    DELETE FROM ReportePagos
    WHERE Periodo = DATE_FORMAT(CURDATE(), '%Y-%m');

    -- ----------------------------------------------------------
    -- PASO 2: Insertar reporte de pagos pendientes / vencidos
    -- ----------------------------------------------------------
    
    INSERT INTO ReportePagos (
        Reporte_ID,
        Contrato_ID,
        Fecha_Reporte,
        Monto_Pendiente,
        Descripcion,
        Periodo
    )
    SELECT
        CONCAT('R',
               DATE_FORMAT(CURDATE(), '%y%m'),
               LPAD(ROW_NUMBER() OVER (ORDER BY c.Contrato_ID), 3, '0')),

        c.Contrato_ID,

        CURDATE(),

        fn_calcular_deuda_pendiente(c.Contrato_ID),

        CONCAT(
            'Reporte mensual automático | Contrato: ', c.Contrato_ID,
            ' | Pagos pendientes/vencidos: ', COUNT(p.Pago_ID),
            ' | Valor mensual: $', FORMAT(ca.Valor_Mensual, 0)
        ),

        DATE_FORMAT(CURDATE(), '%Y-%m')

    FROM       Contratos        c
    JOIN       ContratoArriendo ca ON ca.Contrato_ID  = c.Contrato_ID
    JOIN       Pagos             p ON  p.Contrato_ID  = c.Contrato_ID
    WHERE      c.Tipo_Contrato   = 'Arriendo'        
      AND      p.EstadoPago_ID  IN ('EPG-02', 'EPG-03') 
    GROUP BY   c.Contrato_ID, ca.Valor_Mensual
    HAVING     COUNT(p.Pago_ID) > 0;


    INSERT INTO Logs_Cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'EVENTO MENSUAL EJECUTADO',
        'Evento: evt_reporte_mensual_pagos_pendientes',
        CONCAT(
            'Reporte mensual generado para el periodo: ',
            DATE_FORMAT(CURDATE(), '%Y-%m'),
            ' | Registros insertados: ',
            (SELECT COUNT(*)
             FROM   ReportePagos
             WHERE  Periodo = DATE_FORMAT(CURDATE(), '%Y-%m'))
        )
    );

END$$

DELIMITER ;

-- ============================================================
-- VERIFICACIONES FINALES
-- ============================================================

SHOW EVENTS FROM inmobiliaria_db;

SHOW INDEX FROM Contratos;
SHOW INDEX FROM Pagos;
SHOW INDEX FROM Propiedad;
SHOW INDEX FROM ReportePagos;
SHOW INDEX FROM ContratoArriendo;

SELECT * FROM Logs_Cambios ORDER BY Fecha_Cambio DESC;
SELECT * FROM Logs_Errores ORDER BY Fecha_Error  DESC;

