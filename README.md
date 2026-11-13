# TUKI — Little Adventures

Guía ilustrada bilingüe (español / inglés) para colorear la naturaleza de Costa Rica.
Capítulo **El bosque nuboso** con tres láminas editables (La rana en la hoja, El quetzal, El sendero del bosque) de las 15 previstas, clasificadas por dificultad y edad sugerida, con curiosidades, narración, ambiente y exportación a PNG. Todo funciona sin red.

Estado: **desarrollo y QA local**. Publicación, compras, cuentas, analítica y servicios en línea pertenecen a otra etapa.

- Niveles, edades, inventario de las 15 láminas, monetización futura y contenido: [docs/NIVELES.md](docs/NIVELES.md)
- **Las 60 láminas** (conversión, matriz de aprobación, cambios por ilustración y pendientes): [docs/laminas/INFORME.md](docs/laminas/INFORME.md)
- Matriz de aceptación y evidencia: [docs/ACEPTACION.md](docs/ACEPTACION.md)
- Inventario de recursos (origen, licencia, estado): [docs/RECURSOS.md](docs/RECURSOS.md)

## Para Ema: instalar y repetir el recorrido de aceptación (Android)

Necesitas un teléfono Android 7 o posterior y el archivo `app-debug.apk` (se genera en `build/app/outputs/flutter-apk/app-debug.apk`; pídelo si no compilas tú).

**Instalar**

1. Copia `app-debug.apk` al teléfono (cable, Drive o correo) y ábrelo desde *Mis archivos*. Acepta «Instalar apps desconocidas» para esa app si Android lo pide.
   Con cable y `adb`: `adb install -r app-debug.apk`.
2. En el lanzador aparece **TUKI**.

**Recorrido** (anota cualquier paso que no coincida)

1. **Activa el modo avión** antes de abrir la app por primera vez.
2. Abre **TUKI**. La primera vez aparece **¿Para qué edad buscas aventuras?**: elige un rango y **Continuar**, o toca **Omitir**. No pide ningún dato del niño. Después debes ver «TUKI — Little Adventures», la tarjeta *El bosque nuboso* y el botón **Explorar**. No debe aparecer «Continuar mi dibujo».
3. Toca **Mis dibujos**: mensaje de galería vacía y botón **Explorar capítulos**. Tócalo.
4. Toca **Explorar**. En la portada toca **Escuchar** (suena la narración y el botón dice «Pausar») y **Sonidos** (ambiente del bosque; baja de volumen mientras habla la voz y vuelve a subir cuando termina).
5. Toca **Colorear**. El audio se detiene y aparece **Elige una lámina** con los filtros **Todas | Fácil | Medio | Detallado | Avanzado**. Si elegiste una edad, su filtro llega seleccionado; toca **Todas** para ver las tres láminas, con nivel (hojas), edad sugerida y la marca **Sugerida**. **Avanzado** avisa de que aún no hay láminas. Cualquier lámina se puede abrir.
6. Abre **La rana en la hoja**. Es una lámina fácil: empieza con seis colores y el botón **+** muestra el resto. Con **Rellenar**, elige un color y toca el cuerpo y luego la hoja: solo cambia la zona tocada. La bombilla abre la **curiosidad** de la lámina (solo texto: aún no hay narración).
7. Elige **Pincel** y dibuja encima. Cambia a **Rellenar** y cambia el color del cuerpo: el trazo sigue ahí.
8. Elige **Borrador** y borra parte del trazo. Toca **Deshacer** varias veces: cada toque revierte una acción.
9. Con dos dedos amplía y mueve el lienzo; pinta de nuevo: la pintura cae donde tocas. El botón redondo de la esquina del lienzo vuelve a mostrar todo el dibujo. Gira el teléfono: las herramientas pasan a un panel lateral y el dibujo conserva su proporción.
10. Espera a leer **Guardado** (abajo a la izquierda).
11. **Cierra la app por completo** (recientes → deslizar) y vuelve a abrirla.
12. En Inicio aparece **Continuar mi dibujo**: tócalo. El dibujo vuelve con rellenos y trazos y se puede seguir editando.
13. Toca **Siguiente lámina** dos veces (quetzal, sendero). En El sendero el botón dice **Volver a las láminas**. Prueba también la flecha **Volver** y el botón atrás del sistema desde cada lámina.
14. En Inicio toca el engranaje (**Para adultos**). En **Edad sugerida** cambia el rango y comprueba que «Elige una lámina» lo refleja. Abajo, **Ver aventuras** pide resolver una multiplicación antes de abrir; dentro solo debe verse *El bosque nuboso — Incluido gratis — 3 de 15 láminas disponibles*, sin precios ni botones de compra. Cambia a **English**: la pantalla se traduce al momento. Vuelve a la portada y comprueba que **Listen** usa la narración en inglés. Cierra y abre la app: sigue en inglés.
15. En *Para adultos* toca **Exportar un dibujo**, elige uno y toca **Guardar PNG**. En el diálogo del sistema toca **Guardar**: aparece «Copia PNG exportada» y el archivo `tuki-<lámina>.png` queda donde elegiste.
16. Repite **Guardar PNG** y esta vez pulsa atrás en el diálogo: aparece «Exportación cancelada» y el dibujo sigue en *Mis dibujos*.

