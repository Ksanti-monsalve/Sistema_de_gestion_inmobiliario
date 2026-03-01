-- ============================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Trigger 2 de 2: Registro de un nuevo contrato
--  Motor: MySQL 8.0+
--  Prerrequisito: modelo_fisico.sql
-- ============================================================

USE inmobiliaria_db;

DROP TRIGGER IF EXISTS trg_nuevo_contrato;

DELIMITER $$

CREATE TRIGGER trg_nuevo_contrato
AFTER INSERT ON Contratos
FOR EACH ROW
BEGIN

    -- Variable para el ID de auditoría
    -- Se genera con UNIX_TIMESTAMP+microsegundos para evitar
    -- el error 1064: MySQL no permite subquery SELECT sobre la
    -- misma tabla que recibe el INSERT dentro de un trigger
    DECLARE v_audit_id  VARCHAR(10);
    DECLARE v_usuario   VARCHAR(10);

    SET v_audit_id = CONCAT('ACO',
                        RIGHT(UNIX_TIMESTAMP(NOW(6)), 5));

    -- Obtener usuario activo del sistema
    SELECT Usuario_ID INTO v_usuario
    FROM   UsuarioSistema
    LIMIT  1;

    SET v_usuario = IFNULL(v_usuario, 'USR001');

    -- Registrar en AuditoriaContrato
    INSERT INTO AuditoriaContrato (
        AuditCon_ID,
        Contrato_ID,
        Evento,
        Fecha_Evento,
        Usuario_ID,
        Fecha_Hora
    )
    VALUES (
        v_audit_id,
        NEW.Contrato_ID,
        CONCAT('Nuevo contrato de ', NEW.Tipo_Contrato, ' registrado'),
        CURDATE(),
        v_usuario,
        NOW()
    );

    -- Actualizar estado de la propiedad automáticamente
    -- Arriendo → EP-02 (Arrendada) | Venta → EP-03 (Vendida)
    UPDATE Propiedad
    SET    EstadoP_ID = CASE NEW.Tipo_Contrato
                            WHEN 'Arriendo' THEN 'EP-02'
                            WHEN 'Venta'    THEN 'EP-03'
                        END
    WHERE  Propiedad_ID = NEW.Propiedad_ID;

    -- Registrar en Logs_Cambios
    INSERT INTO Logs_Cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'INSERT - Nuevo contrato',
        'Tabla: Contratos | Trigger: trg_nuevo_contrato',
        CONCAT(
            'Contrato: ',     NEW.Contrato_ID,
            ' | Tipo: ',      NEW.Tipo_Contrato,
            ' | Cliente: ',   NEW.Cliente_ID,
            ' | Agente: ',    NEW.Agente_ID,
            ' | Propiedad: ', NEW.Propiedad_ID,
            ' | Fecha: ',     NEW.Fecha_Contrato
        )
    );

END$$

DELIMITER ;

-- ============================================================
-- PRUEBA DEL TRIGGER
-- Usa variables dinámicas para evitar errores por datos previos
-- ============================================================

-- Paso 0: Ver el estado actual de propiedades y contratos
SELECT 'PROPIEDADES DISPONIBLES (EP-01)' AS info;
SELECT Propiedad_ID, Direccion FROM Propiedad WHERE EstadoP_ID = 'EP-01';

SELECT 'CONTRATOS EXISTENTES' AS info;
SELECT Contrato_ID FROM Contratos ORDER BY Contrato_ID;

-- Paso 1: Insertar con ID y propiedad dinámica usando bloque DO
-- Detecta automáticamente el siguiente ID libre y la primera
-- propiedad disponible → funciona sin importar ejecuciones previas
DROP PROCEDURE IF EXISTS _test_trg_nuevo_contrato;

DELIMITER $$
CREATE PROCEDURE _test_trg_nuevo_contrato()
BEGIN
    DECLARE v_nuevo_id    VARCHAR(10);
    DECLARE v_propiedad   VARCHAR(10);
    DECLARE v_max_num     INT;

    -- Generar siguiente Contrato_ID libre (CON-008, CON-009, etc.)
    SELECT IFNULL(MAX(CAST(SUBSTRING(Contrato_ID, 5) AS UNSIGNED)), 6) + 1
    INTO   v_max_num
    FROM   Contratos
    WHERE  Contrato_ID REGEXP '^CON-[0-9]+$';

    SET v_nuevo_id = CONCAT('CON-', LPAD(v_max_num, 3, '0'));

    -- Obtener la primera propiedad disponible (EP-01)
    SELECT Propiedad_ID INTO v_propiedad
    FROM   Propiedad
    WHERE  EstadoP_ID = 'EP-01'
    LIMIT  1;

    IF v_propiedad IS NULL THEN
        SELECT 'ERROR: No hay propiedades disponibles (EP-01) para la prueba.' AS resultado;
    ELSE
        SELECT CONCAT('Insertando contrato: ', v_nuevo_id,
                      ' | Propiedad: ', v_propiedad) AS info_prueba;

        INSERT INTO Contratos (
            Contrato_ID,  Fecha_Contrato, Tipo_Contrato,
            Cliente_ID,   Agente_ID,      Propiedad_ID
        )
        VALUES (
            v_nuevo_id,  CURDATE(),      'Arriendo',
            'CLI-01',    'AGE-01',        v_propiedad
        );

        -- Verificar AuditoriaContrato
        SELECT 'AUDITORIA CONTRATO GENERADA' AS info;
        SELECT * FROM AuditoriaContrato
        WHERE  Contrato_ID = v_nuevo_id
        ORDER BY Fecha_Hora DESC;

        -- Verificar estado de la propiedad → debe ser EP-02
        SELECT 'ESTADO PROPIEDAD TRAS TRIGGER' AS info;
        SELECT p.Propiedad_ID, ep.Descripcion AS nuevo_estado
        FROM   Propiedad       p
        JOIN   EstadoPropiedad ep ON ep.EstadoP_ID = p.EstadoP_ID
        WHERE  p.Propiedad_ID = v_propiedad;

        -- Verificar Logs_Cambios
        SELECT 'LOGS CAMBIOS RECIENTES' AS info;
        SELECT * FROM Logs_Cambios
        ORDER BY Fecha_Cambio DESC LIMIT 3;
    END IF;
END$$
DELIMITER ;

-- Ejecutar la prueba
CALL _test_trg_nuevo_contrato();

-- Limpiar el procedure de prueba
DROP PROCEDURE IF EXISTS _test_trg_nuevo_contrato;