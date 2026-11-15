# QA integral y prueba física Android — 14 de noviembre de 2026

## Estado y aislamiento

- Base verificada: `master` y `origin/master` en `63008d3`.
- Trabajo: `codex/tuki-quality-android`, en un worktree aislado.
- `F:\Tuki` permaneció limpio; los cambios anteriores siguen recuperables en
  `stash@{0}`.
- Dispositivo autorizado: Samsung `SM-A325M`, Android 13, serie
  `RF8R32GQWGL`.
- ADB: `C:\Users\hen_g\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
- Archivo original de dibujos QA antes y después de las pruebas:
  `files/tuki.sqlite`, 20.480 bytes, SHA-256
  `5BCBABE524CBA0E750FB42DD47A5F5FB753B34C6652F3213DFD6AB78225E4DCA`.
  El hash idéntico demuestra que esta ronda no modificó los dibujos existentes.

## Auditoría de las 60 láminas

La matriz de aprobación automatizada está en
`docs/laminas/matriz_aprobacion.csv` y la matriz física por lámina en
`docs/evidence/matriz-fisica-android-2026-11-14.csv`.

- 60/60 identificadores únicos y presentes en el catálogo; 15 por nivel.
- 60/60 plantillas cargan y pasan parser, orientación, límites, geometría,
  sondas de relleno, fuga, deshacer, zoom y persistencia SQLite en host.
- 60/60 fuentes conservan el SHA-256 registrado. Son 59 fuentes organizadas y
  la fuente corregida versionada de E06, cuyo SHA-256 es
  `64CA321CD4B9073D1DE9DC85016ADFFFFD9BF60596CB87949E2AE0CB47FD6952`.
- A10 y A13 pasan geometría, relleno y prueba física; mantienen el defecto de
  rendimiento descrito abajo.
- E06 pasa geometría, relleno y prueba física. La lectura visual del retoque
  como quetzal continúa pendiente de aprobación artística humana.
- Los originales de `F:\Tuki\ilustraciones` no fueron modificados ni borrados.

## Pruebas físicas reales

Se ejecutó una variante de integración aislada, con paquete
`dev.tukiapp.tuki_little_adventures.qa.integration`, para impedir que el
ejecutor de Flutter pudiera retirar o limpiar `TUKI QA`.

Resultado del recorrido: **60/60 láminas aprobadas** en 3 min 31 s. En cada una
se verificó apertura y render, relleno sin fuga, pincel, borrador, deshacer el
borrador, deshacer el pincel, zoom y restablecimiento, guardado, salida,
reapertura y persistencia. Rehacer no existe todavía y queda marcado como
`no disponible`, no como aprobado.

La aceptación de la app pasó **3/3** recorridos físicos adicionales en 24 s:
audio, coloreado, guardado, siguiente lámina, reapertura, continuación,
edición, exportación PNG, idioma y edad. También se confirmó arranque sin red
con `Active default network: none`; Wi-Fi y datos se restauraron al terminar.

No se atribuye aprobación física a texto ×2, rotación horizontal ni TalkBack:
se restauró la configuración del teléfono después de los intentos, pero no se
obtuvo evidencia concluyente. Las pruebas automatizadas de host para texto ×2,
tableta horizontal, objetivos de 48 dp y etiquetas semánticas sí pasan.

## Rendimiento Android en perfil

Medición base conservada:

| Lámina | Apertura | Raster medio / p90 | Relleno |
|---|---:|---:|---:|
| E01 | 399 ms | 10,5 / 13,2 ms | 34,1 ms |
| M06 | 507 ms | 13,5 / 14,7 ms | 34,9 ms |
| D14 | 458 ms | 13,4 / 14,8 ms | 36,9 ms |
| A10 | 603 ms | 32,9 / 33,4 ms | 47,1 ms |
| A13 | 637 ms | 31,1 / 31,7 ms | 51,9 ms |

Se midieron dos optimizaciones antes de decidir: tres capas independientes
dieron p90 de 34,7 ms en A10 y 33,1 ms en A13; evitar `saveLayer` en pincel
puro dio 34,0 y 31,9 ms. Ninguna mejoró de forma reproducible la base y ambas
se retiraron. El código final no contiene una optimización especulativa. A10 y
A13 siguen cerca de 30 fps durante el pincel y requieren investigación de
render más profunda.

## Correcciones de esta ronda

- Paquete exclusivo `.qa.integration` para pruebas físicas de Flutter, sin
  riesgo para la base de datos de QA o la aplicación normal.
- Recorrido 60/60 ampliado con comprobación real de borrador y doble deshacer.
- Comandos seguros documentados en las tres pruebas de dispositivo.
- Control explícito en CI para catálogo e integridad de las 60 plantillas,
  además de la regresión Flutter completa y compilación de APK QA.

## Regresión y APK final

- Formato: sin diferencias de formato.
- `flutter analyze`: sin observaciones.
- `flutter test`: **199/199** aprobadas.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`, 177.967.687 bytes.
- Identidad: `dev.tukiapp.tuki_little_adventures.qa`, versión
  `0.1.0-qa` (`versionCode` 1), etiqueta `TUKI QA`.
- SHA-256 del APK:
  `86143CD5B92229193D3F6908770FD6C465F584C2109092B72080BA3CE7A64946`.
- Certificado SHA-256:
  `6533B820F58EE837E6BBEDB29F09B26A8384760EE3DE13C5CB6185AD114C0362`.
  Coincide con la aplicación QA instalada y es una clave de depuración.
- Instalación conservadora completada con actualización sobre el paquete
  existente; no se desinstaló ni se limpiaron datos. La app abrió y quedó en
  primer plano. El hash de `tuki.sqlite` siguió idéntico después de instalar.
- Esta APK debug incluye el permiso `INTERNET` añadido por las herramientas de
  Flutter; la prueba sin conexión confirma que la experiencia evaluada funciona
  sin red, pero esta variante no debe describirse como release publicable.
- GitHub Actions: ejecución `43657389783` aprobada en 5 min 39 s. Pasaron
  formato, análisis, validación explícita del catálogo y las 60 plantillas,
  regresión host, compilación de APK QA y publicación del artefacto.

## Pendientes reales

- Evaluación manual con niño, tacto fino y reconocimiento artístico de E06.
- TalkBack, texto ampliado y rotación comprobados manualmente en dispositivo.
- Tableta Android e iOS físicos.
- Mejorar A10 y A13 con una optimización que demuestre ganancia en perfil.
- Rehacer no está implementado.
- Licencias comerciales verificables para todo arte destinado a publicación.
- Firma de distribución y configuración de Play; ninguna release actual debe
  considerarse publicable.

