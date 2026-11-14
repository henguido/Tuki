# QA física Android — 14 de noviembre de 2026

Base: `codex/tuki-hardening` en `b788618`. Trabajo aislado en
`codex/tuki-physical-android`; no se modificó ni fusionó `master`.

## Dispositivo e instalación

- Samsung Galaxy A32, modelo `SM-A325M`, Android 13, 1080 × 2400.
- ADB autorizado: `RF8R32GQWGL`.
- APK inicial verificado: paquete `dev.tukiapp.tuki_little_adventures`,
  versión `0.1.0+1`, SHA-256
  `3DA2A3D50C2ADDDF4FF7BE99EE01B5E74F40ECD1FFE8C27A1526592E10675EF7`.
- La firma SHA-256 del certificado instalado y del APK coincidió:
  `6533B820F58EE837E6BBEDB29F09B26A8384760EE3DE13C5CB6185AD114C0362`.
- La actualización inicial se hizo con `adb install -r` y devolvió `Success`.

## Resultado de las 60 láminas

Se ejecutó el recorrido físico automatizado con Wi-Fi y datos desactivados y
se confirmó `Active default network: none`. Para cada lámina se comprobó:

- carga y render en el editor;
- relleno y guardado;
- trazo de pincel;
- deshacer el trazo;
- zoom de dos dedos y restablecimiento;
- salida, reapertura y recuperación del relleno guardado.

Resultado: **60/60 aprobadas**, 15 por cada nivel. Las 53 que no tenían prueba
física previa quedaron cubiertas. Duración del recorrido: 2:36. Carga media:
714.9 ms (524–2574 ms; E01 incluye arranque en frío). Relleno y confirmación de
guardado: 219.8 ms de media (124–968 ms).

- Matriz por lámina: `matriz-fisica-android-2026-11-14.csv`.
- Registro íntegro: `prueba-fisica-60-android.txt`.

Esta automatización prueba gestos reales enviados al dispositivo, pero no
sustituye una sesión con un niño ni una evaluación artística de las imágenes.

## Rendimiento en perfil

La prueba de perfil abrió y pintó una muestra de los cuatro niveles y las dos
plantillas más pesadas. Resultado:

| Lámina | Abrir | Raster medio / p90 | Relleno |
|---|---:|---:|---:|
| E01 | 399 ms | 10.5 / 13.2 ms | 34.1 ms |
| M06 | 507 ms | 13.5 / 14.7 ms | 34.9 ms |
| D14 | 458 ms | 13.4 / 14.8 ms | 36.9 ms |
| A10 | 603 ms | 32.9 / 33.4 ms | 47.1 ms |
| A13 | 637 ms | 31.1 / 31.7 ms | 51.9 ms |

E01, M06 y D14 caben en 16.7 ms p90. A10 y A13 quedan cerca de 30 fps durante
el pincel: **defecto de rendimiento abierto**. Se probó cachear la capa de
rellenos, pero una segunda medición no mejoró el raster y el cambio se retiró.
El arreglo siguiente requiere separar papel/rellenos, trazos y tinta en capas
de render independientes para que Flutter pueda reutilizar las capas fijas.

Registros: `rendimiento-perfil-android.txt` y
`rendimiento-perfil-android-optimizado.txt`.

## Incidente de conservación de datos

La primera ejecución usó el mismo `applicationId` que la app instalada. Al
terminar, el ejecutor de integración de Flutter retiró el paquete principal.
Esto borró `files/tuki.sqlite` (20,480 bytes, fecha 13 de noviembre) y las
preferencias. El APK se reinstaló correctamente, pero quedó limpio. Se intentó
restaurar solo TUKI desde Google Backup y desde `Local disk image`; ambos
transportes devolvieron `restoreFinished: -1000`. No apareció otra copia local,
por lo que **los dibujos que contenía esa base no se recuperaron**.

Corrección preventiva aplicada:

- debug y profile ahora usan `dev.tukiapp.tuki_little_adventures.qa`;
- el lanzador los muestra como `TUKI QA`;
- release conserva `dev.tukiapp.tuki_little_adventures` y `TUKI`;
- ambos paquetes se instalaron simultáneamente en el teléfono para verificar
  el aislamiento.
- El recorrido 60/60 se repitió sobre el paquete QA en 2:35. Al terminar,
  Flutter retiró QA y `pm list packages` confirmó que el paquete normal seguía
  instalado. Registro: `prueba-fisica-60-android-qa-aislado.txt`.

No se debe volver a ejecutar una prueba de integración contra el paquete de
release ni usar `pm clear`/desinstalar la app normal.

## Regresión

- Formato: 61 archivos sin cambios pendientes de formato.
- `flutter analyze`: limpio.
- `flutter test`: 199/199 aprobadas.
- Pruebas focalizadas tras la investigación de rendimiento: 88/88 aprobadas.
- APK QA final: `dev.tukiapp.tuki_little_adventures.qa`, `0.1.0-qa+1`,
  177,793,923 bytes, SHA-256
  `C23993C8923795127C66F1CD4D9CD940CF0BCBA2403EA443AC8FD7D5685EF065`.

