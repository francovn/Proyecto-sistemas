-- =====================================================================
--  Las 3 Delicias · consultas.sql — consultas de negocio
--  Requiere schema.sql + seed.sql. Motor: MySQL 8.0
--  @hoy fija la "fecha actual" para que los resultados sean reproducibles
--  (el seed llega hasta la mañana del 16-11-2026). En uso real: SET @hoy = CURDATE();
-- =====================================================================
USE las3delicias;
SET @hoy = DATE('2026-11-16');

-- ---------------------------------------------------------------------
-- C1. ¿Qué insumos hay que comprar? (RF06, RF08, RF09)
--     Stock actual vs mínimo semanal. El mínimo efectivo es el mayor entre el
--     mínimo definido y el consumo real de los últimos 7 días.
-- ---------------------------------------------------------------------
WITH stock AS (
  SELECT id_insumo, SUM(cantidad_actual) AS stock_actual
  FROM lote_insumo GROUP BY id_insumo
), consumo7 AS (
  SELECT id_insumo, SUM(cantidad) AS consumo_7d
  FROM movimiento_insumo
  WHERE tipo IN ('consumo','uso') AND fecha_hora >= @hoy - INTERVAL 7 DAY AND fecha_hora < @hoy
  GROUP BY id_insumo
)
SELECT i.nombre AS insumo,
       u.abreviatura AS unidad,
       ROUND(COALESCE(s.stock_actual,0),2)                               AS stock_actual,
       i.stock_minimo_semanal                                            AS minimo_definido,
       ROUND(COALESCE(c.consumo_7d,0),2)                                 AS consumo_ult_7_dias,
       ROUND(GREATEST(i.stock_minimo_semanal, COALESCE(c.consumo_7d,0)) - COALESCE(s.stock_actual,0),2) AS cantidad_a_comprar
FROM insumo i
JOIN unidad_medida u ON u.id_unidad = i.id_unidad
LEFT JOIN stock s    ON s.id_insumo = i.id_insumo
LEFT JOIN consumo7 c ON c.id_insumo = i.id_insumo
WHERE COALESCE(s.stock_actual,0) < GREATEST(i.stock_minimo_semanal, COALESCE(c.consumo_7d,0))
ORDER BY COALESCE(s.stock_actual,0) / GREATEST(i.stock_minimo_semanal, COALESCE(c.consumo_7d,0));

-- ---------------------------------------------------------------------
-- C2. ¿Qué falta en la vitrina y se puede reponer desde bodega?
-- ---------------------------------------------------------------------
SELECT producto, minimo_vitrina, en_tienda, en_bodega,
       CASE WHEN en_bodega > 0 THEN 'Reponer desde bodega' ELSE 'Producir' END AS accion
FROM (
  SELECT p.nombre AS producto,
         p.stock_minimo_tienda AS minimo_vitrina,
         ROUND(COALESCE(SUM(CASE WHEN l.ubicacion='tienda' THEN l.cantidad_actual END),0),2) AS en_tienda,
         ROUND(COALESCE(SUM(CASE WHEN l.ubicacion='bodega' THEN l.cantidad_actual END),0),2) AS en_bodega
  FROM producto p
  LEFT JOIN lote_producto l ON l.id_producto = p.id_producto
  WHERE p.stock_minimo_tienda > 0
  GROUP BY p.id_producto, p.nombre, p.stock_minimo_tienda
) t
WHERE en_tienda < minimo_vitrina
ORDER BY en_tienda / minimo_vitrina;

-- ---------------------------------------------------------------------
-- C3. Lotes que vencen en 5 días o menos (aviso anticipado de vencimiento).
--     Insumos: hasta 5 días. Productos (vida útil corta): solo los de 0 a 2 días; el total está en C3b.
-- ---------------------------------------------------------------------
SELECT 'Insumo' AS tipo, i.nombre AS item, 'bodega' AS ubicacion, SUM(l.cantidad_actual) AS cantidad,
       u.abreviatura AS unidad, l.fecha_vencimiento, DATEDIFF(l.fecha_vencimiento, @hoy) AS dias_restantes
