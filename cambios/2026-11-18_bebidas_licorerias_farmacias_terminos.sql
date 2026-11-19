-- Bebidas, licorerías, farmacias y términos y condiciones (18-nov-2026).
--
-- 1. Categorías: "Bebidas" pasa a ser una categoría principal (sin alcohol) y
--    se agregan "Bebidas alcohólicas" y "Tabaco", solo para mayores de 18.
--    Las farmacias solo publican medicamentos de venta libre (sin receta).
-- 2. Permisos por negocio: si vende bebidas alcohólicas (licorería) o es
--    farmacia, se le piden documentos extra (Alcaldía y SEDES).
-- 3. Términos y condiciones: qué versión aceptó cada usuario (declara ser
--    mayor de 18 años).
-- 4. Pedidos con bebidas alcohólicas: quedan marcados (el cliente confirmó su
--    edad y el repartidor pide el carnet al entregar).
--
-- Va después de los cambios de Daner del 2026-11-16 (SOAT, plazos, columnas
-- nuevas). Aplicar una sola vez.

-- ---------------------------------------------------------------------
-- 1. Categorías
-- ---------------------------------------------------------------------
ALTER TABLE categoria
  ADD COLUMN solo_mayores TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'Solo para mayores de 18 (bebidas alcohólicas): el cliente confirma su edad y el repartidor pide el carnet' AFTER descripcion,
  ADD COLUMN permiso ENUM('alcohol','farmacia') NULL
    COMMENT 'Permiso que necesita el negocio para vender aquí (ver negocio.vende_alcohol / es_farmacia)' AFTER solo_mayores;

-- "Bebidas" sale de "Alimentos y Bebidas" y pasa a ser principal. La
-- subcategoría 103 se queda con sus productos, con otro nombre.
UPDATE categoria SET nombre = 'Alimentos', descripcion = 'Comida preparada, abarrotes, panadería y snacks', updated_at = NOW()
 WHERE id = 1;
UPDATE categoria SET nombre = 'Gaseosas, jugos y refrescos', updated_at = NOW() WHERE id = 103;

INSERT INTO categoria (id, nombre, icono, descripcion, orden, solo_mayores, permiso, created_at, updated_at) VALUES
(13, 'Bebidas',              '🥤', 'Gaseosas, jugos, agua y más (sin alcohol)',                      13, 0, NULL,      NOW(), NOW()),
(14, 'Bebidas alcohólicas',  '🍷', 'Cervezas, vinos y licores. Venta solo a mayores de 18 años',     14, 1, 'alcohol', NOW(), NOW());

UPDATE categoria SET categoria_padre_id = 13, orden = 1, updated_at = NOW() WHERE id = 103;

INSERT INTO categoria (id, categoria_padre_id, nombre, icono, orden, solo_mayores, permiso, created_at, updated_at) VALUES
(1302, 13, 'Agua y hielo',                  '💧', 2, 0, NULL,      NOW(), NOW()),
(1303, 13, 'Energizantes e isotónicas',     '⚡', 3, 0, NULL,      NOW(), NOW()),
(1304, 13, 'Café, té e infusiones',         '☕', 4, 0, NULL,      NOW(), NOW()),
(1401, 14, 'Cervezas',                      '🍺', 1, 1, 'alcohol', NOW(), NOW()),
(1402, 14, 'Vinos y espumantes',            '🍷', 2, 1, 'alcohol', NOW(), NOW()),
(1403, 14, 'Singani y licores',             '🥃', 3, 1, 'alcohol', NOW(), NOW()),
(1404, 14, 'Cócteles y bebidas preparadas', '🍹', 4, 1, 'alcohol', NOW(), NOW());

-- Tabaco (cigarrillos y parecidos): solo mayores de 18 (Ley 1280). No pide permisos extra.
INSERT INTO categoria (id, nombre, icono, descripcion, orden, solo_mayores, permiso, created_at, updated_at) VALUES
(15, 'Tabaco', '🚬', 'Cigarrillos y tabaco. Venta prohibida a menores de 18 años', 15, 1, NULL, NOW(), NOW());
INSERT INTO categoria (id, categoria_padre_id, nombre, icono, orden, solo_mayores, permiso, created_at, updated_at) VALUES
(1501, 15, 'Cigarrillos y tabaco', '🚬', 1, 1, NULL, NOW(), NOW());

-- Vender medicamentos exige ser farmacia.
UPDATE categoria SET permiso = 'farmacia', updated_at = NOW() WHERE id = 201;

-- Medicamentos: solo de venta libre. La farmacia lo confirma al publicar cada uno.
ALTER TABLE producto
  ADD COLUMN venta_libre_confirmada_en TIMESTAMP NULL
    COMMENT 'Medicamentos: cuándo confirmó la farmacia que se vende sin receta médica' AFTER disponible;

-- ---------------------------------------------------------------------
-- 2. Permisos del negocio y documentos que se le piden
-- ---------------------------------------------------------------------
ALTER TABLE negocio
  ADD COLUMN vende_alcohol TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'Vende bebidas alcohólicas (licorería): autorización de expendio + licencia de funcionamiento' AFTER razon_social,
  ADD COLUMN es_farmacia TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'Farmacia: resolución del SEDES + licencia de funcionamiento' AFTER vende_alcohol;