## Entorno usado

| Herramienta | Versión |
|---|---|
| Flutter | 3.47.4 (stable) |
| Dart | 3.13.3 |
| Android SDK | 36.0.0, JDK 25 (el de Android Studio) |
| Sistema de desarrollo | Windows 11 |

Dependencias resueltas (el `pubspec.lock` se versiona):

| Paquete | Versión | Función |
|---|---|---|
| drift / drift_dev | 2.35.4 / 2.35.3 | Obras en SQLite, con generación de código |
| sqlite3 | 3.5.2 | Motor SQLite empaquetado (transitiva de drift) |
| path_provider, path | 2.1.6, 1.9.1 | Almacenamiento privado de la app |
| shared_preferences | 2.5.6 | Idioma y sonido |
| just_audio, audio_session | 0.10.6, 0.2.4 | Narración, ambiente e interrupciones |
| file_picker | 13.3.3 | Diálogo del sistema «Guardar PNG» |
| share_plus | 13.3.1 | Hoja del sistema «Compartir» |
| crypto | 3.0.8 | SHA-256 de paquetes de contenido |
| intl + flutter_localizations | 0.20.3 | Interfaz con ARB / gen_l10n |
| build_runner, flutter_lints | 2.17.1, 6.0.0 | Desarrollo |

## Identificadores (provisionales de desarrollo)

| Plataforma | Identificador | Dónde |
|---|---|---|
| Android `applicationId` / `namespace` | `dev.tukiapp.tuki_little_adventures` | `android/app/build.gradle.kts` |
| iOS bundle ID | `dev.tukiapp.tukiLittleAdventures` | `ios/Runner.xcodeproj` |
| Paquete Dart | `tuki_little_adventures` | `pubspec.yaml` |
| Nombre en el lanzador | `TUKI` | `AndroidManifest.xml`, `Info.plist` |

**Confirmar los definitivos antes de preparar firma o distribución.** El APK actual va firmado con la clave de depuración.

## Comandos

```bash
flutter pub get
dart run build_runner build          # regenera lib/data/local/database.g.dart
dart format lib test tool integration_test
flutter analyze
flutter test                         # 199 pruebas en el host
flutter test integration_test -d <id-del-dispositivo>
flutter build apk --debug            # build/app/outputs/flutter-apk/app-debug.apk
dart run tool/build_templates.dart   # regenera las plantillas (ver aviso abajo)
flutter test test/tool/template_previews_test.dart   # PNG de revisión en build/template_previews/
```

### iOS (pendiente: requiere macOS)

Esta entrega se preparó en Windows, así que **no se ha compilado ni probado iOS**. En un Mac con Xcode:

```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ios --simulator        # o: flutter build ios --no-codesign
flutter test integration_test -d <simulador>
```

Objetivo de despliegue: iOS 15.0. La app no declara permisos de micrófono, ubicación ni galería. Una compilación iOS no sustituye la prueba de audio, orientación y cierre del proceso en un dispositivo iOS.

### Notas de esta máquina de desarrollo

- **Antivirus con inspección TLS (AVG).** Gradle no podía descargar de Maven Central porque el JDK de Android Studio no confía en la raíz del antivirus (Windows sí). Se compiló con un almacén de confianza temporal: copia de `jbr/lib/security/cacerts` + la raíz «AVG Web/Mail Shield Root» exportada del almacén de Windows con `keytool -importcert`, y `JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=<ruta> -Djavax.net.ssl.trustStorePassword=changeit"` solo en la sesión de compilación. No hay nada de esto en el repositorio. Alternativa: excluir `repo.maven.apache.org` de la inspección HTTPS del antivirus.
- **`kotlin.incremental=false`** en `android/gradle.properties`: con el proyecto en `F:` y la caché de pub en `C:`, la compilación incremental de Kotlin fallaba al cerrar sus cachés.
- El APK de depuración declara `INTERNET` (lo añade Flutter para depurar) y `ACCESS_NETWORK_STATE` (lo aporta un plugin). La app no hace ninguna petición de red. No declara micrófono ni ubicación.

## Arquitectura