FROM lote_insumo l JOIN insumo i USING (id_insumo) JOIN unidad_medida u USING (id_unidad)
WHERE l.fecha_vencimiento IS NOT NULL AND DATEDIFF(l.fecha_vencimiento, @hoy) <= 5
GROUP BY i.nombre, u.abreviatura, l.fecha_vencimiento
UNION ALL
SELECT 'Producto', p.nombre, l.ubicacion, SUM(l.cantidad_actual), p.unidad_venta, l.fecha_vencimiento,
       DATEDIFF(l.fecha_vencimiento, @hoy)
FROM lote_producto l JOIN producto p USING (id_producto)
WHERE DATEDIFF(l.fecha_vencimiento, @hoy) <= 2          -- productos: se muestran los más urgentes (0 a 2 días)
GROUP BY p.nombre, l.ubicacion, p.unidad_venta, l.fecha_vencimiento
ORDER BY dias_restantes, tipo, item;

-- C3b. Resumen de C3 por tipo y días restantes (para el informe)
SELECT tipo, dias_restantes, COUNT(*) AS lotes
FROM (
  SELECT 'Insumo' AS tipo, DATEDIFF(fecha_vencimiento, @hoy) AS dias_restantes
  FROM lote_insumo WHERE fecha_vencimiento IS NOT NULL AND DATEDIFF(fecha_vencimiento, @hoy) <= 5
  UNION ALL
  SELECT 'Producto', DATEDIFF(fecha_vencimiento, @hoy)
  FROM lote_producto WHERE DATEDIFF(fecha_vencimiento, @hoy) <= 5
) t
GROUP BY tipo, dias_restantes ORDER BY tipo, dias_restantes;

-- ---------------------------------------------------------------------
-- C4. KPI compras imprevistas por semana y su sobrecosto
--     Semana 1 = sin sistema (AS-IS); semanas 2-3 = con alertas (TO-BE)
-- ---------------------------------------------------------------------
SELECT FLOOR(DATEDIFF(c.fecha, '2026-10-26') / 7) + 1 AS semana,
       MIN(c.fecha) AS desde,
       COUNT(DISTINCT c.id_compra) AS compras,
       COUNT(DISTINCT CASE WHEN NOT c.es_planificada THEN c.id_compra END) AS imprevistas,
       ROUND(100 * COUNT(DISTINCT CASE WHEN NOT c.es_planificada THEN c.id_compra END) / COUNT(DISTINCT c.id_compra), 1) AS pct_imprevistas,
       ROUND(SUM(d.cantidad * d.precio_unitario)) AS gasto_total_clp,
       ROUND(COALESCE(SUM(CASE WHEN NOT c.es_planificada THEN d.cantidad * d.precio_unitario END),0)) AS gasto_imprevisto_clp
FROM compra c JOIN detalle_compra d USING (id_compra)
WHERE c.fecha < @hoy
GROUP BY semana ORDER BY semana;

-- ---------------------------------------------------------------------
-- C5. Merma por producto: % de lo producido que se botó por vencimiento
-- ---------------------------------------------------------------------
SELECT * FROM (
  SELECT p.nombre AS producto, p.vida_util_dias,
         SUM(CASE WHEN m.tipo='produccion' THEN m.cantidad ELSE 0 END) AS producido,
         SUM(CASE WHEN m.tipo='merma'      THEN m.cantidad ELSE 0 END) AS merma,
         ROUND(100 * SUM(CASE WHEN m.tipo='merma' THEN m.cantidad ELSE 0 END)
                   / NULLIF(SUM(CASE WHEN m.tipo='produccion' THEN m.cantidad ELSE 0 END),0), 1) AS pct_merma
  FROM movimiento_producto m JOIN producto p USING (id_producto)
  WHERE m.fecha_hora < @hoy
  GROUP BY p.id_producto, p.nombre, p.vida_util_dias
) t
WHERE merma > 0
ORDER BY pct_merma DESC
LIMIT 10;

-- C5b. Merma total del período
SELECT ROUND(100 * SUM(CASE WHEN tipo='merma' THEN cantidad END) / SUM(CASE WHEN tipo='produccion' THEN cantidad END), 1) AS pct_merma_total
FROM movimiento_producto WHERE fecha_hora < @hoy;

