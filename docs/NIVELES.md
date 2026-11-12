# Niveles, edades y contenido

Estado al 12 de noviembre de 2026, rama `feature/niveles-edades`. Este documento separa lo **implementado y probado** de lo **preparado** y de lo **pendiente**.

## 1. Clasificación

Los niveles y los rangos de edad se declaran en `assets/chapters/catalog.json`, no en el código de las pantallas. Añadir un nivel o cambiar una edad sugerida es un cambio de datos (hay una prueba que añade un quinto nivel sin tocar la app).

| Nivel (`id`) | Edad sugerida | Hojas | Editor |
|---|---|---|---|
| Fácil (`easy`) | 2–4 años | 1 de 4 | Paleta inicial de 6 colores ampliable con «+»; tolerancia táctil del 2,5 % |
| Medio (`medium`) | 4–6 años | 2 de 4 | Paleta completa |
| Detallado (`detailed`) | 6–8 años | 3 de 4 | Paleta completa |
| Avanzado (`advanced`) | 8+ años | 4 de 4 | Paleta completa (sin láminas todavía) |

- Las edades son orientativas. **Ninguna lámina se bloquea**: el rango solo ordena, marca «Sugerida» y preselecciona un filtro.
- El nivel pertenece a la lámina y se fija al abrirla. Cambiar la edad sugerida no altera una lámina que se está coloreando.
- Zoom, desplazamiento, relleno, pincel, borrador y deshacer están en todos los niveles.
- **Tolerancia táctil (Fácil):** si el toque cae en el fondo a menos del 2,5 % del lado de la lámina de una figura, se rellena la figura. Un toque exacto nunca cambia de destino.
- Para quien no lee: hojas llenas (1 a 4) junto al nombre del nivel, en filtros, tarjetas y opciones de edad.

### Metadatos por lámina (`chapter.json`)

| Campo | Requisito | Dónde |
|---|---|---|
| Identificador estable | ✅ | `id` (las obras guardadas lo referencian) |
| Capítulo | ✅ | `CatalogPage.chapterId` |
| Nombre y descripción localizados | ✅ | `title`, `description` (es/en) |
| Nivel | ✅ | `difficulty` → `levels[].id` |
| Edad mínima / máxima | ✅ | Del nivel; `minAge` / `maxAge` por lámina si hace falta |
| Archivo de ilustración | ✅ | `template` (+ `previousTemplates`) |
| Miniatura | ✅ | Se dibuja a partir de la plantilla (y de la obra, si existe); no hay un archivo aparte que pueda quedar desfasado |
| Curiosidad | ✅ | `funFact` (es/en); `funFactAudio` opcional |
| Estado de descarga | ✅ | `status`: `available` (empaquetada) o `planned` (sin arte) |
| Estado de desbloqueo | ✅ | `Entitlements.isUnlocked(capítulo)` a partir de `access` |
| Versión del contenido | ✅ | `contentVersion` en catálogo, capítulo y lámina |

Todos los campos nuevos son opcionales: un manifiesto anterior sigue cargando (probado).

## 2. Edad sugerida

- **Primera apertura:** pantalla «¿Para qué edad buscas aventuras?» con 2–4, 4–6, 6–8, 8+ y «Prefiero no indicar». Se puede omitir.
- **Después:** *Para adultos → Edad sugerida*.
- **Qué se guarda:** solo el identificador del rango (`ageRange`) y que la pantalla ya se mostró (`ageSetupDone`), en las preferencias del dispositivo. No hay nombre, fecha de nacimiento, foto, ubicación ni correo, ni campo alguno donde escribirlos.

| Elección | Filtro al entrar | Orden en «Todas» |
|---|---|---|
| 2–4 | Fácil | Fácil → Medio → Detallado |
| 4–6 | Medio | Medio → Fácil → Detallado |
| 6–8 | Detallado | Detallado → Medio → Fácil |
| 8+ | Todas (aún no hay láminas avanzadas; no se preselecciona un filtro vacío) | Detallado → Medio → Fácil |
| Sin indicar | Todas | Dificultad creciente |

La lógica está en `lib/features/chapters/recommendation.dart`, sin dependencias de interfaz.

## 3. Inventario de las 15 láminas de El bosque nuboso

**Disponibles: 3 de 15.** Las otras 12 están registradas en el manifiesto con `"status": "planned"`: tienen identificador, nombre en dos idiomas y nivel, pero **no tienen ilustración** y la app no las muestra como contenido. No se han generado dibujos de relleno para aparentar un capítulo completo.

