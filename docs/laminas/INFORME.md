# Las 60 láminas de El bosque nuboso — informe

13 de noviembre de 2026 · rama `feature/laminas-60` (parte de `feature/niveles-edades`, commit `65c448e`). `master` no se tocó.

## Resumen

| | Cantidad |
|---|---|
| Ilustraciones convertidas a plantilla del editor | **60 de 60** |
| Aprobadas con el motor real del editor (8 comprobaciones cada una) | **60 de 60** |
| Abiertas y pintadas en un dispositivo Android real | **7 de 60** (E01, E02, M06, D14, A08, A10, A13) |
| Pendientes de que alguien las abra en un dispositivo | 53 |
| Bloqueadas | 0 |
| Con observaciones de arte (no impiden el uso) | 21 — ver la matriz |

«Aprobada» aquí significa exactamente: pasó las comprobaciones automáticas descritas abajo. **No significa aprobación artística ni prueba con niños.** Ninguna lámina se ha probado con el dedo de un niño.

Documentos:

- [MATRIZ_APROBACION.md](MATRIZ_APROBACION.md) (y `matriz_aprobacion.csv`): una fila por lámina.
- [REGISTRO_CAMBIOS.md](REGISTRO_CAMBIOS.md): qué se cambió en cada ilustración respecto a su original.
- `contacto_facil.jpg`, `contacto_medio.jpg`, `contacto_detallado.jpg`, `contacto_avanzado.jpg` y `previas/<ID>.jpg`: cada región con un color distinto, para revisar a ojo las agrupaciones.
- `evidencia/`: salida de la conversión, de las pruebas y capturas del teléfono.

## Fase 1 — Revisión

- La auditoría existente está en `ilustraciones/_auditoria/` (no en `ilustraciones_auditoria/`). Se leyó completa y se usó su matriz `matriz_60.csv` como lista de trabajo e identificadores (`E01`…`A15`).
- Formato del editor: plantilla JSON con `regions` (trazados cerrados, regla `nonZero`, de fondo a frente) y contornos. El conversor que había (`tool/raster_coloring_template.py`) descompone la imagen en rectángulos de píxel a 552 px: bordes en escalera, sin limpieza y 890 regiones en A10.
- Hallazgos medidos sobre las 60 (detalle por lámina en el registro de cambios):
  - **Contornos abiertos:** 41 láminas tenían pasos estrechos que comunicaban dos zonas amplias (hasta 60 en A10).
  - **Zonas demasiado pequeñas:** de 13–53 zonas en Fácil a 194–1155 en Avanzado; la mayoría por debajo de lo que un dedo acierta.
  - **Orientación:** D08, D09, D10, D12 y D14 son horizontales (1600 × 1067).
  - **Duplicados:** ninguno dentro de las 60 (el duplicado exacto que detectó la auditoría quedó fuera de la selección).
  - **E06:** pico grande y curvo, de loro.

## Fases 2 y 3 — Corrección y vectorización

Todo lo hace `tool/laminas/convertir.py`, de forma reproducible, leyendo los originales sin modificarlos:

1. Normaliza a 1600 px y separa tinta de papel.
2. Quita motas, cierra huecos de trazo y engrosa el contorno en Fácil si mide menos de 13 px (no hizo falta en ninguna: el mínimo fue 15,6 px).
3. **Cierra contornos abiertos** con una línea de tinta donde un paso de menos de ~8 px une dos zonas amplias.
4. Reparte la tinta entre las zonas vecinas: las regiones cubren todo el lienzo, no se solapan y un toque sobre una línea rellena la zona más cercana.
5. **Agrupa las zonas pequeñas** con la vecina con la que comparten más frontera. El dibujo no cambia: esas zonas se rellenan juntas. Los brillos de los ojos se conservan como regiones propias para que no tomen el color de la cara.
6. Vectoriza regiones y tinta como polígonos cerrados con huecos (contornos suaves, no rectángulos).

| Nivel | Diámetro mínimo de región | Tope | Regiones (mín – media – máx) | Tamaño por plantilla |
|---|---|---|---|---|
| Fácil | 5,5 % del lado corto (≈ 20 dp sin ampliar) | 36 | 8 – 15 – 27 | 10–30 KB |
| Medio | 4,0 % (≈ 14 dp) | 60 | 10 – 32 – 51 | 15–43 KB |
| Detallado | 2,8 % (≈ 10 dp; 24 dp con zoom ×2,4) | 95 | 33 – 75 – 95 | 20–63 KB |
| Avanzado | 2,0 % (≈ 7 dp; 24 dp con zoom ×3,4) | 140 | 113 – 138 – 140 | 67–181 KB |

