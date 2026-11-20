# Sistema de gestión de inventario – Las 3 Delicias

Proyecto de la asignatura **ICN-292 Sistemas de Información para la Gestión** (UTFSM, 2026-2), Grupo 13, Paralelo 100. Entrega 2 (E2): solución SIG final.

## 1. PYME y problema

Las 3 Delicias es una pastelería de Quilicura atendida por su propietario y su hermano. Antes del proyecto no había registro de inventario: el stock de insumos y productos se revisaba a ojo y se compraba "lo que se ve que falta". Efectos: quiebres de stock, compras imprevistas con sobreprecio y merma de productos con crema.

La solución es un SIG con tres componentes:

1. **Base de datos MySQL en 3FN** (13 tablas): insumos y productos por lote con vencimiento, recetas, compras, producción y movimientos.
2. **Consultas de negocio** (C1–C9) sobre esa base.
3. **Automatización en n8n**: cada día a las 07:00 envía al propietario un correo con insumos por comprar, productos bajo el mínimo de vitrina e insumos que vencen en 5 días o menos.

## 2. Estructura del repositorio

```text
.
├── README.md                     # Este archivo (prueba de oro)
├── CHANGELOG.md                  # Cambios E1 → E2
├── db/                                                               
│   ├── schema.sql                # Crea la base y las 13 tablas (PK, FK, UNIQUE, CHECK)
│   ├── seed.sql                  # Datos de prueba 
│   └── consultas.sql             # Consultas de negocio C1–C9
├── docs/
│   ├── 00-caso-pyme.md
│   ├── 01-requerimientos.md
│   ├── 02-bpmn.md                # BPMN AS-IS / TO-BE y cambios vs. E1
│   ├── 03-modelo-datos.md        # ER 3FN, diccionario de datos
│   ├── 04-sql-consultas.md       # Consultas interpretadas (C1–C3 de alertas en detalle)
│   ├── 05-automatizacion-n8n.md  # Flujo n8n trazado al BPMN TO-BE
│   ├── 06-acta-entrevista.md     # Respaldo de la entrevista al propietario
│   ├── DECLARACION_IA.md
│   └── assets/                   # Diagramas (.png/.bpm), ER, imagen del acta
├── automatizacion/
│   ├── ICN292_P100_E2_Aspee_Suarez_Vargas_Garcia_Landerretche_n8n_flujo_alerta_inventario.json
│   ├── ICN292_P100_E2_Aspee_Suarez_Vargas_Garcia_Landerretche_n8n_codigo_nodo_estado_alertas.js
│   ├── ICN292_P100_E2_Aspee_Suarez_Vargas_Garcia_Landerretche_n8n_consulta_alertas_workbench.sql
│   ├── ICN292_P100_E2_Aspee_Suarez_Vargas_Garcia_Landerretche_n8n_consulta_alertas_json.sql
│   └── ICN292_P100_E2_Aspee_Suarez_Vargas_Garcia_Landerretche_n8n_datos_fijados_13_alertas.json
├── informe/
│   ├── ICN292_P100_E2_<apellidos>.pdf
│   └── ICN292_P100_E2_<apellidos>.docx
└── presentacion/
    └── ICN292_P100_E2_Grupo13.pptx
```

## 3. Prueba de oro: reproducir la solución desde cero

### Requisitos

- **MySQL Server 8.0.16 o superior** y **MySQL Workbench**. Se pide 8.0.16+ porque desde esa versión se hacen cumplir las restricciones `CHECK`, y las consultas usan `JSON_ARRAYAGG` (MySQL Workbench 8.0 CEL)
- **n8n** (nube o autoalojado) solo para el paso 5. 
- Un usuario MySQL con permiso para crear bases de datos.

### Pasos

