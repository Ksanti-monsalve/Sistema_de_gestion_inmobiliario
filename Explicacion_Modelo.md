# Sistema de Gestión Inmobiliaria
### Resumen del Proceso de Solución

**Autor:** Santiago Monsalve  

---

## El Problema

Una inmobiliaria manejaba su información en hojas de cálculo y documentos físicos. Esto generaba datos duplicados, sin historial de cambios, sin control de pagos y sin restricción de acceso por rol.

---

## La Solución

Se construyó una base de datos relacional normalizada en 4 etapas:

---

### Etapa 1 — Análisis y Normalización

Se identificaron las entidades del negocio y se aplicaron las 3 formas normales:

- **1FN:** se atomizaron todos los datos. Campos como "teléfonos del cliente" o "tipo y barrio de la propiedad" que venían mezclados en una sola celda se separaron en columnas y tablas independientes.
- **2FN:** se eliminaron dependencias parciales. Datos de clientes, agentes y propiedades que se repetían en cada fila del contrato se extrajeron a sus propias tablas con PK propia.
- **3FN:** se eliminaron dependencias transitivas. Se crearon catálogos para estados y tipos, y se unificaron los datos de personas (nombre, apellido, email, teléfono) en una superentidad `Personas` compartida por clientes, agentes y usuarios.

**Resultado:** 18 tablas normalizadas sin redundancia de datos.

---

### Etapa 2 — Automatización de la Lógica de Negocio

- **3 Funciones UDF** para encapsular cálculos repetitivos: comisión del agente, deuda pendiente del arrendatario y disponibilidad de propiedades por tipo.
- **2 Triggers** para auditoría automática: cada cambio de estado en una propiedad y cada nuevo contrato quedan registrados sin intervención humana.
- **4 Stored Procedures** para registrar contratos de arriendo, contratos de venta, pagos y cambios de estado — todos con transacciones atómicas que garantizan rollback completo ante cualquier fallo.

---

### Etapa 3 — Acceso y Consulta

- **4 Vistas** que simplifican las consultas más frecuentes: propiedades disponibles, contratos activos, deuda de arriendos y comisiones por agente.
- **1 Evento programado** que genera el reporte mensual de pagos pendientes automáticamente cada día 1 del mes.
- **4 Usuarios MySQL** con privilegios estrictamente segmentados: administrador, agente, contador y cliente — cada uno accede solo a lo que necesita.

---

### Etapa 4 — Optimización y Escalabilidad

- **13 índices adicionales** sobre las columnas más consultadas en `WHERE`, `JOIN` y `ORDER BY`, incluyendo índices compuestos para filtros combinados frecuentes.
- **Particionamiento RANGE** en la tabla `ReportePagos` por año de `Fecha_Reporte`, permitiendo que las consultas lean solo la partición del período relevante en lugar de recorrer toda la tabla.

---

## Resultado Final

| Componente | Cantidad |
|---|---|
| Tablas normalizadas (3FN) | 18 |
| Funciones UDF | 3 |
| Triggers | 2 |
| Stored Procedures | 4 |
| Vistas | 4 |
| Evento programado | 1 |
| Usuarios y roles | 4 |
| Índices adicionales | 13 |
| Tablas particionadas | 1 |

---

## Santiago Monsalve