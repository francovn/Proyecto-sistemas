# Caso PYME

## Las 3 Delicias

Las 3 Delicias es una pequeña empresa ubicada en Quilicura, dedicada a la elaboración y venta de pasteles y masas.

El negocio funciona principalmente con el propietario y su hermano, quienes participan en actividades como compra de insumos, producción, atención de pedidos y comercialización.

## Problema identificado

Actualmente no existe un sistema centralizado para controlar el inventario de materias primas.

Las cantidades disponibles se revisan principalmente de manera visual y las compras se realizan de acuerdo con los insumos que se observa que están faltando.

Esta forma de trabajo puede generar:

- quiebres de stock;
- compras imprevistas;
- problemas de coordinación entre quienes realizan las compras;
- dificultad para planificar las compras y producción;
- falta de información histórica del inventario.

## Solución propuesta

Se propone desarrollar un sistema de información que permita registrar las materias primas, sus entradas y consumos, manteniendo actualizado el stock disponible y apoyando las decisiones de compra y reposición.

## Alcance de la Entrega 2

El caso es el mismo de la Entrega 1. En E2 el alcance creció desde el control de insumos hacia el control de **productos terminados**, porque en la validación con el propietario la merma de los productos con crema resultó ser tan relevante como los quiebres de insumos.

Lo que se agregó:

- control de productos terminados por **ubicación** (tienda y bodega) y por **lote con fecha de vencimiento**;
- aviso de vencimiento a 5 días para los insumos;
- descuento de insumos según la **receta** al registrar una producción;
- **reposición de vitrina** desde bodega;
- proveedores de referencia: La Vega Central y Lo Valledor.

La solución se materializa en una base de datos MySQL en 3FN (`db/`), consultas de negocio, una alerta diaria automática en n8n (`docs/automatizacion/`) y una página web de uso interno, cuyas capturas (de una versión anterior) están en `docs/pagina-web/`. La página no se publica por solicitud del propietario. La trazabilidad completa está en [`CHANGELOG.md`](../CHANGELOG.md).

## Datos del caso

El catálogo, las recetas y los mínimos provienen de un levantamiento con la PYME. Las compras, producciones y movimientos de las tres semanas de prueba (26-10 a 15-11-2026) y la mañana del 16-11-2026 son **sintéticos coherentes con el caso**.