```
lib/
  app/                 composición de dependencias, tema, widgets comunes
  features/chapters/   catálogo, niveles, recomendación, Inicio, portada, láminas y audio
  features/editor/     motor de dibujo y pantalla del editor
  features/gallery/    Mis dibujos y miniaturas
  features/adults/     idioma, edad sugerida, sonido y exportación PNG
  features/store/      derechos de acceso, control de adultos y «Aventuras» (sin tienda)
  data/local/          Drift/SQLite y preferencias
  data/content/        instalador de paquetes de contenido (sin conectar)
  l10n/                ARB es/en (gen_l10n)
assets/chapters/       catálogo, manifiesto, portada, audio y plantillas
test/  integration_test/  tool/
```

- **Estado:** `ChangeNotifier`. La lógica de dibujo, contenido y guardado se prueba sin lanzar pantallas.
- **Editor:** `EditorController` (documento inmutable + pila de deshacer de la sesión), `CanvasViewport` (una sola transformación para render y toque, con zoom y desplazamiento) y `DrawingRenderer` (misma composición para editor, miniaturas y PNG: rellenos → capa de trazos → contornos).
- **Guardado:** `SaveCoordinator` serializa las escrituras de una obra y siempre envía el snapshot más reciente; el repositorio rechaza cualquier revisión igual o anterior a la guardada. La fila se crea con el primer cambio confirmado.
- **Audio:** `ChapterAudioController` sobre una interfaz (`AudioEngine`) que en la app implementa `just_audio`.

## Contrato de contenido

`assets/chapters/catalog.json` (`schemaVersion: 1`) lista manifiestos relativos al catálogo; cada manifiesto declara rutas relativas a su carpeta. Además declara `levels` (niveles con edad sugerida), `ageRanges`, `contentVersion` y, en el futuro, `bundles`. Cada lámina admite `description`, `funFact`, `funFactAudio`, `minAge`/`maxAge`, `contentVersion` y `status` (`available` | `planned`); cada capítulo, `access`. Todos son opcionales y están descritos en [docs/NIVELES.md](docs/NIVELES.md). Extensión para revisiones de plantilla:

```json
"previousTemplates": { "1": "pages/rana-en-la-hoja-v1.json" }
```

Sirve para que las obras guardadas con una revisión anterior sigan abriéndose cuando se publique una nueva. Si la revisión de una obra no está en el catálogo, el editor ofrece volver y no toca el documento.

**Plantillas** (`schemaVersion`, `revision`, `viewBox`, `regions`, `outlines`): las regiones van de fondo a frente y son opacas; el toque selecciona la región visible superior. Regla de relleno única: `nonZero`.

Subconjunto SVG aceptado en `path`: `M L H V C S Q T Z`, absolutos y relativos. No se aceptan arcos (`A`). Cada subtrazado de una región debe cerrarse con `Z`, y tras `Z` el siguiente debe empezar con `M`.

> **No regeneres una plantilla publicada con otra geometría.** Para cambiar un dibujo crea `…-v2.json` con `revision: 2`, apunta `template` a ella y declara la anterior en `previousTemplates`.

## Base de datos

Tabla `drawings` (esquema 1, volcado en `drift_schemas/drift_schema_v1.json`): `drawingId` (PK), única `(chapterId, pageId)`, `templateRevision`, `documentVersion`, `saveRevision`, `fillsJson`, `strokesJson`, `updatedAt` (microsegundos UTC), índice `drawings_updated_at`. Orden de galería: `updatedAt` desc, `saveRevision` desc, `drawingId` asc.

- `fillsJson`: `{"cuerpo":"#7CB342"}`. Una región ausente es blanca.
- `strokesJson`: operaciones ordenadas `{"type":"brush","color":"#RRGGBB","width":22,"points":[[x,y],…]}` y `{"type":"eraser","width":48,"points":[…]}`, en coordenadas de la lámina.

Al cambiar el esquema: sube `schemaVersion`, añade el paso en `onUpgrade`, vuelca el esquema (`dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/`) y añade su prueba de migración.

## Limitaciones conocidas

- Arte de las láminas, narraciones, ambiente e icono son **provisionales** (ver inventario).
- El bucle del ambiente es MP3: puede oírse un corte mínimo al repetirse.
- El capítulo tiene 60 láminas (15 temas × 4 niveles) convertidas desde ilustraciones y verificadas con el motor del editor; solo 7 se han abierto en un dispositivo y ninguna tiene aprobación artística (ver `docs/laminas/INFORME.md`).
- Las curiosidades no tienen narración.
- El área de adultos se abre directamente desde el engranaje, como en los mockups; el control de adultos protege solo «Aventuras».
- En pantallas muy estrechas el título de la portada tapa parte de la ilustración.
