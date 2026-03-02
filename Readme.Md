### Base de Datos MySQL — Documentación Técnica Completa

#  Sistema de Gestión Inmobiliaria
---

## 📋 Tabla de Contenidos

1. [Descripción del Proyecto](#1-descripción-del-proyecto)
2. [Tecnologías Utilizadas](#2-tecnologías-utilizadas)
3. [Modelo Entidad-Relación](#3-modelo-entidad-relación)
4. [Estructura de la Base de Datos](#4-estructura-de-la-base-de-datos)
5. [Normalización](#5-normalización)
6. [Scripts del Proyecto](#6-scripts-del-proyecto)
7. [Funciones UDF](#7-funciones-udf)
8. [Triggers](#8-triggers)
9. [Stored Procedures](#9-stored-procedures)
10. [Vistas](#10-vistas)
11. [Evento Programado](#11-evento-programado)
12. [Usuarios y Roles](#12-usuarios-y-roles)
13. [Optimización e Índices](#13-optimización-e-índices)
14. [Orden de Ejecución](#14-orden-de-ejecución)
15. [Datos de Prueba](#15-datos-de-prueba)
16. [Errores Conocidos y Soluciones](#16-errores-conocidos-y-soluciones)
17. [Estado del Proyecto](#17-estado-del-proyecto)

---

## 1. Descripción del Proyecto

Sistema de gestión para un portafolio inmobiliario que permite administrar propiedades (casas, apartamentos, locales comerciales), clientes, agentes, contratos de arriendo y venta, pagos y auditoría de cambios.

### Objetivos principales

- Registrar y consultar propiedades por estado, tipo y ubicación geográfica
- Gestionar contratos de arriendo y venta con sus respectivos detalles
- Controlar pagos mensuales con seguimiento de deuda pendiente
- Calcular comisiones de agentes en contratos de venta
- Auditar automáticamente cambios de estado en propiedades y contratos
- Generar reportes mensuales de pagos pendientes de forma automática
- Restringir el acceso a la información según el rol del usuario

---

## 2. Tecnologías Utilizadas

| Tecnología | Versión | Uso |
|---|---|---|
| MySQL | 8.0+ | Motor de base de datos |
| InnoDB | — | Motor de tablas (soporte FK y transacciones) |
| utf8mb4 | unicode_ci | Juego de caracteres |
| MySQL Workbench | 8.0+ | Herramienta de modelado y ejecución |

---

## 3. Modelo Entidad-Relación

El modelo físico está compuesto por **18 tablas** organizadas en 7 grupos funcionales:

```
Ciudad ──< Barrio ──< Propiedad >── TipoPropiedad
                          │         EstadoPropiedad
                          │
Personas >── Clientes ──< Contratos >── Agentes >── Personas
                              │
                    ┌─────────┴──────────┐
             ContratoArriendo     ContratoVenta
                              │
                            Pagos >── EstadoPago
                              │
                         ReportePagos
                              │
              ┌───────────────┴──────────────┐
       AuditoriaContrato           AuditoriaPropiedad
              │                              │
         UsuarioSistema >── Rol         UsuarioSistema

   Logs_Errores          Logs_Cambios
   (autónomas — sin FK)
```

### Cardinalidades principales

| Relación | Tipo |
|---|---|
| Ciudad → Barrio | 1:N |
| Barrio → Propiedad | 1:N |
| Propiedad → TipoPropiedad | N:1 |
| Propiedad → EstadoPropiedad | N:1 |
| Personas → Clientes | 1:1 |
| Personas → Agentes | 1:1 |
| Personas → UsuarioSistema | 1:1 |
| Contratos → ContratoArriendo | 1:1 |
| Contratos → ContratoVenta | 1:1 |
| Contratos → Pagos | 1:N |
| Contratos → ReportePagos | 1:N |
| Contratos → AuditoriaContrato | 1:N |
| Propiedad → AuditoriaPropiedad | 1:N |
| UsuarioSistema → Rol | N:1 |

---

## 4. Estructura de la Base de Datos

### 4.1 Tablas Catálogo

| Tabla | Descripción | Columnas clave |
|---|---|---|
| `Ciudad` | Ciudades del país | `Ciudad_ID`, `Nombre_Ciudad`, `Departamento` |
| `Barrio` | Barrios por ciudad | `Barrio_ID`, `Nombre_Barrio`, `Ciudad_ID` |
| `TipoPropiedad` | Tipos: Casa, Apto, Local | `TipoP_ID`, `Descripcion` |
| `EstadoPropiedad` | EP-01 Disponible, EP-02 Arrendada, EP-03 Vendida | `EstadoP_ID`, `Descripcion` |
| `EstadoPago` | EPG-01 Pagado, EPG-02 Pendiente, EPG-03 Vencido | `EstadoPago_ID`, `Descripcion` |
| `Rol` | ROL-01 Admin, ROL-02 Agente, ROL-03 Cliente, ROL-04 Contador | `Rol_ID`, `Nombre_Rol` |

### 4.2 Tablas de Personas

| Tabla | Descripción | Columnas clave |
|---|---|---|
| `Personas` | Superentidad — datos base de cualquier persona | `Persona_ID`, `Nombre`, `Apellido`, `Email` |
| `Clientes` | Clientes que arriendan o compran | `Cliente_ID`, `Persona_ID` |
| `Agentes` | Agentes con porcentaje de comisión | `Agente_ID`, `Persona_ID`, `Comision_Pct` |
| `UsuarioSistema` | Usuarios de acceso al sistema | `Usuario_ID`, `Persona_ID`, `Rol_ID`, `NombreUsuario` |

### 4.3 Tablas Operacionales

| Tabla | Descripción | Columnas clave |
|---|---|---|
| `Propiedad` | Inventario de propiedades | `Propiedad_ID`, `Direccion`, `Precio_Propiedad`, `TipoP_ID`, `EstadoP_ID`, `Barrio_ID` |
| `Contratos` | Tabla central — arriendo o venta | `Contrato_ID`, `Tipo_Contrato` ENUM, `Cliente_ID`, `Agente_ID`, `Propiedad_ID` |
| `ContratoArriendo` | Detalle de arriendos | `ContrArr_ID`, `Contrato_ID`, `Valor_Mensual`, `Fecha_Inicio`, `Fecha_Fin` |
| `ContratoVenta` | Detalle de ventas | `ContrVenta_ID`, `Contrato_ID`, `Precio_Venta`, `Comision_Venta`, `Fecha_Escritura` |
| `Pagos` | Pagos por contrato de arriendo | `Pago_ID`, `Contrato_ID`, `Monto_Pago`, `EstadoPago_ID` |

### 4.4 Tablas de Auditoría y Reportes

| Tabla | Descripción | Poblada por |
|---|---|---|
| `AuditoriaContrato` | Registro de eventos sobre contratos | Trigger `trg_nuevo_contrato` |
| `AuditoriaPropiedad` | Historial de cambios de estado | Trigger `trg_cambio_estado_propiedad` |
| `ReportePagos` | Reporte mensual de pagos pendientes | Evento `evt_reporte_mensual_pagos_pendientes` |
| `Logs_Errores` | Errores capturados del sistema | Handlers en SPs y evento |
| `Logs_Cambios` | Operaciones exitosas registradas | Triggers y SPs |

---

## 5. Normalización

La base de datos está normalizada hasta **Tercera Forma Normal (3FN)**:

| Forma Normal | Criterio aplicado |
|---|---|
| **1FN** | Todos los atributos son atómicos. No hay grupos repetitivos |
| **2FN** | Todos los atributos no clave dependen completamente de la PK |
| **3FN** | No existen dependencias transitivas entre atributos no clave |

### Decisiones de diseño destacadas

- `Personas` como superentidad evita duplicar datos de contacto en `Clientes`, `Agentes` y `UsuarioSistema`
- `Contratos` centraliza arriendo y venta con especialización en `ContratoArriendo` y `ContratoVenta`
- `Ciudad` y `Barrio` separadas eliminan dependencias transitivas en `Propiedad`
- Las tablas de auditoría solo se populan por triggers — nunca por INSERT directo del usuario

---

## 6. Scripts del Proyecto

| # | Archivo | Descripción | Prerrequisito |
|---|---|---|---|
| 1 | `modelo_fisico.sql` | DDL completo + DML datos de prueba | — |
| 2 | `fn_1_calcular_comision.sql` | UDF comisión de agente | modelo_fisico.sql |
| 3 | `fn_2_calcular_deuda_pendiente.sql` | UDF deuda de arriendo | modelo_fisico.sql |
| 4 | `fn_3_total_disponibles_por_tipo.sql` | UDF disponibilidad por tipo | modelo_fisico.sql |
| 5 | `trg_1_cambio_estado_propiedad.sql` | Trigger auditoría de propiedad | modelo_fisico.sql |
| 6 | `trg_2_nuevo_contrato.sql` | Trigger auditoría de contrato | modelo_fisico.sql |
| 7 | `sp_1_registrar_contrato_arriendo.sql` | SP registro de arriendo | modelo_fisico.sql + triggers |
| 8 | `sp_2_registrar_pago.sql` | SP registro de pago | modelo_fisico.sql + UDFs |
| 9 | `sp_3_cambiar_estado_propiedad.sql` | SP cambio de estado | modelo_fisico.sql + triggers |
| 10 | `v1_propiedades_disponibles.sql` | Vista propiedades EP-01 | modelo_fisico.sql |
| 11 | `v2_contratos_activos.sql` | Vista contratos completos | modelo_fisico.sql |
| 12 | `v3_deuda_comisiones.sql` | Vista deuda arriendos + comisiones | modelo_fisico.sql + UDFs |
| 13 | `evento_mensual_v2.sql` | Evento programado mensual | modelo_fisico.sql + UDFs |
| 14 | `usuarios_roles.sql` | Usuarios MySQL y privilegios | modelo_fisico.sql + vistas |
| 15 | `optimizacion_indices.sql` | Índices adicionales de optimización | modelo_fisico.sql |

---

## 7. Funciones UDF

### `fn_calcular_comision(p_contrato_id VARCHAR(10))`

Calcula la comisión en pesos que gana el agente en un contrato de venta.

```sql
-- Fórmula: Precio_Venta × (Comision_Pct / 100)
SELECT fn_calcular_comision('CON-002');
-- Resultado: 9600000.00
```

| Parámetro | Tipo | Descripción |
|---|---|---|
| `p_contrato_id` | VARCHAR(10) | ID del contrato de venta |
| **Retorna** | DECIMAL(15,2) | Monto de comisión en pesos |

> Retorna `0.00` si el contrato no existe o no es de tipo `Venta`.

---

### `fn_calcular_deuda_pendiente(p_contrato_id VARCHAR(10))`

Calcula la deuda total de un contrato de arriendo sumando los meses con estado `EPG-02` (Pendiente) y `EPG-03` (Vencido).

```sql
-- Fórmula: COUNT(meses pendientes/vencidos) × Valor_Mensual
SELECT fn_calcular_deuda_pendiente('CON-001');
-- Resultado: 800000.00
```

| Parámetro | Tipo | Descripción |
|---|---|---|
| `p_contrato_id` | VARCHAR(10) | ID del contrato de arriendo |
| **Retorna** | DECIMAL(15,2) | Deuda total en pesos |

> Retorna `0.00` si el contrato no existe o es de tipo `Venta`.

---

### `fn_total_disponibles_por_tipo(p_tipo_id VARCHAR(10))`

Retorna el número de propiedades disponibles (`EP-01`) para un tipo dado.

```sql
SELECT fn_total_disponibles_por_tipo('TP-01');
-- Resultado: 1  (solo PROP-05 disponible)
```

| Parámetro | Tipo | Descripción |
|---|---|---|
| `p_tipo_id` | VARCHAR(10) | ID del tipo de propiedad |
| **Retorna** | INT | Cantidad de propiedades disponibles |

---

## 8. Triggers

### `trg_cambio_estado_propiedad`

**Evento:** `AFTER UPDATE ON Propiedad`

Se dispara cuando `EstadoP_ID` cambia. Registra automáticamente en `AuditoriaPropiedad` y `Logs_Cambios`.

```
UPDATE Propiedad SET EstadoP_ID = 'EP-02' WHERE Propiedad_ID = 'PROP-05'
    └─► INSERT AuditoriaPropiedad (Disponible → Arrendada)
    └─► INSERT Logs_Cambios
```

---

### `trg_nuevo_contrato`

**Evento:** `AFTER INSERT ON Contratos`

Se dispara al registrar un contrato nuevo. Actualiza el estado de la propiedad y registra en `AuditoriaContrato` y `Logs_Cambios`.

```
INSERT INTO Contratos (Tipo_Contrato = 'Arriendo', Propiedad_ID = 'PROP-05')
    └─► UPDATE Propiedad SET EstadoP_ID = 'EP-02'
    └─► INSERT AuditoriaContrato
    └─► INSERT Logs_Cambios
```

> **Nota:** Los IDs de auditoría se generan con `CONCAT('ACO', RIGHT(UNIX_TIMESTAMP(NOW(6)), 5))` para evitar el Error 1064 (subquery sobre tabla destino dentro de trigger).

---

## 9. Stored Procedures

### `sp_registrar_contrato_arriendo`

Registra un contrato de arriendo completo en una transacción atómica.

```sql
CALL sp_registrar_contrato_arriendo(
    'CON-008',      -- Contrato_ID
    CURDATE(),      -- Fecha
    'CLI-01',       -- Cliente_ID
    'AGE-01',       -- Agente_ID
    'PROP-05',      -- Propiedad_ID
    950000.00,      -- Valor mensual
    CURDATE(),      -- Fecha inicio
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR),
    @resultado
);
SELECT @resultado;
```

**Validaciones:** propiedad disponible (`EP-01`), cliente y agente existentes, valor mensual > 0.

**Acciones:** INSERT en `Contratos` → dispara trigger → INSERT en `ContratoArriendo` → INSERT primer pago como `EPG-02`.

---

### `sp_registrar_pago`

Registra un pago para un contrato de arriendo y determina su estado automáticamente.

```sql
CALL sp_registrar_pago('PAG-010', 'CON-001', CURDATE(), 800000.00, @resultado);
```

**Lógica de estado:** si `Monto_Pago >= Valor_Mensual` → `EPG-01` (Pagado), si es menor → `EPG-02` (Pendiente).

---

### `sp_cambiar_estado_propiedad`

Cambia el estado de una propiedad con validaciones previas. El trigger se encarga de la auditoría.

```sql
CALL sp_cambiar_estado_propiedad('PROP-05', 'EP-01', @resultado);
```

**Validaciones:** propiedad existente, estado válido en catálogo, estado diferente al actual.

> **Nota técnica:** Los 3 SPs usan `proc_label: BEGIN ... END proc_label` para que `LEAVE` funcione correctamente (evita Error 1308).

---

## 10. Vistas

### `v_propiedades_disponibles`

Filtra `EstadoP_ID = 'EP-01'` con detalle completo de tipo, barrio y ciudad.

```sql
SELECT * FROM v_propiedades_disponibles;
SELECT * FROM v_propiedades_disponibles WHERE Tipo_Propiedad = 'Apartamento';
```

---

### `v_contratos_activos`

Todos los contratos con datos completos de propiedad, cliente y agente.

```sql
SELECT * FROM v_contratos_activos WHERE Tipo_Contrato = 'Arriendo';
SELECT * FROM v_contratos_activos WHERE Agente_ID = 'AGE-01';
```

---

### `v_deuda_arriendos`

Arriendos con conteo de pagos por estado y deuda calculada con `fn_calcular_deuda_pendiente()`.

```sql
SELECT * FROM v_deuda_arriendos WHERE Deuda_Pendiente > 0 ORDER BY Deuda_Pendiente DESC;
```

---

### `v_comisiones_agentes`

Ranking de agentes con total de ventas y comisión calculada con `fn_calcular_comision()`.

```sql
SELECT * FROM v_comisiones_agentes ORDER BY Comision_Calculada DESC;
```

> **Requisito:** Las vistas `v_deuda_arriendos` y `v_comisiones_agentes` requieren que las UDFs estén creadas previamente.

---

## 11. Evento Programado

### `evt_reporte_mensual_pagos_pendientes`

Se ejecuta automáticamente el **día 1 de cada mes a las 00:00**. Inserta en `ReportePagos` todos los contratos de arriendo que tengan pagos en estado `EPG-02` (Pendiente) o `EPG-03` (Vencido).

```sql
SET GLOBAL event_scheduler = ON;
```

**Flujo interno:**
1. Elimina registros del periodo actual (idempotente)
2. Inserta nuevos reportes usando `fn_calcular_deuda_pendiente()`
3. Registra ejecución exitosa en `Logs_Cambios`
4. Ante cualquier error → registra en `Logs_Errores` y hace rollback

**Errores corregidos respecto al script original:**

| Error original | Corrección aplicada |
|---|---|
| `'EPG-02'` → `'EPG-03'` eran `'EPG-02'`/`'EPG-03'` | IDs correctos del modelo |
| `Tipo_Contrato = 'Arriendo'` en minúsculas | ENUM con mayúscula inicial |
| `HAVING SUM(Monto_Pago) > 0` | `HAVING COUNT(Pago_ID) > 0` |
| `SUM(Monto_Pago)` como deuda | `fn_calcular_deuda_pendiente()` |
| `UUID_SHORT()` no cabe en VARCHAR(10) | `CONCAT('R', DATE_FORMAT(...), LPAD(...))` |

---

## 12. Usuarios y Roles

### Usuarios creados

| Usuario MySQL | Contraseña | Rol del sistema | Descripción |
|---|---|---|---|
| `admin_inm` | `Admin@Inm2024!` | ROL-01 Administrador | `ALL PRIVILEGES WITH GRANT OPTION` |
| `agente_inm` | `Agente@Inm2024!` | ROL-02 Agente | Gestión de propiedades, clientes y contratos |
| `contador_inm` | `Conta@Inm2024!` | ROL-04 Contador | Gestión de pagos y reportes financieros |
| `cliente_inm` | `Cliente@Inm2024!` | ROL-03 Cliente | Solo consulta de propiedades disponibles |

### Matriz de privilegios

| Tabla / Vista | Admin | Agente | Contador | Cliente |
|---|---|---|---|---|
| Catálogos (Ciudad, Barrio, Tipos) | ALL | SELECT | SELECT | SELECT |
| Personas | ALL | SELECT/INSERT/UPDATE | SELECT | — |
| Clientes | ALL | SELECT/INSERT/UPDATE | SELECT | — |
| Agentes | ALL | SELECT | SELECT | — |
| UsuarioSistema | ALL | — | — | — |
| Propiedad | ALL | SELECT/INSERT/UPDATE | SELECT | — |
| Contratos | ALL | SELECT/INSERT | SELECT | — |
| ContratoArriendo / ContratoVenta | ALL | SELECT/INSERT | SELECT | — |
| Pagos | ALL | SELECT/INSERT | SELECT/INSERT/UPDATE | — |
| ReportePagos | ALL | SELECT | SELECT/INSERT | — |
| AuditoriaContrato / Propiedad | ALL | SELECT | SELECT | — |
| Logs_Errores / Logs_Cambios | ALL | — | SELECT | — |
| `v_propiedades_disponibles` | ALL | SELECT | — | SELECT |
| `v_contratos_activos` | ALL | SELECT | SELECT | — |
| `v_deuda_arriendos` | ALL | SELECT | SELECT | — |
| `v_comisiones_agentes` | ALL | — | SELECT | — |

---

## 13. Optimización e Índices

### Índices adicionales creados

> Los índices sobre columnas FK ya son creados automáticamente por MySQL. Este script solo agrega los índices sobre columnas sin FK.

| Tabla | Índice | Columna(s) | Tipo | Beneficio |
|---|---|---|---|---|
| Propiedad | `idx_propiedad_precio` | Precio_Propiedad | Simple | ORDER BY en búsquedas |
| Propiedad | `idx_propiedad_tipo_estado` | TipoP_ID, EstadoP_ID | **Compuesto** | Filtros combinados frecuentes |
| Contratos | `idx_contratos_tipo` | Tipo_Contrato | Simple | WHERE Tipo = 'Arriendo'/'Venta' |
| Contratos | `idx_contratos_fecha` | Fecha_Contrato | Simple | ORDER BY, rangos de fecha |
| Contratos | `idx_contratos_tipo_agente` | Tipo_Contrato, Agente_ID | **Compuesto** | Ranking de ventas por agente |
| Pagos | `idx_pagos_fecha` | Fecha_Pago | Simple | Reportes por período |
| Pagos | `idx_pagos_contrato_estado` | Contrato_ID, EstadoPago_ID | **Compuesto** | UDFs + evento mensual |
| ContratoArriendo | `idx_contrarriendo_fechas` | Fecha_Inicio, Fecha_Fin | **Compuesto** | Consultas de vigencia |
| ContratoVenta | `idx_contraventa_precio` | Precio_Venta | Simple | ORDER BY en reportes |
| AuditoriaPropiedad | `idx_auditprop_fecha` | Fecha_Hora | Simple | ORDER BY DESC en auditoría |
| AuditoriaContrato | `idx_auditcont_fecha` | Fecha_Hora | Simple | ORDER BY DESC en auditoría |
| ReportePagos | `idx_reporte_periodo` | Periodo | Simple | WHERE Periodo = 'YYYY-MM' |
| Personas | `idx_personas_email` | Email | Simple | Validación de duplicados |

> **Error 1553 corregido:** Los índices sobre FK (`EstadoP_ID`, `TipoP_ID`, `Barrio_ID`, etc.) no se pueden eliminar mientras existan las FK. Este script usa un procedure auxiliar `_create_index_if_not_exists` que verifica en `INFORMATION_SCHEMA` antes de crear.

---

## 14. Orden de Ejecución

```
1.  modelo_fisico.sql                      ← DDL + DML base
2.  fn_1_calcular_comision.sql             ← UDF 1
3.  fn_2_calcular_deuda_pendiente.sql      ← UDF 2
4.  fn_3_total_disponibles_por_tipo.sql    ← UDF 3
5.  trg_1_cambio_estado_propiedad.sql      ← Trigger 1
6.  trg_2_nuevo_contrato.sql               ← Trigger 2
7.  sp_1_registrar_contrato_arriendo.sql   ← SP 1 (depende de triggers)
8.  sp_2_registrar_pago.sql                ← SP 2 (depende de UDFs)
9.  sp_3_cambiar_estado_propiedad.sql      ← SP 3 (depende de triggers)
10. v1_propiedades_disponibles.sql         ← Vista 1
11. v2_contratos_activos.sql               ← Vista 2
12. v3_deuda_comisiones.sql                ← Vista 3 (depende de UDFs)
13. evento_mensual_v2.sql                  ← Evento (depende de UDFs)
14. usuarios_roles.sql                     ← Usuarios (depende de vistas)
15. optimizacion_indices.sql               ← Índices (ejecutar al final)
```

### Ejecución desde terminal

```bash
mysql -u root -p < modelo_fisico.sql
mysql -u root -p < fn_1_calcular_comision.sql
mysql -u root -p < fn_2_calcular_deuda_pendiente.sql
mysql -u root -p < fn_3_total_disponibles_por_tipo.sql
mysql -u root -p < trg_1_cambio_estado_propiedad.sql
mysql -u root -p < trg_2_nuevo_contrato.sql
mysql -u root -p < sp_1_registrar_contrato_arriendo.sql
mysql -u root -p < sp_2_registrar_pago.sql
mysql -u root -p < sp_3_cambiar_estado_propiedad.sql
mysql -u root -p < v1_propiedades_disponibles.sql
mysql -u root -p < v2_contratos_activos.sql
mysql -u root -p < v3_deuda_comisiones.sql
mysql -u root -p < evento_mensual_v2.sql
mysql -u root -p < usuarios_roles.sql
mysql -u root -p < optimizacion_indices.sql
```

---

## 15. Datos de Prueba

El script `modelo_fisico.sql` incluye datos de prueba para todas las tablas:

| Tabla | Registros |
|---|---|
| Ciudad | 5 (Bucaramanga, Medellín, Bogotá, Cali, Barranquilla) |
| Barrio | 6 |
| TipoPropiedad | 3 (Apartamento, Casa, Local Comercial) |
| EstadoPropiedad | 3 (Disponible, Arrendada, Vendida) |
| EstadoPago | 3 (Pagado, Pendiente, Vencido) |
| Rol | 4 (Administrador, Agente, Cliente, Contador) |
| Personas | 9 |
| Clientes | 6 |
| Agentes | 3 |
| UsuarioSistema | 9 |
| Propiedad | 6 |
| Contratos | 6 (3 arriendos + 3 ventas) |
| ContratoArriendo | 3 |
| ContratoVenta | 3 |
| Pagos | 9 (estados variados: pagado, pendiente, vencido) |

### IDs de referencia rápida

```
Clientes : CLI-01 (Carlos Ruiz) ... CLI-06 (Elena Cruz)
Agentes  : AGE-01 (María López, 5%) | AGE-02 (Pedro Gómez, 3%) | AGE-03 (Juan Ríos, 3%)
Contratos: CON-001 Arriendo | CON-002 Venta | CON-003 Arriendo
           CON-004 Venta    | CON-005 Arriendo | CON-006 Venta
Propiedad disponible: PROP-05 (Calle 9 #22-10, Apartamento, San Antonio, Cali)
```

---

## 16. Errores Conocidos y Soluciones

| Error | Causa | Solución aplicada |
|---|---|---|
| **Error 1064** en trigger | Subquery `SELECT COUNT(*) FROM AuditoriaContrato` dentro del trigger | Reemplazado por `UNIX_TIMESTAMP(NOW(6))` para generar IDs únicos |
| **Error 1308** `LEAVE` sin etiqueta | `LEAVE sp_nombre` requiere etiqueta declarada en `BEGIN` | Agregado `proc_label: BEGIN ... END proc_label` en los 3 SPs |
| **Error 1452** FK violation en pruebas | IDs hardcodeados ya usados o propiedad no disponible | Pruebas reemplazadas por procedures dinámicos que detectan IDs libres |
| **Error 1553** no puede borrar índice FK | `DROP INDEX IF EXISTS` sobre índices de FK | Eliminado el DROP — solo se crean índices adicionales con verificación previa |
| **Error 1064** `DROP INDEX IF EXISTS` | Sintaxis no válida en MySQL para índices | Reemplazado por `ALTER TABLE ... DROP INDEX` dentro de procedure con verificación |

---

## 17. Estado del Proyecto

| Componente | Estado |
|---|---|
| ✅ Modelo físico (DDL + DML) | Completado |
| ✅ Normalización 3FN | Completado |
| ✅ Función `fn_calcular_comision` | Completado |
| ✅ Función `fn_calcular_deuda_pendiente` | Completado |
| ✅ Función `fn_total_disponibles_por_tipo` | Completado |
| ✅ Trigger cambio estado propiedad | Completado |
| ✅ Trigger nuevo contrato | Completado |
| ✅ SP registrar contrato arriendo | Completado |
| ✅ SP registrar pago | Completado |
| ✅ SP cambiar estado propiedad | Completado |
| ✅ Vista propiedades disponibles | Completado |
| ✅ Vista contratos activos | Completado |
| ✅ Vista deuda arriendos y comisiones | Completado |
| ✅ Evento programado mensual | Completado |
| ✅ Usuarios y roles | Completado |
| ✅ Optimización e índices | Completado |
| ✅ SP registrar contrato de venta | Completado |
| ✅ SP eliminar / cancelar contrato | Completado |
| ✅ Procedimiento de cierre de mes | Completado |

---

## 👨‍💻 Autor

**Santiago Monsalve**

