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

## Producción: Aiven

La base de producción está en **Aiven for MySQL 8.4** (plan Free, servicio
`mdrmarket-db`, conexión con SSL), **no** en Docker. Se probó un MySQL propio
en Railway, pero el plan gratuito de Railway no alcanza para una base encendida
todo el día. El Docker de este repo queda para **uso local**.

- Copia exacta de la base de Aiven: [`mdrmarket_new_aiven_2026-10-03.sql`](mdrmarket_new_aiven_2026-10-03.sql)
  (el comienzo del archivo explica el caso Aiven).
- Conectarse y aplicar cambios:
  [docs/BASE_DE_DATOS.md](https://github.com/RaschifDaguer/MDRmarket_2.0/blob/main/docs/BASE_DE_DATOS.md)
  del repo de código.

## Cambiar la estructura

> 🚨 **Nunca importes `mdrmarketnewdatabase.sql` ni la copia de Aiven en
> producción:** empiezan borrando las tablas y se pierden los datos reales.

1. Escribe el cambio en un archivo nuevo dentro de [`cambios/`](cambios/)
   (ej. `cambios/2026-10-15_agregar_propina.sql` con el `ALTER TABLE`).
2. Agrega el mismo cambio al script maestro, para instalaciones nuevas.
3. Pruébalo en local (Laragon o Docker).
4. Haz un respaldo de producción y aplica **solo el archivo de `cambios/`** en Aiven.

El `Dockerfile` usa poca memoria (performance_schema apagado, buffer de 64 MB)
para correr en servidores chicos; en local no molesta.

## Notas

- Todo se guarda en **UTC**; los reportes muestran hora de Bolivia (-04:00).
- Los usuarios de ejemplo (`*@mdrmarket.local`) son solo de prueba.
