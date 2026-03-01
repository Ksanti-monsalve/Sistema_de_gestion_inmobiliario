

USE inmobiliaria_db;



DROP USER IF EXISTS 'admin_inm'@'localhost';
DROP USER IF EXISTS 'agente_inm'@'localhost';
DROP USER IF EXISTS 'contador_inm'@'localhost';
DROP USER IF EXISTS 'cliente_inm'@'localhost';

-- ============================================================
-- PARTE 2: CREACIÓN DE USUARIOS
-- ============================================================

-- ── ROL-01: Administrador ────────────────────────────────────
-- Acceso total al sistema
CREATE USER 'admin_inm'@'localhost'
    IDENTIFIED BY 'Admin@Inm2024!'
    COMMENT 'Administrador del sistema inmobiliario';

-- ── ROL-02: Agente Inmobiliario ──────────────────────────────
-- Gestión de propiedades, clientes y contratos
CREATE USER 'agente_inm'@'localhost'
    IDENTIFIED BY 'Agente@Inm2024!'
    COMMENT 'Agente inmobiliario - gestión de contratos y propiedades';

-- ── ROL-04: Contador ─────────────────────────────────────────
-- Acceso a pagos, reportes y vistas financieras
CREATE USER 'contador_inm'@'localhost'
    IDENTIFIED BY 'Conta@Inm2024!'
    COMMENT 'Contador - gestión de pagos y reportes financieros';

-- ── ROL-03: Cliente ──────────────────────────────────────────
-- Solo consulta de propiedades disponibles
CREATE USER 'cliente_inm'@'localhost'
    IDENTIFIED BY 'Cliente@Inm2024!'
    COMMENT 'Cliente - consulta de propiedades disponibles';


GRANT ALL PRIVILEGES
    ON inmobiliaria_db.*
    TO 'admin_inm'@'localhost'
    WITH GRANT OPTION;



-- Catálogos (solo lectura)
GRANT SELECT ON inmobiliaria_db.Ciudad          TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Barrio          TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.TipoPropiedad   TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.EstadoPropiedad TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.EstadoPago      TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Rol             TO 'agente_inm'@'localhost';

-- Personas y entidades relacionadas
GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.Personas        TO 'agente_inm'@'localhost';
GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.Clientes        TO 'agente_inm'@'localhost';
GRANT SELECT                 ON inmobiliaria_db.Agentes         TO 'agente_inm'@'localhost';

-- Propiedades
GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.Propiedad       TO 'agente_inm'@'localhost';

-- Contratos y subtipos
GRANT SELECT, INSERT         ON inmobiliaria_db.Contratos          TO 'agente_inm'@'localhost';
GRANT SELECT, INSERT         ON inmobiliaria_db.ContratoArriendo   TO 'agente_inm'@'localhost';
GRANT SELECT, INSERT         ON inmobiliaria_db.ContratoVenta      TO 'agente_inm'@'localhost';

-- Pagos
GRANT SELECT, INSERT         ON inmobiliaria_db.Pagos           TO 'agente_inm'@'localhost';

-- Auditoría (solo lectura — se escribe por triggers)
GRANT SELECT                 ON inmobiliaria_db.AuditoriaContrato  TO 'agente_inm'@'localhost';
GRANT SELECT                 ON inmobiliaria_db.AuditoriaPropiedad TO 'agente_inm'@'localhost';

-- Reportes (solo lectura)
GRANT SELECT                 ON inmobiliaria_db.ReportePagos    TO 'agente_inm'@'localhost';

-- Vistas
GRANT SELECT ON inmobiliaria_db.v_propiedades_disponibles      TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_contratos_activos            TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_contratos_arriendo_detalle   TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_contratos_venta_detalle      TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_disponibilidad_por_tipo      TO 'agente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_auditoria_completa           TO 'agente_inm'@'localhost';



-- Catálogos (solo lectura)
GRANT SELECT ON inmobiliaria_db.Ciudad          TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Barrio          TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.TipoPropiedad   TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.EstadoPropiedad TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.EstadoPago      TO 'contador_inm'@'localhost';

-- Personas y entidades (solo lectura)
GRANT SELECT ON inmobiliaria_db.Personas        TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Clientes        TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Agentes         TO 'contador_inm'@'localhost';

-- Propiedades (solo lectura)
GRANT SELECT ON inmobiliaria_db.Propiedad       TO 'contador_inm'@'localhost';

-- Contratos (solo lectura)
GRANT SELECT ON inmobiliaria_db.Contratos          TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.ContratoArriendo   TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.ContratoVenta      TO 'contador_inm'@'localhost';

-- Pagos (puede gestionar pagos)
GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.Pagos TO 'contador_inm'@'localhost';

-- Reportes (puede ver y generar)
GRANT SELECT, INSERT ON inmobiliaria_db.ReportePagos TO 'contador_inm'@'localhost';

-- Auditoría (solo lectura)
GRANT SELECT ON inmobiliaria_db.AuditoriaContrato  TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.AuditoriaPropiedad TO 'contador_inm'@'localhost';

