-- =====================================================================
--  Las 3 Delicias · SIG de inventario — schema.sql
--  Motor: MySQL 8.0 (probado también en MariaDB 10.11)
--  Ejecutar en MySQL Workbench: File > Open SQL Script > ⚡ (Execute all)
--  Crea la base desde cero (borra la anterior si existe).
-- =====================================================================
DROP DATABASE IF EXISTS las3delicias;
CREATE DATABASE las3delicias CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE las3delicias;

-- ---------- Catálogos ----------
CREATE TABLE usuario (
  id_usuario  INT          NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(80)  NOT NULL,
  email       VARCHAR(120) NOT NULL,
  rol         VARCHAR(30)  NOT NULL,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uq_usuario_email (email),
  CONSTRAINT ck_usuario_rol CHECK (rol IN ('Propietario','Apoyo operativo'))
);

CREATE TABLE proveedor (
  id_proveedor INT          NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(80)  NOT NULL,
  direccion    VARCHAR(120) NULL,
  PRIMARY KEY (id_proveedor),
  UNIQUE KEY uq_proveedor_nombre (nombre)
);

CREATE TABLE unidad_medida (
  id_unidad   INT         NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(30) NOT NULL,
  abreviatura VARCHAR(10) NOT NULL,
  PRIMARY KEY (id_unidad),
  UNIQUE KEY uq_unidad_abrev (abreviatura)
);

CREATE TABLE insumo (
  id_insumo            INT           NOT NULL AUTO_INCREMENT,
  nombre               VARCHAR(120)  NOT NULL,
  categoria            ENUM('Ingrediente','Empaque') NOT NULL,
  id_unidad            INT           NOT NULL,
  stock_minimo_semanal DECIMAL(10,3) NOT NULL DEFAULT 0,
  vida_util_dias       INT           NULL,            -- NULL = no vence (empaques)
  PRIMARY KEY (id_insumo),
  UNIQUE KEY uq_insumo_nombre (nombre),
  CONSTRAINT fk_insumo_unidad FOREIGN KEY (id_unidad) REFERENCES unidad_medida(id_unidad),
  CONSTRAINT ck_insumo_min  CHECK (stock_minimo_semanal >= 0),
  CONSTRAINT ck_insumo_vida CHECK (vida_util_dias IS NULL OR vida_util_dias > 0)
);

CREATE TABLE producto (
  id_producto          INT           NOT NULL AUTO_INCREMENT,
  nombre               VARCHAR(120)  NOT NULL,
  categoria            VARCHAR(40)   NOT NULL,
  unidad_venta         ENUM('unidad','porcion','entera') NOT NULL,
  porciones_por_unidad INT           NOT NULL DEFAULT 1,   -- torta entera = 16, kuchen grande = 12
  stock_minimo_tienda  DECIMAL(10,3) NOT NULL DEFAULT 0,   -- mínimo en vitrina
  vida_util_dias       INT           NOT NULL,
  PRIMARY KEY (id_producto),
  UNIQUE KEY uq_producto_nombre (nombre),
  CONSTRAINT ck_prod_porciones CHECK (porciones_por_unidad >= 1),
  CONSTRAINT ck_prod_min  CHECK (stock_minimo_tienda >= 0),
  CONSTRAINT ck_prod_vida CHECK (vida_util_dias > 0)
);

-- Receta: cantidad de cada insumo por porción (en la unidad del insumo)
CREATE TABLE receta (
  id_producto          INT           NOT NULL,
  id_insumo            INT           NOT NULL,
  cantidad_por_porcion DECIMAL(10,5) NOT NULL,
  PRIMARY KEY (id_producto, id_insumo),
  CONSTRAINT fk_receta_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto) ON DELETE CASCADE,
  CONSTRAINT fk_receta_insumo   FOREIGN KEY (id_insumo)   REFERENCES insumo(id_insumo),
  CONSTRAINT ck_receta_cant CHECK (cantidad_por_porcion > 0)
);

-- ---------- Compras ----------
CREATE TABLE compra (
  id_compra      INT     NOT NULL AUTO_INCREMENT,
  fecha          DATE    NOT NULL,
  id_usuario     INT     NOT NULL,
  id_proveedor   INT     NOT NULL,
  es_planificada BOOLEAN NOT NULL,      -- FALSE = compra imprevista (KPI de la E1)
  PRIMARY KEY (id_compra),
  CONSTRAINT fk_compra_usuario   FOREIGN KEY (id_usuario)   REFERENCES usuario(id_usuario),
  CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
);

CREATE TABLE detalle_compra (
  id_compra       INT           NOT NULL,
  id_insumo       INT           NOT NULL,
  cantidad        DECIMAL(10,3) NOT NULL,
  precio_unitario INT           NOT NULL,     -- CLP por unidad del insumo
  PRIMARY KEY (id_compra, id_insumo),
  CONSTRAINT fk_det_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra) ON DELETE CASCADE,
  CONSTRAINT fk_det_insumo FOREIGN KEY (id_insumo) REFERENCES insumo(id_insumo),
  CONSTRAINT ck_det_cant   CHECK (cantidad > 0),
  CONSTRAINT ck_det_precio CHECK (precio_unitario >= 0)
);

-- ---------- Producción ----------
CREATE TABLE produccion (
  id_produccion INT           NOT NULL AUTO_INCREMENT,
  fecha_hora    DATETIME      NOT NULL,
  id_producto   INT           NOT NULL,
  id_usuario    INT           NOT NULL,
  cantidad      DECIMAL(10,3) NOT NULL,      -- en unidad de venta del producto
  PRIMARY KEY (id_produccion),
  CONSTRAINT fk_prodn_producto FOREIGN KEY (id_producto) REFERENCES producto(id_producto),
  CONSTRAINT fk_prodn_usuario  FOREIGN KEY (id_usuario)  REFERENCES usuario(id_usuario),
  CONSTRAINT ck_prodn_cant CHECK (cantidad > 0)
);

