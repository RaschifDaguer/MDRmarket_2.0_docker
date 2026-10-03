# MDR Market 2.0 — Base de datos (Docker)

Base de datos MySQL 8.4 de **MDR Market**, app de delivery para Santa Cruz de
la Sierra con tres vistas: cliente, repartidor y comerciante.

El código de la API (Laravel) y de la app (Flutter) está en
[MDRmarket_2.0](https://github.com/RaschifDaguer/MDRmarket_2.0).

## Qué contiene

| Archivo | Para qué |
|---|---|
| `mdrmarketnewdatabase.sql` | Script completo: crea la base `mdrmarket_new` con sus tablas, vistas, triggers, procedimientos y datos iniciales |
| `Dockerfile` | Imagen MySQL 8.4 que ejecuta el script la primera vez que arranca |
| `docker-compose.yml` | Para levantarla en tu PC con un solo comando |

## Qué tiene la base

- **Usuarios y roles:** una sola cuenta por persona. Todos pueden comprar; repartidor y comerciante son perfiles extra.
- **Documentos:** fotos del carnet, licencia, vehículo, placa, RUAT y NIT. Lo que se pide a cada rol está en `requisito_rol`.
- **Vehículos:** liviano (moto, bicicleta), mediano (auto, camioneta) y grande (camión).
- **Catálogo:** 12 categorías con 49 subcategorías, productos con oferta opcional y fotos.
- **Pedidos:** estados, historial, stock que se descuenta solo y se devuelve si se cancela.
- **Envío:** precio por km (`tarifa_envio`) y cobertura del centro al 10mo anillo (`anillo`).
- **Reseñas:** una por usuario para cada producto, negocio o repartidor, editable.
- **Reportes y sanciones:** denuncias de usuarios y sanciones que se cumplen solas.
- **Ganancias del comerciante:** compras, ventas y reportes por día, semana, mes o año.

Funciones útiles: `CALL sp_datos_faltantes(usuario, 'repartidor')`,
`SELECT fn_cotizar_envio(...)`, `CALL sp_reporte_negocio(...)`.

## Usarla en tu PC

### Con Docker Desktop
```
docker compose up -d --build
```
Queda en `localhost:3307`, usuario `root`, contraseña `root`, base `mdrmarket_new`.

### Con Laragon (sin Docker)
En phpMyAdmin → **Importar** → `mdrmarketnewdatabase.sql`. El script crea la
base `mdrmarket_new` sola; no hace falta seleccionar una antes.

## Publicarla en Railway

1. En Railway: **New → GitHub Repo →** este repositorio. Railway detecta el `Dockerfile`.
2. En el servicio, pestaña **Variables**, agregar `MYSQL_ROOT_PASSWORD` con una contraseña segura.
3. Pestaña **Settings → Volumes**: agregar un volumen montado en `/var/lib/mysql` (sin esto los datos se borran en cada despliegue).
4. La API se conecta por la red privada de Railway:
   `DB_HOST=<nombre-del-servicio>.railway.internal`, `DB_PORT=3306`,
   `DB_DATABASE=mdrmarket_new`, `DB_USERNAME=root`, `DB_PASSWORD=<la misma de arriba>`.

> El script solo se ejecuta cuando el volumen está vacío. Para aplicar una
> versión nueva del script hay que borrar el volumen o importarlo a mano.

## Notas

- Todo se guarda en **UTC**; los reportes muestran hora de Bolivia (-04:00).
- Los usuarios de ejemplo (`*@mdrmarket.local`) son solo de prueba.
