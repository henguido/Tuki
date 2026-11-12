# Matriz de aceptación

Última ejecución: 12 de noviembre de 2026. Evidencia en [`docs/evidence/`](evidence/).

**Dispositivos y entornos**

| Entorno | Detalle |
|---|---|
| Host | Windows 11, Flutter 3.47.4, Dart 3.13.3 — `flutter test` (motor real, sin pantalla) |
| Teléfono Android | Samsung SM-A325M (Galaxy A32), Android 13 (API 33), 1080 × 2400, APK de depuración |
| Tableta Android | No disponible |
| iOS (simulador o dispositivo) | No disponible: el entorno es Windows |

**Estados:** ✅ pasó · ❌ falló · ⏳ pendiente (con su causa).

| ID | Prueba | Automatizada (host) | Teléfono Android | Tableta Android | iOS |
|---|---|---|---|---|---|
| A01 | Primera apertura en modo avión | ✅ sin datos ni red: Inicio, capítulo, 3 láminas, audio y galería vacía | ⏳ **modo avión sin activar** (lo hace Ema, paso 1 del README). ✅ con red: primera apertura tras borrar datos, Inicio, portada, audio y galería vacía | ⏳ sin dispositivo | ⏳ |
| A02 | Rellenar vecinas y pintar encima | ✅ | ✅ cuerpo, hoja y pata con colores distintos; trazo encima | ⏳ | ⏳ |
| A03 | Borrar parte de un trazo y deshacer | ✅ | ⏳ borrador y deshacer sin ejercitar a mano en el teléfono | ⏳ | ⏳ |
| A04 | Rotar, zoom y volver a pintar | ✅ zoom con dos dedos, rotación y toque en el punto exacto | ⏳ no se cambió la rotación del sistema ni se hizo zoom a mano | ⏳ | ⏳ |
| A05 | Pintar, esperar Guardado, cerrar proceso y abrir | ✅ cerrar y reabrir la base de datos en disco | ✅ `am force-stop` (PID 3635 → 4306): Inicio ofrece continuar y el editor recupera rellenos y trazo, editables | ⏳ | ⏳ |
| A06 | Escritura tardía y fallo de almacenamiento | ✅ revisión antigua rechazada; Reintentar guarda la más reciente | No aplica (requiere simular el fallo) | No aplica | No aplica |
| A07 | Rana → quetzal → sendero y volver desde cada origen | ✅ orígenes Láminas, Inicio y Mis dibujos; botón atrás del sistema | ✅ avance completo y «Volver a las láminas» desde Láminas; ⏳ orígenes Inicio y galería a mano | ⏳ | ⏳ |
| A08 | Idioma, ambos audios y segundo plano | ✅ pista por idioma, atenuación, parada en segundo plano, persistencia | ✅ ambos audios activos, parada al pulsar Inicio, cambio a inglés sin perder pantalla. ⏳ **atenuación al oído** y persistencia tras reiniciar | ⏳ | ⏳ |
| A09 | Exportar y cancelar una segunda exportación | ✅ PNG 2048 px, colores correctos, cancelación sin cambios | ✅ `tuki-sendero.png` (1707 × 2048) guardado con el diálogo del sistema y recuperado; segunda exportación cancelada sin archivo nuevo | ⏳ | ⏳ |
| A10 | Teléfono y tableta horizontal, texto ampliado, lector de pantalla | ✅ 390 × 844, 320 × 568, 1280 × 800; texto ×2 sin desbordes; áreas de 48 dp y etiquetas | ✅ etiquetas legibles por los servicios de accesibilidad (volcado de `uiautomator`). ⏳ TalkBack, texto ampliado y horizontal a mano | ⏳ | ⏳ |

## Qué se verificó en cada nivel

**Compilación**

- ✅ Android: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk` (firma de depuración).
- ⏳ iOS: `flutter build ios --simulator` / `--no-codesign` sin ejecutar. Causa: requiere macOS con Xcode.
- ✅ `dart format` sin cambios, `flutter analyze` sin incidencias.

**Simulador / emulador**

- ⏳ Ninguno. No hay emuladores Android configurados en la máquina y no hay simulador iOS.

**Dispositivo físico (Samsung SM-A325M, Android 13)**

- ✅ `flutter test integration_test`: 2 de 2 (recorrido con catálogo, SQLite, audio y PNG reales; reapertura de la base).
- ✅ Recorrido manual dirigido por `adb` con capturas.

**Host**

- ✅ `flutter test`: 130 de 130 (88 de la primera entrega + 42 de niveles, edades, acceso y paquetes).

## Evidencia

| Archivo | Contenido |
|---|---|
| `evidence/pruebas-host.txt` | Formato, análisis y lista de las 130 pruebas |
| `evidence/android-edad-configuracion.png`, `android-adultos-edad.png` | Configuración inicial de edad y sección en Para adultos |
| `evidence/android-laminas-filtro-sugerido.png`, `android-laminas-todas.png` | Filtro sugerido (6–8) y vista Todas con «Sugerida» |
| `evidence/android-editor-facil.png`, `android-curiosidad.png`, `android-control-adultos.png` | Paleta corta, curiosidad y control de adultos |
| `evidence/pruebas-integracion-android.txt` | Salida de la prueba de integración en el teléfono |
| `evidence/android-a05-1…3-*.png` | Antes de cerrar el proceso, Inicio tras reabrir, obra retomada y editada |
| `evidence/android-a07-*.png` | Quetzal y sendero (última lámina) |
| `evidence/android-a08-*.png` | Voz y ambiente activos, estado tras segundo plano, interfaz en inglés |
| `evidence/android-a09-*.png` | Diálogo de guardado, PNG exportado, aviso de exportado y de cancelado |
| `evidence/android-portada.png`, `android-inicio-continuar.png`, `android-galeria.png`, `android-adultos.png` | Pantallas |

## Niveles y edades

La matriz de esta ampliación (13 requisitos, automatizada y en teléfono) está en [`NIVELES.md`](NIVELES.md#7-pruebas). Las capturas `android-a0x-*` son de la primera entrega: la pantalla de láminas y el editor fácil han cambiado desde entonces. A01–A10 se volvieron a ejecutar automatizadas y la prueba de integración se repitió en el teléfono; el recorrido manual A01–A10 no se repitió completo.

## Comandos ejecutados

```bash
dart format --output=none --set-exit-if-changed lib test tool integration_test
flutter analyze
flutter test
flutter test integration_test -d RF8R32GQWGL
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell pm clear dev.tukiapp.tuki_little_adventures      # primera apertura limpia
adb shell am force-stop dev.tukiapp.tuki_little_adventures  # cierre del proceso (A05)
adb shell input keyevent 3                                   # segundo plano (A08)
adb pull /sdcard/Download/tuki-sendero.png                   # PNG exportado (A09)
```

## Pendientes y causa

| Pendiente | Causa | Quién |
|---|---|---|
| A01 en modo avión real | No se cambiaron ajustes del sistema del teléfono durante la sesión | Ema (README, pasos 1–5) |
| Todo iOS (compilación, simulador, dispositivo) | Entorno Windows | Quien tenga un Mac |
| Tableta horizontal en dispositivo | Sin tableta | Ema, si dispone de una |
| A03, A04 y orígenes de A07 a mano en el teléfono | Cubiertos solo por pruebas automatizadas | Ema (README, pasos 8, 9 y 13) |
| Atenuación del ambiente al oído, TalkBack, texto ampliado | Requieren una persona | Ema |
| Aprobación de arte y audio | Recursos provisionales | Cliente, por recurso en `docs/RECURSOS.md` |
