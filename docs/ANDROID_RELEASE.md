# Preparación de Android release

Estado al 14 de noviembre de 2026. No autoriza publicación.

## Identidad y variantes

- Nombre visible release: `TUKI`.
- Application ID técnico y recomendado: `dev.tukiapp.tuki_little_adventures`.
  Es válido, ya identifica la variante probada y preserva compatibilidad. El
  propietario debe confirmar que está disponible y que desea conservarlo antes
  de crear la app o cargar el primer artefacto en Play Console.
- Versión candidata: `1.0.0` (`versionCode` 1).
- QA: sufijo `.qa`, nombre `TUKI QA` y versión `1.0.0-qa`.
- Integración: sufijo `.qa.integration`; no comparte los datos de QA.
- `minSdk` y `targetSdk` provienen del SDK Flutter fijado por el proyecto; deben
  comprobarse en el manifiesto final. Para noviembre de 2026 se exige target
  API 36 para apps nuevas y actualizaciones en Google Play.

## Firma

La variante release no acepta la clave de depuración. Para crear un artefacto
publicable:

1. Crear y custodiar una clave de carga fuera del repositorio.
2. Guardar el archivo JKS fuera del repositorio, idealmente en una bóveda
   cifrada administrada por el propietario.
3. Copiar `android/key.properties.example` a `android/key.properties` y dejar
   allí solo la ruta del JKS y el alias. El archivo está ignorado por Git.
4. Entregar las contraseñas al proceso exclusivamente mediante
   `TUKI_UPLOAD_STORE_PASSWORD` y `TUKI_UPLOAD_KEY_PASSWORD`, obtenidas de un
   almacén seguro. No escribirlas en archivos, scripts, historial o CI.
5. Guardar al menos dos respaldos cifrados del JKS en ubicaciones separadas y
   registrar custodios, fecha, alias y huellas del certificado. Probar una
   restauración antes del primer AAB.
6. Inscribirse en Play App Signing. Google debe custodiar la clave de firma de
   la app; el JKS local será únicamente la clave de carga reemplazable.
7. Verificar certificado y firma del AAB/APK exactos antes de subirlos.

La clave no se genera automáticamente: requiere que el propietario elija el
almacén, las contraseñas, los dos destinos de respaldo y los custodios. Si se
pierde después de activar Play App Signing, el propietario puede solicitar el
restablecimiento de la clave de carga; los respaldos siguen siendo obligatorios.

Sin credenciales, las tareas release fallan. La propiedad
`-PtukiAllowUnsignedRelease=true` existe únicamente para inspección técnica: su
resultado debe etiquetarse como **NO FIRMADO / NO PUBLICABLE**.

## Manifiesto y privacidad

Release elimina `INTERNET` y `ACCESS_NETWORK_STATE`; QA puede conservarlos por
las herramientas Flutter. No se declaran permisos sensibles. TUKI no integra
anuncios, analítica, rastreo ni compras. La exportación local, protegida por el
control de adultos, entrega el PNG solo al destino que el adulto elige.

## Bloqueos de publicación

- Clave de carga y Play App Signing no configurados.
- Identidad legal, correo de privacidad y URL HTTPS todavía no aportados.
- Disponibilidad y confirmación final del Application ID pendientes del
  responsable antes de crear la aplicación en Play Console.
- Licencia comercial del icono de tucán y derechos de las ilustraciones aún no
  documentados.
- Declaraciones Play Console (público, Families, Data Safety, contenido e IARC)
  requieren completar y revisar contra el AAB final.