-- Los negocios que ya venden medicamentos quedan como farmacia: la app les
-- pedirá los documentos (sus productos siguen a la venta).
UPDATE negocio n SET n.es_farmacia = 1
 WHERE EXISTS (SELECT 1 FROM producto p WHERE p.negocio_id = n.id AND p.categoria_id = 201 AND p.deleted_at IS NULL);

-- condicion_negocio: el documento solo se pide si el negocio tiene ese permiso.
-- instrucciones_revision: qué revisar en el panel antes de aprobarlo.
ALTER TABLE tipo_documento
  ADD COLUMN instrucciones_revision VARCHAR(600) NULL
    COMMENT 'Qué tiene que revisar el administrador antes de aprobarlo' AFTER descripcion,
  ADD COLUMN condicion_negocio SET('alcohol','farmacia') NULL
    COMMENT 'Si no es NULL, solo se pide a negocios con alguno de esos permisos' AFTER condicion_vehiculo;

INSERT INTO tipo_documento (id, codigo, nombre, descripcion, instrucciones_revision, ambito, condicion_vehiculo, condicion_negocio) VALUES
(10, 'autorizacion_alcohol', 'Autorización de expendio de bebidas alcohólicas',
     'Permiso especial de la Alcaldía para vender bebidas alcohólicas (Seguridad Ciudadana o Administración Tributaria)',
     'Debe estar vigente, a nombre del negocio o de su dueño y con la misma dirección. Si tiene código QR, léelo para verificarla en la página de la Alcaldía.',
     'negocio', NULL, 'alcohol'),
(11, 'licencia_funcionamiento', 'Licencia de funcionamiento municipal',
     'El cartón de la licencia de la Alcaldía. En "Actividad" o "Rubro" debe decir lo que vendes (licorería o farmacia)',
     'En "Actividad" o "Rubro" debe decir "Expendio de bebidas alcohólicas" o "Licorería" (si vende alcohol) o "Farmacia" (si vende medicamentos). Si dice "Pulpería" o "Micromercado", NO está autorizado para vender alcohol: recházala. Lee el QR del cartón para ver en la página de la Alcaldía si está vigente, con deudas o clausurado.',
     'negocio', NULL, 'alcohol,farmacia'),
(12, 'resolucion_sedes', 'Resolución de apertura y funcionamiento (SEDES)',
     'Resolución administrativa del SEDES de tu departamento que autoriza a la farmacia a funcionar',
     'Emitida por el SEDES, vigente, a nombre de la farmacia y con la misma dirección.',
     'negocio', NULL, 'farmacia');

INSERT INTO requisito_rol (rol, tipo_documento_id, obligatorio) VALUES
('comerciante', 10, 1),
('comerciante', 11, 1),
('comerciante', 12, 1)
ON DUPLICATE KEY UPDATE obligatorio = VALUES(obligatorio);

-- ---------------------------------------------------------------------
-- 3. Términos y condiciones
-- ---------------------------------------------------------------------
ALTER TABLE usuario
  ADD COLUMN terminos_version VARCHAR(20) NULL
    COMMENT 'Versión de los términos y condiciones que aceptó (incluye declarar que es mayor de 18)' AFTER fecha_nacimiento,
  ADD COLUMN terminos_aceptados_en TIMESTAMP NULL
    COMMENT 'Cuándo los aceptó' AFTER terminos_version;

-- ---------------------------------------------------------------------
-- 4. Pedidos con bebidas alcohólicas o tabaco
-- ---------------------------------------------------------------------
ALTER TABLE pedido
  ADD COLUMN solo_mayores TINYINT(1) NOT NULL DEFAULT 0
    COMMENT 'Lleva productos para mayores de 18: el cliente confirmó su edad y aceptó la declaración de compra; el repartidor pide el carnet' AFTER notas;

-- ---------------------------------------------------------------------
-- 5. sp_datos_faltantes: documentos según los permisos del negocio.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_datos_faltantes;
DELIMITER $$
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
    -- Documentos de cada NEGOCIO (NIT si se marca obligatorio; permisos de
    -- licorería o farmacia solo si el negocio tiene ese permiso).
    SELECT CONCAT('documento.', td.codigo, ':negocio', n.id)
      FROM requisito_rol rr
      JOIN tipo_documento td ON td.id = rr.tipo_documento_id
      JOIN negocio n         ON n.usuario_id = p_usuario_id AND n.deleted_at IS NULL
     WHERE rr.rol = p_rol AND rr.obligatorio = 1 AND td.activo = 1 AND td.ambito = 'negocio'
       AND (td.condicion_negocio IS NULL
            OR (n.vende_alcohol = 1 AND FIND_IN_SET('alcohol', td.condicion_negocio) > 0)
            OR (n.es_farmacia = 1 AND FIND_IN_SET('farmacia', td.condicion_negocio) > 0))
       AND NOT EXISTS (SELECT 1 FROM documento d
                        WHERE d.negocio_id = n.id
                          AND d.tipo_documento_id = td.id
                          AND d.estado <> 'rechazado')
  ) faltantes;
END$$
DELIMITER ;