-- Logs (solo lectura)
GRANT SELECT ON inmobiliaria_db.Logs_Errores  TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Logs_Cambios  TO 'contador_inm'@'localhost';

-- Vistas financieras
GRANT SELECT ON inmobiliaria_db.v_contratos_activos          TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_contratos_arriendo_detalle TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_contratos_venta_detalle    TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_pagos_por_contrato         TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_resumen_pagos_pendientes   TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_reporte_agentes            TO 'contador_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.v_disponibilidad_por_tipo    TO 'contador_inm'@'localhost';

-- ────────────────────────────────────────────────────────────
-- CLIENTE
-- ✔ Puede: consultar propiedades disponibles
-- ✘ No puede: ver contratos, pagos, ni datos de otros clientes
-- ────────────────────────────────────────────────────────────

-- Solo puede ver propiedades disponibles y catálogos básicos
GRANT SELECT ON inmobiliaria_db.v_propiedades_disponibles  TO 'cliente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.TipoPropiedad              TO 'cliente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Ciudad                     TO 'cliente_inm'@'localhost';
GRANT SELECT ON inmobiliaria_db.Barrio                     TO 'cliente_inm'@'localhost';

-- ============================================================
-- PARTE 4: APLICAR CAMBIOS
-- ============================================================

FLUSH PRIVILEGES;

-- ============================================================
-- PARTE 5: VERIFICACIÓN DE USUARIOS Y PRIVILEGIOS
-- ============================================================

-- Listar todos los usuarios creados
SELECT '== USUARIOS CREADOS ==' AS info;
SELECT User, Host, account_locked, password_expired
FROM   mysql.user
WHERE  User IN ('admin_inm','agente_inm','contador_inm','cliente_inm');

-- Verificar privilegios del administrador
SELECT '== PRIVILEGIOS ADMIN ==' AS info;
SHOW GRANTS FOR 'admin_inm'@'localhost';

-- Verificar privilegios del agente
SELECT '== PRIVILEGIOS AGENTE ==' AS info;
SHOW GRANTS FOR 'agente_inm'@'localhost';

-- Verificar privilegios del contador
SELECT '== PRIVILEGIOS CONTADOR ==' AS info;
SHOW GRANTS FOR 'contador_inm'@'localhost';

-- Verificar privilegios del cliente
SELECT '== PRIVILEGIOS CLIENTE ==' AS info;
SHOW GRANTS FOR 'cliente_inm'@'localhost';



SELECT '== MATRIZ DE ACCESOS ==' AS info;

SELECT * FROM (
    SELECT
        'Ciudad / Barrio / Catálogos' AS Tabla,
        'SELECT'                       AS Administrador,
        'SELECT'                       AS Agente,
        'SELECT'                       AS Contador,
        'SELECT'                       AS Cliente
    UNION ALL SELECT 'Personas',        'ALL','SELECT/INSERT/UPDATE','SELECT','—'
    UNION ALL SELECT 'Clientes',        'ALL','SELECT/INSERT/UPDATE','SELECT','—'
    UNION ALL SELECT 'Agentes',         'ALL','SELECT',             'SELECT','—'
    UNION ALL SELECT 'UsuarioSistema',  'ALL','—',                  '—',     '—'
    UNION ALL SELECT 'Propiedad',       'ALL','SELECT/INSERT/UPDATE','SELECT','—'
    UNION ALL SELECT 'Contratos',       'ALL','SELECT/INSERT',       'SELECT','—'
    UNION ALL SELECT 'ContratoArriendo','ALL','SELECT/INSERT',       'SELECT','—'
    UNION ALL SELECT 'ContratoVenta',   'ALL','SELECT/INSERT',       'SELECT','—'
    UNION ALL SELECT 'Pagos',           'ALL','SELECT/INSERT',  'SELECT/INSERT/UPDATE','—'
    UNION ALL SELECT 'ReportePagos',    'ALL','SELECT',         'SELECT/INSERT','—'
    UNION ALL SELECT 'AuditoriaContrato',  'ALL','SELECT','SELECT','—'
    UNION ALL SELECT 'AuditoriaPropiedad', 'ALL','SELECT','SELECT','—'
    UNION ALL SELECT 'Logs_Errores',    'ALL','—',              'SELECT','—'
    UNION ALL SELECT 'Logs_Cambios',    'ALL','—',              'SELECT','—'
    UNION ALL SELECT 'v_propiedades_disponibles','ALL','SELECT','—','SELECT'
    UNION ALL SELECT 'v_contratos_activos',      'ALL','SELECT','SELECT','—'
    UNION ALL SELECT 'v_pagos_por_contrato',      'ALL','—',    'SELECT','—'
    UNION ALL SELECT 'v_resumen_pagos_pendientes','ALL','—',    'SELECT','—'
    UNION ALL SELECT 'v_reporte_agentes',         'ALL','—',    'SELECT','—'
) AS matriz_accesos;