-- ---------- Lotes (existencias con fecha de vencimiento) ----------
CREATE TABLE lote_insumo (
  id_lote           INT           NOT NULL AUTO_INCREMENT,
  id_insumo         INT           NOT NULL,
  id_compra         INT           NULL,      -- NULL = carga inicial
  cantidad_actual   DECIMAL(10,3) NOT NULL,
  fecha_ingreso     DATE          NOT NULL,
  fecha_vencimiento DATE          NULL,      -- NULL = no vence
  PRIMARY KEY (id_lote),
  CONSTRAINT fk_lotei_insumo FOREIGN KEY (id_insumo) REFERENCES insumo(id_insumo),
  CONSTRAINT fk_lotei_compra FOREIGN KEY (id_compra) REFERENCES compra(id_compra),
  CONSTRAINT ck_lotei_cant  CHECK (cantidad_actual >= 0),
  CONSTRAINT ck_lotei_fecha CHECK (fecha_vencimiento IS NULL OR fecha_vencimiento >= fecha_ingreso)
);

CREATE TABLE lote_producto (
  id_lote           INT           NOT NULL AUTO_INCREMENT,
  id_producto       INT           NOT NULL,
  id_produccion     INT           NULL,      -- NULL = carga inicial
  ubicacion         ENUM('tienda','bodega') NOT NULL,
  cantidad_actual   DECIMAL(10,3) NOT NULL,
  fecha_ingreso     DATE          NOT NULL,
  fecha_vencimiento DATE          NOT NULL,
  PRIMARY KEY (id_lote),
  CONSTRAINT fk_lotep_producto   FOREIGN KEY (id_producto)   REFERENCES producto(id_producto),
  CONSTRAINT fk_lotep_produccion FOREIGN KEY (id_produccion) REFERENCES produccion(id_produccion),
  CONSTRAINT ck_lotep_cant  CHECK (cantidad_actual >= 0),
  CONSTRAINT ck_lotep_fecha CHECK (fecha_vencimiento >= fecha_ingreso)
);

-- ---------- Historial de movimientos ----------
CREATE TABLE movimiento_insumo (
  id_movimiento INT           NOT NULL AUTO_INCREMENT,
  fecha_hora    DATETIME      NOT NULL,
  tipo          ENUM('compra','consumo','uso','merma','ajuste') NOT NULL,
  id_insumo     INT           NOT NULL,
  cantidad      DECIMAL(10,3) NOT NULL,      -- positiva; el tipo indica si entra o sale (ajuste puede ser +/-)
  id_usuario    INT           NOT NULL,
  id_compra     INT           NULL,          -- solo tipo 'compra'
  id_produccion INT           NULL,          -- solo tipo 'consumo' (receta)
  motivo        VARCHAR(200)  NULL,
  PRIMARY KEY (id_movimiento),
  KEY ix_movi_fecha (fecha_hora),
  CONSTRAINT fk_movi_insumo     FOREIGN KEY (id_insumo)     REFERENCES insumo(id_insumo),
  CONSTRAINT fk_movi_usuario    FOREIGN KEY (id_usuario)    REFERENCES usuario(id_usuario),
  CONSTRAINT fk_movi_compra     FOREIGN KEY (id_compra)     REFERENCES compra(id_compra),
  CONSTRAINT fk_movi_produccion FOREIGN KEY (id_produccion) REFERENCES produccion(id_produccion),
  CONSTRAINT ck_movi_cant CHECK (cantidad <> 0),
  CONSTRAINT ck_movi_ref  CHECK ((tipo = 'compra')  = (id_compra IS NOT NULL)
                             AND (tipo = 'consumo') = (id_produccion IS NOT NULL))
);

CREATE TABLE movimiento_producto (
  id_movimiento INT           NOT NULL AUTO_INCREMENT,
  fecha_hora    DATETIME      NOT NULL,
  tipo          ENUM('produccion','reposicion','venta','merma','ajuste') NOT NULL,
  id_producto   INT           NOT NULL,
  cantidad      DECIMAL(10,3) NOT NULL,
  origen        ENUM('tienda','bodega') NULL,
  destino       ENUM('tienda','bodega') NULL,
  id_usuario    INT           NOT NULL,
  id_produccion INT           NULL,          -- solo tipo 'produccion'
  motivo        VARCHAR(200)  NULL,
  PRIMARY KEY (id_movimiento),
  KEY ix_movp_fecha (fecha_hora),
  CONSTRAINT fk_movp_producto   FOREIGN KEY (id_producto)   REFERENCES producto(id_producto),
  CONSTRAINT fk_movp_usuario    FOREIGN KEY (id_usuario)    REFERENCES usuario(id_usuario),
  CONSTRAINT fk_movp_produccion FOREIGN KEY (id_produccion) REFERENCES produccion(id_produccion),
  CONSTRAINT ck_movp_cant CHECK (cantidad <> 0),
  CONSTRAINT ck_movp_ref  CHECK ((tipo = 'produccion') = (id_produccion IS NOT NULL)),
  CONSTRAINT ck_movp_ubic CHECK (
       (tipo = 'produccion' AND origen IS NULL AND destino IS NOT NULL)
    OR (tipo = 'reposicion' AND origen = 'bodega' AND destino = 'tienda')
    OR (tipo IN ('venta','merma') AND origen IS NOT NULL AND destino IS NULL)
    OR (tipo = 'ajuste'))
);
