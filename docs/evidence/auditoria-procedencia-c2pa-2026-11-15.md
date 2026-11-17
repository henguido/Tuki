# Auditoría de procedencia C2PA — 15 de noviembre de 2026

## Alcance

Se revisaron los 60 originales seleccionados, sus copias organizadas, hashes,
registros de conversión, plantillas Flutter, historial Git y conversaciones de
ChatGPT accesibles. No se regeneraron ni modificaron recursos artísticos.

## Evidencia recuperada

- 60/60 SHA-256 de originales coinciden con el inventario.
- 60/60 copias organizadas son coincidencias criptográficas exactas.
- 60/60 contienen `c2pa.actions.v2`, `ChatGPT`,
  `OpenAI Media Service API` y `trainedAlgorithmicMedia`.
- 60/60 contienen una fecha de creación C2PA individual del 13 de noviembre de
  2026 UTC, registrada por fila en el inventario.
- 60/60 enlazan a una plantilla existente y a un registro de validación.
- E06 conserva además el derivado retocado y el script que lo produjo.

La inspección fue local y no subió imágenes. Se comprobó la presencia y
coherencia de los campos, no la firma criptográfica completa del manifiesto
C2PA mediante un validador externo.

## Cambio real

| Categoría | Antes | Después |
|---|---:|---:|
| Acreditadas para publicación | 0 | 0 |
| OpenAI con documentación parcial | 33 | 60 |
| Sin procedencia demostrada | 27 | 0 |
| Revisión necesaria | 0 | 0 |

Se reconstruyó la procedencia técnica de 27 recursos. Los 60 todavía necesitan
una declaración del responsable de la cuenta sobre entradas/referencias y una
autorización a ArtwebCR/TUKI; por eso ninguno se declara publicable todavía.

ArtwebCR aportó posteriormente
`docs/play/DECLARACION_PRODUCCION_GRAFICA.md`, que documenta su dirección
creativa y responsabilidad sobre selección, estilo, edades, revisión,
preparación e integración de las 60 piezas. La propia declaración mantiene los
derechos y referencias en revisión, por lo que la clasificación jurídica no se
eleva todavía.

## Validación técnica

- `master` verificado en
  `2d9c8ded1a166fc125404281db6eeaca31c00a1e`.
- CI posterior a la integración del PR #9: aprobado, ejecución `43722306334`.
- Formato: 63 archivos, sin cambios pendientes.
- `flutter analyze`: sin incidencias.
- `flutter test`: 206/206 aprobadas.
- La nueva prueba `test/art_provenance_test.dart` valida siempre el inventario,
  registros, plantillas y la cadena especial de E06. Cuando los raster locales
  están disponibles también recalcula los 60 hashes e inspecciona C2PA. GitHub
  Actions omite explícitamente esos dos controles locales porque
  `ilustraciones/` no se versiona; no presenta esa omisión como aprobación.

## Tucán oficial

El diseño no se modificó. Dos copias del maestro derivado son idénticas. No se
localizaron el JPG de referencia, el ZIP de Etsy, recibo ni licencia. Para cerrar
el bloqueo se necesita el paquete/archivo adquirido, comprobante vinculado al
producto y texto de licencia vigente en la compra que permita uso comercial,
modificación, icono de aplicación y distribución en Google Play.

## Firma Android

La configuración continúa preparada para `tuki-upload`, contraseñas mediante
`TUKI_UPLOAD_STORE_PASSWORD` y `TUKI_UPLOAD_KEY_PASSWORD`, y keystore fuera de
Git. No hay variables configuradas ni `android/key.properties`. El entorno
dispone de `keytool` a través del JDK de Android Studio, pero no se pudo demostrar
un volumen BitLocker accesible ni se encontraron `gpg`, `age` o `7z` para crear
dos respaldos cifrados. No se generó ningún secreto.

Decisiones humanas pendientes: bóveda primaria, dos destinos de respaldo,
custodios y contraseñas. Solo después corresponde generar, restaurar desde una
copia y registrar la huella pública del certificado.
