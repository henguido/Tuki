# Preparación de Android release

Estado al 14 de noviembre de 2026. No autoriza publicación.

## Identidad y variantes

- Nombre visible release: `TUKI`.
- Application ID propuesto: `dev.tukiapp.tuki_little_adventures`. El responsable
  de Play debe confirmarlo antes del primer artefacto, porque después queda fijo.
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
2. Copiar `android/key.properties.example` a `android/key.properties`.
3. Completar la ruta y secretos localmente; ambos archivos y los almacenes de
   claves están ignorados por Git.
4. Inscribirse en Play App Signing y conservar copias seguras de recuperación.
5. Verificar certificado y firma del AAB/APK exactos antes de subirlos.

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
- Application ID definitivo pendiente de confirmación del responsable.
- Licencia comercial del icono de tucán y derechos de las ilustraciones aún no
  documentados.
- Declaraciones Play Console (público, Families, Data Safety, contenido e IARC)
  requieren completar y revisar contra el AAB final.
