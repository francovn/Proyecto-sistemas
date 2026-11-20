-- Consulta del nodo 'Consultar alertas (MySQL)' del flujo n8n, con la fecha del seed fija (16-11-2026).
USE las3delicias;
SELECT 'Comprar' AS tipo, i.nombre AS item,
       CONCAT('Hay ', ROUND(COALESCE(s.stock,0),2), ' ', u.abreviatura, ' de ', ROUND(GREATEST(i.stock_minimo_semanal, COALESCE(c.c7,0)),2), ' (comprar ',
              ROUND(GREATEST(i.stock_minimo_semanal, COALESCE(c.c7,0)) - COALESCE(s.stock,0),2), ' ', u.abreviatura, ')') AS detalle
FROM insumo i JOIN unidad_medida u ON u.id_unidad = i.id_unidad
LEFT JOIN (SELECT id_insumo, SUM(cantidad_actual) stock FROM lote_insumo GROUP BY id_insumo) s ON s.id_insumo = i.id_insumo
LEFT JOIN (SELECT id_insumo, SUM(cantidad) c7 FROM movimiento_insumo WHERE tipo IN ('consumo','uso') AND fecha_hora >= DATE('2026-11-16') - INTERVAL 7 DAY AND fecha_hora < DATE('2026-11-16') GROUP BY id_insumo) c ON c.id_insumo = i.id_insumo
WHERE COALESCE(s.stock,0) < GREATEST(i.stock_minimo_semanal, COALESCE(c.c7,0))
UNION ALL
SELECT 'Vitrina', producto, CONCAT('Hay ', en_tienda, ' de ', minimo, IF(en_bodega > 0, CONCAT(' (reponer desde bodega: ', en_bodega, ')'), ' (producir)'))
FROM (SELECT p.nombre producto, p.stock_minimo_tienda minimo,
             ROUND(COALESCE(SUM(CASE WHEN l.ubicacion='tienda' THEN l.cantidad_actual END),0),2) en_tienda,
             ROUND(COALESCE(SUM(CASE WHEN l.ubicacion='bodega' THEN l.cantidad_actual END),0),2) en_bodega
      FROM producto p LEFT JOIN lote_producto l ON l.id_producto = p.id_producto
      WHERE p.stock_minimo_tienda > 0 GROUP BY p.id_producto, p.nombre, p.stock_minimo_tienda) t
WHERE en_tienda < minimo
UNION ALL
SELECT 'Vence', i.nombre, CONCAT(SUM(l.cantidad_actual), ' ', u.abreviatura, ' vence el ', DATE_FORMAT(l.fecha_vencimiento,'%d-%m'), ' (', DATEDIFF(l.fecha_vencimiento, DATE('2026-11-16')), ' días)')
FROM lote_insumo l JOIN insumo i ON i.id_insumo = l.id_insumo JOIN unidad_medida u ON u.id_unidad = i.id_unidad
WHERE l.fecha_vencimiento IS NOT NULL AND DATEDIFF(l.fecha_vencimiento, DATE('2026-11-16')) <= 5
GROUP BY i.nombre, u.abreviatura, l.fecha_vencimiento;
