# 📖 Proceso de Solución — Sistema de Gestión Inmobiliaria

### Cómo se identificó el problema, se normalizó y se construyó la base de datos

**Autor:** Santiago Monsalve  
**Motor:** MySQL 8.0+  

---

## 📋 Tabla de Contenidos

1. [El Problema Original](#1-el-problema-original)
2. [Identificación de Entidades](#2-identificación-de-entidades)
3. [Normalización — Primera Forma Normal (1FN)](#3-normalización--primera-forma-normal-1fn)
4. [Normalización — Segunda Forma Normal (2FN)](#4-normalización--segunda-forma-normal-2fn)
5. [Normalización — Tercera Forma Normal (3FN)](#5-normalización--tercera-forma-normal-3fn)
6. [Modelo Físico Final](#6-modelo-físico-final)
7. [Funciones UDF — Lógica de Negocio](#7-funciones-udf--lógica-de-negocio)
8. [Triggers — Automatización y Auditoría](#8-triggers--automatización-y-auditoría)
9. [Stored Procedures — Operaciones Transaccionales](#9-stored-procedures--operaciones-transaccionales)
10. [Vistas — Consultas Predefinidas](#10-vistas--consultas-predefinidas)
11. [Evento Programado — Reporte Mensual](#11-evento-programado--reporte-mensual)
12. [Usuarios y Roles — Control de Acceso](#12-usuarios-y-roles--control-de-acceso)
13. [Índices — Optimización de Consultas](#13-índices--optimización-de-consultas)
14. [Particiones — Escalabilidad](#14-particiones--escalabilidad)
15. [Errores Encontrados y Cómo se Resolvieron](#15-errores-encontrados-y-cómo-se-resolvieron)
16. [Conclusiones](#16-conclusiones)

---

## 1. El Problema Original

Una empresa inmobiliaria manejaba su información en hojas de cálculo y documentos físicos. Esto generaba los siguientes problemas:

**Problemas identificados:**
- Los datos de un mismo cliente se repetían en múltiples contratos
- No existía diferencia entre un contrato de arriendo y uno de venta — todo estaba mezclado en una sola tabla plana
- El estado de una propiedad se actualizaba manualmente, generando inconsistencias
- No había historial de cambios — si una propiedad cambiaba de estado, se perdía el registro anterior
- Los pagos de arriendo no tenían seguimiento — no se sabía quién debía, cuánto ni desde cuándo
- Las comisiones de los agentes se calculaban a mano con riesgo de error
- No había control de quién podía ver o modificar qué información

**Objetivo:** Diseñar una base de datos relacional normalizada que resolviera todos estos problemas con consistencia, trazabilidad y control de acceso.

---

## 2. Identificación de Entidades

El primer paso fue leer el problema y extraer los **sustantivos** — cada sustantivo relevante se convierte en una posible entidad:

```
Texto del problema:
"La inmobiliaria gestiona propiedades (casas, apartamentos, locales)
que pueden ser arrendadas o vendidas a clientes, gestionadas por agentes
que reciben una comisión. Se registran pagos mensuales y se necesita
saber en todo momento el estado de cada propiedad."

Entidades identificadas:
→ Propiedad        (lo que se arrienda o vende)
→ Cliente          (quien arrienda o compra)
→ Agente           (quien gestiona el contrato)
→ Contrato         (el acuerdo entre cliente y empresa)
→ Pago             (el dinero mensual del arriendo)
→ Ciudad / Barrio  (la ubicación de la propiedad)
```

Luego se identificaron los **atributos** de cada entidad y las **relaciones** entre ellas:

| Relación | Descripción |
|---|---|
| Un cliente puede tener varios contratos | 1:N |
| Un agente gestiona varios contratos | 1:N |
| Una propiedad puede tener varios contratos en el tiempo | 1:N |
| Un contrato puede ser de arriendo O de venta (no ambos) | especialización |
| Un contrato de arriendo tiene varios pagos | 1:N |
| Una ciudad tiene varios barrios | 1:N |
| Un barrio tiene varias propiedades | 1:N |

---

## 3. Normalización — Primera Forma Normal (1FN)

### ¿Qué exige la 1FN?
> Todos los atributos deben ser **atómicos** (indivisibles). No puede haber grupos repetitivos ni listas dentro de una celda.

### Tabla inicial sin normalizar (ejemplo del problema):

| Contrato_ID | Cliente | Teléfonos_Cliente | Propiedad | Tipo_Contrato | Valor | Agente | Pagos_Realizados |
|---|---|---|---|---|---|---|---|
| C001 | Carlos Ruiz | 3001234, 3109876 | Calle 5 #10, Apto, Chapinero | Arriendo | 800000 | María López | Ene✓, Feb✗, Mar✓ |
| C002 | Ana Torres | 3205555 | Cra 15 #20, Casa, Laureles | Venta | 320000000 | Pedro Gómez | — |

**Problemas que viola la 1FN:**
- `Teléfonos_Cliente` contiene múltiples valores separados por coma → **no atómico**
- `Propiedad` mezcla dirección, tipo y barrio en una sola celda → **no atómico**
- `Pagos_Realizados` es un grupo repetitivo con estados mezclados → **no atómico**

### Solución aplicada para cumplir 1FN:

Cada atributo compuesto se separó en columnas independientes o en tablas propias:

```
Teléfonos_Cliente     → tabla Personas con una columna Telefono
Propiedad (compuesta) → tabla Propiedad con columnas separadas:
                        Direccion, TipoP_ID, Barrio_ID
Pagos_Realizados      → tabla Pagos con una fila por cada pago:
                        Pago_ID, Contrato_ID, Fecha_Pago, EstadoPago_ID
```

**Resultado tras 1FN:** cada celda tiene un único valor atómico, sin listas ni campos compuestos.

---

## 4. Normalización — Segunda Forma Normal (2FN)

### ¿Qué exige la 2FN?
> Cumplir 1FN y que todos los atributos **no clave** dependan de **toda la clave primaria**, no solo de una parte de ella. Aplica cuando la PK es compuesta.

### Problema detectado:

Después de la 1FN quedó una tabla `Contratos` grande con PK compuesta `(Contrato_ID, Fecha_Pago)`:

| Contrato_ID | Fecha_Pago | Monto | Cliente_Nombre | Cliente_Ciudad | Agente_Nombre | Agente_Comision | Propiedad_Tipo |
|---|---|---|---|---|---|---|---|
| C001 | 2024-01-01 | 800000 | Carlos Ruiz | Bucaramanga | María López | 5% | Apartamento |
| C001 | 2024-02-01 | 800000 | Carlos Ruiz | Bucaramanga | María López | 5% | Apartamento |

**Dependencias parciales encontradas:**
- `Cliente_Nombre`, `Cliente_Ciudad` dependen solo de `Contrato_ID`, no de `Fecha_Pago` → **dependencia parcial**
- `Agente_Nombre`, `Agente_Comision` dependen solo de `Contrato_ID` → **dependencia parcial**
- `Propiedad_Tipo` depende solo de `Contrato_ID` → **dependencia parcial**
- Solo `Monto` depende de `(Contrato_ID, Fecha_Pago)` juntos

### Solución aplicada para cumplir 2FN:

Cada grupo de atributos con dependencia parcial se extrajo a su propia tabla:

```
Datos del cliente    → tabla Clientes  (Cliente_ID como PK)
Datos del agente     → tabla Agentes   (Agente_ID como PK)
Datos de propiedad   → tabla Propiedad (Propiedad_ID como PK)
Pagos del contrato   → tabla Pagos     (Pago_ID como PK, Contrato_ID como FK)
```

**Resultado tras 2FN:** ningún atributo depende de solo una parte de una clave compuesta. Cada tabla tiene una PK simple y sus atributos dependen completamente de ella.

---

## 5. Normalización — Tercera Forma Normal (3FN)

### ¿Qué exige la 3FN?
> Cumplir 2FN y que no existan **dependencias transitivas**: ningún atributo no clave debe depender de otro atributo no clave.

### Problemas detectados:

**Dependencia transitiva 1 — Ubicación de la propiedad:**
```
Propiedad_ID → Barrio_Nombre → Ciudad_Nombre → Departamento
```
`Ciudad_Nombre` y `Departamento` dependen de `Barrio_Nombre`, no directamente de `Propiedad_ID`.

**Dependencia transitiva 2 — Datos de personas:**
```
Contrato_ID → Cliente_ID → Nombre, Apellido, Email, Telefono
Contrato_ID → Agente_ID  → Nombre, Apellido, Email, Telefono
```
`Nombre`, `Email` y `Telefono` son exactamente los mismos atributos para clientes y agentes. Tenerlos duplicados en dos tablas genera redundancia y riesgo de inconsistencia.

**Dependencia transitiva 3 — Descripción de estados:**
```
Propiedad_ID → EstadoP_ID → Descripcion_Estado
```
La descripción `'Disponible'`, `'Arrendada'`, `'Vendida'` depende de `EstadoP_ID`, no de `Propiedad_ID`.

### Solución aplicada para cumplir 3FN:

```
Ciudad y Barrio separados:
  Ciudad   (Ciudad_ID, Nombre_Ciudad, Departamento)
  Barrio   (Barrio_ID, Nombre_Barrio, Ciudad_ID FK)
  Propiedad → solo guarda Barrio_ID

Superentidad Personas:
  Personas  (Persona_ID, Nombre, Apellido, Email, Telefono)
  Clientes  (Cliente_ID, Persona_ID FK)   ← extiende Personas
  Agentes   (Agente_ID,  Persona_ID FK, Comision_Pct)

Catálogos para estados y tipos:
  EstadoPropiedad (EstadoP_ID, Descripcion)
  TipoPropiedad   (TipoP_ID,  Descripcion)
  EstadoPago      (EstadoPago_ID, Descripcion)
  Rol             (Rol_ID, Nombre_Rol)
```

**Resultado tras 3FN:** no existen dependencias transitivas. Cada atributo depende única y directamente de la clave primaria de su tabla.

### Decisión de diseño adicional — Especialización de Contratos:

Un contrato de arriendo y uno de venta comparten datos base (cliente, agente, propiedad, fecha) pero tienen atributos completamente distintos:

```
Arriendo necesita: Valor_Mensual, Fecha_Inicio, Fecha_Fin
Venta    necesita: Precio_Venta, Comision_Venta, Fecha_Escritura
```

Mezclarlos en una sola tabla generaría muchos `NULL`. La solución fue la **especialización**:

```
Contratos        (datos comunes + Tipo_Contrato ENUM)
ContratoArriendo (Contrato_ID FK, Valor_Mensual, Fecha_Inicio, Fecha_Fin)
ContratoVenta    (Contrato_ID FK, Precio_Venta, Comision_Venta, Fecha_Escritura)
```

---

## 6. Modelo Físico Final

Tras aplicar las tres formas normales el modelo quedó con **18 tablas** organizadas en 7 grupos:

```
┌─────────────────────────────────────────────────────┐
│  CATÁLOGOS (6 tablas)                               │
│  Ciudad, Barrio, TipoPropiedad,                     │
│  EstadoPropiedad, EstadoPago, Rol                   │
├─────────────────────────────────────────────────────┤
│  PERSONAS (4 tablas)                                │
│  Personas, Clientes, Agentes, UsuarioSistema        │
├─────────────────────────────────────────────────────┤
│  OPERACIONAL (5 tablas)                             │
│  Propiedad, Contratos,                              │
│  ContratoArriendo, ContratoVenta, Pagos             │
├─────────────────────────────────────────────────────┤
│  AUDITORÍA Y REPORTES (3 tablas)                    │
│  AuditoriaContrato, AuditoriaPropiedad,             │
│  ReportePagos                                       │
├─────────────────────────────────────────────────────┤
│  LOGS (2 tablas)                                    │
│  Logs_Cambios, Logs_Errores                         │
└─────────────────────────────────────────────────────┘
```

---

## 7. Funciones UDF — Lógica de Negocio

Se crearon 3 funciones para encapsular cálculos que se repiten en múltiples consultas, vistas y procedimientos.

### ¿Por qué funciones y no consultas directas?

Si el cálculo de comisión se escribe directamente en cada consulta, un cambio en la fórmula obliga a modificar todos los lugares donde aparece. Con una UDF se modifica en un solo lugar.

### `fn_calcular_comision`
**Problema que resuelve:** los agentes cobran un porcentaje distinto y calcularlo manualmente genera errores.
```sql
-- Fórmula: Precio_Venta × (Comision_Pct / 100)
-- Retorna 0 si el contrato no es de tipo Venta
SELECT fn_calcular_comision('CON-002');
→ 9,600,000
```

### `fn_calcular_deuda_pendiente`
**Problema que resuelve:** saber cuánto debe un arrendatario requería contar manualmente los meses impagos.
```sql
-- Fórmula: COUNT(pagos EPG-02 o EPG-03) × Valor_Mensual
-- Retorna 0 si el contrato no es de tipo Arriendo
SELECT fn_calcular_deuda_pendiente('CON-001');
→ 800,000
```

### `fn_total_disponibles_por_tipo`
**Problema que resuelve:** el área comercial necesitaba saber cuántas propiedades disponibles había por tipo para ofertar a clientes.
```sql
SELECT fn_total_disponibles_por_tipo('TP-01');
→ 1  (un apartamento disponible)
```

---

## 8. Triggers — Automatización y Auditoría

**Problema que resuelven:** cuando una propiedad cambia de estado o se registra un contrato nuevo, estos eventos antes se olvidaban registrar manualmente.

### `trg_cambio_estado_propiedad`

Cada vez que alguien hace `UPDATE` en `Propiedad.EstadoP_ID`, el trigger registra automáticamente quién cambió el estado, de qué a qué y cuándo — sin depender de que el desarrollador recuerde hacerlo.

```
UPDATE Propiedad SET EstadoP_ID = 'EP-02' WHERE Propiedad_ID = 'PROP-05'
   └──► INSERT automático en AuditoriaPropiedad
   └──► INSERT automático en Logs_Cambios
```

### `trg_nuevo_contrato`

Cuando se inserta un contrato nuevo, la propiedad debe quedar automáticamente como Arrendada o Vendida. Antes esto se olvidaba hacer, dejando propiedades "disponibles" que ya tenían contrato activo.

```
INSERT INTO Contratos (Tipo_Contrato = 'Arriendo', Propiedad_ID = 'PROP-05')
   └──► UPDATE Propiedad SET EstadoP_ID = 'EP-02'  ← automático
   └──► INSERT AuditoriaContrato                   ← automático
   └──► INSERT Logs_Cambios                        ← automático
```

**Error encontrado y solución:** los triggers originalmente usaban `SELECT COUNT(*) FROM AuditoriaContrato` para generar IDs secuenciales. MySQL prohíbe hacer SELECT sobre la misma tabla que recibe el INSERT dentro de un trigger (Error 1064). Se resolvió usando `UNIX_TIMESTAMP(NOW(6))` que genera IDs únicos sin consultar la tabla.

---

## 9. Stored Procedures — Operaciones Transaccionales

**Problema que resuelven:** registrar un contrato implica tocar varias tablas. Si el proceso falla a mitad, la base de datos queda en estado inconsistente. Los SPs envuelven todo en una transacción atómica.

### `sp_registrar_contrato_arriendo`

```
CALL sp_registrar_contrato_arriendo(...)
  ├── Valida: propiedad disponible, cliente existe, agente existe, valor > 0
  ├── INSERT Contratos        → dispara trg_nuevo_contrato
  ├── INSERT ContratoArriendo → guarda valor mensual y vigencia
  ├── INSERT Pagos            → crea el primer mes como Pendiente
  └── COMMIT o ROLLBACK completo si algo falla
```

### `sp_registrar_contrato_venta`

```
CALL sp_registrar_contrato_venta(...)
  ├── Valida: propiedad disponible, cliente existe, agente existe, precio > 0
  ├── Calcula comisión automáticamente: Precio × (Comision_Pct / 100)
  ├── INSERT Contratos     → dispara trigger → propiedad pasa a EP-03
  ├── INSERT ContratoVenta → guarda precio, comisión y fecha escritura
  ├── INSERT Pagos         → registra el pago de comisión como EPG-01
  └── COMMIT o ROLLBACK completo si algo falla
```

### `sp_registrar_pago`

Determina automáticamente si un pago queda como Pagado o Pendiente comparando el monto ingresado contra el valor mensual del contrato.

### `sp_cambiar_estado_propiedad`

Valida que el nuevo estado exista en el catálogo y sea diferente al actual antes de ejecutar el UPDATE. El trigger se encarga de la auditoría.

**Error encontrado y solución:** todos los SPs usaban `LEAVE sp_nombre_procedure` para salir anticipadamente en caso de error de validación. MySQL requiere que `LEAVE` apunte a una etiqueta declarada explícitamente (Error 1308). Se resolvió declarando `proc_label: BEGIN ... END proc_label` en cada SP.

---

## 10. Vistas — Consultas Predefinidas

**Problema que resuelven:** los usuarios finales no deben escribir JOINs de 6 tablas para consultar información básica.

### `v_propiedades_disponibles`
Filtra automáticamente `EstadoP_ID = 'EP-01'` y presenta tipo, barrio, ciudad y precio en una sola consulta lista para usar por el área comercial y los clientes.

### `v_contratos_activos`
Une `Contratos`, `Propiedad`, `Clientes`, `Agentes` y sus respectivas tablas de `Personas` en una sola vista que muestra toda la información de un contrato activo.

### `v_deuda_arriendos`
Usa `fn_calcular_deuda_pendiente()` para mostrar en tiempo real cuánto debe cada arrendatario, cuántos meses tiene pendientes y vencidos.

### `v_comisiones_agentes`
Usa `fn_calcular_comision()` para mostrar el ranking de agentes con el total de ventas gestionadas y las comisiones acumuladas.

---

## 11. Evento Programado — Reporte Mensual

**Problema que resuelve:** el área contable necesitaba un reporte de pagos pendientes cada inicio de mes. Antes lo generaban manualmente revisando cada contrato.

El evento `evt_reporte_mensual_pagos_pendientes` se ejecuta automáticamente el día 1 de cada mes a las 00:00 y genera el reporte en la tabla `ReportePagos` usando la UDF `fn_calcular_deuda_pendiente()`.

**Errores encontrados y soluciones durante el desarrollo:**

| Error | Causa | Solución |
|---|---|---|
| IDs `'EPG-02'` con formato incorrecto | Se usaba `'EPG-02'` cuando el modelo usaba el mismo formato | Verificar contra datos reales del modelo |
| `Tipo_Contrato = 'arriendo'` (minúsculas) | El ENUM usa mayúscula inicial | Cambiar a `'Arriendo'` |
| `HAVING SUM(Monto_Pago) > 0` | Los pagos pendientes tienen `Monto_Pago = 0` | Cambiar a `HAVING COUNT(Pago_ID) > 0` |
| `UUID_SHORT()` no cabía en `VARCHAR(10)` | Genera números de 18 dígitos | Usar formato compacto `R` + fecha + secuencia |

---

## 12. Usuarios y Roles — Control de Acceso

**Problema que resuelve:** todos usaban el mismo usuario de base de datos. Un contador podía borrar contratos y un cliente podía ver datos financieros de otros clientes.

Se crearon 4 usuarios MySQL con privilegios estrictamente definidos por rol:

| Usuario | Rol | Privilegios clave |
|---|---|---|
| `admin_inm` | Administrador | `ALL PRIVILEGES WITH GRANT OPTION` |
| `agente_inm` | Agente | INSERT/UPDATE en propiedades y contratos, SELECT en auditoría |
| `contador_inm` | Contador | INSERT/UPDATE en pagos, SELECT en reportes y logs |
| `cliente_inm` | Cliente | Solo SELECT en `v_propiedades_disponibles` |

**Decisión de diseño:** las tablas de auditoría (`AuditoriaContrato`, `AuditoriaPropiedad`) son de **solo lectura** para todos los roles — solo los triggers pueden escribir en ellas. Esto garantiza que el historial no pueda ser alterado manualmente.

---

## 13. Índices — Optimización de Consultas

**Problema que resuelve:** a medida que la base de datos crece, las consultas sin índices hacen un `full table scan` — revisan cada fila de la tabla aunque solo necesiten una.

**Criterio de selección:** se crearon índices adicionales solo sobre columnas que:
- Aparecen frecuentemente en cláusulas `WHERE`, `JOIN` u `ORDER BY`
- **No son FK** (MySQL ya crea índices automáticamente sobre columnas de clave foránea)

**Error encontrado y solución:**
El script original usaba `DROP INDEX IF EXISTS ... ON Tabla` — sintaxis que no existe en MySQL (Error 1064). El segundo intento usó `ALTER TABLE ... DROP INDEX` pero fallaba porque MySQL no permite eliminar índices usados por FK (Error 1553). La solución final fue un procedure auxiliar que verifica en `INFORMATION_SCHEMA.STATISTICS` antes de crear, sin intentar borrar nada.

**Índices compuestos clave creados:**

| Índice | Columnas | Uso |
|---|---|---|
| `idx_propiedad_tipo_estado` | `TipoP_ID, EstadoP_ID` | Búsqueda de "casas disponibles" |
| `idx_contratos_tipo_agente` | `Tipo_Contrato, Agente_ID` | Ranking de ventas por agente |
| `idx_pagos_contrato_estado` | `Contrato_ID, EstadoPago_ID` | UDF de deuda + evento mensual |

---

## 14. Particiones — Escalabilidad

**Problema que resuelve:** con el tiempo, tablas como `Pagos`, `Logs_Cambios` y las de auditoría acumulan miles de registros. Sin particiones, una consulta de pagos de 2024 revisa también todos los registros de 2022 y 2023 innecesariamente.

Se aplicó **particionamiento RANGE por año** en las 6 tablas de mayor crecimiento:

```
Pagos, ReportePagos, AuditoriaContrato,
AuditoriaPropiedad, Logs_Cambios, Logs_Errores
```

Cada tabla quedó dividida en particiones anuales (`p_tabla_2022`, `p_tabla_2023`, ..., `p_tabla_futuro`). Al consultar con `WHERE Fecha BETWEEN '2024-01-01' AND '2024-12-31'`, MySQL solo lee la partición `p_tabla_2024` — ignorando todos los demás años.

**Error encontrado y solución:**  
MySQL **no permite Foreign Keys en tablas particionadas** (Error 1506). El primer intento mantuvo las FK y falló. La solución fue eliminar las FK de las tablas a particionar antes de aplicar la partición. La integridad referencial queda garantizada por los Stored Procedures (que validan la existencia de registros padre antes de insertar) y los Triggers (que controlan los cambios de estado).

**Beneficio adicional:** eliminar un año entero de logs se hace con `ALTER TABLE Logs_Errores DROP PARTITION p_logserr_2022` — una operación instantánea versus un `DELETE` que podría tardar minutos en tablas grandes.

---

## 15. Errores Encontrados y Cómo se Resolvieron

A lo largo del desarrollo se encontraron 7 errores de MySQL. Cada uno enseñó algo importante sobre el motor:

| Error | Mensaje | Causa | Solución |
|---|---|---|---|
| **1064** en trigger | Syntax error | `SELECT COUNT(*) FROM AuditoriaContrato` dentro del trigger que inserta en la misma tabla | Reemplazar por `UNIX_TIMESTAMP(NOW(6))` para generar IDs únicos |
| **1308** en SP | LEAVE with no matching label | `LEAVE sp_nombre` sin etiqueta declarada | Agregar `proc_label: BEGIN ... END proc_label` |
| **1452** en pruebas (primera vez) | FK constraint fails | IDs hardcodeados `'CLI-01'` que no coincidían con los reales `'CLI-02'` | Reemplazar con procedures dinámicos que detectan IDs libres |
| **1452** en pruebas (segunda vez) | FK constraint fails | El fallback `'USR-01'` en triggers no existía en `UsuarioSistema` (el formato real es `'USR001'`) | Corregir el fallback al ID real del modelo |
| **1452** en pruebas (tercera vez) | FK constraint fails | No había propiedades disponibles al ejecutar la prueba de venta | El procedure de prueba ahora libera automáticamente una propiedad si no hay ninguna disponible |
| **1553** en índices | Cannot drop index needed in FK | `DROP INDEX` sobre un índice creado automáticamente por una FK | No borrar índices FK — solo crear índices adicionales con verificación previa |
| **1506** en particiones | FK not supported with partitioning | MySQL no permite FK y particiones en la misma tabla | Eliminar las FK antes de particionar — la integridad la garantizan los SPs y triggers |

---

## 16. Conclusiones

### ¿Qué se logró?

El sistema pasó de hojas de cálculo inconsistentes a una base de datos con:

- **18 tablas** normalizadas en 3FN sin redundancia de datos
- **3 funciones UDF** que encapsulan los cálculos de negocio
- **2 triggers** que garantizan auditoría automática sin intervención humana
- **4 stored procedures** con transacciones atómicas y validaciones completas
- **4 vistas** que simplifican el acceso a información compleja
- **1 evento mensual** que genera reportes automáticamente
- **4 usuarios** con privilegios estrictamente segmentados por rol
- **13 índices adicionales** que optimizan las consultas más frecuentes
- **6 tablas particionadas** por año para escalar sin degradar el rendimiento

### Lecciones aprendidas

**Sobre MySQL:**
- `LEAVE` requiere etiqueta explícita en `BEGIN` — no puede apuntar al nombre del procedure
- Los triggers no pueden hacer `SELECT COUNT(*)` sobre la misma tabla que reciben el `INSERT`
- Las tablas particionadas no pueden tener Foreign Keys
- `DROP INDEX IF EXISTS` no existe — hay que verificar en `INFORMATION_SCHEMA` primero

**Sobre diseño:**
- Normalizar no es solo eliminar redundancia — es garantizar que cada hecho se almacene en un solo lugar
- La superentidad `Personas` evita duplicar los mismos 4 atributos (nombre, apellido, email, teléfono) en cada tabla de persona
- La especialización de `Contratos` en `ContratoArriendo` y `ContratoVenta` evita tener una tabla llena de NULL
- Los catálogos (`EstadoPropiedad`, `TipoPropiedad`, `EstadoPago`) parecen innecesarios al inicio, pero son esenciales para mantener consistencia en los ENUMs y permitir filtros eficientes

