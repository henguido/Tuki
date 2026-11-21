# Corrección del motor de coloreado por zonas conectadas

Fecha de auditoría: 2026-11-20  
Rama auditada: `main`  
Estado: implementación validada en las 60 láminas. D02 v4 fue regenerada
desde la fuente corregida autorizada; D02 v1, v2 y v3 permanecen intactas.

## Defecto reproducido

El documento de dibujo guardaba un color por `region.id` y el renderizador
aplicaba ese color al `Path` completo. El conversor, a su vez, fusionaba zonas
de papel distintas para alcanzar un diámetro táctil mínimo y un tope por
nivel. El resultado era determinista: si un ID contenía dos o más islas, un
solo toque pintaba todas.

La prueba de regresión usa dos puntos de A10, `(359.5, 169.5)` y
`(47.5, 80.5)`. En `a10-helechos-v1.json` ambos pertenecen a `r002`; al tocar
el primero, los dos píxeles toman el mismo color. En la revisión corregida son
`r015` y `r027`: el primer toque deja el segundo blanco y después cada zona
acepta un color distinto.

También se confirmó un segundo defecto en la selección: `regionNear` asumía
que la primera región siempre era el fondo. En A10 y A13 un toque exacto en
`r001` podía ser sustituido por otra región cercana. La selección ahora da
prioridad absoluta a todo acierto exacto; la tolerancia solo interviene ante
un hueco geométrico real.

## Magnitud inicial

Estado encontrado al iniciar la auditoría:

| Medida | Valor |
|---|---:|
| Láminas | 60 |
| Zonas de papel conectadas | 11.833 |
| Regiones publicadas | 4.102 |
| Regiones multiparte | 1.882 |
| Zonas absorbidas por fusiones | 7.731 |

Una región multiparte de esta auditoría no es simplemente un trazado con un
agujero. `partes` cuenta componentes de papel independientes detectados antes
de la vectorización. Los agujeros se mantienen dentro del mismo trazado y no
se convierten en rellenos separados.

## Solución aplicada

1. Cada componente conectado de papel vuelve a ser una región coloreable.
2. Ya no se fusionan zonas por tamaño ni para cumplir el antiguo tope de 140.
3. Los detalles pequeños permanecen disponibles mediante zoom; el tamaño no
   cambia su identidad ni su color.
4. La vectorización usa una tolerancia de medio píxel para mantener alineados
   hit testing, máscara y borde en láminas con muchas zonas.
5. `PageTemplate` crea un índice espacial de 24 × 24 celdas para no recorrer
   todas las rutas en cada toque.
6. El renderizador no dibuja rutas blancas: una obra nueva conserva el fondo
   blanco con cero operaciones de relleno, y solo se pintan zonas modificadas.
7. Cada plantilla corregida recibe una revisión nueva; las revisiones previas
   se conservan mediante `previousTemplates`.

No se dividieron subtrazados indiscriminadamente. La separación ocurre antes
de vectorizar, usando componentes conectados del papel. Un contorno exterior y
sus agujeros continúan siendo una sola región geométrica.

## Pruebas y evidencia

- `test/laminas_test.dart` comprueba las sondas interiores, el raster real, los
  divisores visibles, selección exacta con tolerancia, Deshacer/Rehacer,
  SQLite, zoom y orientación.
- La regresión de A10 demuestra el comportamiento antes y después con lectura
  de píxeles, no solo con conteos o `Path.contains()`.
- `tool/laminas/diagnostico_regiones.py` acepta coordenadas o un ID y genera:
  mapa de IDs, máscara resaltada, componentes conectados, píxeles afectados y
  un JSON reproducible.
- Evidencia puntual disponible en
  `docs/laminas/diagnostico_regiones/A10_r015_seleccion.png` y
  `A10_r027_seleccion.png`.
- Las vistas de las 60 láminas permanecen en `docs/laminas/previas/` y muestran
  un color único por zona conectada.

Resultado actual de la auditoría segura:

| Medida | 60 corregidas |
|---|---:|
| Zonas de papel | 11.833 |
| Regiones publicables | 11.833 |
| Regiones multiparte restantes | 0 |
| Láminas con modelo conectado | 60 |
| Fugas interiores | 0 |
| Solapes visibles | 0 |
| Sondas geométricas | 60/60 |

## Rendimiento

Medición host de peor caso: todas las regiones tienen un color diferente. No
representa una obra normal, pero obliga a recorrer toda la geometría.

| Lámina | Antes: regiones / carga / pintado | Después: regiones / carga / selección total / pintado |
|---|---|---|
| A10 | 140 / 41 ms / 30 ms | 816 / 103 ms / 51 ms / 54 ms |
| A13 | 140 / 54 ms / 32 ms | 1.155 / 96 ms / 94 ms / 41 ms |

La obra en blanco y las obras parcialmente coloreadas se benefician de omitir
rellenos blancos. El índice espacial limita el trabajo de cada toque a las
rutas de su celda. Falta repetir estas cifras en profile sobre Android con el
catálogo final integrado.

## Compatibilidad de obras guardadas

La base de datos ya almacena `templateRevision`. El catálogo carga esa revisión
para editor, galería y exportación. Por ello no se migran IDs antiguos: una
obra existente continúa abriendo con su plantilla anterior, sus colores, sus
trazos de pincel/borrador y su historial persistido. Las pruebas del catálogo
exigen que todas las revisiones intermedias estén en `previousTemplates`.

## Integración de D02

D02 v4 contiene 217 regiones para 217 zonas detectadas, sin componentes
agrupados, fugas, solapes ni papel sin región. El manifiesto publica v4 y
mantiene v1, v2 y v3 en `previousTemplates`, de modo que las obras existentes
continúan abriendo con la geometría con la que fueron guardadas.

## Validación Android física

El 20 de noviembre de 2026, el recorrido instrumental aprobó 60/60 láminas en
un Samsung SM-A325M: carga, selección táctil, relleno, pincel, borrador,
Deshacer, Rehacer, zoom, guardado y reapertura. A10 y D02 comprobaron además
en el dispositivo dos pares de zonas que compartían ID en revisiones antiguas;
en las plantillas actuales cada par resolvió a dos regiones independientes.
La APK QA se instaló con actualización conservadora y la base existente
conservó antes y después el SHA-256
`a6da920a3b4209ee561fd015ba926bf7821af0a2984ea9d4065418291b2eac6d`.
