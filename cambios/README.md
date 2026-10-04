# Cambios de estructura

Un archivo `.sql` por cambio, aplicado **en orden** a la base de producción
(Aiven) después de probarlo en local. Nunca se modifica un archivo que ya se
aplicó: si hay que corregir algo, se agrega un archivo nuevo.

**Nombre:** `AAAA-MM-DD_descripcion_corta.sql`, por ejemplo
`2026-10-15_agregar_propina_a_pedido.sql`.

**Contenido:** solo los `ALTER`, `CREATE` o `INSERT` del cambio, con un
comentario arriba que diga qué hace y por qué:

```sql
-- Agrega propina opcional al pedido (módulo 6).
ALTER TABLE pedido
  ADD COLUMN propina DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER descuento;
```

**Aplicar en Aiven** (con el `mysql` de Laragon y el `ca.pem` de Aiven):

```bash
mysql -h mdrmarket-db-mdrmarket.h.aivencloud.com -P 26451 -u avnadmin -p \
  --ssl-mode=VERIFY_IDENTITY --ssl-ca=ca.pem mdrmarket_new < cambios/ARCHIVO.sql
```

Recuerda reflejar el mismo cambio en `mdrmarketnewdatabase.sql`.

| Archivo | Fecha de aplicación en producción |
|---|---|
| *(todavía no hay cambios: la base de producción se creó con el script del 2026-10-03)* | |
