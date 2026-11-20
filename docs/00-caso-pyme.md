# Requerimientos del sistema

## Actores principales

Los principales actores identificados son:

- Propietario/Administrador.
- Apoyo operativo/Hermano.
- Proveedor.

El propietario y su hermano serán los principales usuarios del sistema, ya que ambos participan en las compras y actividades operativas de la PYME.

## Alcance

El sistema estará enfocado principalmente en el control de materias primas e insumos.

Permitirá:

- registrar materias primas e insumos;
- registrar compras o entradas;
- registrar consumos o salidas;
- mantener actualizado el stock;
- consultar las existencias disponibles;
- establecer niveles mínimos de inventario;
- identificar materias primas que requieren reposición;
- mantener un historial de movimientos;
- apoyar las decisiones de compra.

Quedan fuera de esta primera propuesta funciones como gestión completa de ventas, pedidos por WhatsApp, comercio electrónico, facturación, contabilidad, recursos humanos y gestión de transporte.

## Requerimientos funcionales principales

### Must

- RF01: Registrar materias primas e insumos.
- RF02: Modificar información de materias primas.
- RF03: Registrar compras o entradas.
- RF04: Registrar consumos o salidas.
- RF05: Actualizar las existencias después de una entrada o salida.
- RF06: Consultar el stock disponible.

### Should

- RF07: Establecer niveles mínimos de stock.
- RF08: Identificar insumos que requieren reposición.
- RF09: Generar alertas de reposición.
- RF10: Mantener el historial de movimientos.
- RF11: Consultar el historial de movimientos.
- RF12: Registrar información básica de las compras.
- RF13: Consultar materias primas con mayor frecuencia de reposición.

### Nuevos en la Entrega 2

Derivan de incorporar el control de productos terminados y de vencimientos (ver [`00-caso-pyme.md`](00-caso-pyme.md)).

- RF14 (Must): Controlar el stock de productos terminados por ubicación (tienda y bodega).
- RF15 (Must): Avisar los vencimientos próximos (insumos a 5 días o menos).
- RF16 (Must): Descontar los insumos según la receta al registrar una producción.
- RF17 (Must): Reponer la vitrina desde bodega, sacando primero lo que vence antes.


### Trazabilidad con la solución

| Código | Evidencia |
|---|---|
| RF01–RF02 | Tabla `insumo` |
| RF03 | `compra`, `detalle_compra`, `lote_insumo` |
| RF04 | `movimiento_insumo` |
| RF05–RF06 | Stock = suma de lotes; consultas C1 y C9 |
| RF07–RF09 | `insumo.stock_minimo_semanal`; consulta C1; correo diario de n8n |
| RF10–RF11 | `movimiento_insumo`, `movimiento_producto`; consulta C8 |
| RF12–RF13 | `compra.es_planificada`; consulta C6 |
| RF14–RF17 | `lote_producto`, `receta`, `produccion`; consultas C2 y C3 |

## Requerimientos no funcionales principales

El sistema deberá ser sencillo de utilizar, almacenar la información de forma persistente, validar los datos ingresados y poder ejecutarse localmente.

También se busca que las operaciones principales se realicen rápidamente y que el sistema sea compatible con navegadores web de uso habitual.

En la Entrega 2 se suman: que el sistema sea reproducible siguiendo solo el `README.md` y que el acceso esté restringido a usuarios autorizados.