1. **Crear la base y las tablas.** En MySQL Workbench: `File → Open SQL Script… → db/schema.sql` y ejecutar todo (⚡). Crea 13 tablas.
2. **Cargar los datos.** Abrir `db/seed.sql` y ejecutar todo. La fecha de referencia de los datos es **16-11-2026**.
3. **Ejecutar las consultas.**
   - `db/consultas.sql` → consultas C1–C9 (resultados interpretados en `docs/04-sql-consultas.md`).
   - `automatizacion/…_n8n_consulta_alertas_workbench.sql` → las 13 alertas del día de referencia (6 insumos por comprar, 4 productos bajo mínimo de vitrina, 3 insumos por vencer).
   - Resultado esperado: coincide con `automatizacion/…_n8n_datos_fijados_13_alertas.json`.
4. **Levantar el flujo n8n.** Instrucciones completas en [`docs/05-automatizacion-n8n.md`](docs/05-automatizacion-n8n.md). Resumen:
   1. En n8n: `Workflows → Import from file →` `automatizacion/…_n8n_flujo_alerta_inventario.json`.
   2. Crear las credenciales **MySQL las3delicias** (host, puerto, base `las3delicias`, usuario) y **SMTP alertas**, y asignarlas a los nodos *Consultar alertas (MySQL)* y *Enviar correo al dueño*.
   3. Cambiar el destinatario (`correo-del-propietario@ejemplo.cl`) y el remitente en el nodo de correo.
   4. Ejecutar con *Execute workflow*. El nodo MySQL trae los datos fijados (pin data) de las 13 alertas: el resto del flujo corre sin tocar la base.
   5. Para una corrida real, quitar el pin data y activar el flujo (*Active*). Ojo: la consulta del nodo usa `CURDATE()`, por lo que sobre el seed (fijo en 16-11-2026) devolverá alertas distintas a las de la defensa.

### Resultados de referencia

| Verificación | Esperado |
|---|---|
| Tablas creadas | 13 |
| Alertas del 16-11-2026 | 13 (6 Comprar, 4 Vitrina, 3 Vence) |
| Compras imprevistas S1 / S2 / S3 (C4) | 87,5 % / 25 % / 0 % |
| Descuadres stock vs. historial (C9) | 0 |

## 4. Documentación

| Documento | Contenido |
|---|---|
| [`docs/00-caso-pyme.md`](docs/00-caso-pyme.md) | Caso y problema |
| [`docs/01-requerimientos.md`](docs/01-requerimientos.md) | RF / RNF |
| [`docs/02-bpmn.md`](docs/02-bpmn.md) | BPMN AS-IS / TO-BE y cambios |
| [`docs/03-modelo-datos.md`](docs/03-modelo-datos.md) | ER 3FN y diccionario |
| [`docs/04-sql-consultas.md`](docs/04-sql-consultas.md) | Consultas de negocio interpretadas |
| [`docs/05-automatizacion-n8n.md`](docs/05-automatizacion-n8n.md) | Flujo n8n ↔ BPMN |
| [`docs/06-acta-entrevista.md`](docs/06-acta-entrevista.md) | Entrevista al propietario |
| [`docs/DECLARACION_IA.md`](docs/DECLARACION_IA.md) | Uso de IA |
| [`CHANGELOG.md`](CHANGELOG.md) | Cambios desde E1 |

## 5. Datos y limitaciones

- El catálogo, las recetas y los mínimos provienen de la PYME. Las compras, producciones y movimientos iniciales son **sintéticos coherentes con el caso**, más movimientos reales incorporados después. 
- El estado de las alertas (nueva / pendiente / cerrada) vive en la memoria del flujo n8n, no en la base de datos.
- Aplicación web: 

## 6. Integrantes y roles

- Martín Aspee: analista de datos y modelamiento de la solución.
- Javiera Suárez: vinculación con la PYME y análisis de procesos.
- Franco Vargas: GitHub y documentación técnica.
- Benjamín García: requerimientos y modelamiento BPMN 2.0.
- Maite Landerretche: documentación y coordinación de procesos.
