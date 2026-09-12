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

- Establecer niveles mínimos de stock.
- Identificar insumos que requieren reposición.
- Generar alertas de reposición.
- Mantener y consultar el historial de movimientos.
- Registrar información básica de las compras.
- Consultar materias primas con mayor frecuencia de reposición.

## Requerimientos no funcionales principales

El sistema deberá ser sencillo de utilizar, almacenar la información de forma persistente, validar los datos ingresados y poder ejecutarse localmente.

También se busca que las operaciones principales se realicen rápidamente y que el sistema sea compatible con navegadores web de uso habitual.