A10 pasó de 890 segmentos accidentales a 140 regiones; A13, de 1155 zonas a 140. El total de las 60 plantillas es de 3,3 MB (más 1,6 MB de miniaturas).

**Formato:** el mismo JSON del editor, con un campo nuevo y opcional, `inks`: la tinta como formas negras cerradas que se pintan encima. Identificadores de región `r001`…, estables para una revisión dada (el conversor es determinista).

**E06:** `tool/laminas/corregir_e06.py` sustituye el pico por uno corto y cierra el perfil de la cara; con la cresta y las plumas largas de la cola que ya tenía, se lee como quetzal. Es un retoque hecho por programa, no un dibujo nuevo: **necesita visto bueno artístico**. El original sigue intacto y el retoque está en `tool/laminas/fuentes_corregidas/E06.png`.

**Horizontales:** se conservan con su proporción (lienzo 1600 × 1067). El editor ya ajustaba cualquier proporción; no hubo que deformar ni recortar.

### Cambios en la app (los mínimos que hicieron falta)

- `PageTemplate` y `DrawingRenderer`: leer y pintar `inks`.
- Catálogo: campos opcionales `thumbnail` y `artId` por lámina.
- Miniaturas: una lámina sin pintar muestra su PNG en vez de cargar la plantilla (60 tarjetas ya no leen 60 JSON), y la lista de láminas se construye al desplazarse.

No se cambió la arquitectura.

### Identificadores y obras guardadas

- Las tres páginas que ya existían conservan su identificador y pasan a la revisión 2 con el arte nuevo: `rana-en-la-hoja` ← E01, `quetzal` ← M06, `sendero` ← D15. Las plantillas v1 siguen en el catálogo (`previousTemplates`), así que una obra guardada antes se abre y se sigue editando sobre su dibujo original (probado).
- Las otras 57 usan `<id de arte>-<tema>`: `e02-mariposa`, `a10-helechos`…
- Orden del capítulo: Fácil E01–E15, Medio, Detallado, Avanzado. «Siguiente lámina» sigue ese orden.

## Fase 4 — Pruebas

`flutter analyze`: sin incidencias. `flutter test`: **199 de 199** (las 130 anteriores más 61 de `laminas_test.dart` y 8 de `laminas_app_test.dart`). Las pruebas anteriores, escritas para tres láminas dibujadas a mano, ahora usan ese capítulo como fixture (`test/fixtures/chapter_tres_laminas.json`); ninguna se eliminó.

| # | Requisito | Cómo se comprobó, en las 60 | Resultado |
|---|---|---|---|
| 1 | Carga correcta | Parser del editor sobre cada plantilla | ✅ 60 |
| 2 | Cantidad de regiones | Coincide con la medida del conversor y respeta el tope del nivel | ✅ 60 |
| 3 | Relleno individual | Toque en el centro de cada parte de cada región (8 815 puntos en total): rellena esa región y solo esa | ✅ 60 |
| 4 | Sin fugas | Render real con un color por región y lectura del píxel en cada punto; además, cobertura, solape y fuga medidos sobre los polígonos (< 0,1 %) | ✅ 60 |
| 5 | Deshacer | Rellenar todas las regiones y deshacer hasta la lámina en blanco | ✅ 60 |
| 5 | **Rehacer** | **No aplica: el editor no tiene «rehacer».** No se añadió porque es una función nueva, no una corrección | — |
| 6 | Guardado y recuperación | Obra con todas las regiones y un trazo, escrita y leída en SQLite (en memoria) | ✅ 60 |
| 7 | Zoom y desplazamiento | Zoom ×6 sobre la región más pequeña y desplazamiento, en cuatro tamaños de lienzo | ✅ 60 |
| 8 | Rendimiento en Android | **5 láminas** medidas en el Samsung SM-A325M (abajo) | ⚠️ parcial |
| 9 | Orientación y dimensiones | Encaje sin deformar en cuatro lienzos; D08 abierta en la app en 390×844, 320×568, 844×390 y 1280×800 | ✅ 60 (host) |
| 10 | Tacto del nivel | Diámetro mínimo de región según el nivel | ✅ 60 (medido, no probado con dedo) |

### En el dispositivo (Samsung SM-A325M, Android 13, compilación de depuración)

- `flutter test integration_test`: 3 de 3 (recorrido con E01 y E02, reapertura de la base y PNG; rendimiento).
- Recorrido manual por `adb`: lista de 60 con miniaturas, filtro Avanzado, E01, A10 y A08 pintadas con el dedo simulado, giro a horizontal. Capturas en `evidencia/android-60-*.png`.

