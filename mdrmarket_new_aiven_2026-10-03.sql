-- =====================================================================
--  MDR Market 2.0 · COPIA DE LA BASE DE PRODUCCIÓN (AIVEN)
--  Fecha de la copia: 2026-10-03 · MySQL 8.4 · base `mdrmarket_new`
-- =====================================================================
--
--  QUÉ ES ESTE ARCHIVO
--  -------------------
--  Una copia exacta de la base que usa la app publicada: estructura
--  (40 tablas, 6 vistas, 15 triggers, 10 funciones y procedimientos,
--  1 evento) y todos sus datos al momento de la copia. Se sacó con
--  mysqldump desde Aiven.
--
--  EL CASO AIVEN: DÓNDE VIVE LA BASE DE PRODUCCIÓN
--  -----------------------------------------------
--  * La API publicada (https://api-mdrmarket-production.up.railway.app/api)
--    corre en Railway, pero la base NO está en Railway: el plan gratuito
--    de Railway no alcanza para una base MySQL encendida todo el día
--    (se dormía y se cortaba a mitad de crearse). Por eso la base está en
--    Aiven for MySQL, plan Free.
--  * Servicio en Aiven: `mdrmarket-db` (proyecto `mdrmarket`, DigitalOcean,
--    San Francisco).
--      Host:     mdrmarket-db-mdrmarket.h.aivencloud.com
--      Puerto:   26451
--      Usuario:  avnadmin
--      Base:     mdrmarket_new
--      Clave:    se pide al dueño del proyecto (NUNCA se escribe en el repo)
--  * SSL OBLIGATORIO: hay que conectarse con el certificado `ca.pem` que se
--    descarga en la consola de Aiven (Overview → Connection information).
--    En Railway la API lo recibe en la variable DB_SSL_CA_BASE64.
--  * Aiven Free apaga la base si pasa mucho tiempo sin uso (avisa por
--    correo). Si la API empieza a responder error 500 en todo, revisa que
--    `mdrmarket-db` esté encendido en la consola de Aiven.
--  * Aiven acepta triggers, funciones y eventos
--    (log_bin_trust_function_creators = 1, event_scheduler = ON) y exige
--    PRIMARY KEY en todas las tablas: toda tabla nueva debe tener una.
--
--  PARA QUÉ SIRVE
--  --------------
--  Para tener en tu PC una copia idéntica a producción y probar ahí:
--    * Laragon: phpMyAdmin → Importar → este archivo.
--    * Docker o mysql:  mysql -u root -p < mdrmarket_new_aiven_2026-10-03.sql
--  Crea (o reemplaza) la base `mdrmarket_new` local.
--
--  🚨 PARA QUÉ NO SIRVE
--  --------------------
--  NO lo importes en Aiven. Cada tabla empieza con DROP TABLE: borraría los
--  datos reales. Los cambios de estructura en producción se hacen con un
--  archivo en `cambios/` (ver cambios/README.md).
--
--  DIFERENCIA CON `mdrmarketnewdatabase.sql`
--  -----------------------------------------
--  * mdrmarketnewdatabase.sql = script maestro con comentarios, para crear
--    la base desde cero en una instalación nueva.
--  * Este archivo = foto de cómo está producción en una fecha. Hoy tiene los
--    mismos datos de ejemplo; con el tiempo tendrá usuarios y pedidos reales.
--    Las copias futuras con datos de personas reales NO deben subirse a un
--    repositorio público.
--
--  CÓMO SE GENERÓ
--  --------------
--    mysqldump -h <host> -P 26451 -u avnadmin -p --ssl-mode=VERIFY_IDENTITY
--      --ssl-ca=ca.pem --single-transaction --routines --triggers --events
--      --set-gtid-purged=OFF --no-tablespaces mdrmarket_new
--  Se quitó `DEFINER=avnadmin@%` de vistas, triggers y rutinas para que se
--  pueda importar con cualquier usuario (root de Laragon, Docker, etc.).
-- =====================================================================

SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS `mdrmarket_new` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `mdrmarket_new`;

-- MySQL dump 10.13  Distrib 8.4.3, for Win64 (x86_64)
--
-- Host: mdrmarket-db-mdrmarket.h.aivencloud.com    Database: mdrmarket_new
-- ------------------------------------------------------
-- Server version	8.4.8

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `anillo`
--

DROP TABLE IF EXISTS `anillo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `anillo` (
  `numero` tinyint unsigned NOT NULL COMMENT '1 = dentro del 1er anillo (casco viejo)',
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `radio_km` decimal(5,2) NOT NULL,
  `con_cobertura` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`numero`),
  UNIQUE KEY `uq_anillo_radio` (`radio_km`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `anillo`
--

LOCK TABLES `anillo` WRITE;
/*!40000 ALTER TABLE `anillo` DISABLE KEYS */;
INSERT INTO `anillo` VALUES (1,'Casco viejo (1er anillo)',1.00,1),(2,'2do anillo',1.90,1),(3,'3er anillo',2.80,1),(4,'4to anillo',3.80,1),(5,'5to anillo',4.90,1),(6,'6to anillo',6.00,1),(7,'7mo anillo',7.30,1),(8,'8vo anillo',8.80,1),(9,'9no anillo',10.30,1),(10,'10mo anillo',12.00,1);
/*!40000 ALTER TABLE `anillo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` bigint NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
INSERT INTO `cache` VALUES ('mdr_market_cache_5af0d8defa08d5357c3d82eb92f085d6745bb953','i:1;',1791076246),('mdr_market_cache_5af0d8defa08d5357c3d82eb92f085d6745bb953:timer','i:1791076246;',1791076246),('mdr_market_cache_b9982b12e7b39d94f0ae76087ac7d3dd939a7382','i:1;',1791076220),('mdr_market_cache_b9982b12e7b39d94f0ae76087ac7d3dd939a7382:timer','i:1791076220;',1791076220);
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` bigint NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categoria`
--

DROP TABLE IF EXISTS `categoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categoria` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `categoria_padre_id` bigint unsigned DEFAULT NULL COMMENT 'NULL = categoría principal',
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `icono` varchar(16) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Emoji o nombre de ícono',
  `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `orden` smallint unsigned NOT NULL DEFAULT '0',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_categoria_nombre` (`nombre`),
  KEY `idx_categoria_padre` (`categoria_padre_id`,`orden`),
  CONSTRAINT `fk_categoria_padre` FOREIGN KEY (`categoria_padre_id`) REFERENCES `categoria` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1206 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categoria`
--

LOCK TABLES `categoria` WRITE;
/*!40000 ALTER TABLE `categoria` DISABLE KEYS */;
INSERT INTO `categoria` VALUES (1,NULL,'Alimentos y Bebidas','🍔','Comida, snacks y bebidas',1,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(2,NULL,'Salud y Belleza','💊','Cuidado personal, salud y cosmética',2,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(3,NULL,'Tecnología','💻','Electrónica, gadgets y accesorios tech',3,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(4,NULL,'Hogar, Decoración y Muebles','🏠','Muebles, decoración y artículos del hogar',4,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(5,NULL,'Moda y Accesorios','👕','Ropa, calzado y complementos',5,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(6,NULL,'Deportes y Outdoor','🏋️','Deportes, fitness y actividades al aire libre',6,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(7,NULL,'Automotriz','🚗','Accesorios y repuestos para vehículos',7,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(8,NULL,'Mascotas','🐾','Productos para mascotas y su cuidado',8,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(9,NULL,'Entretenimiento','🎮','Juegos, ocio y entretenimiento',9,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(10,NULL,'Oficina y Papelería','🏢','Suministros de oficina y papelería',10,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(11,NULL,'Bebés y Niños','👶','Productos para bebés y niños',11,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(12,NULL,'Ferretería, Construcción y Jardín','🔨','Herramientas, construcción y jardinería',12,1,'2026-06-16 16:31:37','2026-06-16 16:31:37'),(101,1,'Restaurantes y comida preparada','🍽️',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(102,1,'Supermercado y abarrotes','🛒',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(103,1,'Bebidas','🥤',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(104,1,'Panadería y repostería','🥐',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(105,1,'Snacks y dulces','🍫',NULL,5,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(201,2,'Farmacia y medicamentos','💊',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(202,2,'Cuidado personal e higiene','🧴',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(203,2,'Cosmética y cuidado de la piel','💄',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(204,2,'Vitaminas y suplementos','🌿',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(301,3,'Celulares y accesorios','📱',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(302,3,'Computación','🖥️',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(303,3,'Audio y video','🎧',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(304,3,'Cables y cargadores','🔌',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(401,4,'Muebles','🛋️',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(402,4,'Decoración','🖼️',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(403,4,'Cocina y comedor','🍳',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(404,4,'Limpieza del hogar','🧹',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(405,4,'Electrodomésticos','🔋',NULL,5,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(501,5,'Ropa de mujer','👗',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(502,5,'Ropa de hombre','👔',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(503,5,'Calzado','👟',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(504,5,'Carteras, bisutería y relojes','👜',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(601,6,'Fitness y gimnasio','💪',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(602,6,'Ciclismo','🚴',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(603,6,'Camping y aire libre','⛺',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(604,6,'Ropa deportiva','🎽',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(701,7,'Repuestos de auto','🔧',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(702,7,'Accesorios para vehículos','🚙',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(703,7,'Lubricantes y mantenimiento','🛢️',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(704,7,'Motos y repuestos de moto','🏍️',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(801,8,'Alimento para mascotas','🦴',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(802,8,'Accesorios y juguetes para mascotas','🎾',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(803,8,'Higiene y salud animal','🩺',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(901,9,'Videojuegos y consolas','🕹️',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(902,9,'Juegos de mesa y juguetes','🎲',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(903,9,'Libros','📚',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(904,9,'Música e instrumentos','🎸',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1001,10,'Útiles escolares','✏️',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1002,10,'Útiles de oficina','📎',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1003,10,'Impresión y tintas','🖨️',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1101,11,'Pañales e higiene del bebé','🧷',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1102,11,'Alimentación infantil','🍼',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1103,11,'Ropa infantil','🧸',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1104,11,'Juguetes para bebés','🪀',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1201,12,'Herramientas','🛠️',NULL,1,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1202,12,'Materiales de construcción','🧱',NULL,2,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1203,12,'Electricidad e iluminación','💡',NULL,3,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1204,12,'Plomería','🚰',NULL,4,1,'2026-10-04 00:59:43','2026-10-04 00:59:43'),(1205,12,'Jardinería','🌱',NULL,5,1,'2026-10-04 00:59:43','2026-10-04 00:59:43');
/*!40000 ALTER TABLE `categoria` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categoria_vehiculo`
--

DROP TABLE IF EXISTS `categoria_vehiculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categoria_vehiculo` (
  `id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `capacidad_kg_max` smallint unsigned DEFAULT NULL,
  `nivel` tinyint unsigned NOT NULL COMMENT '1 = más chico. Un vehículo de nivel N lleva pedidos de nivel <= N',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_categoria_vehiculo_codigo` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categoria_vehiculo`
--

LOCK TABLES `categoria_vehiculo` WRITE;
/*!40000 ALTER TABLE `categoria_vehiculo` DISABLE KEYS */;
INSERT INTO `categoria_vehiculo` VALUES (1,'liviano','Liviano','Motos y bicicletas: paquetes chicos y comida',20,1),(2,'mediano','Mediano','Autos y camionetas: compras grandes, muebles chicos',500,2),(3,'grande','Grande','Camiones: muebles, electrodomésticos, materiales de construcción',5000,3);
/*!40000 ALTER TABLE `categoria_vehiculo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `configuracion`
--

DROP TABLE IF EXISTS `configuracion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `configuracion` (
  `clave` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo` enum('string','int','decimal','bool','json') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'string',
  `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`clave`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion`
--

LOCK TABLES `configuracion` WRITE;
/*!40000 ALTER TABLE `configuracion` DISABLE KEYS */;
INSERT INTO `configuracion` VALUES ('centro_latitud','-17.7837300','decimal','Plaza 24 de Septiembre (punto 0 de los anillos)','2026-10-04 00:59:40'),('centro_longitud','-63.1821400','decimal','Plaza 24 de Septiembre (punto 0 de los anillos)','2026-10-04 00:59:40'),('comision_plataforma_pct','0','decimal','% de comisión que se descuenta al negocio','2026-10-04 00:59:40'),('dias_historial_gps','30','int','Días que se guarda el rastro GPS de los repartidores','2026-10-04 00:59:40'),('factor_ruta','1.30','decimal','Km por calle ≈ km en línea recta × factor (solo si la app no manda la distancia real)','2026-10-04 00:59:40'),('radio_busqueda_repartidor_km','5','int','Radio para ofrecer pedidos a repartidores','2026-10-04 00:59:40'),('tarifa_servicio','0.00','decimal','Cargo fijo de la plataforma al comprador (Bs)','2026-10-04 00:59:40'),('zona_horaria','-04:00','string','Hora de Bolivia. Los datos se guardan en UTC y los reportes se muestran en esta zona','2026-10-04 00:59:40');
/*!40000 ALTER TABLE `configuracion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `direccion`
--

DROP TABLE IF EXISTS `direccion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `direccion` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `etiqueta` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Casa, Trabajo…',
  `direccion` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `referencia` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitud` decimal(10,7) DEFAULT NULL,
  `longitud` decimal(10,7) DEFAULT NULL,
  `predeterminada` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_direccion_usuario` (`usuario_id`),
  CONSTRAINT `fk_direccion_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `direccion`
--

LOCK TABLES `direccion` WRITE;
/*!40000 ALTER TABLE `direccion` DISABLE KEYS */;
INSERT INTO `direccion` VALUES (1,8,'Casa','Calle Bolívar 210, Barrio Equipetrol Norte, Santa Cruz',NULL,NULL,NULL,1,'2026-06-16 16:31:39','2026-06-16 16:31:39'),(2,9,'Casa','Av. Cañoto 890, Barrio El Centro, Santa Cruz',NULL,NULL,NULL,1,'2026-06-16 16:31:39','2026-06-16 16:31:39'),(3,10,'Casa','Av. Beni 2345, Barrio Mutualista, Santa Cruz',NULL,NULL,NULL,1,'2026-06-16 16:31:40','2026-06-16 16:31:40');
/*!40000 ALTER TABLE `direccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispositivo`
--

DROP TABLE IF EXISTS `dispositivo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispositivo` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `plataforma` enum('android','ios','web') COLLATE utf8mb4_unicode_ci NOT NULL,
  `ultimo_uso_en` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dispositivo_token` (`token`),
  KEY `fk_dispositivo_usuario` (`usuario_id`),
  CONSTRAINT `fk_dispositivo_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispositivo`
--

LOCK TABLES `dispositivo` WRITE;
/*!40000 ALTER TABLE `dispositivo` DISABLE KEYS */;
/*!40000 ALTER TABLE `dispositivo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documento`
--

DROP TABLE IF EXISTS `documento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documento` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `tipo_documento_id` smallint unsigned NOT NULL,
  `vehiculo_id` bigint unsigned DEFAULT NULL COMMENT 'Si el documento es de un vehículo (RUAT)',
  `negocio_id` bigint unsigned DEFAULT NULL COMMENT 'Si el documento es de un negocio (NIT)',
  `archivo_url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado` enum('pendiente','aprobado','rechazado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `observacion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `revisado_por` bigint unsigned DEFAULT NULL,
  `revisado_en` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_documento_usuario` (`usuario_id`,`tipo_documento_id`),
  KEY `fk_documento_tipo` (`tipo_documento_id`),
  KEY `fk_documento_vehiculo` (`vehiculo_id`),
  KEY `fk_documento_negocio` (`negocio_id`),
  KEY `fk_documento_revisor` (`revisado_por`),
  CONSTRAINT `fk_documento_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_documento_revisor` FOREIGN KEY (`revisado_por`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_documento_tipo` FOREIGN KEY (`tipo_documento_id`) REFERENCES `tipo_documento` (`id`),
  CONSTRAINT `fk_documento_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_documento_vehiculo` FOREIGN KEY (`vehiculo_id`) REFERENCES `vehiculo` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documento`
--

LOCK TABLES `documento` WRITE;
/*!40000 ALTER TABLE `documento` DISABLE KEYS */;
/*!40000 ALTER TABLE `documento` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_documento_bi` BEFORE INSERT ON `documento` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `favorito`
--

DROP TABLE IF EXISTS `favorito`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favorito` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `producto_id` bigint unsigned DEFAULT NULL,
  `negocio_id` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_favorito_producto` (`usuario_id`,`producto_id`),
  UNIQUE KEY `uq_favorito_negocio` (`usuario_id`,`negocio_id`),
  KEY `fk_favorito_producto` (`producto_id`),
  KEY `fk_favorito_negocio` (`negocio_id`),
  CONSTRAINT `fk_favorito_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_favorito_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_favorito_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `favorito`
--

LOCK TABLES `favorito` WRITE;
/*!40000 ALTER TABLE `favorito` DISABLE KEYS */;
/*!40000 ALTER TABLE `favorito` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext COLLATE utf8mb4_unicode_ci,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` smallint unsigned NOT NULL,
  `reserved_at` int unsigned DEFAULT NULL,
  `available_at` int unsigned NOT NULL,
  `created_at` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `motivo_reporte`
--

DROP TABLE IF EXISTS `motivo_reporte`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `motivo_reporte` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `aplica_a` set('producto','negocio','repartidor','usuario','resena') COLLATE utf8mb4_unicode_ci NOT NULL,
  `gravedad` enum('baja','media','alta') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'media',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_motivo_reporte_codigo` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `motivo_reporte`
--

LOCK TABLES `motivo_reporte` WRITE;
/*!40000 ALTER TABLE `motivo_reporte` DISABLE KEYS */;
INSERT INTO `motivo_reporte` VALUES (1,'producto_falso','Producto falso o diferente a lo publicado','producto','alta',1),(2,'producto_prohibido','Producto peligroso, vencido o prohibido','producto','alta',1),(3,'precio_enganoso','Precio u oferta engañosa','producto,negocio','media',1),(4,'negocio_fraudulento','Negocio falso o fraudulento','negocio','alta',1),(5,'pedido_no_entregado','Cobró y no entregó el pedido','negocio,repartidor','alta',1),(6,'pedido_incompleto','Pedido incompleto o en mal estado','negocio,repartidor','media',1),(7,'cobro_indebido','Cobro de más o pidió dinero extra','negocio,repartidor','alta',1),(8,'maltrato','Maltrato, insultos o acoso','negocio,repartidor,usuario','alta',1),(9,'conduccion_peligrosa','Conducción peligrosa','repartidor','media',1),(10,'suplantacion','Se hace pasar por otra persona','negocio,repartidor,usuario','alta',1),(11,'pedido_falso','Pedido falso o broma (cliente no existe)','usuario','media',1),(12,'no_pago','No pagó el pedido','usuario','alta',1),(13,'resena_falsa','Reseña falsa','resena','media',1),(14,'resena_ofensiva','Reseña ofensiva o con datos personales','resena','media',1),(15,'otro','Otro motivo','producto,negocio,repartidor,usuario,resena','baja',1);
/*!40000 ALTER TABLE `motivo_reporte` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `negocio`
--

DROP TABLE IF EXISTS `negocio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `negocio` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL COMMENT 'Dueño (comerciante)',
  `categoria_id` bigint unsigned DEFAULT NULL COMMENT 'Rubro principal',
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `nit` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Opcional: si no tiene, se usa el CI del dueño',
  `razon_social` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `direccion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `referencia` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitud` decimal(10,7) DEFAULT NULL COMMENT 'Marcado con el GPS de la app',
  `longitud` decimal(10,7) DEFAULT NULL,
  `logo_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Foto del negocio',
  `banner_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tiempo_preparacion_min` smallint unsigned DEFAULT NULL,
  `pedido_minimo` decimal(10,2) NOT NULL DEFAULT '0.00',
  `abierto` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Interruptor manual abierto/cerrado',
  `estado_verificacion` enum('pendiente','aprobado','rechazado','suspendido') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `rating_promedio` decimal(3,2) DEFAULT NULL,
  `total_resenas` int unsigned NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_negocio_nit` (`nit`),
  KEY `idx_negocio_usuario` (`usuario_id`),
  KEY `idx_negocio_estado` (`estado_verificacion`,`abierto`),
  KEY `fk_negocio_categoria` (`categoria_id`),
  CONSTRAINT `fk_negocio_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_negocio_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `negocio`
--

LOCK TABLES `negocio` WRITE;
/*!40000 ALTER TABLE `negocio` DISABLE KEYS */;
INSERT INTO `negocio` VALUES (2,2,3,'TechStore SCZ','Tu tienda de tecnología y gadgets en el corazón de Equipetrol. Envíos rápidos a toda la ciudad.',NULL,NULL,'59177001001','Av. San Martín 453, Equipetrol, Santa Cruz',NULL,-17.7745000,-63.1935000,'https://placehold.co/150/1a237e/ffffff?text=Tech','https://placehold.co/600x200/1a237e/ffffff?text=TechStore+SCZ',NULL,0.00,1,'aprobado',NULL,0,'2026-06-16 16:31:37','2026-06-16 16:31:37',NULL),(3,3,1,'Sabor Cruceño','Auténtica gastronomía cruceña. Salteñas, empanadas, platos tradicionales con ingredientes frescos.',NULL,NULL,'59177002002','Calle Junín 320, Centro Histórico, Santa Cruz',NULL,-17.7859000,-63.1816000,'https://placehold.co/150/e65100/ffffff?text=Sabor','https://placehold.co/600x200/e65100/ffffff?text=Sabor+Cruce%C3%B1o',NULL,0.00,1,'aprobado',NULL,0,'2026-06-16 16:31:37','2026-06-16 16:31:37',NULL),(4,4,2,'FarmaSuper','Farmacia y supermercado. Medicamentos, cuidado personal y productos de primera necesidad las 24 horas.',NULL,NULL,'59177003003','Av. Beni 1560, 2do Anillo, Santa Cruz',NULL,-17.7696000,-63.1658000,'https://placehold.co/150/1b5e20/ffffff?text=Farma','https://placehold.co/600x200/1b5e20/ffffff?text=FarmaSuper',NULL,0.00,1,'aprobado',NULL,0,'2026-06-16 16:31:38','2026-06-16 16:31:38',NULL);
/*!40000 ALTER TABLE `negocio` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `negocio_horario`
--

DROP TABLE IF EXISTS `negocio_horario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `negocio_horario` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `negocio_id` bigint unsigned NOT NULL,
  `dia_semana` tinyint unsigned NOT NULL COMMENT '1 = lunes … 7 = domingo',
  `hora_apertura` time NOT NULL,
  `hora_cierre` time NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_negocio_horario` (`negocio_id`,`dia_semana`,`hora_apertura`),
  CONSTRAINT `fk_horario_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`) ON DELETE CASCADE,
  CONSTRAINT `chk_horario_dia` CHECK ((`dia_semana` between 1 and 7))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `negocio_horario`
--

LOCK TABLES `negocio_horario` WRITE;
/*!40000 ALTER TABLE `negocio_horario` DISABLE KEYS */;
/*!40000 ALTER TABLE `negocio_horario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notificacion`
--

DROP TABLE IF EXISTS `notificacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificacion` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL,
  `pedido_id` bigint unsigned DEFAULT NULL,
  `tipo` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'pedido_nuevo, pedido_en_camino, documento_aprobado…',
  `titulo` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cuerpo` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `datos` json DEFAULT NULL,
  `leida_en` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_notificacion_usuario` (`usuario_id`,`leida_en`),
  KEY `fk_notificacion_pedido` (`pedido_id`),
  CONSTRAINT `fk_notificacion_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_notificacion_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificacion`
--

LOCK TABLES `notificacion` WRITE;
/*!40000 ALTER TABLE `notificacion` DISABLE KEYS */;
/*!40000 ALTER TABLE `notificacion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_reset_tokens`
--

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedido`
--

DROP TABLE IF EXISTS `pedido`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `comprador_id` bigint unsigned NOT NULL COMMENT 'Cualquier usuario puede comprar',
  `negocio_id` bigint unsigned NOT NULL,
  `repartidor_id` bigint unsigned DEFAULT NULL,
  `vehiculo_id` bigint unsigned DEFAULT NULL,
  `direccion_id` bigint unsigned DEFAULT NULL COMMENT 'Dirección guardada usada (opcional)',
  `direccion_entrega` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Copia del texto al momento del pedido',
  `referencia_entrega` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitud_entrega` decimal(10,7) NOT NULL,
  `longitud_entrega` decimal(10,7) NOT NULL,
  `anillo_entrega` tinyint unsigned DEFAULT NULL COMMENT 'Anillo de la dirección de entrega (se calcula solo)',
  `notas` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `categoria_vehiculo_requerida_id` tinyint unsigned DEFAULT NULL,
  `estado` enum('pendiente','confirmado','preparando','listo','en_camino','entregado','cancelado','rechazado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `subtotal` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Suma de los ítems',
  `costo_envio` decimal(10,2) NOT NULL DEFAULT '0.00',
  `tarifa_servicio` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Cobrada al comprador',
  `descuento` decimal(10,2) NOT NULL DEFAULT '0.00',
  `total` decimal(10,2) GENERATED ALWAYS AS ((((`subtotal` + `costo_envio`) + `tarifa_servicio`) - `descuento`)) STORED,
  `comision_plataforma` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Se descuenta al negocio, no suma al total',
  `metodo_pago` enum('efectivo','qr','transferencia','tarjeta') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'efectivo',
  `estado_pago` enum('pendiente','pagado','fallido','reembolsado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `referencia_pago` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pagado_en` timestamp NULL DEFAULT NULL,
  `codigo_entrega` char(4) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'PIN que el cliente da al repartidor',
  `distancia_km` decimal(6,2) DEFAULT NULL,
  `tiempo_estimado_min` smallint unsigned DEFAULT NULL,
  `confirmado_en` timestamp NULL DEFAULT NULL,
  `asignado_en` timestamp NULL DEFAULT NULL,
  `recogido_en` timestamp NULL DEFAULT NULL,
  `entregado_en` timestamp NULL DEFAULT NULL,
  `cancelado_en` timestamp NULL DEFAULT NULL,
  `cancelado_por` bigint unsigned DEFAULT NULL,
  `motivo_cancelacion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_pedido_comprador` (`comprador_id`,`created_at`),
  KEY `idx_pedido_negocio` (`negocio_id`,`estado`),
  KEY `idx_pedido_repartidor` (`repartidor_id`,`estado`),
  KEY `idx_pedido_estado` (`estado`,`repartidor_id`),
  KEY `fk_pedido_vehiculo` (`vehiculo_id`),
  KEY `fk_pedido_direccion` (`direccion_id`),
  KEY `fk_pedido_cat_veh` (`categoria_vehiculo_requerida_id`),
  KEY `fk_pedido_cancelador` (`cancelado_por`),
  CONSTRAINT `fk_pedido_cancelador` FOREIGN KEY (`cancelado_por`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_pedido_cat_veh` FOREIGN KEY (`categoria_vehiculo_requerida_id`) REFERENCES `categoria_vehiculo` (`id`),
  CONSTRAINT `fk_pedido_comprador` FOREIGN KEY (`comprador_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `fk_pedido_direccion` FOREIGN KEY (`direccion_id`) REFERENCES `direccion` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_pedido_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`),
  CONSTRAINT `fk_pedido_repartidor` FOREIGN KEY (`repartidor_id`) REFERENCES `repartidor` (`usuario_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_pedido_vehiculo` FOREIGN KEY (`vehiculo_id`) REFERENCES `vehiculo` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_pedido_montos` CHECK (((`subtotal` >= 0) and (`costo_envio` >= 0) and (`tarifa_servicio` >= 0) and (`descuento` >= 0) and (`comision_plataforma` >= 0) and (`descuento` <= ((`subtotal` + `costo_envio`) + `tarifa_servicio`))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido`
--

LOCK TABLES `pedido` WRITE;
/*!40000 ALTER TABLE `pedido` DISABLE KEYS */;
/*!40000 ALTER TABLE `pedido` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_pedido_bi` BEFORE INSERT ON `pedido` FOR EACH ROW BEGIN
  IF fn_sancion_activa(NEW.comprador_id, 'cliente') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tu cuenta tiene una sanción vigente y no puede hacer pedidos';
  END IF;
  IF fn_negocio_sancionado(NEW.negocio_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este negocio está suspendido';
  END IF;
  IF NEW.anillo_entrega IS NULL THEN
    SET NEW.anillo_entrega = fn_anillo(NEW.latitud_entrega, NEW.longitud_entrega);
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_pedido_bu` BEFORE UPDATE ON `pedido` FOR EACH ROW BEGIN
  IF NEW.repartidor_id IS NOT NULL AND NOT (NEW.repartidor_id <=> OLD.repartidor_id)
     AND fn_sancion_activa(NEW.repartidor_id, 'repartidor') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este repartidor está suspendido';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_pedido_au` AFTER UPDATE ON `pedido` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `pedido_estado_historial`
--

DROP TABLE IF EXISTS `pedido_estado_historial`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido_estado_historial` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pedido_id` bigint unsigned NOT NULL,
  `estado_anterior` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado_nuevo` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `motivo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL COMMENT 'Quién hizo el cambio',
  `rol` enum('cliente','repartidor','comerciante','admin','sistema') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sistema',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_historial_pedido` (`pedido_id`,`created_at`),
  KEY `fk_historial_usuario` (`usuario_id`),
  CONSTRAINT `fk_historial_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_historial_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido_estado_historial`
--

LOCK TABLES `pedido_estado_historial` WRITE;
/*!40000 ALTER TABLE `pedido_estado_historial` DISABLE KEYS */;
/*!40000 ALTER TABLE `pedido_estado_historial` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedido_item`
--

DROP TABLE IF EXISTS `pedido_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido_item` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pedido_id` bigint unsigned NOT NULL,
  `producto_id` bigint unsigned NOT NULL,
  `producto_nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Copia del nombre al momento de la compra',
  `precio_unitario` decimal(10,2) NOT NULL COMMENT 'Precio cobrado (ya con oferta si aplicaba)',
  `costo_unitario` decimal(10,2) DEFAULT NULL COMMENT 'Costo del producto al momento de la venta (se copia solo)',
  `cantidad` smallint unsigned NOT NULL DEFAULT '1',
  `subtotal` decimal(10,2) GENERATED ALWAYS AS ((`precio_unitario` * `cantidad`)) STORED,
  `notas` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ej. "sin cebolla"',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_item_pedido` (`pedido_id`),
  KEY `idx_item_producto` (`producto_id`),
  CONSTRAINT `fk_item_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_item_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`),
  CONSTRAINT `chk_item_cantidad` CHECK ((`cantidad` > 0)),
  CONSTRAINT `chk_item_precio` CHECK ((`precio_unitario` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido_item`
--

LOCK TABLES `pedido_item` WRITE;
/*!40000 ALTER TABLE `pedido_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `pedido_item` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_pedido_item_bi` BEFORE INSERT ON `pedido_item` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `personal_access_tokens`
--

DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` bigint unsigned NOT NULL,
  `name` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `personal_access_tokens`
--

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `producto`
--

DROP TABLE IF EXISTS `producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `producto` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `negocio_id` bigint unsigned NOT NULL,
  `categoria_id` bigint unsigned NOT NULL,
  `categoria_vehiculo_id` tinyint unsigned DEFAULT NULL COMMENT 'Vehículo mínimo para llevarlo (NULL = liviano)',
  `nombre` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `precio` decimal(10,2) NOT NULL COMMENT 'Precio de venta',
  `costo` decimal(10,2) DEFAULT NULL COMMENT 'Lo que le cuesta al comerciante (se actualiza con cada compra registrada)',
  `precio_oferta` decimal(10,2) DEFAULT NULL COMMENT 'Opcional. Si tiene valor, el producto está en oferta',
  `oferta_inicio` datetime DEFAULT NULL,
  `oferta_fin` datetime DEFAULT NULL,
  `stock` int unsigned DEFAULT NULL COMMENT 'NULL = sin control de stock (ej. comida hecha al momento)',
  `disponible` tinyint(1) NOT NULL DEFAULT '1',
  `rating_promedio` decimal(3,2) DEFAULT NULL,
  `total_resenas` int unsigned NOT NULL DEFAULT '0',
  `total_vendidos` int unsigned NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_producto_negocio` (`negocio_id`,`disponible`),
  KEY `idx_producto_categoria` (`categoria_id`,`disponible`),
  KEY `fk_producto_vehiculo` (`categoria_vehiculo_id`),
  FULLTEXT KEY `ft_producto_busqueda` (`nombre`,`descripcion`),
  CONSTRAINT `fk_producto_categoria` FOREIGN KEY (`categoria_id`) REFERENCES `categoria` (`id`),
  CONSTRAINT `fk_producto_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`),
  CONSTRAINT `fk_producto_vehiculo` FOREIGN KEY (`categoria_vehiculo_id`) REFERENCES `categoria_vehiculo` (`id`),
  CONSTRAINT `chk_producto_fechas` CHECK (((`oferta_inicio` is null) or (`oferta_fin` is null) or (`oferta_inicio` < `oferta_fin`))),
  CONSTRAINT `chk_producto_oferta` CHECK (((`precio_oferta` is null) or ((`precio_oferta` >= 0) and (`precio_oferta` < `precio`)))),
  CONSTRAINT `chk_producto_precio` CHECK (((`precio` >= 0) and ((`costo` is null) or (`costo` >= 0))))
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `producto`
--

LOCK TABLES `producto` WRITE;
/*!40000 ALTER TABLE `producto` DISABLE KEYS */;
INSERT INTO `producto` VALUES (1,2,303,NULL,'Auriculares Bluetooth Premium','Auriculares inalámbricos con cancelación de ruido activa, 30 h de batería y sonido Hi-Fi.',185.00,NULL,NULL,NULL,NULL,14,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:15:28',NULL),(2,2,304,NULL,'Cable USB-C a USB-A 2m','Cable de carga rápida y datos USB-C trenzado nylon, compatible con Android y laptops.',14.50,NULL,NULL,NULL,NULL,52,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:15:28',NULL),(3,2,302,NULL,'Memoria USB 64 GB USB 3.0','Memoria flash de alta velocidad (hasta 120 MB/s) con carcasa compacta y resistente.',38.00,NULL,NULL,NULL,NULL,54,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-17 06:21:49',NULL),(4,2,301,NULL,'Cargador Inalámbrico 15 W','Pad de carga rápida inalámbrica Qi compatible con iPhone, Samsung y demás.',55.00,NULL,NULL,NULL,NULL,29,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:15:28',NULL),(5,2,302,NULL,'Teclado Mecánico Compacto','Teclado 75 % con switches rojos, retroiluminación RGB y conectividad USB-C.',165.00,NULL,NULL,NULL,NULL,14,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:15:28',NULL),(6,2,302,NULL,'Mouse Inalámbrico Ergonómico','Mouse vertical inalámbrico DPI ajustable, reduce la fatiga en largas sesiones de trabajo.',72.00,NULL,NULL,NULL,NULL,39,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:15:28',NULL),(7,2,302,NULL,'Hub USB-C 7 en 1','Hub multipuerto con HDMI 4K, USB-A, USB-C PD, lector SD/MicroSD y Ethernet.',95.00,NULL,NULL,NULL,NULL,19,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 02:46:44',NULL),(8,2,901,NULL,'Control para PC/Consola','Control Bluetooth compatible con PC, Android y consolas, vibración dual.',120.00,NULL,NULL,NULL,NULL,18,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(9,3,101,NULL,'Salteña de Pollo','Salteña horneada rellena de pollo jugoso, papa, arveja y huevo.',4.50,NULL,NULL,NULL,NULL,99,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:23:04',NULL),(10,3,101,NULL,'Salteña de Carne','Salteña tradicional con carne res, papa, arveja y ají.',5.00,NULL,NULL,NULL,NULL,99,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:23:04',NULL),(11,3,101,NULL,'Empanada de Queso','Empanada frita rellena de queso derretido.',3.50,NULL,NULL,NULL,NULL,78,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-17 19:13:24',NULL),(12,3,101,NULL,'Arroz con Pollo Criollo','Arroz graneado con pollo al mojo, yuca frita y ensalada fresca.',22.00,NULL,NULL,NULL,NULL,39,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:23:04',NULL),(13,3,101,NULL,'Hamburguesa Especial','Hamburguesa artesanal con doble carne, queso y salsa de la casa.',28.00,NULL,NULL,NULL,NULL,35,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(14,3,101,NULL,'Sopa de Maní','Sopa boliviana de maní con fideos, papa y carne.',18.00,NULL,NULL,NULL,NULL,29,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:23:04',NULL),(15,3,103,NULL,'Refresco de Mocochinchi','Bebida tradicional boliviana de durazno. 500 ml.',6.00,NULL,NULL,NULL,NULL,59,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:23:04',NULL),(16,3,101,NULL,'Combo Almuerzo Completo','Sopa + plato principal + refresco. Cambia diariamente.',38.00,NULL,NULL,NULL,NULL,20,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(17,4,201,NULL,'Paracetamol 500 mg (20 comp)','Analgésico y antipirético. Caja de 20 comprimidos.',8.50,NULL,NULL,NULL,NULL,200,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(18,4,201,NULL,'Ibuprofeno 400 mg (15 comp)','Antiinflamatorio y analgésico. Caja de 15 comprimidos.',10.00,NULL,NULL,NULL,NULL,150,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(19,4,201,NULL,'Alcohol Isopropílico 500 ml','Alcohol de uso médico al 70 %. Frasco sellado.',15.00,NULL,NULL,NULL,NULL,80,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(20,4,202,NULL,'Shampoo Anti-Caspa 400 ml','Control de caspa desde la primera aplicación.',22.00,NULL,NULL,NULL,NULL,60,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(21,4,203,NULL,'Crema Hidratante Facial 50 g','Hidratación con ácido hialurónico. Para todo tipo de piel.',28.00,NULL,NULL,NULL,NULL,45,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(22,4,202,NULL,'Jabón Antibacterial x3','Pack de 3 jabones de 90 g. Protección duradera.',9.00,NULL,NULL,NULL,NULL,120,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(23,4,102,NULL,'Leche Entera 1 L','Leche entera pasteurizada local. Entrega el mismo día.',9.50,NULL,NULL,NULL,NULL,89,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:23:04',NULL),(24,4,102,NULL,'Arroz 1 kg','Arroz blanco de grano largo, cosecha santa crucera.',7.50,NULL,NULL,NULL,NULL,200,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL),(25,4,102,NULL,'Aceite Vegetal 1 L','Aceite de girasol refinado, sin colesterol.',12.00,NULL,NULL,NULL,NULL,109,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-18 06:23:04',NULL),(26,4,204,NULL,'Vitamina C 1000 mg (30 comp)','Suplemento efervescente. Refuerza el sistema inmunológico.',18.00,NULL,NULL,NULL,NULL,70,1,NULL,0,0,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL);
/*!40000 ALTER TABLE `producto` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_producto_bi` BEFORE INSERT ON `producto` FOR EACH ROW BEGIN
  IF NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND categoria_padre_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Elige una subcategoría para el producto';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_producto_bu` BEFORE UPDATE ON `producto` FOR EACH ROW BEGIN
  IF NEW.categoria_id <> OLD.categoria_id
     AND NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.categoria_id AND categoria_padre_id IS NOT NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Elige una subcategoría para el producto';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `producto_imagen`
--

DROP TABLE IF EXISTS `producto_imagen`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `producto_imagen` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `producto_id` bigint unsigned NOT NULL,
  `url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `orden` tinyint unsigned NOT NULL DEFAULT '0',
  `es_principal` tinyint(1) NOT NULL DEFAULT '0',
  `principal_de` bigint unsigned GENERATED ALWAYS AS (if((`es_principal` = 1),`producto_id`,NULL)) STORED,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_producto_imagen_principal` (`principal_de`),
  KEY `idx_producto_imagen` (`producto_id`,`orden`),
  CONSTRAINT `fk_imagen_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `producto_imagen`
--

LOCK TABLES `producto_imagen` WRITE;
/*!40000 ALTER TABLE `producto_imagen` DISABLE KEYS */;
INSERT INTO `producto_imagen` (`id`, `producto_id`, `url`, `orden`, `es_principal`, `created_at`, `updated_at`) VALUES (1,1,'https://placehold.co/400x300/1a237e/ffffff?text=Auriculares+Bluetooth+Premium',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(2,2,'https://placehold.co/400x300/1a237e/ffffff?text=Cable+USB-C+a+USB-A+2m',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(3,3,'https://placehold.co/400x300/1a237e/ffffff?text=Memoria+USB+64+GB+USB+3.0',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(4,4,'https://placehold.co/400x300/1a237e/ffffff?text=Cargador+Inal%C3%A1mbrico+15+W',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(5,5,'https://placehold.co/400x300/1a237e/ffffff?text=Teclado+Mec%C3%A1nico+Compacto',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(6,6,'https://placehold.co/400x300/1a237e/ffffff?text=Mouse+Inal%C3%A1mbrico+Ergon%C3%B3mico',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(7,7,'https://placehold.co/400x300/1a237e/ffffff?text=Hub+USB-C+7+en+1',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(8,8,'https://placehold.co/400x300/1a237e/ffffff?text=Control+para+PC%2FConsola',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(9,9,'https://placehold.co/400x300/e65100/ffffff?text=Salte%C3%B1a+de+Pollo',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(10,10,'https://placehold.co/400x300/e65100/ffffff?text=Salte%C3%B1a+de+Carne',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(11,11,'https://placehold.co/400x300/e65100/ffffff?text=Empanada+de+Queso',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(12,12,'https://placehold.co/400x300/e65100/ffffff?text=Arroz+con+Pollo+Criollo',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(13,13,'https://placehold.co/400x300/e65100/ffffff?text=Hamburguesa+Especial',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(14,14,'https://placehold.co/400x300/e65100/ffffff?text=Sopa+de+Man%C3%AD',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(15,15,'https://placehold.co/400x300/e65100/ffffff?text=Refresco+de+Mocochinchi',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(16,16,'https://placehold.co/400x300/e65100/ffffff?text=Combo+Almuerzo+Completo',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(17,17,'https://placehold.co/400x300/1b5e20/ffffff?text=Paracetamol+500+mg+%2820+comp%29',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(18,18,'https://placehold.co/400x300/1b5e20/ffffff?text=Ibuprofeno+400+mg+%2815+comp%29',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(19,19,'https://placehold.co/400x300/1b5e20/ffffff?text=Alcohol+Isoprop%C3%ADlico+500+ml',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(20,20,'https://placehold.co/400x300/1b5e20/ffffff?text=Shampoo+Anti-Caspa+400+ml',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(21,21,'https://placehold.co/400x300/1b5e20/ffffff?text=Crema+Hidratante+Facial+50+g',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(22,22,'https://placehold.co/400x300/1b5e20/ffffff?text=Jab%C3%B3n+Antibacterial+x3',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(23,23,'https://placehold.co/400x300/1b5e20/ffffff?text=Leche+Entera+1+L',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(24,24,'https://placehold.co/400x300/1b5e20/ffffff?text=Arroz+1+kg',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(25,25,'https://placehold.co/400x300/1b5e20/ffffff?text=Aceite+Vegetal+1+L',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40'),(26,26,'https://placehold.co/400x300/1b5e20/ffffff?text=Vitamina+C+1000+mg+%2830+comp%29',0,1,'2026-06-16 16:31:40','2026-06-16 16:31:40');
/*!40000 ALTER TABLE `producto_imagen` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `registro_comercio`
--

DROP TABLE IF EXISTS `registro_comercio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `registro_comercio` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `negocio_id` bigint unsigned NOT NULL,
  `tipo` enum('compra','venta','gasto','comision') COLLATE utf8mb4_unicode_ci NOT NULL,
  `producto_id` bigint unsigned DEFAULT NULL,
  `pedido_id` bigint unsigned DEFAULT NULL,
  `pedido_item_id` bigint unsigned DEFAULT NULL,
  `cantidad` int unsigned NOT NULL DEFAULT '1',
  `precio_unitario` decimal(10,2) DEFAULT NULL COMMENT 'Solo ventas: precio cobrado al cliente',
  `costo_unitario` decimal(10,2) DEFAULT NULL COMMENT 'Compra: costo por unidad · Venta: costo de lo vendido · Gasto/comisión: monto',
  `ingreso` decimal(12,2) GENERATED ALWAYS AS (if((`tipo` = _utf8mb4'venta'),(`cantidad` * coalesce(`precio_unitario`,0)),0)) STORED,
  `egreso` decimal(12,2) GENERATED ALWAYS AS (if((`tipo` in (_utf8mb4'compra',_utf8mb4'gasto',_utf8mb4'comision')),(`cantidad` * coalesce(`costo_unitario`,0)),0)) STORED,
  `costo_vendido` decimal(12,2) GENERATED ALWAYS AS (if((`tipo` = _utf8mb4'venta'),(`cantidad` * coalesce(`costo_unitario`,0)),0)) STORED,
  `ganancia` decimal(12,2) GENERATED ALWAYS AS (if((`tipo` = _utf8mb4'venta'),(`cantidad` * (coalesce(`precio_unitario`,0) - coalesce(`costo_unitario`,0))),0)) STORED,
  `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `proveedor` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha` datetime NOT NULL DEFAULT (utc_timestamp()) COMMENT 'En UTC; los reportes la pasan a hora de Bolivia',
  `registrado_por` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_registro_item` (`pedido_item_id`),
  KEY `idx_registro_negocio_fecha` (`negocio_id`,`fecha`),
  KEY `idx_registro_producto_fecha` (`negocio_id`,`producto_id`,`fecha`),
  KEY `fk_registro_producto` (`producto_id`),
  KEY `fk_registro_pedido` (`pedido_id`),
  KEY `fk_registro_usuario` (`registrado_por`),
  CONSTRAINT `fk_registro_item` FOREIGN KEY (`pedido_item_id`) REFERENCES `pedido_item` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_registro_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`),
  CONSTRAINT `fk_registro_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_registro_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_registro_usuario` FOREIGN KEY (`registrado_por`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_registro_montos` CHECK ((((`tipo` = _utf8mb4'venta') and (`precio_unitario` is not null)) or ((`tipo` <> _utf8mb4'venta') and (`costo_unitario` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `registro_comercio`
--

LOCK TABLES `registro_comercio` WRITE;
/*!40000 ALTER TABLE `registro_comercio` DISABLE KEYS */;
/*!40000 ALTER TABLE `registro_comercio` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_registro_ai` AFTER INSERT ON `registro_comercio` FOR EACH ROW BEGIN
  IF NEW.tipo = 'compra' AND NEW.producto_id IS NOT NULL THEN
    UPDATE producto
       SET stock = IF(stock IS NULL, NULL, stock + NEW.cantidad),
           costo = NEW.costo_unitario
     WHERE id = NEW.producto_id;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `repartidor`
--

DROP TABLE IF EXISTS `repartidor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `repartidor` (
  `usuario_id` bigint unsigned NOT NULL,
  `estado_verificacion` enum('pendiente','aprobado','rechazado','suspendido') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `disponible` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'En línea para recibir pedidos',
  `latitud_actual` decimal(10,7) DEFAULT NULL,
  `longitud_actual` decimal(10,7) DEFAULT NULL,
  `ubicacion_actualizada_en` timestamp NULL DEFAULT NULL,
  `rating_promedio` decimal(3,2) DEFAULT NULL,
  `total_resenas` int unsigned NOT NULL DEFAULT '0',
  `total_entregas` int unsigned NOT NULL DEFAULT '0',
  `verificado_en` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`usuario_id`),
  KEY `idx_repartidor_disponible` (`estado_verificacion`,`disponible`),
  CONSTRAINT `fk_repartidor_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `repartidor`
--

LOCK TABLES `repartidor` WRITE;
/*!40000 ALTER TABLE `repartidor` DISABLE KEYS */;
INSERT INTO `repartidor` VALUES (5,'aprobado',0,NULL,NULL,NULL,NULL,0,0,'2026-06-16 16:31:38','2026-06-16 16:31:38','2026-06-16 16:31:38'),(6,'aprobado',0,NULL,NULL,NULL,NULL,0,0,'2026-06-16 16:31:38','2026-06-16 16:31:38','2026-06-16 16:31:38'),(7,'aprobado',0,NULL,NULL,NULL,NULL,0,0,'2026-06-16 16:31:39','2026-06-16 16:31:39','2026-06-16 16:31:39');
/*!40000 ALTER TABLE `repartidor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reporte`
--

DROP TABLE IF EXISTS `reporte`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reporte` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reportante_id` bigint unsigned NOT NULL,
  `tipo` enum('producto','negocio','repartidor','usuario','resena') COLLATE utf8mb4_unicode_ci NOT NULL,
  `producto_id` bigint unsigned DEFAULT NULL,
  `negocio_id` bigint unsigned DEFAULT NULL,
  `repartidor_id` bigint unsigned DEFAULT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL COMMENT 'Cliente reportado',
  `resena_id` bigint unsigned DEFAULT NULL,
  `objetivo_id` bigint unsigned GENERATED ALWAYS AS (coalesce(`producto_id`,`negocio_id`,`repartidor_id`,`usuario_id`,`resena_id`)) STORED,
  `motivo_id` smallint unsigned NOT NULL,
  `pedido_id` bigint unsigned DEFAULT NULL COMMENT 'Pedido relacionado (se completa solo al reportar personas)',
  `descripcion` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estado` enum('pendiente','en_revision','resuelto','descartado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `abierto` tinyint unsigned GENERATED ALWAYS AS (if((`estado` in (_utf8mb4'pendiente',_utf8mb4'en_revision')),1,NULL)) STORED,
  `resolucion` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Qué decidió el admin',
  `revisado_por` bigint unsigned DEFAULT NULL,
  `revisado_en` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_reporte_abierto` (`reportante_id`,`tipo`,`objetivo_id`,`abierto`),
  KEY `idx_reporte_objetivo` (`tipo`,`objetivo_id`,`estado`),
  KEY `idx_reporte_estado` (`estado`,`created_at`),
  KEY `fk_reporte_producto` (`producto_id`),
  KEY `fk_reporte_negocio` (`negocio_id`),
  KEY `fk_reporte_repartidor` (`repartidor_id`),
  KEY `fk_reporte_usuario` (`usuario_id`),
  KEY `fk_reporte_resena` (`resena_id`),
  KEY `fk_reporte_motivo` (`motivo_id`),
  KEY `fk_reporte_pedido` (`pedido_id`),
  KEY `fk_reporte_revisor` (`revisado_por`),
  CONSTRAINT `fk_reporte_motivo` FOREIGN KEY (`motivo_id`) REFERENCES `motivo_reporte` (`id`),
  CONSTRAINT `fk_reporte_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`),
  CONSTRAINT `fk_reporte_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_reporte_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`),
  CONSTRAINT `fk_reporte_repartidor` FOREIGN KEY (`repartidor_id`) REFERENCES `repartidor` (`usuario_id`),
  CONSTRAINT `fk_reporte_reportante` FOREIGN KEY (`reportante_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reporte_resena` FOREIGN KEY (`resena_id`) REFERENCES `resena` (`id`),
  CONSTRAINT `fk_reporte_revisor` FOREIGN KEY (`revisado_por`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_reporte_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `chk_reporte_objetivo` CHECK ((((`tipo` = _utf8mb4'producto') and (`producto_id` is not null) and (`negocio_id` is null) and (`repartidor_id` is null) and (`usuario_id` is null) and (`resena_id` is null)) or ((`tipo` = _utf8mb4'negocio') and (`negocio_id` is not null) and (`producto_id` is null) and (`repartidor_id` is null) and (`usuario_id` is null) and (`resena_id` is null)) or ((`tipo` = _utf8mb4'repartidor') and (`repartidor_id` is not null) and (`producto_id` is null) and (`negocio_id` is null) and (`usuario_id` is null) and (`resena_id` is null)) or ((`tipo` = _utf8mb4'usuario') and (`usuario_id` is not null) and (`producto_id` is null) and (`negocio_id` is null) and (`repartidor_id` is null) and (`resena_id` is null)) or ((`tipo` = _utf8mb4'resena') and (`resena_id` is not null) and (`producto_id` is null) and (`negocio_id` is null) and (`repartidor_id` is null) and (`usuario_id` is null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reporte`
--

LOCK TABLES `reporte` WRITE;
/*!40000 ALTER TABLE `reporte` DISABLE KEYS */;
/*!40000 ALTER TABLE `reporte` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_reporte_bi` BEFORE INSERT ON `reporte` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `reporte_evidencia`
--

DROP TABLE IF EXISTS `reporte_evidencia`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reporte_evidencia` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `reporte_id` bigint unsigned NOT NULL,
  `url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_evidencia_reporte` (`reporte_id`),
  CONSTRAINT `fk_evidencia_reporte` FOREIGN KEY (`reporte_id`) REFERENCES `reporte` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reporte_evidencia`
--

LOCK TABLES `reporte_evidencia` WRITE;
/*!40000 ALTER TABLE `reporte_evidencia` DISABLE KEYS */;
/*!40000 ALTER TABLE `reporte_evidencia` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `requisito_rol`
--

DROP TABLE IF EXISTS `requisito_rol`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `requisito_rol` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `rol` enum('cliente','repartidor','comerciante') COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo_documento_id` smallint unsigned NOT NULL,
  `obligatorio` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_requisito_rol` (`rol`,`tipo_documento_id`),
  KEY `fk_requisito_tipo` (`tipo_documento_id`),
  CONSTRAINT `fk_requisito_tipo` FOREIGN KEY (`tipo_documento_id`) REFERENCES `tipo_documento` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `requisito_rol`
--

LOCK TABLES `requisito_rol` WRITE;
/*!40000 ALTER TABLE `requisito_rol` DISABLE KEYS */;
INSERT INTO `requisito_rol` VALUES (1,'repartidor',1,1),(2,'repartidor',2,1),(3,'repartidor',3,1),(4,'repartidor',4,1),(5,'repartidor',6,1),(6,'repartidor',7,1),(7,'comerciante',1,1),(8,'comerciante',2,1),(9,'comerciante',5,0);
/*!40000 ALTER TABLE `requisito_rol` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resena`
--

DROP TABLE IF EXISTS `resena`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resena` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `pedido_id` bigint unsigned DEFAULT NULL COMMENT 'Pedido entregado que habilitó la reseña (se completa solo)',
  `autor_id` bigint unsigned NOT NULL,
  `tipo` enum('producto','negocio','repartidor') COLLATE utf8mb4_unicode_ci NOT NULL,
  `producto_id` bigint unsigned DEFAULT NULL,
  `negocio_id` bigint unsigned DEFAULT NULL,
  `repartidor_id` bigint unsigned DEFAULT NULL,
  `objetivo_id` bigint unsigned GENERATED ALWAYS AS (coalesce(`producto_id`,`negocio_id`,`repartidor_id`)) STORED,
  `estrellas` tinyint unsigned NOT NULL,
  `comentario` text COLLATE utf8mb4_unicode_ci,
  `respuesta` text COLLATE utf8mb4_unicode_ci COMMENT 'Respuesta del negocio o repartidor',
  `respondido_en` timestamp NULL DEFAULT NULL,
  `visible` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_resena_unica` (`autor_id`,`tipo`,`objetivo_id`),
  KEY `idx_resena_objetivo` (`tipo`,`objetivo_id`,`visible`),
  KEY `fk_resena_pedido` (`pedido_id`),
  KEY `fk_resena_producto` (`producto_id`),
  KEY `fk_resena_negocio` (`negocio_id`),
  KEY `fk_resena_repartidor` (`repartidor_id`),
  CONSTRAINT `fk_resena_autor` FOREIGN KEY (`autor_id`) REFERENCES `usuario` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_resena_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`),
  CONSTRAINT `fk_resena_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_resena_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`),
  CONSTRAINT `fk_resena_repartidor` FOREIGN KEY (`repartidor_id`) REFERENCES `repartidor` (`usuario_id`),
  CONSTRAINT `chk_resena_estrellas` CHECK ((`estrellas` between 1 and 5)),
  CONSTRAINT `chk_resena_objetivo` CHECK ((((`tipo` = _utf8mb4'producto') and (`producto_id` is not null) and (`negocio_id` is null) and (`repartidor_id` is null)) or ((`tipo` = _utf8mb4'negocio') and (`negocio_id` is not null) and (`producto_id` is null) and (`repartidor_id` is null)) or ((`tipo` = _utf8mb4'repartidor') and (`repartidor_id` is not null) and (`producto_id` is null) and (`negocio_id` is null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resena`
--

LOCK TABLES `resena` WRITE;
/*!40000 ALTER TABLE `resena` DISABLE KEYS */;
/*!40000 ALTER TABLE `resena` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_resena_bi` BEFORE INSERT ON `resena` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_resena_ai` AFTER INSERT ON `resena` FOR EACH ROW BEGIN
  CALL sp_recalcular_rating(NEW.tipo, COALESCE(NEW.producto_id, NEW.negocio_id, NEW.repartidor_id));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_resena_bu` BEFORE UPDATE ON `resena` FOR EACH ROW BEGIN
  IF NEW.autor_id <> OLD.autor_id OR NEW.tipo <> OLD.tipo
  OR NOT (NEW.producto_id   <=> OLD.producto_id)
  OR NOT (NEW.negocio_id    <=> OLD.negocio_id)
  OR NOT (NEW.repartidor_id <=> OLD.repartidor_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden editar las estrellas y el comentario';
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_resena_au` AFTER UPDATE ON `resena` FOR EACH ROW BEGIN
  CALL sp_recalcular_rating(OLD.tipo, COALESCE(OLD.producto_id, OLD.negocio_id, OLD.repartidor_id));
  CALL sp_recalcular_rating(NEW.tipo, COALESCE(NEW.producto_id, NEW.negocio_id, NEW.repartidor_id));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_resena_ad` AFTER DELETE ON `resena` FOR EACH ROW BEGIN
  CALL sp_recalcular_rating(OLD.tipo, COALESCE(OLD.producto_id, OLD.negocio_id, OLD.repartidor_id));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sancion`
--

DROP TABLE IF EXISTS `sancion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sancion` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` bigint unsigned NOT NULL COMMENT 'Persona sancionada (cliente, repartidor o dueño del negocio/producto)',
  `rol_afectado` enum('cliente','repartidor','comerciante','todos') COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo` enum('advertencia','suspension','bloqueo','retiro_producto') COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'suspension = temporal (con termina_en) · bloqueo = permanente',
  `negocio_id` bigint unsigned DEFAULT NULL COMMENT 'Solo ese negocio; NULL = todos los del comerciante',
  `producto_id` bigint unsigned DEFAULT NULL COMMENT 'Obligatorio en retiro_producto',
  `reporte_id` bigint unsigned DEFAULT NULL COMMENT 'Reporte que la originó',
  `motivo` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `inicia_en` datetime NOT NULL DEFAULT (utc_timestamp()),
  `termina_en` datetime DEFAULT NULL,
  `aplicada_por` bigint unsigned DEFAULT NULL,
  `revocada_en` datetime DEFAULT NULL COMMENT 'Si el admin la levanta antes de tiempo',
  `revocada_por` bigint unsigned DEFAULT NULL,
  `motivo_revocacion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sancion_usuario` (`usuario_id`,`rol_afectado`),
  KEY `idx_sancion_negocio` (`negocio_id`),
  KEY `idx_sancion_producto` (`producto_id`),
  KEY `fk_sancion_reporte` (`reporte_id`),
  KEY `fk_sancion_aplicador` (`aplicada_por`),
  KEY `fk_sancion_revocador` (`revocada_por`),
  CONSTRAINT `fk_sancion_aplicador` FOREIGN KEY (`aplicada_por`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sancion_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`),
  CONSTRAINT `fk_sancion_producto` FOREIGN KEY (`producto_id`) REFERENCES `producto` (`id`),
  CONSTRAINT `fk_sancion_reporte` FOREIGN KEY (`reporte_id`) REFERENCES `reporte` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sancion_revocador` FOREIGN KEY (`revocada_por`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_sancion_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`),
  CONSTRAINT `chk_sancion_tipo` CHECK ((((`tipo` <> _utf8mb4'retiro_producto') or (`producto_id` is not null)) and ((`tipo` <> _utf8mb4'suspension') or (`termina_en` is not null)) and ((`tipo` <> _utf8mb4'bloqueo') or (`termina_en` is null)) and ((`termina_en` is null) or (`termina_en` > `inicia_en`))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sancion`
--

LOCK TABLES `sancion` WRITE;
/*!40000 ALTER TABLE `sancion` DISABLE KEYS */;
/*!40000 ALTER TABLE `sancion` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 */ /*!50003 TRIGGER `trg_sancion_ai` AFTER INSERT ON `sancion` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tarifa_envio`
--

DROP TABLE IF EXISTS `tarifa_envio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tarifa_envio` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `categoria_vehiculo_id` tinyint unsigned NOT NULL,
  `km_hasta` decimal(6,2) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tarifa_envio` (`categoria_vehiculo_id`,`km_hasta`),
  CONSTRAINT `fk_tarifa_categoria` FOREIGN KEY (`categoria_vehiculo_id`) REFERENCES `categoria_vehiculo` (`id`),
  CONSTRAINT `chk_tarifa_envio` CHECK (((`km_hasta` > 0) and (`precio` >= 0)))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tarifa_envio`
--

LOCK TABLES `tarifa_envio` WRITE;
/*!40000 ALTER TABLE `tarifa_envio` DISABLE KEYS */;
INSERT INTO `tarifa_envio` VALUES (1,1,3.00,3.00,1,'2026-10-04 00:59:42','2026-10-04 00:59:42'),(2,1,6.00,5.00,1,'2026-10-04 00:59:42','2026-10-04 00:59:42'),(3,1,10.00,8.00,1,'2026-10-04 00:59:42','2026-10-04 00:59:42'),(4,1,15.00,12.00,1,'2026-10-04 00:59:42','2026-10-04 00:59:42'),(5,1,20.00,15.00,1,'2026-10-04 00:59:42','2026-10-04 00:59:42'),(6,1,30.00,20.00,1,'2026-10-04 00:59:42','2026-10-04 00:59:42');
/*!40000 ALTER TABLE `tarifa_envio` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tipo_documento`
--

DROP TABLE IF EXISTS `tipo_documento`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tipo_documento` (
  `id` smallint unsigned NOT NULL AUTO_INCREMENT,
  `codigo` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ambito` enum('persona','vehiculo','negocio') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'persona',
  `condicion_vehiculo` enum('requiere_placa','requiere_ruat','requiere_licencia') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tipo_documento_codigo` (`codigo`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tipo_documento`
--

LOCK TABLES `tipo_documento` WRITE;
/*!40000 ALTER TABLE `tipo_documento` DISABLE KEYS */;
INSERT INTO `tipo_documento` VALUES (1,'ci_anverso','Carnet de identidad (anverso)','Foto del frente del CI','persona',NULL,1),(2,'ci_reverso','Carnet de identidad (reverso)','Foto del reverso del CI','persona',NULL,1),(3,'ruat','RUAT del vehículo','Foto del RUAT','vehiculo','requiere_ruat',1),(4,'licencia_conducir','Licencia de conducir','Foto de la licencia vigente','persona','requiere_licencia',1),(5,'nit','Certificado de NIT','Solo si el negocio tiene NIT','negocio',NULL,1),(6,'foto_vehiculo','Foto del vehículo','Foto completa del vehículo, de costado','vehiculo',NULL,1),(7,'foto_placa','Foto de la placa','Foto donde se lea bien la placa','vehiculo','requiere_placa',1);
/*!40000 ALTER TABLE `tipo_documento` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tipo_vehiculo`
--

DROP TABLE IF EXISTS `tipo_vehiculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tipo_vehiculo` (
  `id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `categoria_vehiculo_id` tinyint unsigned NOT NULL,
  `codigo` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requiere_placa` tinyint(1) NOT NULL DEFAULT '1',
  `requiere_ruat` tinyint(1) NOT NULL DEFAULT '1',
  `requiere_licencia` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tipo_vehiculo_codigo` (`codigo`),
  KEY `fk_tipo_vehiculo_categoria` (`categoria_vehiculo_id`),
  CONSTRAINT `fk_tipo_vehiculo_categoria` FOREIGN KEY (`categoria_vehiculo_id`) REFERENCES `categoria_vehiculo` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tipo_vehiculo`
--

LOCK TABLES `tipo_vehiculo` WRITE;
/*!40000 ALTER TABLE `tipo_vehiculo` DISABLE KEYS */;
INSERT INTO `tipo_vehiculo` VALUES (1,1,'moto','Moto',1,1,1),(2,1,'bicicleta','Bicicleta',0,0,0),(3,2,'auto','Auto',1,1,1),(4,2,'camioneta','Camioneta',1,1,1),(5,3,'camion','Camión',1,1,1);
/*!40000 ALTER TABLE `tipo_vehiculo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transaccion`
--

DROP TABLE IF EXISTS `transaccion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaccion` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tipo` enum('ingreso','egreso') COLLATE utf8mb4_unicode_ci NOT NULL,
  `concepto` enum('comision','envio','suscripcion','membresia','liquidacion','reembolso','costo_operativo','pasarela_pago','otro') COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `estado` enum('pendiente','completado','fallido') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'completado',
  `pedido_id` bigint unsigned DEFAULT NULL,
  `usuario_id` bigint unsigned DEFAULT NULL COMMENT 'Repartidor, cliente o comerciante involucrado',
  `negocio_id` bigint unsigned DEFAULT NULL,
  `fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_transaccion_fecha` (`fecha`),
  KEY `idx_transaccion_usuario` (`usuario_id`),
  KEY `idx_transaccion_negocio` (`negocio_id`),
  KEY `fk_transaccion_pedido` (`pedido_id`),
  CONSTRAINT `fk_transaccion_negocio` FOREIGN KEY (`negocio_id`) REFERENCES `negocio` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transaccion_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_transaccion_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_transaccion_monto` CHECK ((`monto` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transaccion`
--

LOCK TABLES `transaccion` WRITE;
/*!40000 ALTER TABLE `transaccion` DISABLE KEYS */;
/*!40000 ALTER TABLE `transaccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ubicacion_repartidor`
--

DROP TABLE IF EXISTS `ubicacion_repartidor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ubicacion_repartidor` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `repartidor_id` bigint unsigned NOT NULL,
  `pedido_id` bigint unsigned DEFAULT NULL,
  `latitud` decimal(10,7) NOT NULL,
  `longitud` decimal(10,7) NOT NULL,
  `registrado_en` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ubicacion_pedido` (`pedido_id`,`registrado_en`),
  KEY `idx_ubicacion_repartidor` (`repartidor_id`,`registrado_en`),
  CONSTRAINT `fk_ubicacion_pedido` FOREIGN KEY (`pedido_id`) REFERENCES `pedido` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ubicacion_repartidor` FOREIGN KEY (`repartidor_id`) REFERENCES `repartidor` (`usuario_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ubicacion_repartidor`
--

LOCK TABLES `ubicacion_repartidor` WRITE;
/*!40000 ALTER TABLE `ubicacion_repartidor` DISABLE KEYS */;
/*!40000 ALTER TABLE `ubicacion_repartidor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuario`
--

DROP TABLE IF EXISTS `usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuario` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apellido` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Obligatorio en la app; NULL solo en cuentas antiguas',
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telefono` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ci_numero` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Número de carnet de identidad',
  `ci_complemento` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'Complemento del CI (si tiene)',
  `ci_expedido` enum('LP','CB','SC','OR','PT','CH','TJ','BE','PD') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_nacimiento` date DEFAULT NULL,
  `foto_perfil_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `es_admin` tinyint(1) NOT NULL DEFAULT '0',
  `rol_activo` enum('cliente','repartidor','comerciante','admin') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'cliente' COMMENT 'Última vista usada en la app (botón "cambiar a vista…")',
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_usuario_email` (`email`),
  UNIQUE KEY `uq_usuario_ci` (`ci_numero`,`ci_complemento`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario`
--

LOCK TABLES `usuario` WRITE;
/*!40000 ALTER TABLE `usuario` DISABLE KEYS */;
INSERT INTO `usuario` VALUES (1,'Test','User','test@example.com','2026-06-16 16:31:36','$2y$12$Dd9Jts/HlQhcaQSWKqWyT.g2fO57aLKmxi6d8wSqAfMRNRvmNEsO6',NULL,NULL,'',NULL,NULL,NULL,1,'admin',1,NULL,'2026-06-16 16:31:37','2026-06-16 16:31:37',NULL),(2,'TechStore SCZ',NULL,'techstore@mdrmarket.local',NULL,'$2y$12$KxaYq6s4SxCOyiN4UMGzNOcEioVQQEBDFvcV3AuafkxW1MH.A53a.','59177001001',NULL,'',NULL,NULL,NULL,0,'comerciante',1,NULL,'2026-06-16 16:31:37','2026-06-16 16:31:37',NULL),(3,'Sabor Cruceño',NULL,'saborcruceno@mdrmarket.local',NULL,'$2y$12$AvIDIJsj2XW4tRQGEj1GQeER33U/mAodJoULHN7fcHwrwfAt9E.D2','59177002002',NULL,'',NULL,NULL,NULL,0,'comerciante',1,NULL,'2026-06-16 16:31:37','2026-06-16 16:31:37',NULL),(4,'FarmaSuper',NULL,'farmasuper@mdrmarket.local',NULL,'$2y$12$bvytKY12gl8lzb2wG3tMNutrm7V/zB2.Lvt7gqTSFRu5EiAxFefHu','59177003003',NULL,'',NULL,NULL,NULL,0,'comerciante',1,NULL,'2026-06-16 16:31:38','2026-06-16 16:31:38',NULL),(5,'Diego','Rodríguez','diego.rep@mdrmarket.local',NULL,'$2y$12$rJxfcqbxjllibpPrB6azQ.R.byJp0C/MgGk.//9wfXWS1r.20DzBO','59176101001',NULL,'',NULL,NULL,NULL,0,'repartidor',1,NULL,'2026-06-16 16:31:38','2026-06-16 16:31:38',NULL),(6,'Valentina','Cruz','valentina.rep@mdrmarket.local',NULL,'$2y$12$9tP6i99iZeiyB/iCgdfrju3etg72dLxlUC0q2M2heXHLKrIhPY9vW','59176102002',NULL,'',NULL,NULL,NULL,0,'repartidor',1,NULL,'2026-06-16 16:31:38','2026-06-16 16:31:38',NULL),(7,'Marco','Flores','marco.rep@mdrmarket.local',NULL,'$2y$12$/W0929I5lPXPna7MS4afUeVQA4GYenCpguBkC6cHz3gPLHt.1kHoy','59176103003',NULL,'',NULL,NULL,NULL,0,'repartidor',1,NULL,'2026-06-16 16:31:39','2026-06-16 16:31:39',NULL),(8,'Ana','García','ana.cliente@mdrmarket.local',NULL,'$2y$12$zcAekdVmzdGo8ycN5Rgm4euAAj62ngj7WrFoDBvrr3jbDHYZwMQvC','59175201001',NULL,'',NULL,NULL,NULL,0,'cliente',1,NULL,'2026-06-16 16:31:39','2026-06-16 16:31:39',NULL),(9,'Carlos','López','carlos.cliente@mdrmarket.local',NULL,'$2y$12$XZIKuWKNggnB6JZufbZMnuLX05kE2cyixZ2XT3jipXA3MfwJQ053q','59175202002',NULL,'',NULL,NULL,NULL,0,'cliente',1,NULL,'2026-06-16 16:31:39','2026-06-16 16:31:39',NULL),(10,'Sofía','Martínez','sofia.cliente@mdrmarket.local',NULL,'$2y$12$pukWgBRFRN6rCUdDHMOLfu3WftoEV65y02csWtWKZnax/jEcOAvqK','59175203003',NULL,'',NULL,NULL,NULL,0,'cliente',1,NULL,'2026-06-16 16:31:40','2026-06-16 16:31:40',NULL);
/*!40000 ALTER TABLE `usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_catalogo_producto`
--

DROP TABLE IF EXISTS `v_catalogo_producto`;
/*!50001 DROP VIEW IF EXISTS `v_catalogo_producto`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_catalogo_producto` AS SELECT 
 1 AS `id`,
 1 AS `nombre`,
 1 AS `descripcion`,
 1 AS `precio`,
 1 AS `precio_final`,
 1 AS `en_oferta`,
 1 AS `descuento_pct`,
 1 AS `stock`,
 1 AS `rating_promedio`,
 1 AS `total_resenas`,
 1 AS `total_vendidos`,
 1 AS `imagen_url`,
 1 AS `categoria_id`,
 1 AS `categoria`,
 1 AS `categoria_icono`,
 1 AS `categoria_principal_id`,
 1 AS `categoria_principal`,
 1 AS `negocio_id`,
 1 AS `negocio`,
 1 AS `negocio_logo`,
 1 AS `negocio_rating`,
 1 AS `negocio_abierto`,
 1 AS `negocio_latitud`,
 1 AS `negocio_longitud`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_pedido_resumen`
--

DROP TABLE IF EXISTS `v_pedido_resumen`;
/*!50001 DROP VIEW IF EXISTS `v_pedido_resumen`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_pedido_resumen` AS SELECT 
 1 AS `id`,
 1 AS `estado`,
 1 AS `total`,
 1 AS `metodo_pago`,
 1 AS `estado_pago`,
 1 AS `created_at`,
 1 AS `comprador_id`,
 1 AS `comprador`,
 1 AS `negocio_id`,
 1 AS `negocio`,
 1 AS `repartidor_id`,
 1 AS `repartidor`,
 1 AS `vehiculo`,
 1 AS `placa`,
 1 AS `direccion_entrega`,
 1 AS `latitud_entrega`,
 1 AS `longitud_entrega`,
 1 AS `total_items`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_registro_diario`
--

DROP TABLE IF EXISTS `v_registro_diario`;
/*!50001 DROP VIEW IF EXISTS `v_registro_diario`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_registro_diario` AS SELECT 
 1 AS `negocio_id`,
 1 AS `dia`,
 1 AS `ventas`,
 1 AS `costo_de_lo_vendido`,
 1 AS `ganancia_bruta`,
 1 AS `compras`,
 1 AS `gastos`,
 1 AS `comisiones`,
 1 AS `ganancia_neta`,
 1 AS `flujo_caja`,
 1 AS `unidades_vendidas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_reportes_pendientes`
--

DROP TABLE IF EXISTS `v_reportes_pendientes`;
/*!50001 DROP VIEW IF EXISTS `v_reportes_pendientes`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_reportes_pendientes` AS SELECT 
 1 AS `tipo`,
 1 AS `objetivo_id`,
 1 AS `objetivo`,
 1 AS `total_reportes`,
 1 AS `personas_que_reportan`,
 1 AS `gravedad`,
 1 AS `motivos`,
 1 AS `primer_reporte`,
 1 AS `ultimo_reporte`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_sancion_activa`
--

DROP TABLE IF EXISTS `v_sancion_activa`;
/*!50001 DROP VIEW IF EXISTS `v_sancion_activa`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_sancion_activa` AS SELECT 
 1 AS `id`,
 1 AS `usuario_id`,
 1 AS `rol_afectado`,
 1 AS `tipo`,
 1 AS `negocio_id`,
 1 AS `producto_id`,
 1 AS `reporte_id`,
 1 AS `motivo`,
 1 AS `inicia_en`,
 1 AS `termina_en`,
 1 AS `aplicada_por`,
 1 AS `revocada_en`,
 1 AS `revocada_por`,
 1 AS `motivo_revocacion`,
 1 AS `created_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_usuario_roles`
--

DROP TABLE IF EXISTS `v_usuario_roles`;
/*!50001 DROP VIEW IF EXISTS `v_usuario_roles`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_usuario_roles` AS SELECT 
 1 AS `usuario_id`,
 1 AS `nombre`,
 1 AS `apellido`,
 1 AS `email`,
 1 AS `rol_activo`,
 1 AS `es_repartidor`,
 1 AS `estado_repartidor`,
 1 AS `total_negocios`,
 1 AS `es_admin`,
 1 AS `cuenta_bloqueada`,
 1 AS `sancionado_cliente`,
 1 AS `sancionado_repartidor`,
 1 AS `sancionado_comerciante`,
 1 AS `advertencias`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `vehiculo`
--

DROP TABLE IF EXISTS `vehiculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehiculo` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `repartidor_id` bigint unsigned NOT NULL,
  `tipo_vehiculo_id` tinyint unsigned NOT NULL,
  `placa` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ruat` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Número de RUAT del vehículo',
  `marca` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `modelo` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `color` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `anio` smallint unsigned DEFAULT NULL,
  `en_uso` tinyint(1) NOT NULL DEFAULT '1',
  `estado_verificacion` enum('pendiente','aprobado','rechazado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vehiculo_placa` (`placa`),
  KEY `idx_vehiculo_repartidor` (`repartidor_id`),
  KEY `fk_vehiculo_tipo` (`tipo_vehiculo_id`),
  CONSTRAINT `fk_vehiculo_repartidor` FOREIGN KEY (`repartidor_id`) REFERENCES `repartidor` (`usuario_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_vehiculo_tipo` FOREIGN KEY (`tipo_vehiculo_id`) REFERENCES `tipo_vehiculo` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vehiculo`
--

LOCK TABLES `vehiculo` WRITE;
/*!40000 ALTER TABLE `vehiculo` DISABLE KEYS */;
INSERT INTO `vehiculo` VALUES (1,5,1,'SCZ-1234',NULL,NULL,NULL,NULL,NULL,1,'aprobado','2026-06-16 16:31:38','2026-06-16 16:31:38',NULL),(2,6,1,'SCZ-5678',NULL,NULL,NULL,NULL,NULL,1,'aprobado','2026-06-16 16:31:38','2026-06-16 16:31:38',NULL),(3,7,2,'SCZ-9012',NULL,NULL,NULL,NULL,NULL,1,'aprobado','2026-06-16 16:31:39','2026-06-16 16:31:39',NULL);
/*!40000 ALTER TABLE `vehiculo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'mdrmarket_new'
--
/*!50106 SET @save_time_zone= @@TIME_ZONE */ ;
/*!50106 DROP EVENT IF EXISTS `ev_limpiar_ubicaciones` */;
DELIMITER ;;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;;
/*!50003 SET character_set_client  = utf8mb4 */ ;;
/*!50003 SET character_set_results = utf8mb4 */ ;;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;;
/*!50003 SET @saved_time_zone      = @@time_zone */ ;;
/*!50003 SET time_zone             = '+00:00' */ ;;
/*!50106 CREATE*/ /*!50117 */ /*!50106 EVENT `ev_limpiar_ubicaciones` ON SCHEDULE EVERY 1 DAY STARTS '2026-10-05 08:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
  DECLARE v_dias INT DEFAULT COALESCE(
    (SELECT CAST(valor AS UNSIGNED) FROM configuracion WHERE clave = 'dias_historial_gps'), 30);
  DELETE FROM ubicacion_repartidor WHERE registrado_en < NOW() - INTERVAL v_dias DAY;
END */ ;;
/*!50003 SET time_zone             = @saved_time_zone */ ;;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;;
/*!50003 SET character_set_client  = @saved_cs_client */ ;;
/*!50003 SET character_set_results = @saved_cs_results */ ;;
/*!50003 SET collation_connection  = @saved_col_connection */ ;;
DELIMITER ;
/*!50106 SET TIME_ZONE= @save_time_zone */ ;

--
-- Dumping routines for database 'mdrmarket_new'
--
/*!50003 DROP FUNCTION IF EXISTS `fn_anillo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  FUNCTION `fn_anillo`(p_lat DECIMAL(10,7), p_lng DECIMAL(10,7)) RETURNS tinyint unsigned
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_costo_envio` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  FUNCTION `fn_costo_envio`(p_km DECIMAL(6,2), p_categoria_vehiculo_id TINYINT UNSIGNED) RETURNS decimal(10,2)
    READS SQL DATA
BEGIN
  DECLARE v_cat TINYINT UNSIGNED DEFAULT COALESCE(p_categoria_vehiculo_id, 1);
  IF NOT EXISTS (SELECT 1 FROM tarifa_envio WHERE categoria_vehiculo_id = v_cat AND activo = 1) THEN
    SET v_cat = 1;
  END IF;
  RETURN (SELECT precio FROM tarifa_envio
           WHERE categoria_vehiculo_id = v_cat AND activo = 1 AND km_hasta >= p_km
           ORDER BY km_hasta LIMIT 1);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_cotizar_envio` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  FUNCTION `fn_cotizar_envio`(p_lat_origen DECIMAL(10,7), p_lng_origen DECIMAL(10,7),
                                 p_lat_destino DECIMAL(10,7), p_lng_destino DECIMAL(10,7),
                                 p_km_ruta DECIMAL(6,2), p_categoria_vehiculo_id TINYINT UNSIGNED) RETURNS decimal(10,2)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_distancia_km` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  FUNCTION `fn_distancia_km`(p_lat1 DECIMAL(10,7), p_lng1 DECIMAL(10,7), p_lat2 DECIMAL(10,7), p_lng2 DECIMAL(10,7)) RETURNS decimal(8,2)
    NO SQL
    DETERMINISTIC
BEGIN
  RETURN ROUND(ST_Distance_Sphere(POINT(p_lng1, p_lat1), POINT(p_lng2, p_lat2)) / 1000, 2);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_negocio_sancionado` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  FUNCTION `fn_negocio_sancionado`(p_negocio_id BIGINT UNSIGNED) RETURNS tinyint
    READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM v_sancion_activa s JOIN negocio n ON n.id = p_negocio_id
                  WHERE s.tipo IN ('suspension','bloqueo')
                    AND (s.negocio_id = n.id
                         OR (s.negocio_id IS NULL AND s.usuario_id = n.usuario_id
                             AND s.rol_afectado IN ('comerciante','todos'))));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP FUNCTION IF EXISTS `fn_sancion_activa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  FUNCTION `fn_sancion_activa`(p_usuario_id BIGINT UNSIGNED, p_rol VARCHAR(20)) RETURNS tinyint
    READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM v_sancion_activa
                  WHERE usuario_id = p_usuario_id
                    AND tipo IN ('suspension','bloqueo')
                    AND (rol_afectado = p_rol OR rol_afectado = 'todos'));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_datos_faltantes` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  PROCEDURE `sp_datos_faltantes`(IN p_usuario_id BIGINT UNSIGNED, IN p_rol VARCHAR(20))
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_recalcular_rating` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  PROCEDURE `sp_recalcular_rating`(IN p_tipo VARCHAR(20), IN p_id BIGINT UNSIGNED)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_reporte_negocio` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  PROCEDURE `sp_reporte_negocio`(IN p_negocio_id BIGINT UNSIGNED, IN p_desde DATE, IN p_hasta DATE, IN p_agrupar VARCHAR(10))
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_reporte_productos` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE  PROCEDURE `sp_reporte_productos`(IN p_negocio_id BIGINT UNSIGNED, IN p_desde DATE, IN p_hasta DATE)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_catalogo_producto`
--

/*!50001 DROP VIEW IF EXISTS `v_catalogo_producto`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY DEFINER */
/*!50001 VIEW `v_catalogo_producto` AS select `p`.`id` AS `id`,`p`.`nombre` AS `nombre`,`p`.`descripcion` AS `descripcion`,`p`.`precio` AS `precio`,(case when (`p`.`oferta_vigente` = 1) then `p`.`precio_oferta` else `p`.`precio` end) AS `precio_final`,`p`.`oferta_vigente` AS `en_oferta`,(case when (`p`.`oferta_vigente` = 1) then round(((1 - (`p`.`precio_oferta` / `p`.`precio`)) * 100),0) else 0 end) AS `descuento_pct`,`p`.`stock` AS `stock`,`p`.`rating_promedio` AS `rating_promedio`,`p`.`total_resenas` AS `total_resenas`,`p`.`total_vendidos` AS `total_vendidos`,(select `pi`.`url` from `producto_imagen` `pi` where (`pi`.`producto_id` = `p`.`id`) order by `pi`.`es_principal` desc,`pi`.`orden` limit 1) AS `imagen_url`,`c`.`id` AS `categoria_id`,`c`.`nombre` AS `categoria`,`c`.`icono` AS `categoria_icono`,coalesce(`cp`.`id`,`c`.`id`) AS `categoria_principal_id`,coalesce(`cp`.`nombre`,`c`.`nombre`) AS `categoria_principal`,`n`.`id` AS `negocio_id`,`n`.`nombre` AS `negocio`,`n`.`logo_url` AS `negocio_logo`,`n`.`rating_promedio` AS `negocio_rating`,`n`.`abierto` AS `negocio_abierto`,`n`.`latitud` AS `negocio_latitud`,`n`.`longitud` AS `negocio_longitud` from ((((select `pr`.`id` AS `id`,`pr`.`negocio_id` AS `negocio_id`,`pr`.`categoria_id` AS `categoria_id`,`pr`.`categoria_vehiculo_id` AS `categoria_vehiculo_id`,`pr`.`nombre` AS `nombre`,`pr`.`descripcion` AS `descripcion`,`pr`.`precio` AS `precio`,`pr`.`costo` AS `costo`,`pr`.`precio_oferta` AS `precio_oferta`,`pr`.`oferta_inicio` AS `oferta_inicio`,`pr`.`oferta_fin` AS `oferta_fin`,`pr`.`stock` AS `stock`,`pr`.`disponible` AS `disponible`,`pr`.`rating_promedio` AS `rating_promedio`,`pr`.`total_resenas` AS `total_resenas`,`pr`.`total_vendidos` AS `total_vendidos`,`pr`.`created_at` AS `created_at`,`pr`.`updated_at` AS `updated_at`,`pr`.`deleted_at` AS `deleted_at`,((`pr`.`precio_oferta` is not null) and ((`pr`.`oferta_inicio` is null) or (`pr`.`oferta_inicio` <= now())) and ((`pr`.`oferta_fin` is null) or (`pr`.`oferta_fin` >= now()))) AS `oferta_vigente` from `producto` `pr`) `p` join `negocio` `n` on((`n`.`id` = `p`.`negocio_id`))) join `categoria` `c` on((`c`.`id` = `p`.`categoria_id`))) left join `categoria` `cp` on((`cp`.`id` = `c`.`categoria_padre_id`))) where ((`p`.`deleted_at` is null) and (`p`.`disponible` = 1) and (`n`.`deleted_at` is null) and (`n`.`estado_verificacion` = 'aprobado') and exists(select 1 from `v_sancion_activa` `s` where (((`s`.`tipo` = 'retiro_producto') and (`s`.`producto_id` = `p`.`id`)) or ((`s`.`tipo` in ('suspension','bloqueo')) and ((`s`.`negocio_id` = `n`.`id`) or ((`s`.`negocio_id` is null) and (`s`.`usuario_id` = `n`.`usuario_id`) and (`s`.`rol_afectado` in ('comerciante','todos'))))))) is false) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_pedido_resumen`
--

/*!50001 DROP VIEW IF EXISTS `v_pedido_resumen`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY DEFINER */
/*!50001 VIEW `v_pedido_resumen` AS select `pe`.`id` AS `id`,`pe`.`estado` AS `estado`,`pe`.`total` AS `total`,`pe`.`metodo_pago` AS `metodo_pago`,`pe`.`estado_pago` AS `estado_pago`,`pe`.`created_at` AS `created_at`,`pe`.`comprador_id` AS `comprador_id`,concat_ws(' ',`uc`.`nombre`,`uc`.`apellido`) AS `comprador`,`pe`.`negocio_id` AS `negocio_id`,`n`.`nombre` AS `negocio`,`pe`.`repartidor_id` AS `repartidor_id`,concat_ws(' ',`ur`.`nombre`,`ur`.`apellido`) AS `repartidor`,`tv`.`nombre` AS `vehiculo`,`v`.`placa` AS `placa`,`pe`.`direccion_entrega` AS `direccion_entrega`,`pe`.`latitud_entrega` AS `latitud_entrega`,`pe`.`longitud_entrega` AS `longitud_entrega`,(select count(0) from `pedido_item` `i` where (`i`.`pedido_id` = `pe`.`id`)) AS `total_items` from (((((`pedido` `pe` join `usuario` `uc` on((`uc`.`id` = `pe`.`comprador_id`))) join `negocio` `n` on((`n`.`id` = `pe`.`negocio_id`))) left join `usuario` `ur` on((`ur`.`id` = `pe`.`repartidor_id`))) left join `vehiculo` `v` on((`v`.`id` = `pe`.`vehiculo_id`))) left join `tipo_vehiculo` `tv` on((`tv`.`id` = `v`.`tipo_vehiculo_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_registro_diario`
--

/*!50001 DROP VIEW IF EXISTS `v_registro_diario`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY DEFINER */
/*!50001 VIEW `v_registro_diario` AS select `registro_comercio`.`negocio_id` AS `negocio_id`,cast(convert_tz(`registro_comercio`.`fecha`,'+00:00',(select `configuracion`.`valor` from `configuracion` where (`configuracion`.`clave` = 'zona_horaria'))) as date) AS `dia`,sum(`registro_comercio`.`ingreso`) AS `ventas`,sum(`registro_comercio`.`costo_vendido`) AS `costo_de_lo_vendido`,sum(`registro_comercio`.`ganancia`) AS `ganancia_bruta`,sum(if((`registro_comercio`.`tipo` = 'compra'),`registro_comercio`.`egreso`,0)) AS `compras`,sum(if((`registro_comercio`.`tipo` = 'gasto'),`registro_comercio`.`egreso`,0)) AS `gastos`,sum(if((`registro_comercio`.`tipo` = 'comision'),`registro_comercio`.`egreso`,0)) AS `comisiones`,(sum(`registro_comercio`.`ganancia`) - sum(if((`registro_comercio`.`tipo` in ('gasto','comision')),`registro_comercio`.`egreso`,0))) AS `ganancia_neta`,(sum(`registro_comercio`.`ingreso`) - sum(`registro_comercio`.`egreso`)) AS `flujo_caja`,sum(if((`registro_comercio`.`tipo` = 'venta'),`registro_comercio`.`cantidad`,0)) AS `unidades_vendidas` from `registro_comercio` group by `registro_comercio`.`negocio_id`,`dia` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_reportes_pendientes`
--

/*!50001 DROP VIEW IF EXISTS `v_reportes_pendientes`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY DEFINER */
/*!50001 VIEW `v_reportes_pendientes` AS select `r`.`tipo` AS `tipo`,`r`.`objetivo_id` AS `objetivo_id`,(case `r`.`tipo` when 'producto' then (select `producto`.`nombre` from `producto` where (`producto`.`id` = `r`.`objetivo_id`)) when 'negocio' then (select `negocio`.`nombre` from `negocio` where (`negocio`.`id` = `r`.`objetivo_id`)) when 'repartidor' then (select concat_ws(' ',`usuario`.`nombre`,`usuario`.`apellido`) from `usuario` where (`usuario`.`id` = `r`.`objetivo_id`)) when 'usuario' then (select concat_ws(' ',`usuario`.`nombre`,`usuario`.`apellido`) from `usuario` where (`usuario`.`id` = `r`.`objetivo_id`)) else concat('Reseña #',`r`.`objetivo_id`) end) AS `objetivo`,count(0) AS `total_reportes`,count(distinct `r`.`reportante_id`) AS `personas_que_reportan`,elt(max(field(`m`.`gravedad`,'baja','media','alta')),'baja','media','alta') AS `gravedad`,group_concat(distinct `m`.`nombre` order by `m`.`nombre` ASC separator ' · ') AS `motivos`,min(`r`.`created_at`) AS `primer_reporte`,max(`r`.`created_at`) AS `ultimo_reporte` from (`reporte` `r` join `motivo_reporte` `m` on((`m`.`id` = `r`.`motivo_id`))) where (`r`.`estado` in ('pendiente','en_revision')) group by `r`.`tipo`,`r`.`objetivo_id` order by max(field(`m`.`gravedad`,'baja','media','alta')) desc,`personas_que_reportan` desc,`ultimo_reporte` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_sancion_activa`
--

/*!50001 DROP VIEW IF EXISTS `v_sancion_activa`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY DEFINER */
/*!50001 VIEW `v_sancion_activa` AS select `sancion`.`id` AS `id`,`sancion`.`usuario_id` AS `usuario_id`,`sancion`.`rol_afectado` AS `rol_afectado`,`sancion`.`tipo` AS `tipo`,`sancion`.`negocio_id` AS `negocio_id`,`sancion`.`producto_id` AS `producto_id`,`sancion`.`reporte_id` AS `reporte_id`,`sancion`.`motivo` AS `motivo`,`sancion`.`inicia_en` AS `inicia_en`,`sancion`.`termina_en` AS `termina_en`,`sancion`.`aplicada_por` AS `aplicada_por`,`sancion`.`revocada_en` AS `revocada_en`,`sancion`.`revocada_por` AS `revocada_por`,`sancion`.`motivo_revocacion` AS `motivo_revocacion`,`sancion`.`created_at` AS `created_at`,`sancion`.`updated_at` AS `updated_at` from `sancion` where ((`sancion`.`tipo` <> 'advertencia') and (`sancion`.`revocada_en` is null) and (`sancion`.`inicia_en` <= utc_timestamp()) and ((`sancion`.`termina_en` is null) or (`sancion`.`termina_en` > utc_timestamp()))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_usuario_roles`
--

/*!50001 DROP VIEW IF EXISTS `v_usuario_roles`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013  SQL SECURITY DEFINER */
/*!50001 VIEW `v_usuario_roles` AS select `u`.`id` AS `usuario_id`,`u`.`nombre` AS `nombre`,`u`.`apellido` AS `apellido`,`u`.`email` AS `email`,`u`.`rol_activo` AS `rol_activo`,(`r`.`usuario_id` is not null) AS `es_repartidor`,`r`.`estado_verificacion` AS `estado_repartidor`,(select count(0) from `negocio` `n` where ((`n`.`usuario_id` = `u`.`id`) and (`n`.`deleted_at` is null))) AS `total_negocios`,`u`.`es_admin` AS `es_admin`,exists(select 1 from `v_sancion_activa` `s` where ((`s`.`usuario_id` = `u`.`id`) and (`s`.`tipo` in ('suspension','bloqueo')) and (`s`.`rol_afectado` = 'todos'))) AS `cuenta_bloqueada`,exists(select 1 from `v_sancion_activa` `s` where ((`s`.`usuario_id` = `u`.`id`) and (`s`.`tipo` in ('suspension','bloqueo')) and (`s`.`rol_afectado` in ('cliente','todos')))) AS `sancionado_cliente`,exists(select 1 from `v_sancion_activa` `s` where ((`s`.`usuario_id` = `u`.`id`) and (`s`.`tipo` in ('suspension','bloqueo')) and (`s`.`rol_afectado` in ('repartidor','todos')))) AS `sancionado_repartidor`,exists(select 1 from `v_sancion_activa` `s` where ((`s`.`usuario_id` = `u`.`id`) and (`s`.`tipo` in ('suspension','bloqueo')) and (`s`.`rol_afectado` in ('comerciante','todos')) and (`s`.`negocio_id` is null))) AS `sancionado_comerciante`,(select count(0) from `sancion` `s` where ((`s`.`usuario_id` = `u`.`id`) and (`s`.`tipo` = 'advertencia'))) AS `advertencias` from (`usuario` `u` left join `repartidor` `r` on((`r`.`usuario_id` = `u`.`id`))) where (`u`.`deleted_at` is null) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-03 21:21:21
