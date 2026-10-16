-- Selfie (foto del rostro) para repartidores y comerciantes: el administrador
-- la compara con la foto del carnet para confirmar que es la misma persona.
-- Solo agrega filas; sp_datos_faltantes ya la pide sola a quien le falte.
-- Se puede ejecutar más de una vez sin duplicar nada.
INSERT IGNORE INTO tipo_documento (id, codigo, nombre, descripcion, ambito, condicion_vehiculo) VALUES
(8, 'foto_rostro', 'Foto del rostro (selfie)', 'Selfie de frente para compararla con la foto del carnet', 'persona', NULL);

INSERT IGNORE INTO requisito_rol (rol, tipo_documento_id, obligatorio)
SELECT rol, td.id, 1
  FROM (SELECT 'repartidor' AS rol UNION ALL SELECT 'comerciante') roles
  JOIN tipo_documento td ON td.codigo = 'foto_rostro';
