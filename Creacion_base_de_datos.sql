
    DROP DATABASE IF EXISTS inmobiliaria_db;
    CREATE DATABASE inmobiliaria_db
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_spanish_ci;

    USE inmobiliaria_db;


    CREATE TABLE logs_errores (
        Log_ID        INT           NOT NULL AUTO_INCREMENT,
        Fecha_Error   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
        Nombre_Error  VARCHAR(150)  NOT NULL,
        Lugar_Error   VARCHAR(200)      NULL,
        Detalle       TEXT              NULL,
        CONSTRAINT pk_logs_errores PRIMARY KEY (Log_ID)
    ) ENGINE=InnoDB COMMENT='Registro de errores del sistema';

    -- ------------------------------------------------------------
    CREATE TABLE logs_cambios (
        Log_ID          INT           NOT NULL AUTO_INCREMENT,
        Fecha_Cambio    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
        Nombre_Cambio   VARCHAR(150)  NOT NULL,
        Lugar_Cambio    VARCHAR(200)      NULL,
        Descripcion     TEXT              NULL,
        CONSTRAINT pk_logs_cambios PRIMARY KEY (Log_ID)
    ) ENGINE=InnoDB COMMENT='Registro de cambios realizados en el sistema';

    -- ------------------------------------------------------------
    CREATE TABLE rol (
        Rol_ID      VARCHAR(10)   NOT NULL,
        Nombre_Rol  VARCHAR(50)   NOT NULL,
        Descripcion VARCHAR(200)      NULL,
        CONSTRAINT pk_rol PRIMARY KEY (Rol_ID)
    ) ENGINE=InnoDB COMMENT='Roles del sistema: admin, agente, contador';

    -- ------------------------------------------------------------
    CREATE TABLE ciudad (
        Ciudad_ID      VARCHAR(10)   NOT NULL,
        Nombre_Ciudad  VARCHAR(100)  NOT NULL,
        Departamento   VARCHAR(100)      NULL,
        CONSTRAINT pk_ciudad PRIMARY KEY (Ciudad_ID)
    ) ENGINE=InnoDB COMMENT='Catálogo de ciudades';

    -- ------------------------------------------------------------
    CREATE TABLE tipopropiedad (
        TipoP_ID    VARCHAR(10)  NOT NULL,
        Descripcion VARCHAR(50)  NOT NULL,
        CONSTRAINT pk_tipopropiedad PRIMARY KEY (TipoP_ID)
    ) ENGINE=InnoDB COMMENT='Tipos de propiedad: Casa, Apto, Local, etc.';

    -- ------------------------------------------------------------
    CREATE TABLE estadopropiedad (
        EstadoP_ID  VARCHAR(10)  NOT NULL,
        Descripcion VARCHAR(50)  NOT NULL,
        CONSTRAINT pk_estadopropiedad PRIMARY KEY (EstadoP_ID)
    ) ENGINE=InnoDB COMMENT='Estados de propiedad: disponible, arrendada, vendida';

    -- ------------------------------------------------------------
    CREATE TABLE estadopago (
        EstadoPago_ID VARCHAR(10)  NOT NULL,
        Descripcion   VARCHAR(50)  NOT NULL,
        CONSTRAINT pk_estadopago PRIMARY KEY (EstadoPago_ID)
    ) ENGINE=InnoDB COMMENT='Estados de pago: pagado, pendiente, parcial';

    -- ============================================================
    -- 2. TABLAS CON DEPENDENCIAS DE PRIMER NIVEL
    -- ============================================================

    CREATE TABLE barrio (
        Barrio_ID      VARCHAR(10)   NOT NULL,
        Nombre_Barrio  VARCHAR(100)  NOT NULL,
        Ciudad_ID      VARCHAR(10)   NOT NULL,
        CONSTRAINT pk_barrio         PRIMARY KEY (Barrio_ID),
        CONSTRAINT fk_barrio_ciudad  FOREIGN KEY (Ciudad_ID) REFERENCES ciudad(Ciudad_ID)
    ) ENGINE=InnoDB COMMENT='Barrios asociados a una ciudad';

    -- ------------------------------------------------------------
    CREATE TABLE personas (
        Persona_ID VARCHAR(10)   NOT NULL,
        Nombre     VARCHAR(80)   NOT NULL,
        Apellido   VARCHAR(80)   NOT NULL,
        Telefono   VARCHAR(20)       NULL,
        Email      VARCHAR(120)      NULL,
        CONSTRAINT pk_personas PRIMARY KEY (Persona_ID)
    ) ENGINE=InnoDB COMMENT='Datos base de cualquier persona (cliente, agente, usuario)';

    -- ------------------------------------------------------------
    CREATE TABLE propiedad (
        Propiedad_ID     VARCHAR(10)    NOT NULL,
        Direccion        VARCHAR(150)   NOT NULL,
        Precio_Propiedad DECIMAL(15,2)  NOT NULL,
        TipoP_ID         VARCHAR(10)    NOT NULL,
        EstadoP_ID       VARCHAR(10)    NOT NULL,
        Barrio_ID        VARCHAR(10)    NOT NULL,
        CONSTRAINT pk_propiedad            PRIMARY KEY (Propiedad_ID),
        CONSTRAINT fk_propiedad_tipo       FOREIGN KEY (TipoP_ID)   REFERENCES tipopropiedad(TipoP_ID),
        CONSTRAINT fk_propiedad_estado     FOREIGN KEY (EstadoP_ID) REFERENCES estadopropiedad(EstadoP_ID),
        CONSTRAINT fk_propiedad_barrio     FOREIGN KEY (Barrio_ID)  REFERENCES barrio(Barrio_ID)
    ) ENGINE=InnoDB COMMENT='Inventario de propiedades inmobiliarias';

    -- ============================================================
    -- 3. TABLAS CON DEPENDENCIAS DE SEGUNDO NIVEL
    -- ============================================================

    CREATE TABLE clientes (
        Cliente_ID VARCHAR(10)  NOT NULL,
        Persona_ID VARCHAR(10)  NOT NULL,
        CONSTRAINT pk_clientes         PRIMARY KEY (Cliente_ID),
        CONSTRAINT fk_clientes_persona FOREIGN KEY (Persona_ID) REFERENCES personas(Persona_ID)
    ) ENGINE=InnoDB COMMENT='Clientes interesados en arrendar o comprar';

    -- ------------------------------------------------------------
    CREATE TABLE agentes (
        Agente_ID       VARCHAR(10)    NOT NULL,
        Persona_ID      VARCHAR(10)    NOT NULL,
        Precio_Venta    DECIMAL(15,2)      NULL,
        Comision_Pct    DECIMAL(5,2)   NOT NULL DEFAULT 3.00,
        CONSTRAINT pk_agentes         PRIMARY KEY (Agente_ID),
        CONSTRAINT fk_agentes_persona FOREIGN KEY (Persona_ID) REFERENCES personas(Persona_ID)
    ) ENGINE=InnoDB COMMENT='Agentes inmobiliarios con comisión asignada';

    -- ------------------------------------------------------------
    CREATE TABLE usuariosistema (
        Usuario_ID    VARCHAR(10)  NOT NULL,
        Persona_ID    VARCHAR(10)  NOT NULL,
        Rol_ID        VARCHAR(10)  NOT NULL,
        NombreUsuario VARCHAR(60)  NOT NULL,
        CONSTRAINT pk_usuariosistema         PRIMARY KEY (Usuario_ID),
        CONSTRAINT fk_usuario_persona        FOREIGN KEY (Persona_ID) REFERENCES personas(Persona_ID),
        CONSTRAINT fk_usuario_rol            FOREIGN KEY (Rol_ID)     REFERENCES rol(Rol_ID),
        CONSTRAINT uq_usuario_nombre         UNIQUE (NombreUsuario)
    ) ENGINE=InnoDB COMMENT='Usuarios del sistema con rol asignado';

    -- ============================================================
    -- 4. CONTRATOS Y SUBTABLAS
    -- ============================================================

    CREATE TABLE contratos (
        Contrato_ID   VARCHAR(10)                         NOT NULL,
        Fecha_Contrato DATE                               NOT NULL,
        Tipo_Contrato  ENUM('arriendo','venta')           NOT NULL,
        Cliente_ID     VARCHAR(10)                        NOT NULL,
        Agente_ID      VARCHAR(10)                        NOT NULL,
        Propiedad_ID   VARCHAR(10)                        NOT NULL,
        CONSTRAINT pk_contratos            PRIMARY KEY (Contrato_ID),
        CONSTRAINT fk_contratos_cliente    FOREIGN KEY (Cliente_ID)   REFERENCES clientes(Cliente_ID),
        CONSTRAINT fk_contratos_agente     FOREIGN KEY (Agente_ID)    REFERENCES agentes(Agente_ID),
        CONSTRAINT fk_contratos_propiedad  FOREIGN KEY (Propiedad_ID) REFERENCES propiedad(Propiedad_ID)
    ) ENGINE=InnoDB COMMENT='Contratos generales (arriendo o venta)';

    -- ------------------------------------------------------------
    CREATE TABLE contratoarriendo (
        ContrArr_ID    VARCHAR(10)    NOT NULL,
        Contrato_ID    VARCHAR(10)    NOT NULL,
        Valor_Mensual  DECIMAL(12,2)  NOT NULL,
        Fecha_Inicio   DATE           NOT NULL,
        Fecha_Fin      DATE               NULL,
        CONSTRAINT pk_contratoarriendo         PRIMARY KEY (ContrArr_ID),
        CONSTRAINT fk_contrarriendo_contrato   FOREIGN KEY (Contrato_ID) REFERENCES contratos(Contrato_ID)
    ) ENGINE=InnoDB COMMENT='Detalle específico de contratos de arriendo';

    -- ------------------------------------------------------------
    CREATE TABLE contratoventa (
        ContrVenta_ID   VARCHAR(10)    NOT NULL,
        Contrato_ID     VARCHAR(10)    NOT NULL,
        Precio_Venta    DECIMAL(15,2)  NOT NULL,
        Comision_Venta  DECIMAL(15,2)      NULL,
        Fecha_Escritura DATE               NULL,
        CONSTRAINT pk_contratoventa          PRIMARY KEY (ContrVenta_ID),
        CONSTRAINT fk_contratoventa_contrato FOREIGN KEY (Contrato_ID) REFERENCES contratos(Contrato_ID)
    ) ENGINE=InnoDB COMMENT='Detalle específico de contratos de venta';

    -- ============================================================
    -- 5. PAGOS Y REPORTES
    -- ============================================================

    CREATE TABLE pagos (
        Pago_ID        VARCHAR(10)    NOT NULL,
        Contrato_ID    VARCHAR(10)    NOT NULL,
        Fecha_Pago     DATE           NOT NULL,
        Monto_Pago     DECIMAL(12,2)  NOT NULL,
        EstadoPago_ID  VARCHAR(10)    NOT NULL,
        CONSTRAINT pk_pagos              PRIMARY KEY (Pago_ID),
        CONSTRAINT fk_pagos_contrato     FOREIGN KEY (Contrato_ID)   REFERENCES contratos(Contrato_ID),
        CONSTRAINT fk_pagos_estadopago   FOREIGN KEY (EstadoPago_ID) REFERENCES estadopago(EstadoPago_ID)
    ) ENGINE=InnoDB COMMENT='Pagos registrados por contrato';

    -- ------------------------------------------------------------
    CREATE TABLE reportepagos (
        Reporte_ID       VARCHAR(10)    NOT NULL,
        Contrato_ID      VARCHAR(10)    NOT NULL,
        Fecha_Reporte    DATE           NOT NULL DEFAULT (CURRENT_DATE),
        Monto_Pendiente  DECIMAL(12,2)  NOT NULL DEFAULT 0.00,
        Descripcion      VARCHAR(200)       NULL,
        Periodo          VARCHAR(7)         NULL COMMENT 'Formato YYYY-MM',
        CONSTRAINT pk_reportepagos          PRIMARY KEY (Reporte_ID),
        CONSTRAINT fk_reportepagos_contrato FOREIGN KEY (Contrato_ID) REFERENCES contratos(Contrato_ID)
    ) ENGINE=InnoDB COMMENT='Reporte mensual de pagos pendientes';

    -- ============================================================
    -- 6. TABLAS DE AUDITORÍA
    -- ============================================================

    CREATE TABLE auditoriacontrato (
        AuditCon_ID  VARCHAR(10)   NOT NULL,
        Contrato_ID  VARCHAR(10)   NOT NULL,
        Evento       VARCHAR(100)  NOT NULL,
        Fecha_Evento DATE          NOT NULL,
        Usuario_ID   VARCHAR(10)   NOT NULL,
        Fecha_Hora   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT pk_auditoriacontrato         PRIMARY KEY (AuditCon_ID),
        CONSTRAINT fk_auditcontrato_contrato    FOREIGN KEY (Contrato_ID) REFERENCES contratos(Contrato_ID),
        CONSTRAINT fk_auditcontrato_usuario     FOREIGN KEY (Usuario_ID)  REFERENCES usuariosistema(Usuario_ID)
    ) ENGINE=InnoDB COMMENT='Auditoría de eventos sobre contratos';

    -- ------------------------------------------------------------
    CREATE TABLE auditoriapropiedad (
        Audit_ID        VARCHAR(10)  NOT NULL,
        Propiedad_ID    VARCHAR(10)  NOT NULL,
        Estado_Anterior VARCHAR(50)  NOT NULL,
        Estado_Nuevo    VARCHAR(50)  NOT NULL,
        Fecha_Cambio    DATE         NOT NULL,
        Usuario_ID      VARCHAR(10)  NOT NULL,
        Fecha_Hora      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT pk_auditoriapropiedad        PRIMARY KEY (Audit_ID),
        CONSTRAINT fk_auditprop_propiedad       FOREIGN KEY (Propiedad_ID) REFERENCES propiedad(Propiedad_ID),
        CONSTRAINT fk_auditprop_usuario         FOREIGN KEY (Usuario_ID)   REFERENCES usuariosistema(Usuario_ID)
    ) ENGINE=InnoDB COMMENT='Auditoría de cambios de estado en propiedades';

    -- ============================================================
    -- 7. ÍNDICES DE OPTIMIZACIÓN
    -- ============================================================

    CREATE INDEX idx_propiedad_estado    ON propiedad(EstadoP_ID);
    CREATE INDEX idx_propiedad_tipo      ON propiedad(TipoP_ID);
    CREATE INDEX idx_propiedad_barrio    ON propiedad(Barrio_ID);
    CREATE INDEX idx_barrio_ciudad       ON barrio(Ciudad_ID);
    CREATE INDEX idx_contratos_cliente   ON contratos(Cliente_ID);
    CREATE INDEX idx_contratos_agente    ON contratos(Agente_ID);
    CREATE INDEX idx_contratos_propiedad ON contratos(Propiedad_ID);
    CREATE INDEX idx_contratos_tipo      ON contratos(Tipo_Contrato);
    CREATE INDEX idx_pagos_estado        ON pagos(EstadoPago_ID);
    CREATE INDEX idx_pagos_fecha         ON pagos(Fecha_Pago);
    CREATE INDEX idx_pagos_contrato      ON pagos(Contrato_ID);
    CREATE INDEX idx_reporte_periodo     ON reportepagos(Periodo);
    CREATE INDEX idx_usuario_rol         ON usuariosistema(Rol_ID);
    CREATE INDEX idx_auditprop_fecha     ON auditoriapropiedad(Fecha_Cambio);
    CREATE INDEX idx_auditcont_fecha     ON auditoriacontrato(Fecha_Evento);

    -- ============================================================
    -- 8. DATOS DE PRUEBA
    -- ============================================================

    -- ── Estados de propiedad ─────────────────────────────────────
    INSERT INTO estadopropiedad (EstadoP_ID, Descripcion) VALUES
        ('EP001', 'Disponible'),
        ('EP002', 'Arrendada'),
        ('EP003', 'Vendida'),
        ('EP004', 'En Mantenimiento');

    -- ── Estados de pago ──────────────────────────────────────────
    INSERT INTO estadopago (EstadoPago_ID, Descripcion) VALUES
        ('EPG001', 'Pagado'),
        ('EPG002', 'Pendiente'),
        ('EPG003', 'Parcial'),
        ('EPG004', 'Vencido');

    -- ── Tipos de propiedad ───────────────────────────────────────
    INSERT INTO tipopropiedad (TipoP_ID, Descripcion) VALUES
        ('TP001', 'Casa'),
        ('TP002', 'Apartamento'),
        ('TP003', 'Local Comercial'),
        ('TP004', 'Bodega'),
        ('TP005', 'Oficina');

    -- ── Roles ────────────────────────────────────────────────────
    INSERT INTO rol (Rol_ID, Nombre_Rol, Descripcion) VALUES
        ('ROL001', 'Administrador',       'Acceso total al sistema'),
        ('ROL002', 'Agente Inmobiliario', 'Gestión de propiedades, clientes y contratos'),
        ('ROL003', 'Contador',            'Gestión de pagos y reportes financieros');

    -- ── Ciudades ─────────────────────────────────────────────────
    INSERT INTO ciudad (Ciudad_ID, Nombre_Ciudad, Departamento) VALUES
        ('CIU001', 'Neiva',    'Huila'),
        ('CIU002', 'Pitalito', 'Huila'),
        ('CIU003', 'Garzón',   'Huila'),
        ('CIU004', 'La Plata', 'Huila'),
        ('CIU005', 'Bogotá',   'Cundinamarca');

    -- ── Barrios ──────────────────────────────────────────────────
    INSERT INTO barrio (Barrio_ID, Nombre_Barrio, Ciudad_ID) VALUES
        ('BAR001', 'Centro',             'CIU001'),
        ('BAR002', 'El Rosario',         'CIU001'),
        ('BAR003', 'Miraflores',         'CIU001'),
        ('BAR004', 'Zona Industrial',    'CIU001'),
        ('BAR005', 'Norte',              'CIU001'),
        ('BAR006', 'Bellavista',         'CIU002'),
        ('BAR007', 'Villa Verde',        'CIU002'),
        ('BAR008', 'Centro Garzón',      'CIU003'),
        ('BAR009', 'Zona Industrial Sur','CIU003'),
        ('BAR010', 'El Centro',          'CIU004');

    -- ── Personas ─────────────────────────────────────────────────
    INSERT INTO personas (Persona_ID, Nombre, Apellido, Telefono, Email) VALUES
        -- Agentes
        ('PER001', 'Ludy',    'Monsalve',    '3101001001', 'Ludy.Monsalve@inm.co'),
        ('PER002', 'omar',  'pinto',     '3101001002', 'Omar.pinto@inm.co'),
        ('PER003', 'samuel',  'javier',   '3101001003', 'Samuel.javier@inm.co'),
        ('PER004', 'ana', 'maria',   '3101001004', 'Ana.maria@inm.co'),
        ('PER005', 'maricela', 'rodriguez',     '3101001005', 'maricela.rodrigez@inm.co'),
        -- Clientes
        ('PER006', 'Juan',      'Pérez',     '3200001001', 'juan.perez@mail.com'),
        ('PER007', 'María',     'López',     '3200001002', 'maria.lopez@mail.com'),
        ('PER008', 'Carlos',    'Vera',      '3200001003', 'carlos.vera@mail.com'),
        ('PER009', 'Sofía',     'Martínez',  '3200001004', 'sofia.martinez@mail.com'),
        ('PER010', 'Andrés',    'Torres',    '3200001005', 'andres.torres@mail.com'),
        ('PER011', 'Valentina', 'Ríos',      '3200001006', 'valentina.rios@mail.com'),
        ('PER012', 'Felipe',    'Sánchez',   '3200001007', 'felipe.sanchez@mail.com'),
        ('PER013', 'Camila',    'Herrera',   '3200001008', 'camila.herrera@mail.com'),
        ('PER014', 'Luis',      'Castillo',  '3200001009', 'luis.castillo@mail.com'),
        ('PER015', 'Paula',     'Jiménez',   '3200001010', 'paula.jimenez@mail.com'),
        -- Usuarios admin
        ('PER016', 'Admin',  'Sistema',  '3000000001', 'admin@inm.co');

    -- ── Agentes ──────────────────────────────────────────────────
    INSERT INTO agentes (Agente_ID, Persona_ID, Comision_Pct) VALUES
        ('AGE001', 'PER001', 3.00),
        ('AGE002', 'PER002', 3.50),
        ('AGE003', 'PER003', 2.50),
        ('AGE004', 'PER004', 4.00),
        ('AGE005', 'PER005', 3.00);

    -- ── Clientes ─────────────────────────────────────────────────
    INSERT INTO clientes (Cliente_ID, Persona_ID) VALUES
        ('CLI001', 'PER006'),
        ('CLI002', 'PER007'),
        ('CLI003', 'PER008'),
        ('CLI004', 'PER009'),
        ('CLI005', 'PER010'),
        ('CLI006', 'PER011'),
        ('CLI007', 'PER012'),
        ('CLI008', 'PER013'),
        ('CLI009', 'PER014'),
        ('CLI010', 'PER015');

    -- ── Usuarios del sistema ─────────────────────────────────────
    INSERT INTO usuariosistema (Usuario_ID, Persona_ID, Rol_ID, NombreUsuario) VALUES
        ('USR001', 'PER016', 'ROL001', 'admin'),
        ('USR002', 'PER001', 'ROL002', 'agente.gomez'),
        ('USR003', 'PER002', 'ROL002', 'agente.ruiz'),
        ('USR004', 'PER003', 'ROL002', 'agente.castro'),
        ('USR005', 'PER004', 'ROL002', 'agente.ortega'),
        ('USR006', 'PER005', 'ROL003', 'contadora.vega');

    -- ── Propiedades ──────────────────────────────────────────────
    INSERT INTO propiedad (Propiedad_ID, Direccion, Precio_Propiedad, TipoP_ID, EstadoP_ID, Barrio_ID) VALUES
        ('PROP001', 'Cra 5 # 8-30 Piso 3',              1200000,   'TP002', 'EP001', 'BAR001'),
        ('PROP002', 'Vereda El Porvenir Km 3',          85000000,   'TP001', 'EP001', 'BAR006'),
        ('PROP003', 'Calle 8 # 4-55 Local 2',           2500000,   'TP003', 'EP001', 'BAR001'),
        ('PROP004', 'Cra 12 # 15-40 Apto 204',          1500000,   'TP002', 'EP001', 'BAR003'),
        ('PROP005', 'Calle 20 # 10-15',               230000000,   'TP001', 'EP001', 'BAR002'),
        ('PROP006', 'Av. Circunvalar # 5-80 Of 305',    1800000,   'TP005', 'EP001', 'BAR001'),
        ('PROP007', 'Vía Garzón Km 2 Lote 5',          4000000,   'TP004', 'EP001', 'BAR009'),
        ('PROP008', 'Cra 18 # 32-10',                 310000000,   'TP001', 'EP001', 'BAR005'),
        ('PROP009', 'CC La Plata Local 14',             1100000,   'TP003', 'EP001', 'BAR010'),
        ('PROP010', 'Urb. Villa Verde Casa 7',         180000000,   'TP001', 'EP001', 'BAR007'),
        ('PROP011', 'Calle 12 # 8-20 Of 104',           2200000,   'TP005', 'EP001', 'BAR008'),
        ('PROP012', 'Zona Industrial Lote 12',          6500000,   'TP004', 'EP001', 'BAR004'),
        ('PROP013', 'Cra 9 # 22-15 Apto 301',          1050000,   'TP002', 'EP001', 'BAR001'),
        ('PROP014', 'Vda Los Pinos Km 5',             420000000,   'TP001', 'EP001', 'BAR006'),
        ('PROP015', 'Cra 22 # 45-10 Apto 101',         980000,    'TP002', 'EP001', 'BAR003');

    -- ── Contratos ────────────────────────────────────────────────
    INSERT INTO contratos (Contrato_ID, Fecha_Contrato, Tipo_Contrato, Cliente_ID, Agente_ID, Propiedad_ID) VALUES
        ('CON001', '2024-01-01', 'arriendo', 'CLI001', 'AGE001', 'PROP001'),
        ('CON002', '2024-02-15', 'venta',    'CLI002', 'AGE001', 'PROP002'),
        ('CON003', '2024-03-01', 'arriendo', 'CLI003', 'AGE002', 'PROP003'),
        ('CON004', '2024-04-01', 'arriendo', 'CLI004', 'AGE003', 'PROP006'),
        ('CON005', '2024-02-01', 'arriendo', 'CLI006', 'AGE002', 'PROP007'),
        ('CON006', '2024-04-10', 'venta',    'CLI005', 'AGE003', 'PROP005'),
        ('CON007', '2024-06-01', 'venta',    'CLI007', 'AGE004', 'PROP008'),
        ('CON008', '2024-05-01', 'arriendo', 'CLI009', 'AGE004', 'PROP009'),
        ('CON009', '2024-07-20', 'venta',    'CLI010', 'AGE002', 'PROP014'),
        ('CON010', '2023-06-01', 'arriendo', 'CLI001', 'AGE001', 'PROP013');

    -- Actualizar estado de propiedades contratadas
    UPDATE propiedad SET EstadoP_ID = 'EP002' WHERE Propiedad_ID IN ('PROP001','PROP003','PROP006','PROP007','PROP009');
    UPDATE propiedad SET EstadoP_ID = 'EP003' WHERE Propiedad_ID IN ('PROP002','PROP005','PROP008','PROP014');

    -- ── Detalle contratos de arriendo ────────────────────────────
    INSERT INTO contratoarriendo (ContrArr_ID, Contrato_ID, Valor_Mensual, Fecha_Inicio, Fecha_Fin) VALUES
        ('CA001', 'CON001', 1200000, '2024-01-01', '2025-01-01'),
        ('CA002', 'CON003', 2500000, '2024-03-01', '2025-03-01'),
        ('CA003', 'CON004', 1800000, '2024-04-01', '2025-04-01'),
        ('CA004', 'CON005', 4000000, '2024-02-01', '2025-02-01'),
        ('CA005', 'CON008', 1100000, '2024-05-01', '2025-05-01'),
        ('CA006', 'CON010', 1000000, '2023-06-01', '2024-06-01');

    -- ── Detalle contratos de venta ───────────────────────────────
    INSERT INTO contratoventa (ContrVenta_ID, Contrato_ID, Precio_Venta, Comision_Venta, Fecha_Escritura) VALUES
        ('CV001', 'CON002', 85000000,  2550000,  '2024-03-01'),
        ('CV002', 'CON006', 230000000, 8050000,  '2024-05-15'),
        ('CV003', 'CON007', 310000000, 12400000, NULL),
        ('CV004', 'CON009', 420000000, 10500000, NULL);

    -- ── Pagos ────────────────────────────────────────────────────
    INSERT INTO pagos (Pago_ID, Contrato_ID, Fecha_Pago, Monto_Pago, EstadoPago_ID) VALUES
        -- CON001 – Arriendo Apto (Juan Pérez)
        ('PAG001', 'CON001', '2024-01-05', 1200000, 'EPG001'),
        ('PAG002', 'CON001', '2024-02-04', 1200000, 'EPG001'),
        ('PAG003', 'CON001', '2024-03-06', 1200000, 'EPG001'),
        ('PAG004', 'CON001', '2024-04-10',  600000, 'EPG003'),  -- parcial
        ('PAG005', 'CON001', '2024-05-01',       0, 'EPG002'),  -- pendiente
        -- CON003 – Arriendo Local (Carlos Vera)
        ('PAG006', 'CON003', '2024-03-02', 2500000, 'EPG001'),
        ('PAG007', 'CON003', '2024-04-01', 2500000, 'EPG001'),
        ('PAG008', 'CON003', '2024-05-01',       0, 'EPG002'),  -- pendiente
        -- CON004 – Arriendo Oficina (Sofía Martínez)
        ('PAG009', 'CON004', '2024-04-03', 1800000, 'EPG001'),
        ('PAG010', 'CON004', '2024-05-02', 1800000, 'EPG001'),
        -- CON005 – Arriendo Bodega (Valentina Ríos)
        ('PAG011', 'CON005', '2024-02-05', 4000000, 'EPG001'),
        ('PAG012', 'CON005', '2024-03-04', 4000000, 'EPG001'),
        ('PAG013', 'CON005', '2024-04-01',       0, 'EPG002'),  -- pendiente
        ('PAG014', 'CON005', '2024-05-01',       0, 'EPG002'),  -- pendiente
        -- CON008 – Arriendo Local Galería (Luis Castillo)
        ('PAG015', 'CON008', '2024-05-03', 1100000, 'EPG001');

    -- ── Auditoría de propiedades ──────────────────────────────────
    INSERT INTO auditoriapropiedad (Audit_ID, Propiedad_ID, Estado_Anterior, Estado_Nuevo, Fecha_Cambio, Usuario_ID) VALUES
        ('AUP001', 'PROP001', 'Disponible', 'Arrendada', '2024-01-01', 'USR002'),
        ('AUP002', 'PROP002', 'Disponible', 'Vendida',   '2024-02-15', 'USR002'),
        ('AUP003', 'PROP003', 'Disponible', 'Arrendada', '2024-03-01', 'USR003'),
        ('AUP004', 'PROP006', 'Disponible', 'Arrendada', '2024-04-01', 'USR004'),
        ('AUP005', 'PROP007', 'Disponible', 'Arrendada', '2024-02-01', 'USR003'),
        ('AUP006', 'PROP005', 'Disponible', 'Vendida',   '2024-04-10', 'USR004'),
        ('AUP007', 'PROP008', 'Disponible', 'Vendida',   '2024-06-01', 'USR005'),
        ('AUP008', 'PROP009', 'Disponible', 'Arrendada', '2024-05-01', 'USR005'),
        ('AUP009', 'PROP014', 'Disponible', 'Vendida',   '2024-07-20', 'USR003');

    -- ── Auditoría de contratos ────────────────────────────────────
    INSERT INTO auditoriacontrato (AuditCon_ID, Contrato_ID, Evento, Fecha_Evento, Usuario_ID) VALUES
        ('AUC001', 'CON001', 'Contrato de arriendo registrado',  '2024-01-01', 'USR002'),
        ('AUC002', 'CON002', 'Contrato de venta registrado',     '2024-02-15', 'USR002'),
        ('AUC003', 'CON003', 'Contrato de arriendo registrado',  '2024-03-01', 'USR003'),
        ('AUC004', 'CON004', 'Contrato de arriendo registrado',  '2024-04-01', 'USR004'),
        ('AUC005', 'CON005', 'Contrato de arriendo registrado',  '2024-02-01', 'USR003'),
        ('AUC006', 'CON006', 'Contrato de venta registrado',     '2024-04-10', 'USR004'),
        ('AUC007', 'CON007', 'Contrato de venta registrado',     '2024-06-01', 'USR005'),
        ('AUC008', 'CON008', 'Contrato de arriendo registrado',  '2024-05-01', 'USR005'),
        ('AUC009', 'CON009', 'Contrato de venta registrado',     '2024-07-20', 'USR003'),
        ('AUC010', 'CON010', 'Contrato de arriendo finalizado',  '2024-06-01', 'USR002');

    -- ── Reporte de pagos pendientes ───────────────────────────────
    INSERT INTO reportepagos (Reporte_ID, Contrato_ID, Fecha_Reporte, Monto_Pendiente, Descripcion, Periodo) VALUES
        ('REP001', 'CON001', '2024-05-01', 1800000, 'Pago parcial abril + pendiente mayo', '2024-05'),
        ('REP002', 'CON003', '2024-05-01',  2500000, 'Pago pendiente mayo',                 '2024-05'),
        ('REP003', 'CON005', '2024-05-01',  8000000, 'Dos meses pendientes: abril y mayo',  '2024-05');

    -- ── Logs de ejemplo ──────────────────────────────────────────
    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion) VALUES
        ('2024-01-01 09:00:00', 'Registro contrato CON001', 'tabla contratos',        'Nuevo contrato de arriendo PROP001'),
        ('2024-02-15 14:30:00', 'Registro contrato CON002', 'tabla contratos',        'Nuevo contrato de venta PROP002'),
        ('2024-04-10 11:00:00', 'Cambio estado PROP001',    'tabla propiedad',        'Estado cambió de Disponible a Arrendada'),
        ('2024-05-01 08:00:00', 'Generación reporte pagos', 'tabla reportepagos',     'Reporte mensual mayo 2024 generado');

    INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle) VALUES
        ('2024-03-15 10:22:00', 'FK_VIOLATION',       'tabla pagos',    'Intento de insertar pago con Contrato_ID inexistente'),
        ('2024-04-02 16:45:00', 'DUPLICATE_ENTRY',    'tabla personas', 'Email duplicado al registrar cliente'),
        ('2024-05-10 09:10:00', 'NULL_VALUE_ERROR',   'tabla contratoventa', 'Precio_Venta no puede ser NULL en contrato de venta');

    -- ============================================================
    -- FIN DEL SCRIPT
    -- ============================================================