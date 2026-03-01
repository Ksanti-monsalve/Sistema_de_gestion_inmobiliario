

USE inmobiliaria_db;

DROP VIEW IF EXISTS v_contratos_activos;

CREATE VIEW v_contratos_activos AS
SELECT
    c.Contrato_ID,
    c.Fecha_Contrato,
    c.Tipo_Contrato,
    -- Propiedad
    p.Propiedad_ID,
    p.Direccion                               AS Direccion_Propiedad,
    tp.Descripcion                            AS Tipo_Propiedad,
    b.Nombre_Barrio                           AS Barrio,
    ci.Nombre_Ciudad                          AS Ciudad,
    -- Cliente
    c.Cliente_ID,
    CONCAT(pcl.Nombre, ' ', pcl.Apellido)     AS Nombre_Cliente,
    pcl.Telefono                              AS Tel_Cliente,
    pcl.Email                                 AS Email_Cliente,
    -- Agente
    c.Agente_ID,
    CONCAT(pag.Nombre, ' ', pag.Apellido)     AS Nombre_Agente,
    pag.Email                                 AS Email_Agente,
    ag.Comision_Pct
FROM   Contratos       c
JOIN   Propiedad        p  ON  p.Propiedad_ID = c.Propiedad_ID
JOIN   TipoPropiedad   tp  ON tp.TipoP_ID     = p.TipoP_ID
JOIN   Barrio           b  ON  b.Barrio_ID    = p.Barrio_ID
JOIN   Ciudad          ci  ON ci.Ciudad_ID    = b.Ciudad_ID
JOIN   Clientes        cl  ON cl.Cliente_ID   = c.Cliente_ID
JOIN   Personas        pcl ON pcl.Persona_ID  = cl.Persona_ID
JOIN   Agentes         ag  ON ag.Agente_ID    = c.Agente_ID
JOIN   Personas        pag ON pag.Persona_ID  = ag.Persona_ID;

-- ============================================================
-- PRUEBAS
-- ============================================================

-- Todos los contratos activos
SELECT * FROM v_contratos_activos;

-- Solo arriendos
SELECT * FROM v_contratos_activos WHERE Tipo_Contrato = 'Arriendo';

-- Solo ventas
SELECT * FROM v_contratos_activos WHERE Tipo_Contrato = 'Venta';

-- Contratos de un agente específico
SELECT * FROM v_contratos_activos WHERE Agente_ID = 'AGE-01';