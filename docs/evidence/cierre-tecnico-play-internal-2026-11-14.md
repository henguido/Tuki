# Cierre técnico para Google Play Internal Testing

Evidencia del 14 de noviembre de 2026. No autoriza publicación ni carga en
Play Console.

## Identidad Android

- Producción: `dev.tukiapp.tuki_little_adventures`.
- QA: `dev.tukiapp.tuki_little_adventures.qa`.
- Integración física aislada:
  `dev.tukiapp.tuki_little_adventures.qa.integration`.
- Versión release candidata: `1.0.0` (`versionCode` 1).
- Versión QA: `1.0.0-qa` (`versionCode` 1).

Se recomienda conservar el identificador actual de producción: es válido, ya
está integrado con el namespace y la actividad Android y evita fragmentar datos
o identidad. Antes de crear la app o cargar el primer artefacto, el propietario
debe confirmar disponibilidad y decisión final. Un cambio posterior requeriría
otra aplicación y no heredaría datos ni actualizaciones de la identidad actual.

## Firma

- Release rechaza la clave debug y falla si no existe firma de carga válida.
- `android/key.properties` conserva únicamente ruta del JKS y alias.
- Las contraseñas se leen de `TUKI_UPLOAD_STORE_PASSWORD` y
  `TUKI_UPLOAD_KEY_PASSWORD`, suministradas por el almacén seguro del
  propietario; no se guardan en Git.
- No se generó una clave: faltan decisión de bóveda, contraseñas, dos destinos
  cifrados de respaldo y custodios.
- La compilación `flutter build appbundle --release` se probó y quedó bloqueada
  antes de producir un AAB nuevo por ausencia de esas credenciales.
- Existe en `build/` un AAB anterior del 14 de noviembre a las 20:15:33 -06:00,
  65.012.764 bytes, SHA-256
  `406569ED0D08AF2A6FC425D87F0C261B330990CD3A521B4FA79F160967703DB9`.
  `jarsigner` confirma `jar is unsigned`; es NO PUBLICABLE y no es el artefacto
  de este cierre.

## Recursos de publicación

- Los dos archivos fuente del tucán oficial conservan el mismo SHA-256:
  `C9FA00A9232DD8520AAD06F3362FB02ED9C83BF66DE50DE2CDA38ED173F76F1E`.
- Los mipmaps legacy existen en 48, 72, 96, 144 y 192 px.
- No existe adaptive icon. No se creó una composición nueva porque cambiar el
  encuadre o separar fondo/primer plano requiere aprobación de diseño y derechos.
- Se preparó una reducción RGB 512 × 512 del icono oficial, sin cambiar el
  diseño: `docs/play/icon/tuki-play-512.png`, SHA-256
  `508523594D296F9D30C7C7F3F153E9E3EB37926C57456E269F2584B5CD5094A4`.
  Su uso permanece bloqueado hasta documentar la licencia comercial.
- Las seis capturas fuente 1080 × 2400 siguen intactas. Las copias de
  `prepared-phone/` son 1080 × 2160, RGB, relación 2:1, sin recorte ni contenido
  generado.

## Compilación y manifiesto

- APK QA: `build/app/outputs/flutter-apk/app-debug.apk`.
- Tamaño: 177.970.887 bytes.
- SHA-256:
  `4F4EF97C9F286C3314124F07A83E5CD3074B3C581A7349F5D28DDD1FC18FA304`.
- Package QA: `dev.tukiapp.tuki_little_adventures.qa`.
- SDK: mínimo 24; target y compile 36.
- QA declara `INTERNET` y `ACCESS_NETWORK_STATE` por las herramientas Flutter.
- El manifiesto release fusionado contiene el package de producción, versión
  1.0.0+1 y solo el permiso interno de receptor dinámico; no contiene permisos
  de red, anuncios, compras, cámara, micrófono, ubicación o almacenamiento.
- AAB firmado: no generado; estado bloqueado por firma y custodia.

## Validación

- Formato: 61 archivos, cero cambios.
- `flutter analyze`: sin incidencias.
- Catálogo y 60 láminas: 73/73 pruebas aprobadas.
- Suite host: 201/201 pruebas aprobadas.
- Samsung SM-A325M, Android 13: recorrido físico aislado 3/3 aprobado.
- Base de dibujos QA antes y después:
  `d49d24cced6635634e8be9b4c08a9589cce05abc7b91604fd2cadd481a5d3b87`.
  No se desinstaló ni borró la app QA y la prueba usó el paquete de integración.

## Bloqueos del propietario

1. Confirmar package name y que `versionCode` 1 no se haya usado.
2. Definir bóveda, contraseñas, custodios y dos respaldos cifrados; después
   generar la clave de carga y probar recuperación.
3. Crear la aplicación e inscribirse en Play App Signing.
4. Aportar licencia comercial del tucán y evidencia para las 60 ilustraciones.
5. Aportar identidad legal, correo de privacidad y URL HTTPS.
6. Completar Data Safety, público objetivo/Families, contenido e IARC.
7. Aprobar diseño/encuadre si se exige un adaptive icon y capturar en inglés y
   nivel Detallado con la interfaz real.