| # | Lámina | `id` | Nivel | Arte | Curiosidad | Estado |
|---|---|---|---|---|---|---|
| 1 | La rana en la hoja | `rana-en-la-hoja` | Fácil | Provisional (12 regiones) | ✅ es/en | **Disponible** |
| 2 | La mariposa | `mariposa` | Fácil | ❌ Falta | ❌ | Pendiente |
| 3 | El colibrí | `colibri` | Fácil | ❌ Falta | ❌ | Pendiente |
| 4 | El tucán | `tucan` | Fácil | ❌ Falta (la referencia de Etsy no tiene licencia verificada) | ❌ | Pendiente |
| 5 | La flor tropical | `flor-tropical` | Fácil | ❌ Falta | ❌ | Pendiente |
| 6 | El quetzal | `quetzal` | Medio | Provisional (24 regiones) | ✅ es/en | **Disponible** |
| 7 | El perezoso | `perezoso` | Medio | ❌ Falta | ❌ | Pendiente |
| 8 | El mono | `mono` | Medio | ❌ Falta | ❌ | Pendiente |
| 9 | El coatí | `coati` | Medio | ❌ Falta | ❌ | Pendiente |
| 10 | Los helechos | `helechos` | Medio | ❌ Falta | ❌ | Pendiente |
| 11 | Las orquídeas | `orquideas` | Detallado | ❌ Falta | ❌ | Pendiente |
| 12 | Las ranas del bosque | `ranas-del-bosque` | Detallado | ❌ Falta | ❌ | Pendiente |
| 13 | El árbol gigante | `arbol-gigante` | Detallado | ❌ Falta | ❌ | Pendiente |
| 14 | La cascada | `cascada` | Detallado | ❌ Falta | ❌ | Pendiente |
| 15 | El sendero del bosque | `sendero` | Detallado | Provisional (48 regiones) | ✅ es/en | **Disponible** |

Notas:

- Las tres láminas disponibles siguen siendo **arte provisional** pendiente de aprobación (ver `RECURSOS.md`).
- **Narración de las curiosidades: no existe ningún audio.** El botón «Escuchar» de la curiosidad está implementado y probado con un catálogo de prueba, y solo aparece cuando el manifiesto declara `funFactAudio`. Hoy la curiosidad se lee en pantalla.
- Las curiosidades publicadas son afirmaciones generales y comprobables; conviene que las revise quien valide el contenido educativo.
- «El sendero» pasó a llamarse «El sendero del bosque»; su `id` no cambió y las obras guardadas se conservan.

### Para integrar una lámina pendiente

1. Añadir `pages/<id>-v1.json` (regiones cerradas de fondo a frente, contornos; ver el contrato en el README).
2. En `chapter.json`: quitar `"status": "planned"` y añadir `template`, `description`, `funFact` y `contentVersion`.
3. `flutter test`: las pruebas del catálogo validan plantilla, textos en los dos idiomas y rutas de audio.

No hace falta tocar código de la app.

## 4. Monetización futura (diseño; nada activo)

**No hay compras, precios, productos ni cobros en esta versión.** No se ha añadido ningún SDK de tienda, de anuncios ni de analítica (hay una prueba que lo comprueba sobre `pubspec.lock`).

| Oferta | Cómo se modela | Estado |
|---|---|---|
| TUKI Free: primer capítulo, sin anuncios, herramientas completas | `access: {"type": "free"}` | ✅ Así se entrega |
| Adventure Packs: capítulo de compra única | `access: {"type": "pack", "productId": "…"}` en el capítulo | Preparado y probado con una tienda simulada |
| TUKI Complete: cinco capítulos | `bundles: [{"productId": "…", "chapters": [ids]}]` en el catálogo | Preparado. La lista de capítulos es cerrada: el catálogo rechaza un paquete que nombre un capítulo inexistente, así que no puede prometer capítulos futuros |

Piezas (`lib/features/store/`):

- `PurchaseGateway`: interfaz para Google Play Billing / StoreKit. La única implementación es `DisabledPurchaseGateway`, que no puede cobrar.
- `Entitlements`: decide si un capítulo está desbloqueado y guarda las compras en el dispositivo para que el contenido abra sin conexión. Un fallo de red al restaurar nunca retira contenido.
- `showAdultGate` / `openAdventures`: control de adultos (multiplicación) delante de la pantalla «Aventuras», que es la única comercial. Un capítulo de pago en Inicio lleva al control, no al contenido.

Pendiente antes de vender: elegir el plugin de tienda, mostrar el precio que devuelva la tienda (hoy el botón «Comprar» de un capítulo de pago no muestra precio), flujo de «Restaurar compras» en pantalla, productos dados de alta en las consolas y autorización explícita.