| Lámina | Regiones | Abrir | Pincel: ms por fotograma (media / p90) | Toque de relleno |
|---|---|---|---|---|
| E01 rana | 11 | 2,0 s (primera apertura) | 7,3 / 10,0 | 108 ms |
| M06 quetzal | 51 | 1,0 s | 9,6 / 13,2 | 92 ms |
| D14 cascada (horizontal) | 95 | 0,9 s | 12,4 / 14,8 | 74 ms |
| A10 helechos | 150* | 0,9 s | 27,4 / 35,0 | 84 ms |
| A13 árbol gigante | 150* | 0,9 s | 27,3 / 33,2 | 104 ms |

\* Medido antes de bajar el tope de Avanzado de 150 a 140 regiones; la tinta, que es lo que más pesa, no cambió.

Lectura: hasta Detallado el pintado cabe en 16 ms incluso en depuración. **En Avanzado, pintar con el pincel va a unos 30 fotogramas por segundo en este teléfono en depuración.** No se midió en compilación de perfil o de lanzamiento, que es más rápida. Si ahí siguiera por encima de 16 ms, el arreglo es guardar la tinta ya dibujada en vez de trazarla en cada fotograma; no se hizo porque aún no está demostrado que haga falta.

## Pendientes

**Requieren un dispositivo o una persona**

- Abrir y pintar las 53 láminas que nadie ha abierto en un dispositivo.
- Ninguna lámina horizontal de Detallado se capturó en pantalla (D14 se abrió y pintó en la prueba de rendimiento; D08 solo en el host).
- Tacto real con niños de cada edad, sobre todo las regiones de ~7 dp de Avanzado y ~10 dp de Detallado, que piden ampliar.
- Rendimiento en compilación de perfil, y en un dispositivo más modesto.
- iOS y tableta física: sin probar (entorno Windows, sin tableta).

**Decisiones de arte**

- **E06:** aprobar el retoque del pico o encargar un quetzal nuevo.
- **D02 (mariposa):** el dibujo es más sencillo que su nivel (33 regiones, como una de Medio).
- **Láminas con pocas regiones para su nivel:** E01, E03, E05, E10, E11, E13, E14, M01, M03, M04, M05, M13 quedan por debajo de la guía orientativa de la auditoría porque el dibujo es simple. Funcionan; solo no llegan al número.
- **Agrupaciones:** en Fácil, el blanco de los ojos se rellena con la cabeza (es un anillo de ~4 dp, imposible de acertar). Conviene mirar las hojas de contacto por si alguna agrupación no convence.
- D13, A14 y A15 incluyen elementos secundarios que la auditoría ya señaló.
- Los cuatro niveles de un tema comparten título («La rana en la hoja»); en la galería solo los distingue la miniatura.
- Las curiosidades de los 12 temas nuevos son afirmaciones sencillas y comprobables, pero necesitan revisión educativa. Siguen sin narración.
- Derechos de uso de las ilustraciones generadas: sin confirmar para distribución.

**Integración**

- **En `F:\Tuki` hay trabajo sin confirmar de otro agente** sobre la rama `feature/niveles-edades` (plantillas v2 por rectángulos para las tres páginas, `inks` en el motor y cambios en `chapter.json` y en pruebas). No se tocó: este trabajo se hizo en una copia de trabajo aparte (`F:\Tuki-laminas-60`). Al unir ambos habrá conflicto en `page_template.dart`, `drawing_renderer.dart`, `chapter.json`, `catalog.json` y dos pruebas; las dos implementaciones de `inks` son equivalentes y esta rama ya sustituye esas tres páginas.
- Los originales (`ilustraciones/`, 58 MB) no están en el repositorio: el conversor los lee de `F:\Tuki\ilustraciones\organizadas` y cada plantilla registra el SHA-256 de su fuente. Para reproducir la conversión en otra máquina hay que aportar esa carpeta.
- Los filtros de «Elige una lámina» se desplazan con la lista; con 15 tarjetas por nivel hay que volver arriba para cambiar de filtro.
- `tool/build_templates.dart` sigue generando las tres plantillas v1; ya no son las vigentes.

## Cómo repetirlo

```bash
python tool/laminas/corregir_e06.py <ilustraciones>/organizadas/facil/E06_quetzal.webp
python tool/laminas/convertir.py <ilustraciones>/organizadas     # numpy, opencv, scipy, scikit-image
TUKI_WRITE_APPROVAL_EVIDENCE=1 flutter test test/laminas_test.dart # escribe tool/laminas/aprobacion.json
python tool/laminas/manifiesto.py                                # publica solo las aprobadas
python tool/laminas/contacto.py && python tool/laminas/informe.py
flutter test
flutter test integration_test -d <dispositivo>
```