-- ---------------------------------------------------------------------
-- C6. Insumos con mayor frecuencia de reposición (RF13)
-- ---------------------------------------------------------------------
SELECT i.nombre AS insumo,
       COUNT(*) AS veces_comprado,
       SUM(CASE WHEN NOT c.es_planificada THEN 1 ELSE 0 END) AS veces_imprevisto,
       ROUND(SUM(d.cantidad),2) AS cantidad_total,
       u.abreviatura AS unidad
FROM detalle_compra d
JOIN compra c USING (id_compra)
JOIN insumo i USING (id_insumo)
JOIN unidad_medida u USING (id_unidad)
WHERE c.fecha < @hoy
GROUP BY i.id_insumo, i.nombre, u.abreviatura
ORDER BY veces_comprado DESC, veces_imprevisto DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- C7. ¿Los mínimos semanales están bien calibrados?
--     Consumo real promedio por semana (por receta y uso) vs mínimo definido
-- ---------------------------------------------------------------------
SELECT * FROM (
  SELECT i.nombre AS insumo, u.abreviatura AS unidad,
         i.stock_minimo_semanal AS minimo_definido,
         ROUND(SUM(m.cantidad) / 3, 2) AS consumo_semanal_promedio,
         ROUND(SUM(m.cantidad) / 3 / NULLIF(i.stock_minimo_semanal,0), 2) AS veces_el_minimo
  FROM movimiento_insumo m
  JOIN insumo i USING (id_insumo)
  JOIN unidad_medida u USING (id_unidad)
  WHERE m.tipo IN ('consumo','uso') AND m.fecha_hora >= '2026-10-26' AND m.fecha_hora < @hoy
  GROUP BY i.id_insumo, i.nombre, u.abreviatura, i.stock_minimo_semanal
) t
WHERE veces_el_minimo > 1.2
ORDER BY veces_el_minimo DESC;

-- ---------------------------------------------------------------------
-- C8. Historial de un insumo (RF11): últimos movimientos de la harina
-- ---------------------------------------------------------------------
SELECT m.fecha_hora, m.tipo, m.cantidad, us.nombre AS usuario, m.motivo
FROM movimiento_insumo m
JOIN insumo i  USING (id_insumo)
JOIN usuario us USING (id_usuario)
WHERE i.nombre = 'Harina'
ORDER BY m.fecha_hora DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- C9. Conciliación (RF05 / KPI exactitud del inventario):
--     el stock en lotes debe ser igual a la suma del historial de movimientos.
--     Resultado esperado: 0 insumos y 0 productos descuadrados.
-- ---------------------------------------------------------------------
SELECT 'insumos' AS tabla, COUNT(*) AS descuadrados FROM (
  SELECT i.id_insumo,
         COALESCE((SELECT SUM(l.cantidad_actual) FROM lote_insumo l WHERE l.id_insumo = i.id_insumo),0) AS en_lotes,
         COALESCE((SELECT SUM(CASE WHEN m.tipo IN ('compra','ajuste') THEN m.cantidad ELSE -m.cantidad END)
                   FROM movimiento_insumo m WHERE m.id_insumo = i.id_insumo),0) AS segun_movimientos
  FROM insumo i) t
WHERE ABS(en_lotes - segun_movimientos) > 0.01
UNION ALL
SELECT 'productos', COUNT(*) FROM (
  SELECT p.id_producto,
         COALESCE((SELECT SUM(l.cantidad_actual) FROM lote_producto l WHERE l.id_producto = p.id_producto),0) AS en_lotes,
         COALESCE((SELECT SUM(CASE WHEN m.tipo IN ('produccion','ajuste') THEN m.cantidad
                                   WHEN m.tipo = 'reposicion' THEN 0 ELSE -m.cantidad END)
                   FROM movimiento_producto m WHERE m.id_producto = p.id_producto),0) AS segun_movimientos
  FROM producto p) t
WHERE ABS(en_lotes - segun_movimientos) > 0.01;
