# Base de datos MDR Market 2.0 (MySQL 8.4).
#
# La primera vez que arranca (con el volumen de datos vacío), MySQL ejecuta
# el script y crea la base `mdrmarket_new` con tablas, vistas, triggers,
# procedimientos y datos iniciales. Si el volumen ya tiene datos, no se toca.
FROM mysql:8.4

# Hora del servidor en UTC: la base guarda todo en UTC y los reportes
# lo convierten a hora de Bolivia (-04:00).
ENV TZ=UTC

COPY mdrmarketnewdatabase.sql /docker-entrypoint-initdb.d/01-mdrmarket.sql

# Configuración para poca memoria (el plan gratuito de Railway da 0.5 GB):
# sin performance_schema (ahorra ~150 MB), buffer de InnoDB chico y pocas
# conexiones simultáneas. Suficiente para pruebas; se puede subir en un plan mayor.
CMD ["mysqld", \
     "--performance-schema=OFF", \
     "--innodb-buffer-pool-size=64M", \
     "--max-connections=40", \
     "--skip-name-resolve"]
