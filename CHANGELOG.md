# Changelog

## [v1.0-e2] –· Entrega 2 (solución SIG final)

### Agregado
- **Base de datos:** `db/schema.sql` (13 tablas con PK, FK, UNIQUE y CHECK) y `db/seed.sql` (datos de prueba con fecha de referencia 16-11-2026) y `db/consultas.sql` (C1–C9).
- **Automatización n8n** en `automatizacion/`:
  - flujo `…_n8n_flujo_alerta_inventario.json` (disparo diario 07:00 → consulta MySQL → estado de alertas → compuerta `If` → correo);
  - consultas de alertas `…_workbench.sql` y `…_json.sql`;
  - código del nodo de estado (`nueva` / `pendiente` / `cerrada`);
  - datos fijados de 13 alertas para probar sin base.
- **Modelo de datos:** nuevas tablas `lote_insumo`, `lote_producto`, `produccion`, `movimiento_insumo` y `movimiento_producto`. `docs/Las_3_Delicias_-_Modelo_ER_3FN_E2.png`.
- **Informe E2** en PDF y Word, y **presentación** para la defensa (≤7 min).
- **Documentación:** `docs/assets/bpmn.md`, `03-sql-consultas.md`, `04-automatizacion-n8n.md`, `DECLARACION_IA.md`, `CHANGELOG.md`.
- **Requerimientos nuevos (RF14–RF17):** stock por ubicación (tienda/bodega), aviso de vencimiento, descuento de insumos por receta y reposición de vitrina.

### Cambiado
- **BPMN TO-BE:** nuevo carril «Sistema (app web + n8n)». El abastecimiento parte con el temporizador diario de las 07:00 y la tarea «Generar alerta de inventario». Se agregan «Registrar producción», «Reponer vitrina desde bodega» y «Revisar vencimientos y registrar merma».
- **BPMN TO-BE, correcciones:**
  - unión posterior a la producción que habría ejecutado dos veces el registro;
  - bucle de alerta que volvía a una sola de las compras paralelas;
  - compuerta paralela cambiada por exclusiva en «¿Hay stock suficiente?» del subproceso de pedidos.
- **Modelo de datos:** se eliminó `stock_actual` (dato derivado); el stock se calcula sumando lotes. El movimiento único de E1 se separó en `movimiento_insumo` y `movimiento_producto`.
- **Mínimos:** el mínimo de cada insumo equivale al consumo de una semana (acordado con el propietario).
- **Stack:** de Python + Streamlit + SQLite (previsto en E1) a **MySQL** con aplicación web. 
- **README:** reescrito como guía de reproducción (prueba de oro).

### Eliminado
- Regla de precio por volumen y tarea «Almacenar insumos» del BPMN (fuera del control de inventario).
- Atributo `stock_actual` de `insumo`.

### Conservado de E1
- Caso y problema, actores (propietario, hermano, proveedores La Vega Central y Lo Valledor), requerimientos RF01–RF13 y RNF01–RNF07, KPI (compras imprevistas, exactitud del inventario, quiebres de stock).

## [v1.0-e1] – 2026-09 · Entrega 1 

- Caso PYME, requerimientos, acta de entrevista (11-09-2026), BPMN AS-IS y TO-BE, informe E1.
