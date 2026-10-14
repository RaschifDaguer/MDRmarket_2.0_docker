-- Verificación en dos pasos para entrar al panel de administración (/admin).
-- Guardan la clave del autenticador (Google Authenticator) y los códigos de
-- recuperación. Los dos van CIFRADOS con el APP_KEY de la API: si el APP_KEY
-- cambia, hay que volver a configurar la verificación (poner ambas en NULL).
ALTER TABLE usuario
  ADD COLUMN app_authentication_secret TEXT NULL
    COMMENT 'Clave del autenticador del panel admin (cifrada con APP_KEY)' AFTER remember_token,
  ADD COLUMN app_authentication_recovery_codes TEXT NULL
    COMMENT 'Códigos de recuperación del panel admin (cifrados con APP_KEY)' AFTER app_authentication_secret;
