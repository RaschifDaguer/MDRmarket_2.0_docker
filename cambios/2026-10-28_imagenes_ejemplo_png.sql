-- Las imágenes de los negocios y productos de ejemplo (placehold.co) llegaban
-- en formato SVG, que la app (Flutter) no dibuja: se veía un recuadro vacío.
-- Pidiéndolas con ".png" llegan como imagen normal. Solo cambia esas URLs y se
-- puede ejecutar más de una vez (la segunda no encuentra nada que cambiar).
UPDATE producto_imagen SET url = REPLACE(url, '/ffffff?text=', '/ffffff.png?text=')
 WHERE url LIKE 'https://placehold.co/%/ffffff?text=%';

UPDATE negocio SET logo_url = REPLACE(logo_url, '/ffffff?text=', '/ffffff.png?text=')
 WHERE logo_url LIKE 'https://placehold.co/%/ffffff?text=%';

UPDATE negocio SET banner_url = REPLACE(banner_url, '/ffffff?text=', '/ffffff.png?text=')
 WHERE banner_url LIKE 'https://placehold.co/%/ffffff?text=%';
