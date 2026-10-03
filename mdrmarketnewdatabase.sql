-- =====================================================================
--  MDR MARKET  ·  Base de datos v2 (rediseño)
--  App de delivery en Flutter con 3 vistas: cliente, repartidor, comerciante
--  Motor: MySQL 8.0.16+ / 8.4 (necesita CHECK y columnas generadas)   ·   Charset: utf8mb4_unicode_ci
--  Crea y usa la base `mdrmarket_new` (no toca la antigua `mdrmarket`).
--  Si se vuelve a importar, borra y recrea todo dentro de `mdrmarket_new`.
-- =====================================================================
--
--  IDEA CENTRAL
--  ------------
--  * `usuario` guarda los datos de la PERSONA (correo, contraseña, nombre,
--    apellido, carnet). Todo usuario puede comprar: no existe tabla `cliente`.
--  * Los roles extra son tablas de perfil que cuelgan del mismo usuario:
--      - repartidor  (1 a 1 con usuario)  + vehiculo (1 a N)
--      - negocio     (1 a N con usuario, el comerciante es el dueño)
--    Así un cliente se vuelve repartidor/comerciante sin crear otra cuenta y
--    sin volver a pedir lo que ya llenó. `CALL sp_datos_faltantes(id, rol)`
--    devuelve solo lo que le falta para activar ese rol.
--  * Documentos (fotos del carnet, licencia, vehículo, placa, RUAT, NIT…) van
--    en `documento`, y QUÉ se exige a cada rol está en `requisito_rol`. Los
--    del vehículo se piden según su tipo (a una bicicleta no se le pide placa,
--    RUAT ni licencia). Para pedir un documento nuevo se inserta una fila.
--  * Vehículos catalogados: liviano (moto, bicicleta), mediano (auto,
--    camioneta), grande (camión).
--  * Reseñas unificadas en `resena` (producto, negocio o repartidor, de 1 a
--    5 estrellas). Una sola reseña por usuario y objetivo, editable; solo
--    después de recibir un pedido. Los promedios se actualizan solos.
--  * `registro_comercio`: libro de compras y ventas de cada negocio. Las
--    ventas se registran solas al entregar un pedido; las compras de
--    mercadería y los gastos los carga el comerciante. Reportes de ganancia
--    por día/semana/mes/año: `CALL sp_reporte_negocio(...)`, y por producto:
--    `CALL sp_reporte_productos(...)`.
--  * `tarifa_envio`: precio del delivery por distancia (hasta X km = Y Bs),
--    por tipo de vehículo. `SELECT fn_costo_envio(km, categoria)` da el precio.
--  * Cobertura Santa Cruz de la Sierra: `anillo` guarda el radio aproximado
--    de cada anillo medido desde la Plaza 24 de Septiembre. Se atiende del
--    centro hasta el 10mo anillo; `fn_anillo(lat, lng)` dice en qué anillo
--    está un punto y `fn_cotizar_envio(...)` rechaza lo que quede afuera.
--  * Borrado lógico (`deleted_at`) en usuario, negocio, producto y vehiculo
--    para no romper el historial de pedidos.
--  * Reportes y sanciones: `reporte` (denuncias de usuarios, con motivos de
--    `motivo_reporte` y fotos en `reporte_evidencia`) y `sancion` (la aplica
--    un admin). Las sanciones vigentes se cumplen solas en la base: el
--    negocio/producto sale del catálogo y no se puede pedir, el cliente no
--    puede comprar y al repartidor no se le asignan pedidos. Panel del admin:
--    `v_reportes_pendientes`.
--  * El stock se descuenta en la base al crear el pedido (falla con "Stock
--    insuficiente" si no alcanza) y se devuelve si el pedido se cancela.
--  * HORARIO: todo se guarda en UTC. En Laravel poner en config/database.php,
--    conexión mysql: 'timezone' => '+00:00'. Los reportes muestran hora de
--    Bolivia (-04:00) según `configuracion.zona_horaria`.
--
--  CAMBIOS RESPECTO AL VOLCADO ANTERIOR
--  ------------------------------------
--  * Eliminadas: cliente, comerciante, archivo, audit_logs, calificaciones,
--    historialpedido, pedidoitem, productoimagen, seguimiento, transacciones.
--  * Nuevas / reemplazos: direccion, tipo_documento, requisito_rol,
--    documento, categoria_vehiculo, tipo_vehiculo, vehiculo, negocio,
--    negocio_horario, producto_imagen, pedido_item, pedido_estado_historial,
--    resena, ubicacion_repartidor, transaccion, favorito, dispositivo,
--    notificacion, configuracion, registro_comercio, tarifa_envio.
--  * Todas las relaciones tienen FOREIGN KEY (antes faltaban en pedido,
--    producto, pedidoitem y productoimagen).
--  * pedido.total y pedido_item.subtotal son columnas calculadas: no pueden
--    quedar descuadradas. Se quitaron `monto_total`, `monto_pagado`,
--    `id_zona_envio`, `id_ubicacion_entrega` y `producto.en_oferta`.
--  * Datos: quedan los datos semilla limpios (admin, 3 negocios con sus 26
--    productos, 3 repartidores y 3 clientes). Se borraron las cuentas de
--    prueba (ids 11 a 17) con sus negocios, productos, pedidos y reseñas, y
--    las transacciones inventadas. Tokens, sesiones y caché vacíos.
-- =====================================================================

-- Modo estricto: los triggers y procedimientos guardan el modo con el que se
-- crean; sin STRICT, MySQL recortaría datos inválidos en silencio.
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION,NO_AUTO_VALUE_ON_ZERO';
SET FOREIGN_KEY_CHECKS = 0;
SET time_zone = "+00:00";
SET NAMES utf8mb4;

-- Crea una base NUEVA (mdrmarket_new) y trabaja solo en ella: la base
-- antigua `mdrmarket` no se toca. Para usar otro nombre, cambiarlo en
-- estas dos líneas.
CREATE DATABASE IF NOT EXISTS mdrmarket_new DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mdrmarket_new;

START TRANSACTION;

-- ---------------------------------------------------------------------
-- Limpieza de tablas antiguas y nuevas
-- ---------------------------------------------------------------------
DROP VIEW      IF EXISTS v_catalogo_producto, v_usuario_roles, v_pedido_resumen, v_registro_diario;
DROP EVENT     IF EXISTS ev_limpiar_ubicaciones;
DROP PROCEDURE IF EXISTS sp_datos_faltantes;
DROP PROCEDURE IF EXISTS sp_recalcular_rating;
DROP PROCEDURE IF EXISTS sp_reporte_negocio;
DROP PROCEDURE IF EXISTS sp_reporte_productos;
DROP FUNCTION  IF EXISTS fn_costo_envio;
DROP FUNCTION  IF EXISTS fn_distancia_km;
DROP FUNCTION  IF EXISTS fn_anillo;
DROP FUNCTION  IF EXISTS fn_cotizar_envio;
DROP FUNCTION  IF EXISTS fn_sancion_activa;
DROP FUNCTION  IF EXISTS fn_negocio_sancionado;
DROP VIEW      IF EXISTS v_sancion_activa, v_reportes_pendientes;

DROP TABLE IF EXISTS
  archivo, audit_logs, calificaciones, cliente, comerciante, historialpedido,
  pedidoitem, productoimagen, seguimiento, transacciones,
  auditoria, registro_comercio, tarifa_envio, anillo,
  sancion, reporte_evidencia, reporte, motivo_reporte,
  notificacion, dispositivo, favorito, configuracion, transaccion,
  ubicacion_repartidor, resena, pedido_estado_historial, pedido_item, pedido,
  producto_imagen, producto, categoria, negocio_horario, negocio,
  documento, requisito_rol, tipo_documento, vehiculo, tipo_vehiculo,
  categoria_vehiculo, repartidor, direccion, usuario,
  cache, cache_locks, jobs, job_batches, failed_jobs, sessions,
  password_reset_tokens, personal_access_tokens, migrations;

-- =====================================================================
-- 1. USUARIOS Y ROLES
-- =====================================================================

-- Persona. Datos comunes a los tres roles.
CREATE TABLE usuario (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre            VARCHAR(100) NOT NULL,
  apellido          VARCHAR(100) NULL COMMENT 'Obligatorio en la app; NULL solo en cuentas antiguas',
  email             VARCHAR(191) NOT NULL,
  email_verified_at TIMESTAMP NULL,
  password          VARCHAR(255) NOT NULL,
  telefono          VARCHAR(20)  NULL,
  ci_numero         VARCHAR(20)  NULL COMMENT 'Número de carnet de identidad',
  ci_complemento    VARCHAR(5)   NOT NULL DEFAULT '' COMMENT 'Complemento del CI (si tiene)',
  ci_expedido       ENUM('LP','CB','SC','OR','PT','CH','TJ','BE','PD') NULL,
  fecha_nacimiento  DATE NULL,
  foto_perfil_url   VARCHAR(500) NULL,
  es_admin          TINYINT(1) NOT NULL DEFAULT 0,
  rol_activo        ENUM('cliente','repartidor','comerciante','admin') NOT NULL DEFAULT 'cliente'
                    COMMENT 'Última vista usada en la app (botón "cambiar a vista…")',
  activo            TINYINT(1) NOT NULL DEFAULT 1,
  remember_token    VARCHAR(100) NULL,
  created_at        TIMESTAMP NULL,
  updated_at        TIMESTAMP NULL,
  deleted_at        TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuario_email (email),
  UNIQUE KEY uq_usuario_ci (ci_numero, ci_complemento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Direcciones guardadas para recibir pedidos.
CREATE TABLE direccion (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id      BIGINT UNSIGNED NOT NULL,
  etiqueta        VARCHAR(50)  NULL COMMENT 'Casa, Trabajo…',
  direccion       VARCHAR(255) NOT NULL,
  referencia      VARCHAR(255) NULL,
  latitud         DECIMAL(10,7) NULL,
  longitud        DECIMAL(10,7) NULL,
  predeterminada  TINYINT(1) NOT NULL DEFAULT 0,
  created_at      TIMESTAMP NULL,
  updated_at      TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_direccion_usuario (usuario_id),
  CONSTRAINT fk_direccion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Catálogo de documentos que se pueden pedir.
--  ambito: a qué pertenece el documento.
--    persona  -> uno por usuario (carnet, licencia)
--    vehiculo -> uno por cada vehículo en uso (foto, placa, RUAT)
--    negocio  -> uno por negocio (NIT)
--  condicion_vehiculo: si no es NULL, solo se pide cuando el tipo de vehículo
--    tiene ese requisito (ej. a una bicicleta no se le pide placa ni licencia).
CREATE TABLE tipo_documento (
  id                 SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo             VARCHAR(50)  NOT NULL,
  nombre             VARCHAR(100) NOT NULL,
  descripcion        VARCHAR(255) NULL,
  ambito             ENUM('persona','vehiculo','negocio') NOT NULL DEFAULT 'persona',
  condicion_vehiculo ENUM('requiere_placa','requiere_ruat','requiere_licencia') NULL,
  activo             TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tipo_documento_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Qué documentos exige cada rol. Editable sin tocar la estructura.
CREATE TABLE requisito_rol (
  id                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  rol               ENUM('cliente','repartidor','comerciante') NOT NULL,
  tipo_documento_id SMALLINT UNSIGNED NOT NULL,
  obligatorio       TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_requisito_rol (rol, tipo_documento_id),
  CONSTRAINT fk_requisito_tipo FOREIGN KEY (tipo_documento_id) REFERENCES tipo_documento (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Clasificación de vehículos.
CREATE TABLE categoria_vehiculo (
  id               TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo           VARCHAR(20)  NOT NULL,
  nombre           VARCHAR(50)  NOT NULL,
  descripcion      VARCHAR(255) NULL,
  capacidad_kg_max SMALLINT UNSIGNED NULL,
  nivel            TINYINT UNSIGNED NOT NULL COMMENT '1 = más chico. Un vehículo de nivel N lleva pedidos de nivel <= N',
  PRIMARY KEY (id),
  UNIQUE KEY uq_categoria_vehiculo_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tipo_vehiculo (
  id                    TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_vehiculo_id TINYINT UNSIGNED NOT NULL,
  codigo                VARCHAR(20) NOT NULL,
  nombre                VARCHAR(50) NOT NULL,
  requiere_placa        TINYINT(1) NOT NULL DEFAULT 1,
  requiere_ruat         TINYINT(1) NOT NULL DEFAULT 1,
  requiere_licencia     TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tipo_vehiculo_codigo (codigo),
  CONSTRAINT fk_tipo_vehiculo_categoria FOREIGN KEY (categoria_vehiculo_id) REFERENCES categoria_vehiculo (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Perfil de repartidor (1 a 1 con usuario).
CREATE TABLE repartidor (
  usuario_id               BIGINT UNSIGNED NOT NULL,
  estado_verificacion      ENUM('pendiente','aprobado','rechazado','suspendido') NOT NULL DEFAULT 'pendiente',
  disponible               TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'En línea para recibir pedidos',
  latitud_actual           DECIMAL(10,7) NULL,
  longitud_actual          DECIMAL(10,7) NULL,
  ubicacion_actualizada_en TIMESTAMP NULL,
  rating_promedio          DECIMAL(3,2) NULL,
  total_resenas            INT UNSIGNED NOT NULL DEFAULT 0,
  total_entregas           INT UNSIGNED NOT NULL DEFAULT 0,
  verificado_en            TIMESTAMP NULL,
  created_at               TIMESTAMP NULL,
  updated_at               TIMESTAMP NULL,
  PRIMARY KEY (usuario_id),
  KEY idx_repartidor_disponible (estado_verificacion, disponible),
  CONSTRAINT fk_repartidor_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vehículos del repartidor (puede registrar más de uno y marcar cuál usa).
CREATE TABLE vehiculo (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  repartidor_id       BIGINT UNSIGNED NOT NULL,
  tipo_vehiculo_id    TINYINT UNSIGNED NOT NULL,
  placa               VARCHAR(15) NULL,
  ruat                VARCHAR(30) NULL COMMENT 'Número de RUAT del vehículo',
  marca               VARCHAR(50) NULL,
  modelo              VARCHAR(50) NULL,
  color               VARCHAR(30) NULL,
  anio                SMALLINT UNSIGNED NULL,
  en_uso              TINYINT(1) NOT NULL DEFAULT 1,
  estado_verificacion ENUM('pendiente','aprobado','rechazado') NOT NULL DEFAULT 'pendiente',
  created_at          TIMESTAMP NULL,
  updated_at          TIMESTAMP NULL,
  deleted_at          TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vehiculo_placa (placa),
  KEY idx_vehiculo_repartidor (repartidor_id),
  CONSTRAINT fk_vehiculo_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidor (usuario_id) ON DELETE CASCADE,
  CONSTRAINT fk_vehiculo_tipo FOREIGN KEY (tipo_vehiculo_id) REFERENCES tipo_vehiculo (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 2. CATÁLOGO: CATEGORÍAS, NEGOCIOS Y PRODUCTOS
-- =====================================================================

-- Dos niveles: categoría principal (categoria_padre_id NULL) y subcategoría
-- (apunta a su principal). Los productos van siempre en una subcategoría.
-- Ids de subcategorías = id del padre × 100 + n (ej. 201 = Farmacia).
CREATE TABLE categoria (
  id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_padre_id BIGINT UNSIGNED NULL COMMENT 'NULL = categoría principal',
  nombre             VARCHAR(100) NOT NULL,
  icono              VARCHAR(16)  NULL COMMENT 'Emoji o nombre de ícono',
  descripcion        VARCHAR(255) NULL,
  orden              SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  activo             TINYINT(1) NOT NULL DEFAULT 1,
  created_at         TIMESTAMP NULL,
  updated_at         TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_categoria_nombre (nombre),
  KEY idx_categoria_padre (categoria_padre_id, orden),
  CONSTRAINT fk_categoria_padre FOREIGN KEY (categoria_padre_id) REFERENCES categoria (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Negocio del comerciante (un comerciante puede tener varios).
CREATE TABLE negocio (
  id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id              BIGINT UNSIGNED NOT NULL COMMENT 'Dueño (comerciante)',
  categoria_id            BIGINT UNSIGNED NULL COMMENT 'Rubro principal',
  nombre                  VARCHAR(150) NOT NULL,
  descripcion             TEXT NULL,
  nit                     VARCHAR(20)  NULL COMMENT 'Opcional: si no tiene, se usa el CI del dueño',
  razon_social            VARCHAR(200) NULL,
  telefono                VARCHAR(20)  NULL,
  direccion               VARCHAR(255) NULL,
  referencia              VARCHAR(255) NULL,
  latitud                 DECIMAL(10,7) NULL COMMENT 'Marcado con el GPS de la app',
  longitud                DECIMAL(10,7) NULL,
  logo_url                VARCHAR(500) NULL COMMENT 'Foto del negocio',
  banner_url              VARCHAR(500) NULL,
  tiempo_preparacion_min  SMALLINT UNSIGNED NULL,
  pedido_minimo           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  abierto                 TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Interruptor manual abierto/cerrado',
  estado_verificacion     ENUM('pendiente','aprobado','rechazado','suspendido') NOT NULL DEFAULT 'pendiente',
  rating_promedio         DECIMAL(3,2) NULL,
  total_resenas           INT UNSIGNED NOT NULL DEFAULT 0,
  created_at              TIMESTAMP NULL,
  updated_at              TIMESTAMP NULL,
  deleted_at              TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_negocio_nit (nit),
  KEY idx_negocio_usuario (usuario_id),
  KEY idx_negocio_estado (estado_verificacion, abierto),
  CONSTRAINT fk_negocio_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuario (id),
  CONSTRAINT fk_negocio_categoria FOREIGN KEY (categoria_id) REFERENCES categoria (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE negocio_horario (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id    BIGINT UNSIGNED NOT NULL,
  dia_semana    TINYINT UNSIGNED NOT NULL COMMENT '1 = lunes … 7 = domingo',
  hora_apertura TIME NOT NULL,
  hora_cierre   TIME NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_negocio_horario (negocio_id, dia_semana, hora_apertura),
  CONSTRAINT chk_horario_dia CHECK (dia_semana BETWEEN 1 AND 7),
  CONSTRAINT fk_horario_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Documentos subidos (fotos de carnet, RUAT, licencia, NIT…).
CREATE TABLE documento (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id        BIGINT UNSIGNED NOT NULL,
  tipo_documento_id SMALLINT UNSIGNED NOT NULL,
  vehiculo_id       BIGINT UNSIGNED NULL COMMENT 'Si el documento es de un vehículo (RUAT)',
  negocio_id        BIGINT UNSIGNED NULL COMMENT 'Si el documento es de un negocio (NIT)',
  archivo_url       VARCHAR(500) NOT NULL,
  numero            VARCHAR(50)  NULL,
  estado            ENUM('pendiente','aprobado','rechazado') NOT NULL DEFAULT 'pendiente',
  observacion       VARCHAR(255) NULL,
  revisado_por      BIGINT UNSIGNED NULL,
  revisado_en       TIMESTAMP NULL,
  created_at        TIMESTAMP NULL,
  updated_at        TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_documento_usuario (usuario_id, tipo_documento_id),
  CONSTRAINT fk_documento_usuario  FOREIGN KEY (usuario_id)        REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_documento_tipo     FOREIGN KEY (tipo_documento_id) REFERENCES tipo_documento (id),
  CONSTRAINT fk_documento_vehiculo FOREIGN KEY (vehiculo_id)       REFERENCES vehiculo (id) ON DELETE CASCADE,
  CONSTRAINT fk_documento_negocio  FOREIGN KEY (negocio_id)        REFERENCES negocio (id) ON DELETE CASCADE,
  CONSTRAINT fk_documento_revisor  FOREIGN KEY (revisado_por)      REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE producto (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id            BIGINT UNSIGNED NOT NULL,
  categoria_id          BIGINT UNSIGNED NOT NULL,
  categoria_vehiculo_id TINYINT UNSIGNED NULL COMMENT 'Vehículo mínimo para llevarlo (NULL = liviano)',
  nombre                VARCHAR(150) NOT NULL,
  descripcion           TEXT NULL,
  precio                DECIMAL(10,2) NOT NULL COMMENT 'Precio de venta',
  costo                 DECIMAL(10,2) NULL COMMENT 'Lo que le cuesta al comerciante (se actualiza con cada compra registrada)',
  precio_oferta         DECIMAL(10,2) NULL COMMENT 'Opcional. Si tiene valor, el producto está en oferta',
  oferta_inicio         DATETIME NULL,
  oferta_fin            DATETIME NULL,
  stock                 INT UNSIGNED NULL COMMENT 'NULL = sin control de stock (ej. comida hecha al momento)',
  disponible            TINYINT(1) NOT NULL DEFAULT 1,
  rating_promedio       DECIMAL(3,2) NULL,
  total_resenas         INT UNSIGNED NOT NULL DEFAULT 0,
  total_vendidos        INT UNSIGNED NOT NULL DEFAULT 0,
  created_at            TIMESTAMP NULL,
  updated_at            TIMESTAMP NULL,
  deleted_at            TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_producto_negocio (negocio_id, disponible),
  KEY idx_producto_categoria (categoria_id, disponible),
  FULLTEXT KEY ft_producto_busqueda (nombre, descripcion),
  CONSTRAINT chk_producto_precio CHECK (precio >= 0 AND (costo IS NULL OR costo >= 0)),
  CONSTRAINT chk_producto_oferta CHECK (precio_oferta IS NULL OR (precio_oferta >= 0 AND precio_oferta < precio)),
  CONSTRAINT chk_producto_fechas CHECK (oferta_inicio IS NULL OR oferta_fin IS NULL OR oferta_inicio < oferta_fin),
  CONSTRAINT fk_producto_negocio   FOREIGN KEY (negocio_id)            REFERENCES negocio (id),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id)          REFERENCES categoria (id),
  CONSTRAINT fk_producto_vehiculo  FOREIGN KEY (categoria_vehiculo_id) REFERENCES categoria_vehiculo (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE producto_imagen (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  producto_id  BIGINT UNSIGNED NOT NULL,
  url          VARCHAR(500) NOT NULL,
  orden        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  es_principal TINYINT(1) NOT NULL DEFAULT 0,
  -- Garantiza como máximo UNA imagen principal por producto.
  principal_de BIGINT UNSIGNED GENERATED ALWAYS AS (IF(es_principal = 1, producto_id, NULL)) STORED,
  created_at   TIMESTAMP NULL,
  updated_at   TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_producto_imagen_principal (principal_de),
  KEY idx_producto_imagen (producto_id, orden),
  -- Sin CASCADE: MySQL no lo permite en columnas usadas por una columna
  -- generada. Los productos se borran con deleted_at, así que no hace falta.
  CONSTRAINT fk_imagen_producto FOREIGN KEY (producto_id) REFERENCES producto (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE favorito (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id  BIGINT UNSIGNED NOT NULL,
  producto_id BIGINT UNSIGNED NULL,
  negocio_id  BIGINT UNSIGNED NULL,
  created_at  TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_favorito_producto (usuario_id, producto_id),
  UNIQUE KEY uq_favorito_negocio (usuario_id, negocio_id),
  CONSTRAINT fk_favorito_usuario  FOREIGN KEY (usuario_id)  REFERENCES usuario (id)  ON DELETE CASCADE,
  CONSTRAINT fk_favorito_producto FOREIGN KEY (producto_id) REFERENCES producto (id) ON DELETE CASCADE,
  CONSTRAINT fk_favorito_negocio  FOREIGN KEY (negocio_id)  REFERENCES negocio (id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 3. PEDIDOS Y ENTREGA
-- =====================================================================
--  Flujo de estados:
--  pendiente -> confirmado -> preparando -> listo -> en_camino -> entregado
--  (en cualquier punto antes de en_camino: cancelado / rechazado)
--  El repartidor se asigna con repartidor_id + asignado_en.

CREATE TABLE pedido (
  id                             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  comprador_id                   BIGINT UNSIGNED NOT NULL COMMENT 'Cualquier usuario puede comprar',
  negocio_id                     BIGINT UNSIGNED NOT NULL,
  repartidor_id                  BIGINT UNSIGNED NULL,
  vehiculo_id                    BIGINT UNSIGNED NULL,
  direccion_id                   BIGINT UNSIGNED NULL COMMENT 'Dirección guardada usada (opcional)',
  direccion_entrega              VARCHAR(255) NOT NULL COMMENT 'Copia del texto al momento del pedido',
  referencia_entrega             VARCHAR(255) NULL,
  latitud_entrega                DECIMAL(10,7) NOT NULL,
  longitud_entrega               DECIMAL(10,7) NOT NULL,
  anillo_entrega                 TINYINT UNSIGNED NULL COMMENT 'Anillo de la dirección de entrega (se calcula solo)',
  notas                         VARCHAR(500) NULL,
  categoria_vehiculo_requerida_id TINYINT UNSIGNED NULL,
  estado                         ENUM('pendiente','confirmado','preparando','listo','en_camino','entregado','cancelado','rechazado')
                                 NOT NULL DEFAULT 'pendiente',
  subtotal                       DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Suma de los ítems',
  costo_envio                    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  tarifa_servicio                DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Cobrada al comprador',
  descuento                      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total                          DECIMAL(10,2) GENERATED ALWAYS AS (subtotal + costo_envio + tarifa_servicio - descuento) STORED,
  comision_plataforma            DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Se descuenta al negocio, no suma al total',
  metodo_pago                    ENUM('efectivo','qr','transferencia','tarjeta') NOT NULL DEFAULT 'efectivo',
  estado_pago                    ENUM('pendiente','pagado','fallido','reembolsado') NOT NULL DEFAULT 'pendiente',
  referencia_pago                VARCHAR(100) NULL,
  pagado_en                      TIMESTAMP NULL,
  codigo_entrega                 CHAR(4) NULL COMMENT 'PIN que el cliente da al repartidor',
  distancia_km                   DECIMAL(6,2) NULL,
  tiempo_estimado_min            SMALLINT UNSIGNED NULL,
  confirmado_en                  TIMESTAMP NULL,
  asignado_en                    TIMESTAMP NULL,
  recogido_en                    TIMESTAMP NULL,
  entregado_en                   TIMESTAMP NULL,
  cancelado_en                   TIMESTAMP NULL,
  cancelado_por                  BIGINT UNSIGNED NULL,
  motivo_cancelacion             VARCHAR(255) NULL,
  created_at                     TIMESTAMP NULL,
  updated_at                     TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_pedido_comprador (comprador_id, created_at),
  KEY idx_pedido_negocio (negocio_id, estado),
  KEY idx_pedido_repartidor (repartidor_id, estado),
  KEY idx_pedido_estado (estado, repartidor_id),
  CONSTRAINT chk_pedido_montos CHECK (subtotal >= 0 AND costo_envio >= 0 AND tarifa_servicio >= 0
                                      AND descuento >= 0 AND comision_plataforma >= 0
                                      AND descuento <= subtotal + costo_envio + tarifa_servicio),
  CONSTRAINT fk_pedido_comprador  FOREIGN KEY (comprador_id)  REFERENCES usuario (id),
  CONSTRAINT fk_pedido_negocio    FOREIGN KEY (negocio_id)    REFERENCES negocio (id),
  CONSTRAINT fk_pedido_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidor (usuario_id) ON DELETE SET NULL,
  CONSTRAINT fk_pedido_vehiculo   FOREIGN KEY (vehiculo_id)   REFERENCES vehiculo (id) ON DELETE SET NULL,
  CONSTRAINT fk_pedido_direccion  FOREIGN KEY (direccion_id)  REFERENCES direccion (id) ON DELETE SET NULL,
  CONSTRAINT fk_pedido_cat_veh    FOREIGN KEY (categoria_vehiculo_requerida_id) REFERENCES categoria_vehiculo (id),
  CONSTRAINT fk_pedido_cancelador FOREIGN KEY (cancelado_por) REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pedido_item (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id       BIGINT UNSIGNED NOT NULL,
  producto_id     BIGINT UNSIGNED NOT NULL,
  producto_nombre VARCHAR(150) NOT NULL COMMENT 'Copia del nombre al momento de la compra',
  precio_unitario DECIMAL(10,2) NOT NULL COMMENT 'Precio cobrado (ya con oferta si aplicaba)',
  costo_unitario  DECIMAL(10,2) NULL COMMENT 'Costo del producto al momento de la venta (se copia solo)',
  cantidad        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  subtotal        DECIMAL(10,2) GENERATED ALWAYS AS (precio_unitario * cantidad) STORED,
  notas           VARCHAR(255) NULL COMMENT 'Ej. "sin cebolla"',
  created_at      TIMESTAMP NULL,
  updated_at      TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_item_pedido (pedido_id),
  KEY idx_item_producto (producto_id),
  CONSTRAINT chk_item_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_item_precio CHECK (precio_unitario >= 0),
  CONSTRAINT fk_item_pedido   FOREIGN KEY (pedido_id)   REFERENCES pedido (id) ON DELETE CASCADE,
  CONSTRAINT fk_item_producto FOREIGN KEY (producto_id) REFERENCES producto (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pedido_estado_historial (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id       BIGINT UNSIGNED NOT NULL,
  estado_anterior VARCHAR(20) NULL,
  estado_nuevo    VARCHAR(20) NOT NULL,
  motivo          VARCHAR(255) NULL,
  usuario_id      BIGINT UNSIGNED NULL COMMENT 'Quién hizo el cambio',
  rol             ENUM('cliente','repartidor','comerciante','admin','sistema') NOT NULL DEFAULT 'sistema',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_historial_pedido (pedido_id, created_at),
  CONSTRAINT fk_historial_pedido  FOREIGN KEY (pedido_id)  REFERENCES pedido (id) ON DELETE CASCADE,
  CONSTRAINT fk_historial_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Precio del delivery por distancia: cada fila dice "hasta km_hasta cuesta
-- precio". Se usa el rango más chico que cubra la distancia. Si la distancia
-- supera el último rango, fn_costo_envio devuelve NULL (fuera de cobertura).
-- Si una categoría de vehículo no tiene filas, se usan las de 'liviano'.
CREATE TABLE tarifa_envio (
  id                    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  categoria_vehiculo_id TINYINT UNSIGNED NOT NULL,
  km_hasta              DECIMAL(6,2) NOT NULL,
  precio                DECIMAL(10,2) NOT NULL,
  activo                TINYINT(1) NOT NULL DEFAULT 1,
  created_at            TIMESTAMP NULL,
  updated_at            TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tarifa_envio (categoria_vehiculo_id, km_hasta),
  CONSTRAINT chk_tarifa_envio CHECK (km_hasta > 0 AND precio >= 0),
  CONSTRAINT fk_tarifa_categoria FOREIGN KEY (categoria_vehiculo_id) REFERENCES categoria_vehiculo (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Anillos de Santa Cruz de la Sierra. radio_km = distancia aproximada en
-- línea recta desde la Plaza 24 de Septiembre hasta ese anillo. Los anillos
-- no son círculos perfectos: ajustar los radios si algún barrio queda mal.
CREATE TABLE anillo (
  numero      TINYINT UNSIGNED NOT NULL COMMENT '1 = dentro del 1er anillo (casco viejo)',
  nombre      VARCHAR(50)  NOT NULL,
  radio_km    DECIMAL(5,2) NOT NULL,
  con_cobertura TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (numero),
  UNIQUE KEY uq_anillo_radio (radio_km)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Rastro GPS del repartidor (para el mapa en vivo del cliente).
CREATE TABLE ubicacion_repartidor (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  repartidor_id BIGINT UNSIGNED NOT NULL,
  pedido_id     BIGINT UNSIGNED NULL,
  latitud       DECIMAL(10,7) NOT NULL,
  longitud      DECIMAL(10,7) NOT NULL,
  registrado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ubicacion_pedido (pedido_id, registrado_en),
  KEY idx_ubicacion_repartidor (repartidor_id, registrado_en),
  CONSTRAINT fk_ubicacion_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidor (usuario_id) ON DELETE CASCADE,
  CONSTRAINT fk_ubicacion_pedido     FOREIGN KEY (pedido_id)     REFERENCES pedido (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4. RESEÑAS (producto, negocio y repartidor)
-- =====================================================================
-- Exactamente uno de producto_id / negocio_id / repartidor_id, según `tipo`.
-- UNA sola reseña por usuario para cada producto, negocio o repartidor,
-- aunque le haya comprado muchas veces. Si cambia de opinión, EDITA la
-- misma reseña (en Laravel: Resena::updateOrCreate([...autor, tipo, objetivo], [...])).
-- Solo puede reseñar quien tenga al menos un pedido entregado con ese
-- producto/negocio/repartidor, y nadie puede reseñarse a sí mismo.
CREATE TABLE resena (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pedido_id     BIGINT UNSIGNED NULL COMMENT 'Pedido entregado que habilitó la reseña (se completa solo)',
  autor_id      BIGINT UNSIGNED NOT NULL,
  tipo          ENUM('producto','negocio','repartidor') NOT NULL,
  producto_id   BIGINT UNSIGNED NULL,
  negocio_id    BIGINT UNSIGNED NULL,
  repartidor_id BIGINT UNSIGNED NULL,
  objetivo_id   BIGINT UNSIGNED GENERATED ALWAYS AS (COALESCE(producto_id, negocio_id, repartidor_id)) STORED,
  estrellas     TINYINT UNSIGNED NOT NULL,
  comentario    TEXT NULL,
  respuesta     TEXT NULL COMMENT 'Respuesta del negocio o repartidor',
  respondido_en TIMESTAMP NULL,
  visible       TINYINT(1) NOT NULL DEFAULT 1,
  created_at    TIMESTAMP NULL,
  updated_at    TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_resena_unica (autor_id, tipo, objetivo_id),
  KEY idx_resena_objetivo (tipo, objetivo_id, visible),
  CONSTRAINT chk_resena_estrellas CHECK (estrellas BETWEEN 1 AND 5),
  CONSTRAINT chk_resena_objetivo CHECK (
       (tipo = 'producto'   AND producto_id   IS NOT NULL AND negocio_id  IS NULL AND repartidor_id IS NULL)
    OR (tipo = 'negocio'    AND negocio_id    IS NOT NULL AND producto_id IS NULL AND repartidor_id IS NULL)
    OR (tipo = 'repartidor' AND repartidor_id IS NOT NULL AND producto_id IS NULL AND negocio_id    IS NULL)
  ),
  CONSTRAINT fk_resena_pedido     FOREIGN KEY (pedido_id)     REFERENCES pedido (id) ON DELETE SET NULL,
  CONSTRAINT fk_resena_autor      FOREIGN KEY (autor_id)      REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_resena_producto   FOREIGN KEY (producto_id)   REFERENCES producto (id),
  CONSTRAINT fk_resena_negocio    FOREIGN KEY (negocio_id)    REFERENCES negocio (id),
  CONSTRAINT fk_resena_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidor (usuario_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 4b. REPORTES (DENUNCIAS) Y SANCIONES
-- =====================================================================
--  Reporte: cualquier usuario denuncia un producto, negocio, repartidor,
--           cliente o reseña. Queda pendiente hasta que un admin lo revisa.
--  Sanción: la aplica un admin. Tiene efecto real mientras está vigente:
--           - suspension/bloqueo como cliente      -> no puede hacer pedidos
--           - suspension/bloqueo como comerciante  -> sus negocios salen del
--             catálogo y no reciben pedidos (o solo uno, si se indica negocio_id)
--           - suspension/bloqueo como repartidor   -> no se le pueden asignar pedidos
--           - rol 'todos'                          -> todo lo anterior (la API
--             además debe impedir el login: fn_sancion_activa(id, 'todos'))
--           - retiro_producto                      -> ese producto sale del catálogo
--           - advertencia                          -> solo queda registrada
--  Las suspensiones vencen solas al llegar `termina_en`: no hay que "levantarlas".

-- Catálogo de motivos (editable). aplica_a dice qué se puede reportar con él.
CREATE TABLE motivo_reporte (
  id        SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  codigo    VARCHAR(50)  NOT NULL,
  nombre    VARCHAR(150) NOT NULL,
  aplica_a  SET('producto','negocio','repartidor','usuario','resena') NOT NULL,
  gravedad  ENUM('baja','media','alta') NOT NULL DEFAULT 'media',
  activo    TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_motivo_reporte_codigo (codigo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Un usuario no puede tener dos reportes ABIERTOS contra lo mismo (evita
-- spam); cuando se resuelve, puede volver a reportar si se repite.
CREATE TABLE reporte (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reportante_id BIGINT UNSIGNED NOT NULL,
  tipo          ENUM('producto','negocio','repartidor','usuario','resena') NOT NULL,
  producto_id   BIGINT UNSIGNED NULL,
  negocio_id    BIGINT UNSIGNED NULL,
  repartidor_id BIGINT UNSIGNED NULL,
  usuario_id    BIGINT UNSIGNED NULL COMMENT 'Cliente reportado',
  resena_id     BIGINT UNSIGNED NULL,
  objetivo_id   BIGINT UNSIGNED GENERATED ALWAYS AS (COALESCE(producto_id, negocio_id, repartidor_id, usuario_id, resena_id)) STORED,
  motivo_id     SMALLINT UNSIGNED NOT NULL,
  pedido_id     BIGINT UNSIGNED NULL COMMENT 'Pedido relacionado (se completa solo al reportar personas)',
  descripcion   VARCHAR(1000) NULL,
  estado        ENUM('pendiente','en_revision','resuelto','descartado') NOT NULL DEFAULT 'pendiente',
  abierto       TINYINT UNSIGNED GENERATED ALWAYS AS (IF(estado IN ('pendiente','en_revision'), 1, NULL)) STORED,
  resolucion    VARCHAR(500) NULL COMMENT 'Qué decidió el admin',
  revisado_por  BIGINT UNSIGNED NULL,
  revisado_en   DATETIME NULL,
  created_at    TIMESTAMP NULL,
  updated_at    TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_reporte_abierto (reportante_id, tipo, objetivo_id, abierto),
  KEY idx_reporte_objetivo (tipo, objetivo_id, estado),
  KEY idx_reporte_estado (estado, created_at),
  CONSTRAINT chk_reporte_objetivo CHECK (
       (tipo = 'producto'   AND producto_id   IS NOT NULL AND negocio_id IS NULL AND repartidor_id IS NULL AND usuario_id IS NULL AND resena_id IS NULL)
    OR (tipo = 'negocio'    AND negocio_id    IS NOT NULL AND producto_id IS NULL AND repartidor_id IS NULL AND usuario_id IS NULL AND resena_id IS NULL)
    OR (tipo = 'repartidor' AND repartidor_id IS NOT NULL AND producto_id IS NULL AND negocio_id IS NULL AND usuario_id IS NULL AND resena_id IS NULL)
    OR (tipo = 'usuario'    AND usuario_id    IS NOT NULL AND producto_id IS NULL AND negocio_id IS NULL AND repartidor_id IS NULL AND resena_id IS NULL)
    OR (tipo = 'resena'     AND resena_id     IS NOT NULL AND producto_id IS NULL AND negocio_id IS NULL AND repartidor_id IS NULL AND usuario_id IS NULL)
  ),
  CONSTRAINT fk_reporte_reportante FOREIGN KEY (reportante_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_reporte_producto   FOREIGN KEY (producto_id)   REFERENCES producto (id),
  CONSTRAINT fk_reporte_negocio    FOREIGN KEY (negocio_id)    REFERENCES negocio (id),
  CONSTRAINT fk_reporte_repartidor FOREIGN KEY (repartidor_id) REFERENCES repartidor (usuario_id),
  CONSTRAINT fk_reporte_usuario    FOREIGN KEY (usuario_id)    REFERENCES usuario (id),
  CONSTRAINT fk_reporte_resena     FOREIGN KEY (resena_id)     REFERENCES resena (id),
  CONSTRAINT fk_reporte_motivo     FOREIGN KEY (motivo_id)     REFERENCES motivo_reporte (id),
  CONSTRAINT fk_reporte_pedido     FOREIGN KEY (pedido_id)     REFERENCES pedido (id) ON DELETE SET NULL,
  CONSTRAINT fk_reporte_revisor    FOREIGN KEY (revisado_por)  REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Fotos o capturas que adjunta quien reporta.
CREATE TABLE reporte_evidencia (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  reporte_id BIGINT UNSIGNED NOT NULL,
  url        VARCHAR(500) NOT NULL,
  created_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_evidencia_reporte (reporte_id),
  CONSTRAINT fk_evidencia_reporte FOREIGN KEY (reporte_id) REFERENCES reporte (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Fechas en UTC (como registro_comercio).
CREATE TABLE sancion (
  id                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id        BIGINT UNSIGNED NOT NULL COMMENT 'Persona sancionada (cliente, repartidor o dueño del negocio/producto)',
  rol_afectado      ENUM('cliente','repartidor','comerciante','todos') NOT NULL,
  tipo              ENUM('advertencia','suspension','bloqueo','retiro_producto') NOT NULL
                    COMMENT 'suspension = temporal (con termina_en) · bloqueo = permanente',
  negocio_id        BIGINT UNSIGNED NULL COMMENT 'Solo ese negocio; NULL = todos los del comerciante',
  producto_id       BIGINT UNSIGNED NULL COMMENT 'Obligatorio en retiro_producto',
  reporte_id        BIGINT UNSIGNED NULL COMMENT 'Reporte que la originó',
  motivo            VARCHAR(500) NOT NULL,
  inicia_en         DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()),
  termina_en        DATETIME NULL,
  aplicada_por      BIGINT UNSIGNED NULL,
  revocada_en       DATETIME NULL COMMENT 'Si el admin la levanta antes de tiempo',
  revocada_por      BIGINT UNSIGNED NULL,
  motivo_revocacion VARCHAR(255) NULL,
  created_at        TIMESTAMP NULL,
  updated_at        TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_sancion_usuario (usuario_id, rol_afectado),
  KEY idx_sancion_negocio (negocio_id),
  KEY idx_sancion_producto (producto_id),
  CONSTRAINT chk_sancion_tipo CHECK (
        (tipo <> 'retiro_producto' OR producto_id IS NOT NULL)
    AND (tipo <> 'suspension'      OR termina_en  IS NOT NULL)
    AND (tipo <> 'bloqueo'         OR termina_en  IS NULL)
    AND (termina_en IS NULL OR termina_en > inicia_en)
  ),
  CONSTRAINT fk_sancion_usuario   FOREIGN KEY (usuario_id)   REFERENCES usuario (id),
  CONSTRAINT fk_sancion_negocio   FOREIGN KEY (negocio_id)   REFERENCES negocio (id),
  CONSTRAINT fk_sancion_producto  FOREIGN KEY (producto_id)  REFERENCES producto (id),
  CONSTRAINT fk_sancion_reporte   FOREIGN KEY (reporte_id)   REFERENCES reporte (id) ON DELETE SET NULL,
  CONSTRAINT fk_sancion_aplicador FOREIGN KEY (aplicada_por) REFERENCES usuario (id) ON DELETE SET NULL,
  CONSTRAINT fk_sancion_revocador FOREIGN KEY (revocada_por) REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 5. FINANZAS, NOTIFICACIONES Y CONFIGURACIÓN
-- =====================================================================

-- Libro de compras y ventas del comerciante.
--   venta    -> se crea sola (una fila por ítem) cuando el pedido pasa a 'entregado'.
--               ingreso = cantidad × precio_unitario; ganancia = cantidad × (precio - costo)
--   compra   -> la carga el comerciante al reponer mercadería:
--               cantidad × costo_unitario. Suma stock y actualiza producto.costo.
--   gasto    -> otros gastos del negocio (alquiler, luz, bolsas…): costo_unitario = monto.
--   comision -> comisión de la plataforma del pedido (se crea sola si es > 0).
CREATE TABLE registro_comercio (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  negocio_id      BIGINT UNSIGNED NOT NULL,
  tipo            ENUM('compra','venta','gasto','comision') NOT NULL,
  producto_id     BIGINT UNSIGNED NULL,
  pedido_id       BIGINT UNSIGNED NULL,
  pedido_item_id  BIGINT UNSIGNED NULL,
  cantidad        INT UNSIGNED NOT NULL DEFAULT 1,
  precio_unitario DECIMAL(10,2) NULL COMMENT 'Solo ventas: precio cobrado al cliente',
  costo_unitario  DECIMAL(10,2) NULL COMMENT 'Compra: costo por unidad · Venta: costo de lo vendido · Gasto/comisión: monto',
  ingreso         DECIMAL(12,2) GENERATED ALWAYS AS (IF(tipo = 'venta', cantidad * COALESCE(precio_unitario, 0), 0)) STORED,
  egreso          DECIMAL(12,2) GENERATED ALWAYS AS (IF(tipo IN ('compra','gasto','comision'), cantidad * COALESCE(costo_unitario, 0), 0)) STORED,
  costo_vendido   DECIMAL(12,2) GENERATED ALWAYS AS (IF(tipo = 'venta', cantidad * COALESCE(costo_unitario, 0), 0)) STORED,
  ganancia        DECIMAL(12,2) GENERATED ALWAYS AS (IF(tipo = 'venta', cantidad * (COALESCE(precio_unitario, 0) - COALESCE(costo_unitario, 0)), 0)) STORED,
  descripcion     VARCHAR(255) NULL,
  proveedor       VARCHAR(150) NULL,
  fecha           DATETIME NOT NULL DEFAULT (UTC_TIMESTAMP()) COMMENT 'En UTC; los reportes la pasan a hora de Bolivia',
  registrado_por  BIGINT UNSIGNED NULL,
  created_at      TIMESTAMP NULL,
  updated_at      TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_registro_item (pedido_item_id),
  KEY idx_registro_negocio_fecha (negocio_id, fecha),
  KEY idx_registro_producto_fecha (negocio_id, producto_id, fecha),
  CONSTRAINT chk_registro_montos CHECK (
       (tipo = 'venta'  AND precio_unitario IS NOT NULL)
    OR (tipo <> 'venta' AND costo_unitario  IS NOT NULL)
  ),
  CONSTRAINT fk_registro_negocio  FOREIGN KEY (negocio_id)     REFERENCES negocio (id),
  CONSTRAINT fk_registro_producto FOREIGN KEY (producto_id)    REFERENCES producto (id) ON DELETE SET NULL,
  CONSTRAINT fk_registro_pedido   FOREIGN KEY (pedido_id)      REFERENCES pedido (id) ON DELETE CASCADE,
  CONSTRAINT fk_registro_item     FOREIGN KEY (pedido_item_id) REFERENCES pedido_item (id) ON DELETE CASCADE,
  CONSTRAINT fk_registro_usuario  FOREIGN KEY (registrado_por) REFERENCES usuario (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE transaccion (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo        ENUM('ingreso','egreso') NOT NULL,
  concepto    ENUM('comision','envio','suscripcion','membresia','liquidacion','reembolso',
                   'costo_operativo','pasarela_pago','otro') NOT NULL,
  descripcion VARCHAR(300) NOT NULL,
  monto       DECIMAL(10,2) NOT NULL,
  estado      ENUM('pendiente','completado','fallido') NOT NULL DEFAULT 'completado',
  pedido_id   BIGINT UNSIGNED NULL,
  usuario_id  BIGINT UNSIGNED NULL COMMENT 'Repartidor, cliente o comerciante involucrado',
  negocio_id  BIGINT UNSIGNED NULL,
  fecha       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at  TIMESTAMP NULL,
  updated_at  TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_transaccion_fecha (fecha),
  KEY idx_transaccion_usuario (usuario_id),
  KEY idx_transaccion_negocio (negocio_id),
  CONSTRAINT chk_transaccion_monto CHECK (monto > 0),
  CONSTRAINT fk_transaccion_pedido  FOREIGN KEY (pedido_id)  REFERENCES pedido (id)  ON DELETE SET NULL,
  CONSTRAINT fk_transaccion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE SET NULL,
  CONSTRAINT fk_transaccion_negocio FOREIGN KEY (negocio_id) REFERENCES negocio (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tokens de notificaciones push (FCM) por teléfono.
CREATE TABLE dispositivo (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id    BIGINT UNSIGNED NOT NULL,
  token         VARCHAR(255) NOT NULL,
  plataforma    ENUM('android','ios','web') NOT NULL,
  ultimo_uso_en TIMESTAMP NULL,
  created_at    TIMESTAMP NULL,
  updated_at    TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_dispositivo_token (token),
  CONSTRAINT fk_dispositivo_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE notificacion (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id BIGINT UNSIGNED NOT NULL,
  pedido_id  BIGINT UNSIGNED NULL,
  tipo       VARCHAR(50)  NOT NULL COMMENT 'pedido_nuevo, pedido_en_camino, documento_aprobado…',
  titulo     VARCHAR(150) NOT NULL,
  cuerpo     VARCHAR(500) NULL,
  datos      JSON NULL,
  leida_en   TIMESTAMP NULL,
  created_at TIMESTAMP NULL,
  PRIMARY KEY (id),
  KEY idx_notificacion_usuario (usuario_id, leida_en),
  CONSTRAINT fk_notificacion_usuario FOREIGN KEY (usuario_id) REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_notificacion_pedido  FOREIGN KEY (pedido_id)  REFERENCES pedido (id)  ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Parámetros del negocio editables sin tocar código.
CREATE TABLE configuracion (
  clave       VARCHAR(100) NOT NULL,
  valor       VARCHAR(255) NOT NULL,
  tipo        ENUM('string','int','decimal','bool','json') NOT NULL DEFAULT 'string',
  descripcion VARCHAR(255) NULL,
  updated_at  TIMESTAMP NULL,
  PRIMARY KEY (clave)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 6. TABLAS INTERNAS DE LARAVEL (vacías)
-- =====================================================================

CREATE TABLE cache (
  `key`      VARCHAR(255) NOT NULL,
  value      MEDIUMTEXT NOT NULL,
  expiration BIGINT NOT NULL,
  PRIMARY KEY (`key`),
  KEY cache_expiration_index (expiration)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cache_locks (
  `key`      VARCHAR(255) NOT NULL,
  owner      VARCHAR(255) NOT NULL,
  expiration BIGINT NOT NULL,
  PRIMARY KEY (`key`),
  KEY cache_locks_expiration_index (expiration)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE jobs (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  queue        VARCHAR(255) NOT NULL,
  payload      LONGTEXT NOT NULL,
  attempts     SMALLINT UNSIGNED NOT NULL,
  reserved_at  INT UNSIGNED NULL,
  available_at INT UNSIGNED NOT NULL,
  created_at   INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  KEY jobs_queue_index (queue)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE job_batches (
  id             VARCHAR(255) NOT NULL,
  name           VARCHAR(255) NOT NULL,
  total_jobs     INT NOT NULL,
  pending_jobs   INT NOT NULL,
  failed_jobs    INT NOT NULL,
  failed_job_ids LONGTEXT NOT NULL,
  options        MEDIUMTEXT NULL,
  cancelled_at   INT NULL,
  created_at     INT NOT NULL,
  finished_at    INT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE failed_jobs (
  id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uuid       VARCHAR(255) NOT NULL,
  connection TEXT NOT NULL,
  queue      TEXT NOT NULL,
  payload    LONGTEXT NOT NULL,
  exception  LONGTEXT NOT NULL,
  failed_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY failed_jobs_uuid_unique (uuid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sessions (
  id            VARCHAR(255) NOT NULL,
  user_id       BIGINT UNSIGNED NULL,
  ip_address    VARCHAR(45) NULL,
  user_agent    TEXT NULL,
  payload       LONGTEXT NOT NULL,
  last_activity INT NOT NULL,
  PRIMARY KEY (id),
  KEY sessions_user_id_index (user_id),
  KEY sessions_last_activity_index (last_activity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE password_reset_tokens (
  email      VARCHAR(191) NOT NULL,
  token      VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NULL,
  PRIMARY KEY (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE personal_access_tokens (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  tokenable_type VARCHAR(255) NOT NULL,
  tokenable_id   BIGINT UNSIGNED NOT NULL,
  name           TEXT NOT NULL,
  token          VARCHAR(64) NOT NULL,
  abilities      TEXT NULL,
  last_used_at   TIMESTAMP NULL,
  expires_at     TIMESTAMP NULL,
  created_at     TIMESTAMP NULL,
  updated_at     TIMESTAMP NULL,
  PRIMARY KEY (id),
  UNIQUE KEY personal_access_tokens_token_unique (token),
  KEY personal_access_tokens_tokenable_index (tokenable_type, tokenable_id),
  KEY personal_access_tokens_expires_at_index (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE migrations (
  id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  migration VARCHAR(255) NOT NULL,
  batch     INT NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
-- 7. DATOS
-- =====================================================================

-- ---------- Catálogos fijos ----------
INSERT INTO categoria_vehiculo (id, codigo, nombre, descripcion, capacidad_kg_max, nivel) VALUES
(1, 'liviano', 'Liviano', 'Motos y bicicletas: paquetes chicos y comida', 20,   1),
(2, 'mediano', 'Mediano', 'Autos y camionetas: compras grandes, muebles chicos', 500, 2),
(3, 'grande',  'Grande',  'Camiones: muebles, electrodomésticos, materiales de construcción', 5000, 3);

INSERT INTO tipo_vehiculo (id, categoria_vehiculo_id, codigo, nombre, requiere_placa, requiere_ruat, requiere_licencia) VALUES
(1, 1, 'moto',      'Moto',      1, 1, 1),
(2, 1, 'bicicleta', 'Bicicleta', 0, 0, 0),
(3, 2, 'auto',      'Auto',      1, 1, 1),
(4, 2, 'camioneta', 'Camioneta', 1, 1, 1),
(5, 3, 'camion',    'Camión',    1, 1, 1);

INSERT INTO tipo_documento (id, codigo, nombre, descripcion, ambito, condicion_vehiculo) VALUES
(1, 'ci_anverso',        'Carnet de identidad (anverso)', 'Foto del frente del CI',                     'persona',  NULL),
(2, 'ci_reverso',        'Carnet de identidad (reverso)', 'Foto del reverso del CI',                    'persona',  NULL),
(3, 'ruat',              'RUAT del vehículo',             'Foto del RUAT',                              'vehiculo', 'requiere_ruat'),
(4, 'licencia_conducir', 'Licencia de conducir',          'Foto de la licencia vigente',                'persona',  'requiere_licencia'),
(5, 'nit',               'Certificado de NIT',            'Solo si el negocio tiene NIT',               'negocio',  NULL),
(6, 'foto_vehiculo',     'Foto del vehículo',             'Foto completa del vehículo, de costado',     'vehiculo', NULL),
(7, 'foto_placa',        'Foto de la placa',              'Foto donde se lea bien la placa',            'vehiculo', 'requiere_placa');

-- Cambiar `obligatorio` o agregar filas aquí para pedir más o menos documentos.
-- Repartidor (moto/auto/camioneta/camión): CI anverso y reverso, licencia,
-- foto del vehículo, foto de la placa y RUAT. Bicicleta: CI y foto del vehículo.
INSERT INTO requisito_rol (rol, tipo_documento_id, obligatorio) VALUES
('repartidor',  1, 1),
('repartidor',  2, 1),
('repartidor',  3, 1),
('repartidor',  4, 1),
('repartidor',  6, 1),
('repartidor',  7, 1),
('comerciante', 1, 1),
('comerciante', 2, 1),
('comerciante', 5, 0);

-- Motivos de reporte (agregar o desactivar filas según haga falta).
INSERT INTO motivo_reporte (id, codigo, nombre, aplica_a, gravedad) VALUES
(1,  'producto_falso',      'Producto falso o diferente a lo publicado',     'producto',                    'alta'),
(2,  'producto_prohibido',  'Producto peligroso, vencido o prohibido',       'producto',                    'alta'),
(3,  'precio_enganoso',     'Precio u oferta engañosa',                      'producto,negocio',            'media'),
(4,  'negocio_fraudulento', 'Negocio falso o fraudulento',                   'negocio',                     'alta'),
(5,  'pedido_no_entregado', 'Cobró y no entregó el pedido',                  'negocio,repartidor',          'alta'),
(6,  'pedido_incompleto',   'Pedido incompleto o en mal estado',             'negocio,repartidor',          'media'),
(7,  'cobro_indebido',      'Cobro de más o pidió dinero extra',             'negocio,repartidor',          'alta'),
(8,  'maltrato',            'Maltrato, insultos o acoso',                    'negocio,repartidor,usuario',  'alta'),
(9,  'conduccion_peligrosa','Conducción peligrosa',                          'repartidor',                  'media'),
(10, 'suplantacion',        'Se hace pasar por otra persona',                'negocio,repartidor,usuario',  'alta'),
(11, 'pedido_falso',        'Pedido falso o broma (cliente no existe)',      'usuario',                     'media'),
(12, 'no_pago',             'No pagó el pedido',                             'usuario',                     'alta'),
(13, 'resena_falsa',        'Reseña falsa',                                  'resena',                      'media'),
(14, 'resena_ofensiva',     'Reseña ofensiva o con datos personales',        'resena',                      'media'),
(15, 'otro',                'Otro motivo',                                   'producto,negocio,repartidor,usuario,resena', 'baja');

INSERT INTO configuracion (clave, valor, tipo, descripcion, updated_at) VALUES
('tarifa_servicio',              '0.00', 'decimal', 'Cargo fijo de la plataforma al comprador (Bs)',    NOW()),
('comision_plataforma_pct',       '0',    'decimal', '% de comisión que se descuenta al negocio',        NOW()),
('radio_busqueda_repartidor_km',  '5',    'int',     'Radio para ofrecer pedidos a repartidores',        NOW()),
('centro_latitud',   '-17.7837300', 'decimal', 'Plaza 24 de Septiembre (punto 0 de los anillos)', NOW()),
('centro_longitud',  '-63.1821400', 'decimal', 'Plaza 24 de Septiembre (punto 0 de los anillos)', NOW()),
('zona_horaria',     '-04:00',      'string',  'Hora de Bolivia. Los datos se guardan en UTC y los reportes se muestran en esta zona', NOW()),
('dias_historial_gps', '30',        'int',     'Días que se guarda el rastro GPS de los repartidores', NOW()),
('factor_ruta',     '1.30',        'decimal', 'Km por calle ≈ km en línea recta × factor (solo si la app no manda la distancia real)', NOW());

-- Anillos de Santa Cruz de la Sierra (radios aproximados desde la Plaza).
INSERT INTO anillo (numero, nombre, radio_km, con_cobertura) VALUES
(1,  'Casco viejo (1er anillo)', 1.00, 1),
(2,  '2do anillo',               1.90, 1),
(3,  '3er anillo',               2.80, 1),
(4,  '4to anillo',               3.80, 1),
(5,  '5to anillo',               4.90, 1),
(6,  '6to anillo',               6.00, 1),
(7,  '7mo anillo',               7.30, 1),
(8,  '8vo anillo',               8.80, 1),
(9,  '9no anillo',              10.30, 1),
(10, '10mo anillo',             12.00, 1);

-- Tarifas de delivery por km recorridos (editar libremente).
-- Dentro del 10mo anillo un viaje de punta a punta llega a ~30 km por calle,
-- por eso hay tramos después de los 10 km (12, 15 y 20 Bs: propuesta, ajustar).
--   hasta 3 km  ≈ mismo barrio o 1–2 anillos       -> 3 Bs
--   hasta 6 km  ≈ del centro al 5to anillo         -> 5 Bs
--   hasta 10 km ≈ del centro al 8vo anillo         -> 8 Bs
--   hasta 15 km ≈ del centro al 10mo anillo        -> 12 Bs
--   hasta 20 km ≈ cruzar media ciudad              -> 15 Bs
--   hasta 30 km ≈ de un extremo al otro del 10mo   -> 20 Bs
-- Mediano y grande no tienen filas todavía, así que usan las del liviano.
INSERT INTO tarifa_envio (categoria_vehiculo_id, km_hasta, precio, created_at, updated_at) VALUES
(1,  3.00,  3.00, NOW(), NOW()),
(1,  6.00,  5.00, NOW(), NOW()),
(1, 10.00,  8.00, NOW(), NOW()),
(1, 15.00, 12.00, NOW(), NOW()),
(1, 20.00, 15.00, NOW(), NOW()),
(1, 30.00, 20.00, NOW(), NOW());

-- ---------- Categorías (se separó el emoji del nombre) ----------
INSERT INTO categoria (id, nombre, icono, descripcion, orden, created_at, updated_at) VALUES
(1,  'Alimentos y Bebidas',               '🍔', 'Comida, snacks y bebidas',                      1,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(2,  'Salud y Belleza',                   '💊', 'Cuidado personal, salud y cosmética',           2,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(3,  'Tecnología',                        '💻', 'Electrónica, gadgets y accesorios tech',        3,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(4,  'Hogar, Decoración y Muebles',       '🏠', 'Muebles, decoración y artículos del hogar',     4,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(5,  'Moda y Accesorios',                 '👕', 'Ropa, calzado y complementos',                  5,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(6,  'Deportes y Outdoor',                '🏋️', 'Deportes, fitness y actividades al aire libre', 6,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(7,  'Automotriz',                        '🚗', 'Accesorios y repuestos para vehículos',         7,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(8,  'Mascotas',                          '🐾', 'Productos para mascotas y su cuidado',          8,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(9,  'Entretenimiento',                   '🎮', 'Juegos, ocio y entretenimiento',                9,  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(10, 'Oficina y Papelería',               '🏢', 'Suministros de oficina y papelería',            10, '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(11, 'Bebés y Niños',                     '👶', 'Productos para bebés y niños',                  11, '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(12, 'Ferretería, Construcción y Jardín', '🔨', 'Herramientas, construcción y jardinería',       12, '2026-06-16 16:31:37', '2026-06-16 16:31:37');

-- Subcategorías (agregar o desactivar filas libremente).
INSERT INTO categoria (id, categoria_padre_id, nombre, icono, orden, created_at, updated_at) VALUES
(101,  1, 'Restaurantes y comida preparada', '🍽️', 1, NOW(), NOW()),
(102,  1, 'Supermercado y abarrotes',        '🛒', 2, NOW(), NOW()),
(103,  1, 'Bebidas',                         '🥤', 3, NOW(), NOW()),
(104,  1, 'Panadería y repostería',          '🥐', 4, NOW(), NOW()),
(105,  1, 'Snacks y dulces',                 '🍫', 5, NOW(), NOW()),
(201,  2, 'Farmacia y medicamentos',         '💊', 1, NOW(), NOW()),
(202,  2, 'Cuidado personal e higiene',      '🧴', 2, NOW(), NOW()),
(203,  2, 'Cosmética y cuidado de la piel',  '💄', 3, NOW(), NOW()),
(204,  2, 'Vitaminas y suplementos',         '🌿', 4, NOW(), NOW()),
(301,  3, 'Celulares y accesorios',          '📱', 1, NOW(), NOW()),
(302,  3, 'Computación',                     '🖥️', 2, NOW(), NOW()),
(303,  3, 'Audio y video',                   '🎧', 3, NOW(), NOW()),
(304,  3, 'Cables y cargadores',             '🔌', 4, NOW(), NOW()),
(401,  4, 'Muebles',                         '🛋️', 1, NOW(), NOW()),
(402,  4, 'Decoración',                      '🖼️', 2, NOW(), NOW()),
(403,  4, 'Cocina y comedor',                '🍳', 3, NOW(), NOW()),
(404,  4, 'Limpieza del hogar',              '🧹', 4, NOW(), NOW()),
(405,  4, 'Electrodomésticos',               '🔋', 5, NOW(), NOW()),
(501,  5, 'Ropa de mujer',                   '👗', 1, NOW(), NOW()),
(502,  5, 'Ropa de hombre',                  '👔', 2, NOW(), NOW()),
(503,  5, 'Calzado',                         '👟', 3, NOW(), NOW()),
(504,  5, 'Carteras, bisutería y relojes',   '👜', 4, NOW(), NOW()),
(601,  6, 'Fitness y gimnasio',              '💪', 1, NOW(), NOW()),
(602,  6, 'Ciclismo',                        '🚴', 2, NOW(), NOW()),
(603,  6, 'Camping y aire libre',            '⛺', 3, NOW(), NOW()),
(604,  6, 'Ropa deportiva',                  '🎽', 4, NOW(), NOW()),
(701,  7, 'Repuestos de auto',               '🔧', 1, NOW(), NOW()),
(702,  7, 'Accesorios para vehículos',       '🚙', 2, NOW(), NOW()),
(703,  7, 'Lubricantes y mantenimiento',     '🛢️', 3, NOW(), NOW()),
(704,  7, 'Motos y repuestos de moto',       '🏍️', 4, NOW(), NOW()),
(801,  8, 'Alimento para mascotas',          '🦴', 1, NOW(), NOW()),
(802,  8, 'Accesorios y juguetes para mascotas', '🎾', 2, NOW(), NOW()),
(803,  8, 'Higiene y salud animal',          '🩺', 3, NOW(), NOW()),
(901,  9, 'Videojuegos y consolas',          '🕹️', 1, NOW(), NOW()),
(902,  9, 'Juegos de mesa y juguetes',       '🎲', 2, NOW(), NOW()),
(903,  9, 'Libros',                          '📚', 3, NOW(), NOW()),
(904,  9, 'Música e instrumentos',           '🎸', 4, NOW(), NOW()),
(1001, 10, 'Útiles escolares',               '✏️', 1, NOW(), NOW()),
(1002, 10, 'Útiles de oficina',              '📎', 2, NOW(), NOW()),
(1003, 10, 'Impresión y tintas',             '🖨️', 3, NOW(), NOW()),
(1101, 11, 'Pañales e higiene del bebé',     '🧷', 1, NOW(), NOW()),
(1102, 11, 'Alimentación infantil',          '🍼', 2, NOW(), NOW()),
(1103, 11, 'Ropa infantil',                  '🧸', 3, NOW(), NOW()),
(1104, 11, 'Juguetes para bebés',            '🪀', 4, NOW(), NOW()),
(1201, 12, 'Herramientas',                   '🛠️', 1, NOW(), NOW()),
(1202, 12, 'Materiales de construcción',     '🧱', 2, NOW(), NOW()),
(1203, 12, 'Electricidad e iluminación',     '💡', 3, NOW(), NOW()),
(1204, 12, 'Plomería',                       '🚰', 4, NOW(), NOW()),
(1205, 12, 'Jardinería',                     '🌱', 5, NOW(), NOW());

-- ---------- Usuarios ----------
-- Los dueños de negocios semilla (2, 3, 4) no tienen apellido ni CI: la app
-- se los pedirá (ver sp_datos_faltantes). Contraseñas: las del volcado original.
INSERT INTO usuario (id, nombre, apellido, email, email_verified_at, password, telefono, es_admin, rol_activo, created_at, updated_at) VALUES
(1,  'Test',            'User',      'test@example.com',              '2026-06-16 16:31:36', '$2y$12$Dd9Jts/HlQhcaQSWKqWyT.g2fO57aLKmxi6d8wSqAfMRNRvmNEsO6', NULL,          1, 'admin',       '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(2,  'TechStore SCZ',   NULL,        'techstore@mdrmarket.local',     NULL, '$2y$12$KxaYq6s4SxCOyiN4UMGzNOcEioVQQEBDFvcV3AuafkxW1MH.A53a.', '59177001001', 0, 'comerciante', '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(3,  'Sabor Cruceño',   NULL,        'saborcruceno@mdrmarket.local',  NULL, '$2y$12$AvIDIJsj2XW4tRQGEj1GQeER33U/mAodJoULHN7fcHwrwfAt9E.D2', '59177002002', 0, 'comerciante', '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(4,  'FarmaSuper',      NULL,        'farmasuper@mdrmarket.local',    NULL, '$2y$12$bvytKY12gl8lzb2wG3tMNutrm7V/zB2.Lvt7gqTSFRu5EiAxFefHu', '59177003003', 0, 'comerciante', '2026-06-16 16:31:38', '2026-06-16 16:31:38'),
(5,  'Diego',           'Rodríguez', 'diego.rep@mdrmarket.local',     NULL, '$2y$12$rJxfcqbxjllibpPrB6azQ.R.byJp0C/MgGk.//9wfXWS1r.20DzBO', '59176101001', 0, 'repartidor',  '2026-06-16 16:31:38', '2026-06-16 16:31:38'),
(6,  'Valentina',       'Cruz',      'valentina.rep@mdrmarket.local', NULL, '$2y$12$9tP6i99iZeiyB/iCgdfrju3etg72dLxlUC0q2M2heXHLKrIhPY9vW', '59176102002', 0, 'repartidor',  '2026-06-16 16:31:38', '2026-06-16 16:31:38'),
(7,  'Marco',           'Flores',    'marco.rep@mdrmarket.local',     NULL, '$2y$12$/W0929I5lPXPna7MS4afUeVQA4GYenCpguBkC6cHz3gPLHt.1kHoy', '59176103003', 0, 'repartidor',  '2026-06-16 16:31:39', '2026-06-16 16:31:39'),
(8,  'Ana',             'García',    'ana.cliente@mdrmarket.local',   NULL, '$2y$12$zcAekdVmzdGo8ycN5Rgm4euAAj62ngj7WrFoDBvrr3jbDHYZwMQvC', '59175201001', 0, 'cliente',     '2026-06-16 16:31:39', '2026-06-16 16:31:39'),
(9,  'Carlos',          'López',     'carlos.cliente@mdrmarket.local',NULL, '$2y$12$XZIKuWKNggnB6JZufbZMnuLX05kE2cyixZ2XT3jipXA3MfwJQ053q', '59175202002', 0, 'cliente',     '2026-06-16 16:31:39', '2026-06-16 16:31:39'),
(10, 'Sofía',           'Martínez',  'sofia.cliente@mdrmarket.local', NULL, '$2y$12$pukWgBRFRN6rCUdDHMOLfu3WftoEV65y02csWtWKZnax/jEcOAvqK', '59175203003', 0, 'cliente',     '2026-06-16 16:31:40', '2026-06-16 16:31:40');

INSERT INTO direccion (usuario_id, etiqueta, direccion, predeterminada, created_at, updated_at) VALUES
(8,  'Casa', 'Calle Bolívar 210, Barrio Equipetrol Norte, Santa Cruz', 1, '2026-06-16 16:31:39', '2026-06-16 16:31:39'),
(9,  'Casa', 'Av. Cañoto 890, Barrio El Centro, Santa Cruz',           1, '2026-06-16 16:31:39', '2026-06-16 16:31:39'),
(10, 'Casa', 'Av. Beni 2345, Barrio Mutualista, Santa Cruz',           1, '2026-06-16 16:31:40', '2026-06-16 16:31:40');

-- ---------- Repartidores y vehículos ----------
INSERT INTO repartidor (usuario_id, estado_verificacion, verificado_en, created_at, updated_at) VALUES
(5,  'aprobado', '2026-06-16 16:31:38', '2026-06-16 16:31:38', '2026-06-16 16:31:38'),
(6,  'aprobado', '2026-06-16 16:31:38', '2026-06-16 16:31:38', '2026-06-16 16:31:38'),
(7,  'aprobado', '2026-06-16 16:31:39', '2026-06-16 16:31:39', '2026-06-16 16:31:39');

INSERT INTO vehiculo (id, repartidor_id, tipo_vehiculo_id, placa, en_uso, estado_verificacion, created_at, updated_at) VALUES
(1, 5,  1, 'SCZ-1234', 1, 'aprobado', '2026-06-16 16:31:38', '2026-06-16 16:31:38'),
(2, 6,  1, 'SCZ-5678', 1, 'aprobado', '2026-06-16 16:31:38', '2026-06-16 16:31:38'),
(3, 7,  2, 'SCZ-9012', 1, 'aprobado', '2026-06-16 16:31:39', '2026-06-16 16:31:39');

-- ---------- Negocios (mismo id que el antiguo `comerciante`) ----------
INSERT INTO negocio (id, usuario_id, categoria_id, nombre, descripcion, nit, razon_social, telefono, direccion, latitud, longitud, logo_url, banner_url, estado_verificacion, created_at, updated_at) VALUES
(2,  2,  3,    'TechStore SCZ', 'Tu tienda de tecnología y gadgets en el corazón de Equipetrol. Envíos rápidos a toda la ciudad.', NULL, NULL, '59177001001', 'Av. San Martín 453, Equipetrol, Santa Cruz', -17.7745000, -63.1935000, 'https://placehold.co/150/1a237e/ffffff?text=Tech',  'https://placehold.co/600x200/1a237e/ffffff?text=TechStore+SCZ',        'aprobado',  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(3,  3,  1,    'Sabor Cruceño', 'Auténtica gastronomía cruceña. Salteñas, empanadas, platos tradicionales con ingredientes frescos.', NULL, NULL, '59177002002', 'Calle Junín 320, Centro Histórico, Santa Cruz', -17.7859000, -63.1816000, 'https://placehold.co/150/e65100/ffffff?text=Sabor', 'https://placehold.co/600x200/e65100/ffffff?text=Sabor+Cruce%C3%B1o', 'aprobado',  '2026-06-16 16:31:37', '2026-06-16 16:31:37'),
(4,  4,  2,    'FarmaSuper',    'Farmacia y supermercado. Medicamentos, cuidado personal y productos de primera necesidad las 24 horas.', NULL, NULL, '59177003003', 'Av. Beni 1560, 2do Anillo, Santa Cruz', -17.7696000, -63.1658000, 'https://placehold.co/150/1b5e20/ffffff?text=Farma', 'https://placehold.co/600x200/1b5e20/ffffff?text=FarmaSuper', 'aprobado',  '2026-06-16 16:31:38', '2026-06-16 16:31:38');

-- ---------- Productos ----------
INSERT INTO producto (id, negocio_id, categoria_id, categoria_vehiculo_id, nombre, descripcion, precio, precio_oferta, stock, created_at, updated_at) VALUES
(1,  2,  303 , NULL, 'Auriculares Bluetooth Premium', 'Auriculares inalámbricos con cancelación de ruido activa, 30 h de batería y sonido Hi-Fi.', 185.00, NULL, 14, '2026-06-16 16:31:40', '2026-06-18 06:15:28'),
(2,  2,  304 , NULL, 'Cable USB-C a USB-A 2m', 'Cable de carga rápida y datos USB-C trenzado nylon, compatible con Android y laptops.', 14.50, NULL, 52, '2026-06-16 16:31:40', '2026-06-18 06:15:28'),
(3,  2,  302 , NULL, 'Memoria USB 64 GB USB 3.0', 'Memoria flash de alta velocidad (hasta 120 MB/s) con carcasa compacta y resistente.', 38.00, NULL, 54, '2026-06-16 16:31:40', '2026-06-17 06:21:49'),
(4,  2,  301 , NULL, 'Cargador Inalámbrico 15 W', 'Pad de carga rápida inalámbrica Qi compatible con iPhone, Samsung y demás.', 55.00, NULL, 29, '2026-06-16 16:31:40', '2026-06-18 06:15:28'),
(5,  2,  302 , NULL, 'Teclado Mecánico Compacto', 'Teclado 75 % con switches rojos, retroiluminación RGB y conectividad USB-C.', 165.00, NULL, 14, '2026-06-16 16:31:40', '2026-06-18 06:15:28'),
(6,  2,  302 , NULL, 'Mouse Inalámbrico Ergonómico', 'Mouse vertical inalámbrico DPI ajustable, reduce la fatiga en largas sesiones de trabajo.', 72.00, NULL, 39, '2026-06-16 16:31:40', '2026-06-18 06:15:28'),
(7,  2,  302 , NULL, 'Hub USB-C 7 en 1', 'Hub multipuerto con HDMI 4K, USB-A, USB-C PD, lector SD/MicroSD y Ethernet.', 95.00, NULL, 19, '2026-06-16 16:31:40', '2026-06-18 02:46:44'),
(8,  2,  901 , NULL, 'Control para PC/Consola', 'Control Bluetooth compatible con PC, Android y consolas, vibración dual.', 120.00, NULL, 18, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(9,  3,  101 , NULL, 'Salteña de Pollo', 'Salteña horneada rellena de pollo jugoso, papa, arveja y huevo.', 4.50, NULL, 99, '2026-06-16 16:31:40', '2026-06-18 06:23:04'),
(10, 3,  101 , NULL, 'Salteña de Carne', 'Salteña tradicional con carne res, papa, arveja y ají.', 5.00, NULL, 99, '2026-06-16 16:31:40', '2026-06-18 06:23:04'),
(11, 3,  101 , NULL, 'Empanada de Queso', 'Empanada frita rellena de queso derretido.', 3.50, NULL, 78, '2026-06-16 16:31:40', '2026-06-17 19:13:24'),
(12, 3,  101 , NULL, 'Arroz con Pollo Criollo', 'Arroz graneado con pollo al mojo, yuca frita y ensalada fresca.', 22.00, NULL, 39, '2026-06-16 16:31:40', '2026-06-18 06:23:04'),
(13, 3,  101 , NULL, 'Hamburguesa Especial', 'Hamburguesa artesanal con doble carne, queso y salsa de la casa.', 28.00, NULL, 35, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(14, 3,  101 , NULL, 'Sopa de Maní', 'Sopa boliviana de maní con fideos, papa y carne.', 18.00, NULL, 29, '2026-06-16 16:31:40', '2026-06-18 06:23:04'),
(15, 3,  103 , NULL, 'Refresco de Mocochinchi', 'Bebida tradicional boliviana de durazno. 500 ml.', 6.00, NULL, 59, '2026-06-16 16:31:40', '2026-06-18 06:23:04'),
(16, 3,  101 , NULL, 'Combo Almuerzo Completo', 'Sopa + plato principal + refresco. Cambia diariamente.', 38.00, NULL, 20, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(17, 4,  201 , NULL, 'Paracetamol 500 mg (20 comp)', 'Analgésico y antipirético. Caja de 20 comprimidos.', 8.50, NULL, 200, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(18, 4,  201 , NULL, 'Ibuprofeno 400 mg (15 comp)', 'Antiinflamatorio y analgésico. Caja de 15 comprimidos.', 10.00, NULL, 150, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(19, 4,  201 , NULL, 'Alcohol Isopropílico 500 ml', 'Alcohol de uso médico al 70 %. Frasco sellado.', 15.00, NULL, 80, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(20, 4,  202 , NULL, 'Shampoo Anti-Caspa 400 ml', 'Control de caspa desde la primera aplicación.', 22.00, NULL, 60, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(21, 4,  203 , NULL, 'Crema Hidratante Facial 50 g', 'Hidratación con ácido hialurónico. Para todo tipo de piel.', 28.00, NULL, 45, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(22, 4,  202 , NULL, 'Jabón Antibacterial x3', 'Pack de 3 jabones de 90 g. Protección duradera.', 9.00, NULL, 120, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(23, 4,  102 , NULL, 'Leche Entera 1 L', 'Leche entera pasteurizada local. Entrega el mismo día.', 9.50, NULL, 89, '2026-06-16 16:31:40', '2026-06-18 06:23:04'),
(24, 4,  102 , NULL, 'Arroz 1 kg', 'Arroz blanco de grano largo, cosecha santa crucera.', 7.50, NULL, 200, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(25, 4,  102 , NULL, 'Aceite Vegetal 1 L', 'Aceite de girasol refinado, sin colesterol.', 12.00, NULL, 109, '2026-06-16 16:31:40', '2026-06-18 06:23:04'),
(26, 4,  204 , NULL, 'Vitamina C 1000 mg (30 comp)', 'Suplemento efervescente. Refuerza el sistema inmunológico.', 18.00, NULL, 70, '2026-06-16 16:31:40', '2026-06-16 16:31:40');

INSERT INTO producto_imagen (id, producto_id, url, orden, es_principal, created_at, updated_at) VALUES
(1,  1,  'https://placehold.co/400x300/1a237e/ffffff?text=Auriculares+Bluetooth+Premium', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(2,  2,  'https://placehold.co/400x300/1a237e/ffffff?text=Cable+USB-C+a+USB-A+2m', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(3,  3,  'https://placehold.co/400x300/1a237e/ffffff?text=Memoria+USB+64+GB+USB+3.0', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(4,  4,  'https://placehold.co/400x300/1a237e/ffffff?text=Cargador+Inal%C3%A1mbrico+15+W', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(5,  5,  'https://placehold.co/400x300/1a237e/ffffff?text=Teclado+Mec%C3%A1nico+Compacto', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(6,  6,  'https://placehold.co/400x300/1a237e/ffffff?text=Mouse+Inal%C3%A1mbrico+Ergon%C3%B3mico', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(7,  7,  'https://placehold.co/400x300/1a237e/ffffff?text=Hub+USB-C+7+en+1', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(8,  8,  'https://placehold.co/400x300/1a237e/ffffff?text=Control+para+PC%2FConsola', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(9,  9,  'https://placehold.co/400x300/e65100/ffffff?text=Salte%C3%B1a+de+Pollo', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(10, 10, 'https://placehold.co/400x300/e65100/ffffff?text=Salte%C3%B1a+de+Carne', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(11, 11, 'https://placehold.co/400x300/e65100/ffffff?text=Empanada+de+Queso', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(12, 12, 'https://placehold.co/400x300/e65100/ffffff?text=Arroz+con+Pollo+Criollo', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(13, 13, 'https://placehold.co/400x300/e65100/ffffff?text=Hamburguesa+Especial', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(14, 14, 'https://placehold.co/400x300/e65100/ffffff?text=Sopa+de+Man%C3%AD', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(15, 15, 'https://placehold.co/400x300/e65100/ffffff?text=Refresco+de+Mocochinchi', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(16, 16, 'https://placehold.co/400x300/e65100/ffffff?text=Combo+Almuerzo+Completo', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(17, 17, 'https://placehold.co/400x300/1b5e20/ffffff?text=Paracetamol+500+mg+%2820+comp%29', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(18, 18, 'https://placehold.co/400x300/1b5e20/ffffff?text=Ibuprofeno+400+mg+%2815+comp%29', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(19, 19, 'https://placehold.co/400x300/1b5e20/ffffff?text=Alcohol+Isoprop%C3%ADlico+500+ml', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(20, 20, 'https://placehold.co/400x300/1b5e20/ffffff?text=Shampoo+Anti-Caspa+400+ml', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(21, 21, 'https://placehold.co/400x300/1b5e20/ffffff?text=Crema+Hidratante+Facial+50+g', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(22, 22, 'https://placehold.co/400x300/1b5e20/ffffff?text=Jab%C3%B3n+Antibacterial+x3', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(23, 23, 'https://placehold.co/400x300/1b5e20/ffffff?text=Leche+Entera+1+L', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(24, 24, 'https://placehold.co/400x300/1b5e20/ffffff?text=Arroz+1+kg', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(25, 25, 'https://placehold.co/400x300/1b5e20/ffffff?text=Aceite+Vegetal+1+L', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40'),
(26, 26, 'https://placehold.co/400x300/1b5e20/ffffff?text=Vitamina+C+1000+mg+%2830+comp%29', 0, 1, '2026-06-16 16:31:40', '2026-06-16 16:31:40');

-- =====================================================================
-- 8. VISTAS
-- =====================================================================

-- Sanciones que están en efecto ahora mismo (las advertencias no cuentan).
CREATE VIEW v_sancion_activa AS
SELECT *
FROM sancion
WHERE tipo <> 'advertencia'
  AND revocada_en IS NULL
  AND inicia_en <= UTC_TIMESTAMP()
  AND (termina_en IS NULL OR termina_en > UTC_TIMESTAMP());

-- Catálogo listo para la app del cliente (precio final con oferta vigente).
-- Excluye negocios y productos con sanción vigente.
CREATE VIEW v_catalogo_producto AS
SELECT
  p.id,
  p.nombre,
  p.descripcion,
  p.precio,
  CASE WHEN p.oferta_vigente = 1 THEN p.precio_oferta ELSE p.precio END                       AS precio_final,
  p.oferta_vigente                                                                             AS en_oferta,
  CASE WHEN p.oferta_vigente = 1 THEN ROUND((1 - p.precio_oferta / p.precio) * 100) ELSE 0 END AS descuento_pct,
  p.stock,
  p.rating_promedio,
  p.total_resenas,
  p.total_vendidos,
  (SELECT pi.url FROM producto_imagen pi WHERE pi.producto_id = p.id
    ORDER BY pi.es_principal DESC, pi.orden LIMIT 1)                                      AS imagen_url,
  c.id               AS categoria_id,
  c.nombre           AS categoria,
  c.icono            AS categoria_icono,
  COALESCE(cp.id, c.id)         AS categoria_principal_id,
  COALESCE(cp.nombre, c.nombre) AS categoria_principal,
  n.id               AS negocio_id,
  n.nombre           AS negocio,
  n.logo_url         AS negocio_logo,
  n.rating_promedio  AS negocio_rating,
  n.abierto          AS negocio_abierto,
  n.latitud          AS negocio_latitud,
  n.longitud         AS negocio_longitud
FROM (
  SELECT pr.*,
         (pr.precio_oferta IS NOT NULL
          AND (pr.oferta_inicio IS NULL OR pr.oferta_inicio <= NOW())
          AND (pr.oferta_fin    IS NULL OR pr.oferta_fin    >= NOW())) AS oferta_vigente
  FROM producto pr
) p
JOIN negocio   n ON n.id = p.negocio_id
JOIN categoria c ON c.id = p.categoria_id
LEFT JOIN categoria cp ON cp.id = c.categoria_padre_id
WHERE p.deleted_at IS NULL
  AND p.disponible = 1
  AND n.deleted_at IS NULL
  AND n.estado_verificacion = 'aprobado'
  AND NOT EXISTS (
    SELECT 1 FROM v_sancion_activa s
    WHERE (s.tipo = 'retiro_producto' AND s.producto_id = p.id)
       OR (s.tipo IN ('suspension','bloqueo')
           AND (s.negocio_id = n.id
                OR (s.negocio_id IS NULL AND s.usuario_id = n.usuario_id
                    AND s.rol_afectado IN ('comerciante','todos'))))
  );

-- Qué vistas puede usar cada usuario (para el botón "cambiar a vista…").
CREATE VIEW v_usuario_roles AS
SELECT
  u.id                                    AS usuario_id,
  u.nombre,
  u.apellido,
  u.email,
  u.rol_activo,
  (r.usuario_id IS NOT NULL)              AS es_repartidor,
  r.estado_verificacion                   AS estado_repartidor,
  (SELECT COUNT(*) FROM negocio n WHERE n.usuario_id = u.id AND n.deleted_at IS NULL) AS total_negocios,
  u.es_admin,
  -- Sanciones vigentes por rol (1 = sancionado).
  EXISTS (SELECT 1 FROM v_sancion_activa s WHERE s.usuario_id = u.id AND s.tipo IN ('suspension','bloqueo') AND s.rol_afectado = 'todos')                      AS cuenta_bloqueada,
  EXISTS (SELECT 1 FROM v_sancion_activa s WHERE s.usuario_id = u.id AND s.tipo IN ('suspension','bloqueo') AND s.rol_afectado IN ('cliente','todos'))       AS sancionado_cliente,
  EXISTS (SELECT 1 FROM v_sancion_activa s WHERE s.usuario_id = u.id AND s.tipo IN ('suspension','bloqueo') AND s.rol_afectado IN ('repartidor','todos'))    AS sancionado_repartidor,
  EXISTS (SELECT 1 FROM v_sancion_activa s WHERE s.usuario_id = u.id AND s.tipo IN ('suspension','bloqueo') AND s.rol_afectado IN ('comerciante','todos') AND s.negocio_id IS NULL) AS sancionado_comerciante,
  (SELECT COUNT(*) FROM sancion s WHERE s.usuario_id = u.id AND s.tipo = 'advertencia') AS advertencias
FROM usuario u
LEFT JOIN repartidor r ON r.usuario_id = u.id
WHERE u.deleted_at IS NULL;

-- Resumen de pedidos: quién compró, a qué negocio y quién lo lleva.
CREATE VIEW v_pedido_resumen AS
SELECT
  pe.id,
  pe.estado,
  pe.total,
  pe.metodo_pago,
  pe.estado_pago,
  pe.created_at,
  pe.comprador_id,
  CONCAT_WS(' ', uc.nombre, uc.apellido) AS comprador,
  pe.negocio_id,
  n.nombre                               AS negocio,
  pe.repartidor_id,
  CONCAT_WS(' ', ur.nombre, ur.apellido) AS repartidor,
  tv.nombre                              AS vehiculo,
  v.placa,
  pe.direccion_entrega,
  pe.latitud_entrega,
  pe.longitud_entrega,
  (SELECT COUNT(*) FROM pedido_item i WHERE i.pedido_id = pe.id) AS total_items
FROM pedido pe
JOIN usuario  uc ON uc.id = pe.comprador_id
JOIN negocio  n  ON n.id  = pe.negocio_id
LEFT JOIN usuario       ur ON ur.id = pe.repartidor_id
LEFT JOIN vehiculo      v  ON v.id  = pe.vehiculo_id
LEFT JOIN tipo_vehiculo tv ON tv.id = v.tipo_vehiculo_id;

-- Resumen diario por negocio (base para gráficos del panel del comerciante).
-- `dia` está en hora de Bolivia.
CREATE VIEW v_registro_diario AS
SELECT
  negocio_id,
  DATE(CONVERT_TZ(fecha, '+00:00', (SELECT valor FROM configuracion WHERE clave = 'zona_horaria'))) AS dia,
  SUM(ingreso)                                         AS ventas,
  SUM(costo_vendido)                                   AS costo_de_lo_vendido,
  SUM(ganancia)                                        AS ganancia_bruta,
  SUM(IF(tipo = 'compra',   egreso, 0))                AS compras,
  SUM(IF(tipo = 'gasto',    egreso, 0))                AS gastos,
  SUM(IF(tipo = 'comision', egreso, 0))                AS comisiones,
  SUM(ganancia) - SUM(IF(tipo IN ('gasto','comision'), egreso, 0)) AS ganancia_neta,
  SUM(ingreso) - SUM(egreso)                           AS flujo_caja,
  SUM(IF(tipo = 'venta', cantidad, 0))                 AS unidades_vendidas
FROM registro_comercio
GROUP BY negocio_id, dia;

-- Panel del admin: qué tiene reportes abiertos, cuántas personas lo
-- reportaron y la gravedad máxima. Lo más urgente primero.
CREATE VIEW v_reportes_pendientes AS
SELECT
  r.tipo,
  r.objetivo_id,
  CASE r.tipo
    WHEN 'producto'   THEN (SELECT nombre FROM producto WHERE id = r.objetivo_id)
    WHEN 'negocio'    THEN (SELECT nombre FROM negocio  WHERE id = r.objetivo_id)
    WHEN 'repartidor' THEN (SELECT CONCAT_WS(' ', nombre, apellido) FROM usuario WHERE id = r.objetivo_id)
    WHEN 'usuario'    THEN (SELECT CONCAT_WS(' ', nombre, apellido) FROM usuario WHERE id = r.objetivo_id)
    ELSE CONCAT('Reseña #', r.objetivo_id)
  END                                                                 AS objetivo,
  COUNT(*)                                                            AS total_reportes,
  COUNT(DISTINCT r.reportante_id)                                     AS personas_que_reportan,
  ELT(MAX(FIELD(m.gravedad, 'baja', 'media', 'alta')), 'baja', 'media', 'alta') AS gravedad,
  GROUP_CONCAT(DISTINCT m.nombre ORDER BY m.nombre SEPARATOR ' · ')   AS motivos,
  MIN(r.created_at)                                                   AS primer_reporte,
  MAX(r.created_at)                                                   AS ultimo_reporte
FROM reporte r
JOIN motivo_reporte m ON m.id = r.motivo_id
WHERE r.estado IN ('pendiente','en_revision')
GROUP BY r.tipo, r.objetivo_id
ORDER BY MAX(FIELD(m.gravedad, 'baja', 'media', 'alta')) DESC, personas_que_reportan DESC, ultimo_reporte DESC;

COMMIT;

-- =====================================================================
-- 9. PROCEDIMIENTOS Y TRIGGERS
-- =====================================================================
DELIMITER $$

-- ---------- Sanciones ----------

-- ¿El usuario tiene una suspensión o bloqueo vigente para ese rol?
-- p_rol: 'cliente' | 'repartidor' | 'comerciante' | 'todos'
-- Con 'todos' responde si la cuenta entera está bloqueada (usar en el login).
CREATE FUNCTION fn_sancion_activa(p_usuario_id BIGINT UNSIGNED, p_rol VARCHAR(20))
RETURNS TINYINT
READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM v_sancion_activa
                  WHERE usuario_id = p_usuario_id
                    AND tipo IN ('suspension','bloqueo')
                    AND (rol_afectado = p_rol OR rol_afectado = 'todos'));
END$$

-- ¿El negocio está suspendido (él solo, o su dueño como comerciante)?
CREATE FUNCTION fn_negocio_sancionado(p_negocio_id BIGINT UNSIGNED)
RETURNS TINYINT
READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM v_sancion_activa s JOIN negocio n ON n.id = p_negocio_id
                  WHERE s.tipo IN ('suspension','bloqueo')
                    AND (s.negocio_id = n.id
                         OR (s.negocio_id IS NULL AND s.usuario_id = n.usuario_id
                             AND s.rol_afectado IN ('comerciante','todos'))));
END$$

-- Antes de guardar un reporte:
--  * el motivo tiene que corresponder a lo que se reporta;
--  * nadie puede reportarse a sí mismo (ni a su negocio, productos o reseñas);
--  * a una PERSONA (repartidor o cliente) solo se la puede reportar si
--    compartió un pedido con quien reporta. Productos, negocios y reseñas
--    los puede reportar cualquiera, porque son públicos.
CREATE TRIGGER trg_reporte_bi BEFORE INSERT ON reporte FOR EACH ROW
BEGIN
  DECLARE v_pedido BIGINT UNSIGNED;

  IF NOT EXISTS (SELECT 1 FROM motivo_reporte
                  WHERE id = NEW.motivo_id AND activo = 1 AND FIND_IN_SET(NEW.tipo, aplica_a)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ese motivo no corresponde a lo que se reporta';
  END IF;

  IF (NEW.tipo = 'usuario'    AND NEW.usuario_id    = NEW.reportante_id)
  OR (NEW.tipo = 'repartidor' AND NEW.repartidor_id = NEW.reportante_id)
  OR (NEW.tipo = 'negocio'  AND EXISTS (SELECT 1 FROM negocio WHERE id = NEW.negocio_id AND usuario_id = NEW.reportante_id))
  OR (NEW.tipo = 'producto' AND EXISTS (SELECT 1 FROM producto p JOIN negocio n ON n.id = p.negocio_id
                                         WHERE p.id = NEW.producto_id AND n.usuario_id = NEW.reportante_id))
  OR (NEW.tipo = 'resena'   AND EXISTS (SELECT 1 FROM resena WHERE id = NEW.resena_id AND autor_id = NEW.reportante_id)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puedes reportarte a ti mismo';
  END IF;

  IF NEW.tipo = 'repartidor' THEN
    SET v_pedido = (SELECT pe.id FROM pedido pe JOIN negocio n ON n.id = pe.negocio_id
                     WHERE pe.repartidor_id = NEW.repartidor_id
                       AND (pe.comprador_id = NEW.reportante_id OR n.usuario_id = NEW.reportante_id)
                     ORDER BY pe.id DESC LIMIT 1);
    IF v_pedido IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puedes reportar a un repartidor que llevó uno de tus pedidos';
    END IF;
  ELSEIF NEW.tipo = 'usuario' THEN
    SET v_pedido = (SELECT pe.id FROM pedido pe JOIN negocio n ON n.id = pe.negocio_id
                     WHERE pe.comprador_id = NEW.usuario_id
                       AND (pe.repartidor_id = NEW.reportante_id OR n.usuario_id = NEW.reportante_id)
                     ORDER BY pe.id DESC LIMIT 1);
    IF v_pedido IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puedes reportar a un cliente con el que tuviste un pedido';
    END IF;
  END IF;

  IF NEW.pedido_id IS NULL THEN
    SET NEW.pedido_id = v_pedido;
  END IF;
END$$

-- Al aplicar una sanción ligada a un reporte, se cierran como 'resuelto'
-- todos los reportes abiertos contra el mismo objetivo.
CREATE TRIGGER trg_sancion_ai AFTER INSERT ON sancion FOR EACH ROW
BEGIN
  IF NEW.reporte_id IS NOT NULL THEN
    UPDATE reporte r
      JOIN reporte origen ON origen.id = NEW.reporte_id
       SET r.estado       = 'resuelto',
           r.resolucion   = CONCAT('Sanción #', NEW.id, ': ', NEW.tipo),
           r.revisado_por = NEW.aplicada_por,
           r.revisado_en  = UTC_TIMESTAMP()
     WHERE r.tipo = origen.tipo AND r.objetivo_id = origen.objetivo_id
       AND r.estado IN ('pendiente','en_revision');
  END IF;
END$$

-- Devuelve lo que le falta a un usuario para usar un rol.
-- Uso:  CALL sp_datos_faltantes(14, 'repartidor');
-- Resultado vacío = puede activar el rol (o ya lo tiene completo).
CREATE PROCEDURE sp_datos_faltantes(IN p_usuario_id BIGINT UNSIGNED, IN p_rol VARCHAR(20))
BEGIN
  SELECT dato FROM (
    SELECT 'apellido' AS dato FROM usuario
     WHERE id = p_usuario_id AND (apellido IS NULL OR apellido = '')
    UNION ALL
    SELECT 'ci_numero' FROM usuario
     WHERE id = p_usuario_id AND (ci_numero IS NULL OR ci_numero = '')
    UNION ALL
    SELECT 'vehiculo' FROM DUAL
     WHERE p_rol = 'repartidor'
       AND NOT EXISTS (SELECT 1 FROM vehiculo WHERE repartidor_id = p_usuario_id AND deleted_at IS NULL)
    UNION ALL
    SELECT CONCAT('vehiculo.ruat:', v.id)
      FROM vehiculo v JOIN tipo_vehiculo t ON t.id = v.tipo_vehiculo_id
     WHERE p_rol = 'repartidor' AND v.repartidor_id = p_usuario_id AND v.deleted_at IS NULL
       AND t.requiere_ruat = 1 AND (v.ruat IS NULL OR v.ruat = '')
    UNION ALL
    SELECT CONCAT('vehiculo.placa:', v.id)
      FROM vehiculo v JOIN tipo_vehiculo t ON t.id = v.tipo_vehiculo_id
     WHERE p_rol = 'repartidor' AND v.repartidor_id = p_usuario_id AND v.deleted_at IS NULL
       AND t.requiere_placa = 1 AND (v.placa IS NULL OR v.placa = '')
    UNION ALL
    SELECT 'negocio' FROM DUAL
     WHERE p_rol = 'comerciante'
       AND NOT EXISTS (SELECT 1 FROM negocio WHERE usuario_id = p_usuario_id AND deleted_at IS NULL)
    UNION ALL
    SELECT CONCAT('negocio.ubicacion:', n.id) FROM negocio n
     WHERE p_rol = 'comerciante' AND n.usuario_id = p_usuario_id AND n.deleted_at IS NULL
       AND (n.latitud IS NULL OR n.longitud IS NULL)
    UNION ALL
    SELECT CONCAT('negocio.foto:', n.id) FROM negocio n
     WHERE p_rol = 'comerciante' AND n.usuario_id = p_usuario_id AND n.deleted_at IS NULL
       AND (n.logo_url IS NULL OR n.logo_url = '')
    UNION ALL
    -- Documentos de la PERSONA (carnet, licencia). Los que dependen del
    -- vehículo (licencia) solo se piden si algún vehículo en uso los exige.
    SELECT CONCAT('documento.', td.codigo)
      FROM requisito_rol rr JOIN tipo_documento td ON td.id = rr.tipo_documento_id
     WHERE rr.rol = p_rol AND rr.obligatorio = 1 AND td.activo = 1 AND td.ambito = 'persona'
       AND (td.condicion_vehiculo IS NULL
            OR EXISTS (SELECT 1 FROM vehiculo v JOIN tipo_vehiculo t ON t.id = v.tipo_vehiculo_id
                        WHERE v.repartidor_id = p_usuario_id AND v.en_uso = 1 AND v.deleted_at IS NULL
                          AND CASE td.condicion_vehiculo
                                WHEN 'requiere_placa'    THEN t.requiere_placa
                                WHEN 'requiere_ruat'     THEN t.requiere_ruat
                                WHEN 'requiere_licencia' THEN t.requiere_licencia
                              END = 1))
       AND NOT EXISTS (SELECT 1 FROM documento d
                        WHERE d.usuario_id = p_usuario_id
                          AND d.tipo_documento_id = td.id
                          AND d.estado <> 'rechazado')
    UNION ALL
    -- Documentos de cada VEHÍCULO en uso (foto, placa, RUAT), según su tipo.
    SELECT CONCAT('documento.', td.codigo, ':vehiculo', v.id)
      FROM requisito_rol rr
      JOIN tipo_documento td ON td.id = rr.tipo_documento_id
      JOIN vehiculo v        ON v.repartidor_id = p_usuario_id AND v.en_uso = 1 AND v.deleted_at IS NULL
      JOIN tipo_vehiculo t   ON t.id = v.tipo_vehiculo_id
     WHERE rr.rol = p_rol AND rr.obligatorio = 1 AND td.activo = 1 AND td.ambito = 'vehiculo'
       AND (td.condicion_vehiculo IS NULL
            OR CASE td.condicion_vehiculo
                 WHEN 'requiere_placa'    THEN t.requiere_placa
                 WHEN 'requiere_ruat'     THEN t.requiere_ruat
                 WHEN 'requiere_licencia' THEN t.requiere_licencia
               END = 1)
       AND NOT EXISTS (SELECT 1 FROM documento d
                        WHERE d.vehiculo_id = v.id
                          AND d.tipo_documento_id = td.id
                          AND d.estado <> 'rechazado')
    UNION ALL
    -- Documentos de cada NEGOCIO (NIT, si se marca obligatorio).
    SELECT CONCAT('documento.', td.codigo, ':negocio', n.id)
      FROM requisito_rol rr
      JOIN tipo_documento td ON td.id = rr.tipo_documento_id
      JOIN negocio n         ON n.usuario_id = p_usuario_id AND n.deleted_at IS NULL
     WHERE rr.rol = p_rol AND rr.obligatorio = 1 AND td.activo = 1 AND td.ambito = 'negocio'
       AND NOT EXISTS (SELECT 1 FROM documento d
                        WHERE d.negocio_id = n.id
                          AND d.tipo_documento_id = td.id
                          AND d.estado <> 'rechazado')
  ) faltantes;
END$$

-- Al subir un documento: los de vehículo deben indicar de qué vehículo
-- (y que sea del mismo usuario); los de negocio, de qué negocio.
CREATE TRIGGER trg_documento_bi BEFORE INSERT ON documento FOR EACH ROW
BEGIN
  DECLARE v_ambito VARCHAR(10);
  SET v_ambito = (SELECT ambito FROM tipo_documento WHERE id = NEW.tipo_documento_id);
  IF v_ambito = 'vehiculo' AND NOT EXISTS (SELECT 1 FROM vehiculo
                                            WHERE id = NEW.vehiculo_id AND repartidor_id = NEW.usuario_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este documento debe ir ligado a un vehículo tuyo';
  END IF;
  IF v_ambito = 'negocio' AND NOT EXISTS (SELECT 1 FROM negocio
                                           WHERE id = NEW.negocio_id AND usuario_id = NEW.usuario_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este documento debe ir ligado a un negocio tuyo';
  END IF;
END$$

-- Recalcula promedio y total de reseñas de un producto, negocio o repartidor.
CREATE PROCEDURE sp_recalcular_rating(IN p_tipo VARCHAR(20), IN p_id BIGINT UNSIGNED)
BEGIN
  IF p_tipo = 'producto' THEN
    UPDATE producto SET
      rating_promedio = (SELECT ROUND(AVG(estrellas), 2) FROM resena WHERE tipo = 'producto' AND producto_id = p_id AND visible = 1),
      total_resenas   = (SELECT COUNT(*) FROM resena WHERE tipo = 'producto' AND producto_id = p_id AND visible = 1)
    WHERE id = p_id;
  ELSEIF p_tipo = 'negocio' THEN
    UPDATE negocio SET
      rating_promedio = (SELECT ROUND(AVG(estrellas), 2) FROM resena WHERE tipo = 'negocio' AND negocio_id = p_id AND visible = 1),
      total_resenas   = (SELECT COUNT(*) FROM resena WHERE tipo = 'negocio' AND negocio_id = p_id AND visible = 1)
    WHERE id = p_id;
  ELSEIF p_tipo = 'repartidor' THEN
    UPDATE repartidor SET
      rating_promedio = (SELECT ROUND(AVG(estrellas), 2) FROM resena WHERE tipo = 'repartidor' AND repartidor_id = p_id AND visible = 1),
      total_resenas   = (SELECT COUNT(*) FROM resena WHERE tipo = 'repartidor' AND repartidor_id = p_id AND visible = 1)
    WHERE usuario_id = p_id;
  END IF;
END$$

CREATE TRIGGER trg_resena_ai AFTER INSERT ON resena FOR EACH ROW
BEGIN
  CALL sp_recalcular_rating(NEW.tipo, COALESCE(NEW.producto_id, NEW.negocio_id, NEW.repartidor_id));
END$$

CREATE TRIGGER trg_resena_au AFTER UPDATE ON resena FOR EACH ROW
BEGIN
  CALL sp_recalcular_rating(OLD.tipo, COALESCE(OLD.producto_id, OLD.negocio_id, OLD.repartidor_id));
  CALL sp_recalcular_rating(NEW.tipo, COALESCE(NEW.producto_id, NEW.negocio_id, NEW.repartidor_id));
END$$

CREATE TRIGGER trg_resena_ad AFTER DELETE ON resena FOR EACH ROW
BEGIN
  CALL sp_recalcular_rating(OLD.tipo, COALESCE(OLD.producto_id, OLD.negocio_id, OLD.repartidor_id));
END$$

-- ---------- Envío ----------

-- Precio del delivery para una distancia. NULL = fuera de cobertura.
-- Uso:  SELECT fn_costo_envio(4.2, 1);   -> 5.00
CREATE FUNCTION fn_costo_envio(p_km DECIMAL(6,2), p_categoria_vehiculo_id TINYINT UNSIGNED)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
  DECLARE v_cat TINYINT UNSIGNED DEFAULT COALESCE(p_categoria_vehiculo_id, 1);
  IF NOT EXISTS (SELECT 1 FROM tarifa_envio WHERE categoria_vehiculo_id = v_cat AND activo = 1) THEN
    SET v_cat = 1;
  END IF;
  RETURN (SELECT precio FROM tarifa_envio
           WHERE categoria_vehiculo_id = v_cat AND activo = 1 AND km_hasta >= p_km
           ORDER BY km_hasta LIMIT 1);
END$$

-- Distancia en línea recta (km) entre dos puntos GPS. Sirve de respaldo;
-- la distancia real por calles conviene sacarla de Google Maps en la app.
CREATE FUNCTION fn_distancia_km(p_lat1 DECIMAL(10,7), p_lng1 DECIMAL(10,7), p_lat2 DECIMAL(10,7), p_lng2 DECIMAL(10,7))
RETURNS DECIMAL(8,2)
DETERMINISTIC NO SQL
BEGIN
  RETURN ROUND(ST_Distance_Sphere(POINT(p_lng1, p_lat1), POINT(p_lng2, p_lat2)) / 1000, 2);
END$$

-- En qué anillo de Santa Cruz está un punto. NULL = fuera de cobertura
-- (más allá del 10mo anillo o en un anillo marcado sin cobertura).
-- Uso:  SELECT fn_anillo(-17.7745, -63.1935);   -> 2
CREATE FUNCTION fn_anillo(p_lat DECIMAL(10,7), p_lng DECIMAL(10,7))
RETURNS TINYINT UNSIGNED
READS SQL DATA
BEGIN
  DECLARE v_km DECIMAL(8,2);
  IF p_lat IS NULL OR p_lng IS NULL THEN
    RETURN NULL;
  END IF;
  SET v_km = fn_distancia_km(
    p_lat, p_lng,
    (SELECT CAST(valor AS DECIMAL(10,7)) FROM configuracion WHERE clave = 'centro_latitud'),
    (SELECT CAST(valor AS DECIMAL(10,7)) FROM configuracion WHERE clave = 'centro_longitud'));
  RETURN (SELECT numero FROM anillo
           WHERE radio_km >= v_km AND con_cobertura = 1
           ORDER BY radio_km LIMIT 1);
END$$

-- Precio del envío entre el negocio y el cliente.
--   p_km_ruta: km por calle que calcula la app con Google Maps. Si llega
--              NULL se estima con línea recta × factor_ruta.
-- Devuelve NULL si el negocio o el cliente están fuera del 10mo anillo.
-- Uso:  SELECT fn_cotizar_envio(-17.7745, -63.1935, -17.7953, -63.1868, NULL, 1);
CREATE FUNCTION fn_cotizar_envio(p_lat_origen DECIMAL(10,7), p_lng_origen DECIMAL(10,7),
                                 p_lat_destino DECIMAL(10,7), p_lng_destino DECIMAL(10,7),
                                 p_km_ruta DECIMAL(6,2), p_categoria_vehiculo_id TINYINT UNSIGNED)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
  DECLARE v_km DECIMAL(6,2);
  IF fn_anillo(p_lat_origen, p_lng_origen) IS NULL OR fn_anillo(p_lat_destino, p_lng_destino) IS NULL THEN
    RETURN NULL;
  END IF;
  SET v_km = COALESCE(
    p_km_ruta,
    fn_distancia_km(p_lat_origen, p_lng_origen, p_lat_destino, p_lng_destino)
      * (SELECT CAST(valor AS DECIMAL(4,2)) FROM configuracion WHERE clave = 'factor_ruta'));
  RETURN fn_costo_envio(v_km, p_categoria_vehiculo_id);
END$$

-- Al crear un pedido: bloquea compradores o negocios sancionados y guarda
-- en qué anillo se entrega.
CREATE TRIGGER trg_pedido_bi BEFORE INSERT ON pedido FOR EACH ROW
BEGIN
  IF fn_sancion_activa(NEW.comprador_id, 'cliente') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu cuenta tiene una sanción vigente y no puede hacer pedidos';
  END IF;
  IF fn_negocio_sancionado(NEW.negocio_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este negocio está suspendido';
  END IF;
  IF NEW.anillo_entrega IS NULL THEN
    SET NEW.anillo_entrega = fn_anillo(NEW.latitud_entrega, NEW.longitud_entrega);
  END IF;
END$$

-- No se puede asignar un pedido a un repartidor sancionado.
CREATE TRIGGER trg_pedido_bu BEFORE UPDATE ON pedido FOR EACH ROW
BEGIN
  IF NEW.repartidor_id IS NOT NULL AND NOT (NEW.repartidor_id <=> OLD.repartidor_id)
     AND fn_sancion_activa(NEW.repartidor_id, 'repartidor') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este repartidor está suspendido';
  END IF;
END$$

-- ---------- Reportes del comerciante ----------

-- Ganancias agrupadas por día, semana, mes o año entre dos fechas.
-- Uso:  CALL sp_reporte_negocio(2, '2026-06-01', '2026-06-30', 'dia');
--       p_agrupar: 'dia' | 'semana' | 'mes' | 'anio'. Fechas NULL = sin límite.
--       Las fechas y los periodos están en hora de Bolivia.
CREATE PROCEDURE sp_reporte_negocio(IN p_negocio_id BIGINT UNSIGNED, IN p_desde DATE, IN p_hasta DATE, IN p_agrupar VARCHAR(10))
BEGIN
  DECLARE v_tz VARCHAR(6) DEFAULT COALESCE((SELECT valor FROM configuracion WHERE clave = 'zona_horaria'), '-04:00');
  SELECT
    CASE p_agrupar
      WHEN 'dia'    THEN DATE_FORMAT(fecha_local, '%Y-%m-%d')
      WHEN 'semana' THEN DATE_FORMAT(fecha_local, '%x-S%v')
      WHEN 'mes'    THEN DATE_FORMAT(fecha_local, '%Y-%m')
      ELSE               DATE_FORMAT(fecha_local, '%Y')
    END                                                  AS periodo,
    MIN(DATE(fecha_local))                               AS desde,
    MAX(DATE(fecha_local))                               AS hasta,
    SUM(ingreso)                                         AS ventas,
    SUM(costo_vendido)                                   AS costo_de_lo_vendido,
    SUM(ganancia)                                        AS ganancia_bruta,
    SUM(IF(tipo = 'compra',   egreso, 0))                AS compras,
    SUM(IF(tipo = 'gasto',    egreso, 0))                AS gastos,
    SUM(IF(tipo = 'comision', egreso, 0))                AS comisiones,
    SUM(ganancia) - SUM(IF(tipo IN ('gasto','comision'), egreso, 0)) AS ganancia_neta,
    SUM(ingreso) - SUM(egreso)                           AS flujo_caja,
    SUM(IF(tipo = 'venta', cantidad, 0))                 AS unidades_vendidas
  FROM (
    SELECT r.*, CONVERT_TZ(r.fecha, '+00:00', v_tz) AS fecha_local
    FROM registro_comercio r
    WHERE r.negocio_id = p_negocio_id
      -- Los límites se pasan a UTC para que el índice (negocio_id, fecha) se use.
      AND r.fecha >= CONVERT_TZ(COALESCE(p_desde, '1970-01-02'), v_tz, '+00:00')
      AND r.fecha <  CONVERT_TZ(COALESCE(p_hasta, '2999-12-30') + INTERVAL 1 DAY, v_tz, '+00:00')
  ) x
  GROUP BY periodo
  ORDER BY periodo;
END$$

-- Por producto: cuánto gastó comprándolo y cuánto ganó vendiéndolo.
-- Uso:  CALL sp_reporte_productos(2, '2026-06-01', '2026-06-30');
CREATE PROCEDURE sp_reporte_productos(IN p_negocio_id BIGINT UNSIGNED, IN p_desde DATE, IN p_hasta DATE)
BEGIN
  DECLARE v_tz VARCHAR(6) DEFAULT COALESCE((SELECT valor FROM configuracion WHERE clave = 'zona_horaria'), '-04:00');
  SELECT
    p.id                                                  AS producto_id,
    p.nombre                                              AS producto,
    SUM(IF(r.tipo = 'compra', r.cantidad, 0))             AS unidades_compradas,
    SUM(IF(r.tipo = 'compra', r.egreso,   0))             AS gasto_en_compras,
    SUM(IF(r.tipo = 'venta',  r.cantidad, 0))             AS unidades_vendidas,
    SUM(r.ingreso)                                        AS ventas,
    SUM(r.costo_vendido)                                  AS costo_de_lo_vendido,
    SUM(r.ganancia)                                       AS ganancia,
    ROUND(SUM(r.ganancia) / NULLIF(SUM(r.ingreso), 0) * 100, 1) AS margen_pct
  FROM registro_comercio r
  JOIN producto p ON p.id = r.producto_id
  WHERE r.negocio_id = p_negocio_id
    AND r.fecha >= CONVERT_TZ(COALESCE(p_desde, '1970-01-02'), v_tz, '+00:00')
    AND r.fecha <  CONVERT_TZ(COALESCE(p_hasta, '2999-12-30') + INTERVAL 1 DAY, v_tz, '+00:00')
  GROUP BY p.id, p.nombre
  ORDER BY ganancia DESC;
END$$

-- ---------- Productos en subcategoría ----------

-- Un producto siempre va en una subcategoría (ej. "Farmacia y medicamentos"),
-- no directamente en la principal ("Salud y Belleza").
CREATE TRIGGER trg_producto_bi BEFORE INSERT ON producto FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND categoria_padre_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Elige una subcategoría para el producto';
  END IF;
END$$

CREATE TRIGGER trg_producto_bu BEFORE UPDATE ON producto FOR EACH ROW
BEGIN
  IF NEW.categoria_id <> OLD.categoria_id
     AND NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND categoria_padre_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Elige una subcategoría para el producto';
  END IF;
END$$

-- ---------- Automatismos de pedidos y compras ----------

-- Al agregar un ítem: descuenta stock (o falla si no alcanza) y copia el
-- nombre y el costo actual del producto. El descuento es atómico, así dos
-- compras simultáneas no pueden vender la misma última unidad.
CREATE TRIGGER trg_pedido_item_bi BEFORE INSERT ON pedido_item FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM v_sancion_activa WHERE tipo = 'retiro_producto' AND producto_id = NEW.producto_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este producto fue retirado';
  END IF;
  UPDATE producto
     SET stock = stock - NEW.cantidad
   WHERE id = NEW.producto_id AND stock IS NOT NULL AND stock >= NEW.cantidad;
  IF ROW_COUNT() = 0 AND EXISTS (SELECT 1 FROM producto WHERE id = NEW.producto_id AND stock IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente';
  END IF;
  IF NEW.costo_unitario IS NULL THEN
    SET NEW.costo_unitario = (SELECT costo FROM producto WHERE id = NEW.producto_id);
  END IF;
  IF NEW.producto_nombre IS NULL OR NEW.producto_nombre = '' THEN
    SET NEW.producto_nombre = (SELECT nombre FROM producto WHERE id = NEW.producto_id);
  END IF;
END$$

-- Al entregar un pedido: registra la venta, la comisión y los contadores.
-- Si un pedido entregado cambia a otro estado (ej. reembolso), lo revierte.
CREATE TRIGGER trg_pedido_au AFTER UPDATE ON pedido FOR EACH ROW
BEGIN
  IF NEW.estado = 'entregado' AND OLD.estado <> 'entregado' THEN
    INSERT INTO registro_comercio (negocio_id, tipo, producto_id, pedido_id, pedido_item_id, cantidad,
                                   precio_unitario, costo_unitario, descripcion, fecha, created_at, updated_at)
    SELECT NEW.negocio_id, 'venta', i.producto_id, NEW.id, i.id, i.cantidad,
           i.precio_unitario, i.costo_unitario, CONCAT('Venta pedido #', NEW.id),
           COALESCE(NEW.entregado_en, UTC_TIMESTAMP()), NOW(), NOW()
    FROM pedido_item i WHERE i.pedido_id = NEW.id;

    IF NEW.comision_plataforma > 0 THEN
      INSERT INTO registro_comercio (negocio_id, tipo, pedido_id, cantidad, costo_unitario, descripcion, fecha, created_at, updated_at)
      VALUES (NEW.negocio_id, 'comision', NEW.id, 1, NEW.comision_plataforma,
              CONCAT('Comisión plataforma pedido #', NEW.id), COALESCE(NEW.entregado_en, UTC_TIMESTAMP()), NOW(), NOW());
    END IF;

    UPDATE producto p JOIN pedido_item i ON i.producto_id = p.id
       SET p.total_vendidos = p.total_vendidos + i.cantidad
     WHERE i.pedido_id = NEW.id;

    IF NEW.repartidor_id IS NOT NULL THEN
      UPDATE repartidor SET total_entregas = total_entregas + 1 WHERE usuario_id = NEW.repartidor_id;
    END IF;

  ELSEIF OLD.estado = 'entregado' AND NEW.estado <> 'entregado' THEN
    DELETE FROM registro_comercio WHERE pedido_id = NEW.id AND tipo IN ('venta','comision');

    UPDATE producto p JOIN pedido_item i ON i.producto_id = p.id
       SET p.total_vendidos = GREATEST(CAST(p.total_vendidos AS SIGNED) - i.cantidad, 0)
     WHERE i.pedido_id = NEW.id;

    IF OLD.repartidor_id IS NOT NULL THEN
      UPDATE repartidor SET total_entregas = GREATEST(CAST(total_entregas AS SIGNED) - 1, 0) WHERE usuario_id = OLD.repartidor_id;
    END IF;
  END IF;

  -- Pedido cancelado o rechazado: devuelve el stock.
  IF NEW.estado IN ('cancelado','rechazado') AND OLD.estado NOT IN ('cancelado','rechazado') THEN
    UPDATE producto p JOIN pedido_item i ON i.producto_id = p.id
       SET p.stock = p.stock + i.cantidad
     WHERE i.pedido_id = NEW.id AND p.stock IS NOT NULL;
  END IF;
END$$

-- Antes de crear una reseña:
--  * nadie puede reseñarse a sí mismo (su negocio, sus productos o a sí como repartidor);
--  * el autor debe tener al menos un pedido ENTREGADO con ese producto,
--    negocio o repartidor. pedido_id se completa con el más reciente.
-- La regla de "una sola reseña por usuario" la garantiza uq_resena_unica.
CREATE TRIGGER trg_resena_bi BEFORE INSERT ON resena FOR EACH ROW
BEGIN
  DECLARE v_pedido BIGINT UNSIGNED;

  IF (NEW.tipo = 'repartidor' AND NEW.repartidor_id = NEW.autor_id)
  OR (NEW.tipo = 'negocio'  AND EXISTS (SELECT 1 FROM negocio WHERE id = NEW.negocio_id AND usuario_id = NEW.autor_id))
  OR (NEW.tipo = 'producto' AND EXISTS (SELECT 1 FROM producto p JOIN negocio n ON n.id = p.negocio_id
                                         WHERE p.id = NEW.producto_id AND n.usuario_id = NEW.autor_id)) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No puedes reseñarte a ti mismo';
  END IF;

  IF NEW.tipo = 'producto' THEN
    SET v_pedido = (SELECT pe.id FROM pedido pe JOIN pedido_item i ON i.pedido_id = pe.id
                     WHERE pe.comprador_id = NEW.autor_id AND pe.estado = 'entregado' AND i.producto_id = NEW.producto_id
                     ORDER BY pe.id DESC LIMIT 1);
  ELSEIF NEW.tipo = 'negocio' THEN
    SET v_pedido = (SELECT id FROM pedido
                     WHERE comprador_id = NEW.autor_id AND estado = 'entregado' AND negocio_id = NEW.negocio_id
                     ORDER BY id DESC LIMIT 1);
  ELSE
    SET v_pedido = (SELECT id FROM pedido
                     WHERE comprador_id = NEW.autor_id AND estado = 'entregado' AND repartidor_id = NEW.repartidor_id
                     ORDER BY id DESC LIMIT 1);
  END IF;

  IF v_pedido IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo puedes reseñar después de recibir un pedido';
  END IF;
  SET NEW.pedido_id = v_pedido;
END$$

-- Al editar: solo se pueden cambiar estrellas, comentario, respuesta y
-- visibilidad; no el autor ni a quién va dirigida.
CREATE TRIGGER trg_resena_bu BEFORE UPDATE ON resena FOR EACH ROW
BEGIN
  IF NEW.autor_id <> OLD.autor_id OR NEW.tipo <> OLD.tipo
  OR NOT (NEW.producto_id   <=> OLD.producto_id)
  OR NOT (NEW.negocio_id    <=> OLD.negocio_id)
  OR NOT (NEW.repartidor_id <=> OLD.repartidor_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden editar las estrellas y el comentario';
  END IF;
END$$

-- Limpieza diaria del rastro GPS viejo (la tabla crece muy rápido).
CREATE EVENT ev_limpiar_ubicaciones
ON SCHEDULE EVERY 1 DAY STARTS (CURRENT_DATE + INTERVAL 1 DAY + INTERVAL 8 HOUR)
DO
BEGIN
  DECLARE v_dias INT DEFAULT COALESCE(
    (SELECT CAST(valor AS UNSIGNED) FROM configuracion WHERE clave = 'dias_historial_gps'), 30);
  DELETE FROM ubicacion_repartidor WHERE registrado_en < NOW() - INTERVAL v_dias DAY;
END$$

-- Al registrar una compra de mercadería: suma stock y guarda el nuevo costo.
CREATE TRIGGER trg_registro_ai AFTER INSERT ON registro_comercio FOR EACH ROW
BEGIN
  IF NEW.tipo = 'compra' AND NEW.producto_id IS NOT NULL THEN
    UPDATE producto
       SET stock = IF(stock IS NULL, NULL, stock + NEW.cantidad),
           costo = NEW.costo_unitario
     WHERE id = NEW.producto_id;
  END IF;
END$$

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;
