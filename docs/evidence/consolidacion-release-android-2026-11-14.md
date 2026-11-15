# Consolidación y preparación Android de TUKI 1.0

Evidencia del 14 de noviembre de 2026. Dispositivo: Samsung SM-A325M,
Android 13 (API 33), serie `RF8R32GQWGL`.

## Consolidación

- `master` y `origin/master`: `63008d3`.
- PR #4: `codex/tuki-quality-android` (`c19fe97`), abierto en borrador,
  limpio y con CI aprobado; base `master`.
- PR #5: `codex/tuki-1.0-polish` (`967f242`), abierto en borrador,
  limpio y con CI aprobado; base PR #4.
- PR #5 depende de #4. Secuencia: revisar/integrar #4, después cambiar la
  base o integrar #5, y finalmente esta rama. No se modificó ni fusionó
  `master`.

## Rendimiento medido

Mismo Samsung, prueba `laminas_rendimiento_test.dart` en profile. Se rasterizan
una vez las capas estáticas de plantilla y tinta; el trazo activo permanece
dinámico y los rellenos regeneran su capa con debounce. Una comparación por
píxel de A10/A13 limita la diferencia media a menos de 2 y los píxeles
visiblemente diferentes a menos de 2 %.

| Lámina | Raster p90 antes | Raster p90 final | Relleno antes | Relleno final |
|---|---:|---:|---:|---:|
| A10 | 33,4 ms | 13,4 ms | 46,4 ms | 40,5 ms |
| A13 | 31,8 ms | 13,7 ms | 48,2 ms | 46,1 ms |

El resultado final mantiene 124 fotogramas de muestra por trazo y queda dentro
del presupuesto de 16,7 ms para 60 fps. Se descartó una primera variante que
empeoraba el relleno y se corrigió una carrera de ciclo de vida de imágenes
antes de conservar la solución.

## Pruebas

- `flutter analyze`: sin hallazgos.
- `flutter test`: 201/201 aprobadas.
- Android físico: 60/60 láminas aprobadas con relleno, pincel, borrador,
  Deshacer, Rehacer, zoom, guardado y reapertura; base de integración aislada.
- Texto al 200 %: interfaz accesible y desplazable, sin cierre ni desborde
  detectado por jerarquía UI.
- Rotación: jerarquía completa en horizontal; ajustes restaurados.
- Offline: red predeterminada `none`, TUKI abrió y mostró obras/controles;
  Wi-Fi y datos restaurados.
- Etiquetas, foco, estados seleccionados y objetivos de 48 dp: cubiertos por
  pruebas de widgets; jerarquía física expuso `Ajustes para adultos`,
  `Explorar`, `Continuar mi dibujo`, `Capítulos` y `Mis dibujos`.
- TalkBack: no concluyente. El servicio Samsung está instalado, pero al
  activarlo por primera vez mostró su propio permiso para llamadas. No se
  concedió un permiso ajeno a TUKI. Estado restaurado: accesibilidad desactivada
  y sin servicios habilitados.
- Ajustes restaurados: escala 1,1; rotación automática activa; orientación 0;
  Wi-Fi y datos activos.

## Preservación

La APK QA se instaló con actualización (`install -r`), nunca se desinstaló ni
se borraron datos. SHA-256 de `files/tuki.sqlite` antes y después:
`d49d24cced6635634e8be9b4c08a9589cce05abc7b91604fd2cadd481a5d3b87`.

## Android y firma

- Versión: `1.0.0+1`; QA `1.0.0-qa`.
- Release inspeccionado: `dev.tukiapp.tuki_little_adventures`, nombre `TUKI`,
  minSdk 24, target/compile SDK 36.
- Release solo declara el permiso interno de receptor dinámico; no contiene
  `INTERNET`, `ACCESS_NETWORK_STATE` ni permisos sensibles.
- La construcción release falla sin `key.properties`; ya no puede usar la
  clave debug. La configuración segura y un ejemplo ignorado por Git están
  preparados.
- APK/AAB release de inspección se generaron deliberadamente sin firma y **no
  son publicables**. Verificación: APK `DOES NOT VERIFY`; AAB `jar is unsigned`.

## Privacidad, familias y arte

- Sin anuncios, compras, analítica, cuentas ni rastreo.
- Exportación protegida ahora por control de adultos; el destino externo lo
  elige la persona adulta.
- Política de privacidad en borrador y lista de Data Safety preparadas sin
  inventar responsable, correo o dominio.
- E06 se conserva: el quetzal es reconocible y no apareció una mejora clara
  que justificara alterar el original.
- El icono de tucán integrado sigue bloqueado: el JPG/nombre de Etsy no prueba
  una licencia comercial ni derecho a crear un icono derivado. Se creó una
  propuesta original separada, no integrada, pendiente de aprobación y revisión
  de términos.

Referencias oficiales consultadas: [firma de Android](https://developer.android.com/studio/publish/app-signing),
[target SDK de Google Play](https://developer.android.com/google/play/requirements/target-sdk),
[Families](https://support.google.com/googleplay/android-developer/answer/9893335),
[User Data](https://support.google.com/googleplay/android-developer/answer/10144311)
y [preparación de la ficha](https://support.google.com/googleplay/android-developer/answer/9859455).

## Recomendación

- **GO condicionado para integración técnica**, respetando #4 → #5 → esta
  rama y volviendo a ejecutar CI después de cada cambio de base.
- **NO-GO para Google Play**, incluso para considerar la candidata publicable,
  hasta aportar clave de carga/Play App Signing, confirmar Application ID,
  identidad/contacto/URL HTTPS, completar declaraciones de Play, cerrar
  licencias de icono e ilustraciones y realizar TalkBack humano y sesión
  infantil. Los artefactos sin firma son solo evidencia técnica.
