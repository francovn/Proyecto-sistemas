# 03 – Consultas SQL de negocio

Motor: **MySQL Workbench 8.0 CE** (base `las3delicias`). Scripts: `db/schema.sql`, `db/seed.sql`, `db/consultas.sql`. Fecha de referencia del seed: **16-11-2026**.

## 1. Consultas de alerta (C1, C2, C3)

Las tres alimentan el correo diario de n8n (ver [`04-automatizacion-n8n.md`](04-automatizacion-n8n.md)). Se consolidan con `UNION ALL` en una salida de tres columnas: `tipo`, `item`, `detalle`.

Tablas y campos usados: `insumo(nombre, id_unidad, stock_minimo_semanal)`, `unidad_medida(abreviatura)`, `lote_insumo(cantidad_actual, fecha_vencimiento)`, `movimiento_insumo(tipo, cantidad, fecha_hora)`, `producto(nombre, stock_minimo_tienda)`, `lote_producto(ubicacion, cantidad_actual)`.

### C1 – Insumos a comprar (`tipo = 'Comprar'`)

- **Regla:** se alerta si `stock actual < mínimo efectivo`.
  - Stock actual = suma de `lote_insumo.cantidad_actual` del insumo (el stock no se guarda, se calcula).
  - Mínimo efectivo = `GREATEST(stock_minimo_semanal, consumo de los últimos 7 días)`. El consumo suma los movimientos `consumo` y `uso` desde `fecha − 7 días` hasta antes de `fecha`.
- **Cantidad sugerida:** mínimo efectivo − stock actual.
- **Interpretación:** convierte "compro lo que veo que falta" en una lista objetiva. Si el consumo reciente supera el mínimo definido a ojo, el sistema usa el consumo real.
- **Resultado al 16-11-2026 (6 insumos):**

| Insumo | Stock | Mínimo efectivo | Comprar |
|---|---|---|---|
| Coco rallado | 1,90 kg | 2,00 | 0,10 kg |
| Fruta confitada y pasas | 1,90 kg | 2,00 | 0,10 kg |
| Almendra | 0,00 kg | 1,10 | 1,10 kg |
| Manzana fresca | 2,90 kg | 13,00 | 10,10 kg |
| Leche evaporada | 0,40 kg | 3,00 | 2,60 kg |
| Yoghurt | 0,40 L | 2,00 | 1,60 L |

### C2 – Reposición de vitrina (`tipo = 'Vitrina'`)

- **Regla:** productos con `stock_minimo_tienda > 0` cuyo stock en `ubicacion = 'tienda'` es menor que ese mínimo.
- **Acción sugerida:** si hay stock en `bodega` → "reponer desde bodega"; si no → "producir".
- **Interpretación:** separa dos decisiones distintas, mover producto ya hecho o fabricar más. Evita vitrina vacía y sobreproducción.
- **Limitación:** solo verifica que haya algo en bodega, no que alcance para cubrir el faltante.
- **Resultado al 16-11-2026 (4 productos, todos "producir"):** Pastel individual surtido 19/20, Rollito dulce 9/12, Berlín manjar 9/12, Berlín crema pastelera 10/12.

### C3 – Vencimientos próximos de insumos (`tipo = 'Vence'`)

- **Regla:** lotes de insumo con `fecha_vencimiento` no nula y `DATEDIFF(fecha_vencimiento, fecha) <= 5`, agrupados por insumo y fecha.
- **Interpretación:** permite usar primero lo que vence antes y evitar merma.
- **Importante:** no hay cota inferior, así que **los lotes ya vencidos (días negativos) también aparecen**. Así no se pierde de vista un lote vencido que sigue en bodega.
- **Alcance:** la alerta cubre solo insumos. Los productos terminados (horizonte de 2 días) se revisan en la tarea BPMN «Revisar vencimientos y registrar merma».
- **Resultado al 16-11-2026 (3 insumos):** Arándano 0,100 kg (hoy), Crema para batir 2,420 L (3 días), Frutilla 7,000 kg (4 días).

## 2. Variantes de la consulta de alertas

Hay tres textos de la misma lógica. Solo cambian la fecha de referencia y el formato de salida.

| Archivo | Fecha | Salida | Uso |
|---|---|---|---|
| `…_n8n_consulta_alertas_workbench.sql` | fija `2026-11-16` | tabla: una fila por alerta | Revisión manual en Workbench; reproduce el seed |
| `…_n8n_consulta_alertas_json.sql` | fija `2026-11-16` | **una celda** `json_n8n` con un arreglo JSON (`JSON_ARRAYAGG` + `JSON_OBJECT`) | Obtener el JSON equivalente a los datos fijados del flujo |
| Consulta dentro del nodo MySQL del flujo | `CURDATE()` | tabla: una fila por alerta | Ejecución diaria real |

**Por qué existen:**

- **Fecha fija:** el seed está fechado en 16-11-2026. Con `CURDATE()` el resultado cambiaría cada día y el ayudante no podría repetir los 13 resultados de la defensa.
- **`_workbench`:** el formato tabular se revisa a simple vista en Workbench.
- **`_json`:** entrega todo el resultado en una celda, que se puede copiar como pin data de n8n. Ese resultado equivale a `…_n8n_datos_fijados_13_alertas.json`.
- **Nodo n8n:** el nodo MySQL devuelve filas y n8n las convierte en ítems, así que el flujo no necesita el formato JSON.


## 3. Otras consultas de negocio (C4–C9)

| Consulta | Pregunta de negocio | Resultado informado |
|---|---|---|
| C4 | ¿Qué proporción de las compras fue imprevista por semana? | S1 87,5 % ($390.759 imprevisto), S2 25 %, S3 0 % |
| C5 | ¿Qué productos tienen más merma sobre lo producido? | Total 2,0 %; kuchen grande 25–29 %, tres leches 25 %, berlín crema 23 % |
| C6 | ¿Qué insumos se reponen con más frecuencia? | Azúcar 10 compras (7 imprevistas), manjar 9, huevos 9 |
| C7 | ¿Los mínimos cubren el consumo semanal por receta? | El consumo supera al mínimo entre 1,9 y 7,7 veces |
| C8 | ¿Cuál es el historial de movimientos de un insumo? | Ejemplo: harina |
| C9 | ¿El stock por lotes cuadra con el historial? | 0 descuadres |

**Cautelas:** C4 no prueba que el cambio se deba solo al sistema. C5 mezcla unidades de venta distintas, por lo que se usan los porcentajes por producto. El período de C4 y C7 es de tres semanas.