**Decisión abierta:** el engranaje de «Para adultos» sigue abriéndose sin control, como en los mockups aprobados. Solo «Aventuras» está protegida. Las tiendas suelen pedir que también los ajustes queden tras un control en apps infantiles.

## 5. Actualizaciones de contenido

Ya en uso (contenido empaquetado):

- Manifiestos versionados (`schemaVersion`, `contentVersion`), identificadores persistentes.
- `previousTemplates`: una obra guardada con una revisión anterior se abre con esa revisión.

Preparado y probado, **sin conectar a la app** (`lib/data/content/content_pack_installer.dart`):

- Descarga por archivo a `*.part` con reanudación desde el último byte recibido.
- Verificación de tamaño y SHA-256 de cada archivo; rutas que salgan de la carpeta se rechazan.
- Publicación atómica (un cambio de nombre de carpeta) en almacenamiento privado.
- Varias versiones instaladas a la vez; la vigente no se puede retirar.

Pendiente: decidir dónde se alojan los paquetes, implementar `PackFetcher` sobre HTTPS, firmar o fijar el descriptor del paquete, y hacer que `CatalogRepository` lea capítulos instalados además de los empaquetados. No se ha creado ningún servidor: con un solo capítulo gratuito, el catálogo local basta.

## 6. Privacidad y seguridad infantil

| Requisito | Estado |
|---|---|
| Sin datos personales del niño | ✅ Solo el rango de edad, en el dispositivo |
| Sin anuncios, analítica ni rastreo | ✅ Ninguna dependencia de ese tipo; sin permiso `AD_ID` |
| Sin enlaces externos | ✅ El código de la app no contiene direcciones web (probado) |
| Compras solo tras control de adultos | ✅ Estructura lista; no hay compras |
| Sin cuentas | ✅ |
| Permisos | Micrófono, cámara, ubicación y contactos: no declarados. `INTERNET` aparece en el APK de **depuración** (lo añade Flutter); la app no hace peticiones de red |

`share_plus` trae como dependencias transitivas las implementaciones de `url_launcher` para Linux, Windows y web. No forman parte de las compilaciones de Android ni de iOS y la app no las invoca.

**Sin hacer:** revisión de los requisitos vigentes de Google Play Families y Apple Kids Category. Hay que hacerla contra las políticas publicadas antes de preparar una publicación (formulario de público objetivo, política de privacidad, compilación de lanzamiento sin `INTERNET` si no se usa, control de adultos en ajustes).

## 7. Pruebas

`flutter test`: **130 de 130** (las 88 anteriores, sin eliminar ninguna, más 42 nuevas en `test/levels_test.dart` y `test/content_pack_test.dart`). Cuatro pruebas anteriores se actualizaron porque el comportamiento cambió a propósito: nombres «Medio/Detallado», título «El sendero del bosque», etiqueta accesible con la edad y paleta corta en la lámina fácil.

| # | Requisito | Automatizada | Teléfono (SM-A325M, Android 13) |
|---|---|---|---|
| 1 | Selección del rango de edad | ✅ | ✅ captura `android-edad-configuracion.png` |
| 2 | Persistencia de preferencias | ✅ | ⏳ sin reiniciar la app a mano |
| 3 | Cambio de dificultad | ✅ | ✅ |
| 4 | Filtros | ✅ | ✅ `android-laminas-*.png` |
| 5 | Láminas fuera del rango | ✅ | ✅ rana abierta con 6–8 elegido |
| 6 | Español / inglés | ✅ | ⏳ inglés sin recorrer a mano en esta versión |
| 7 | Guardado y restauración | ✅ (existentes + integración) | ✅ prueba de integración 2 de 2 |
| 8 | Dibujos tras actualizar contenido | ✅ | ⏳ sin actualizar sobre una instalación con dibujos (se borraron los datos para capturar la primera apertura) |
| 9 | Sin conexión | ✅ sin red en las pruebas | ⏳ modo avión real |
| 10 | Editor en teléfono y tableta | ✅ 390×844, 320×568, 1280×800 | ✅ teléfono; ⏳ tableta (sin dispositivo) |
| 11 | Sin anuncios ni rastreadores | ✅ | — |
| 12 | Acceso protegido al área comercial | ✅ | ✅ `android-control-adultos.png` |
| 13 | Compatibilidad con capítulos existentes | ✅ manifiesto anterior | — |

iOS sigue sin compilar ni probar (entorno Windows).
