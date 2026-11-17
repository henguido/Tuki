# Inventario de recursos

Estado al 14 de noviembre de 2026. «Provisional» significa integrado y funcional, pendiente de sustituir o aprobar. La aprobación se registra por recurso en la última columna.

| Archivo | Qué es | Origen / autoría | Licencia | Estado | Para reemplazarlo | Aprobación |
|---|---|---|---|---|---|---|
| `assets/chapters/bosque-nuboso/cover.webp` | Portada del capítulo (1122 × 1402, sin texto) | Ilustración entregada por el cliente (`Descubrimientos en el bosque nuboso.png`), recodificada a WebP con `tool/assets/build_assets.py` | **Por confirmar con el cliente** (autoría y derechos de uso) | Provisional | Sustituir el archivo con el mismo nombre; conviene una versión más alta para que rana y quetzal no queden al borde | Pendiente |
| `assets/chapters/bosque-nuboso/pages/rana-en-la-hoja-v1.json` | Lámina fácil (12 regiones) | Dibujo vectorial original creado para esta entrega; fuente en `tool/build_templates.dart` | Obra original del proyecto | Provisional | Publicar `rana-en-la-hoja-v2.json` (`revision: 2`) y declarar la v1 en `previousTemplates` | Pendiente |
| `assets/chapters/bosque-nuboso/pages/quetzal-v1.json` | Lámina media (24 regiones) | Ídem | Obra original del proyecto | Provisional | Ídem, `quetzal-v2.json` | Pendiente |
| `assets/chapters/bosque-nuboso/chapter.json` (`description`, `funFact`) | Descripciones y curiosidades de las 3 láminas disponibles (es/en) | Redactadas para esta entrega | Obra original del proyecto | Provisional | Editar el manifiesto y subir `contentVersion` | Pendiente (revisión educativa) |
| `assets/chapters/bosque-nuboso/pages/sendero-v1.json` | Lámina detallada (48 regiones) | Ídem | Obra original del proyecto | Provisional | Ídem, `sendero-v2.json` | Pendiente |
| `assets/chapters/bosque-nuboso/audio/intro_es.mp3` | Narración en español (9,1 s) | Voz sintética «Microsoft Helena Desktop» (SAPI de Windows) generada con `tool/assets/speak.ps1` | **Verificar** los términos de las voces de Microsoft antes de distribuir; válida solo para QA interno | Provisional | Grabación con locutor; mismo nombre de archivo | Pendiente |
| `assets/chapters/bosque-nuboso/audio/intro_en.mp3` | Narración en inglés (9,8 s) | Voz sintética «Microsoft Zira Desktop», mismo script | Ídem | Provisional | Ídem | Pendiente |
| `assets/chapters/bosque-nuboso/audio/bosque.mp3` | Ambiente en bucle (32 s) | Sintetizado desde cero en `tool/assets/build_assets.py` (ruido filtrado, gotas, cantos) | Obra original del proyecto | Provisional | Grabación de campo o librería con licencia; mismo nombre | Pendiente |
| `assets/branding/tuki-icon-master.png`, `android/app/src/main/res/mipmap-*/ic_launcher.png`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`, `assets/brand/icon.png` | Icono de la app | Adaptación cuadrada declarada del JPG entregado por el cliente `Cute Toucan Clipart Bundle _ Tropical Bird Nursery Art (digital Download) - Etsy Israel.jpg` (SHA-256 documentado `82125094A8B7F090D2BF2CE74A8900AC04FF5456413E4A614C1561A7A4DDD66A`), generada con edición de imagen de OpenAI; las dos copias del maestro presentes coinciden en SHA-256 `C9FA00A9232DD8520AAD06F3362FB02ED9C83BF66DE50DE2CDA38ED173F76F1E` | **Por confirmar**: el JPG fuente, recibo, ZIP original y licencia no están en las ubicaciones auditadas; se necesita permiso expreso para modificación, icono comercial, Google Play y distribución compilada | Provisional, integrado por solicitud del cliente | Conservar sin modificar hasta que el propietario aporte la evidencia de adquisición y licencia | Pendiente de licencia |
| `assets/fonts/Fredoka-Variable.ttf` | Tipografía redondeada de la interfaz | The Fredoka Project Authors, vía Google Fonts | SIL Open Font License 1.1 (`assets/fonts/OFL.txt`) | **Definitivo** | — | No requiere |
| Iconos de la interfaz | Material Icons | Incluidos con Flutter | Apache 2.0 | **Definitivo** | — | No requiere |
| `docs/evidence/tuki-icon-original-proposal-2026-11-14.png` | Propuesta alternativa de icono, no integrada | Generada desde una instrucción original con la herramienta de imágenes de OpenAI; SHA-256 `FDCDCD2632516B4BC4208690873F0019D22109888B5BC33B703EF1FF7A3CABCF` | **Revisar términos aplicables y registrar aprobación antes de usar comercialmente** | Concepto separado; no reemplaza el icono actual | Solo integrar mediante una decisión y commit propios | Pendiente artística y legal |

## Recursos que faltan

| Recurso | Cantidad | Detalle |
|---|---|---|
| Derechos de las 60 ilustraciones | 60 | Las plantillas están integradas para QA, pero su distribución requiere confirmar la procedencia y los derechos comerciales de cada fuente registrada por SHA-256. |
| Curiosidades | 12 | Una por lámina pendiente, en español e inglés |
| Narración de curiosidades | 30 | 15 láminas × 2 idiomas. Hoy no existe ninguna; la app solo muestra «Escuchar» cuando el manifiesto la declara |
| Aprobación artística y prueba infantil | 60 | La validación automática no sustituye la revisión de arte ni las pruebas de tacto por edades. |

## Referencias que NO se integraron

| Archivo | Motivo |
|---|---|
| `Explora y colorea el bosque nuboso.png`, `Pantallas de coloreado del bosque nuboso.png`, `mockups_el_bosque_nuboso_v2.pdf` | Referencias de interfaz y navegación. Contienen textos y controles incrustados; no se usan como recurso. |

## Cómo se generan los recursos provisionales

```powershell
pwsh tool/assets/speak.ps1 -OutDir <carpeta-wav>
python tool/assets/build_assets.py --cover <ilustracion.png> --wav-dir <carpeta-wav>   # pillow, numpy, lameenc
dart run tool/build_templates.dart
```
