# Matriz de procedencia de las 60 ilustraciones

Actualizada el 15 de noviembre de 2026. El detalle fila por fila está en
`inventario-licencias-60.csv` y su integridad se comprueba automáticamente en
`test/art_provenance_test.dart`.

## Resultado recuperado

Los **60 originales**, incluidos los 27 que antes carecían de proveedor
demostrado, conservan una credencial C2PA incrustada con estos campos:

- acción `c2pa.created` y fecha UTC individual;
- agente `ChatGPT`;
- generador `OpenAI Media Service API`;
- tipo `trainedAlgorithmicMedia`;
- cadena de identificación de `OpenAI OpCo, LLC`.

Esto constituye evidencia técnica de generación o exportación mediante una
herramienta de OpenAI. OpenAI explica que las Content Credentials sirven como
señales de procedencia, pero no prueban propiedad legal, exactitud, ausencia de
ediciones ni el contexto correcto. La auditoría local inspeccionó los campos
incrustados; no realizó una verificación criptográfica externa ni subió los
archivos a un servicio de terceros.

## Clasificación actual

| Clasificación | Cantidad | Motivo |
|---|---:|---|
| Acreditada para publicación | 0 | No existe declaración sobre cuenta y derechos de entradas/referencias. |
| Documentada, pendiente de autorización | 60 | Original, hash, fecha y procedencia OpenAI documentados mediante C2PA. |
| Sin procedencia demostrada | 0 | Las 27 anteriores ahora tienen señal C2PA verificable localmente. |
| Revisión necesaria | 0 | E06 es un derivado conocido y su cadena está documentada, no una inconsistencia. |

El cambio real es **27 recursos trasladados** de “sin procedencia demostrada” a
“documentada, pendiente de autorización”. Ninguno pasa todavía a “acreditada”.

## Trazabilidad técnica 60/60

- El SHA-256 recalculado del original coincide con el inventario en 60/60.
- La copia bajo `ilustraciones/organizadas` es byte a byte idéntica al original
  inventariado en 60/60.
- Cada ID tiene registro en `tool/laminas/validacion` y plantilla existente en
  `assets/chapters/bosque-nuboso/pages`.
- 59 plantillas parten directamente del raster inventariado.
- E06 parte del original OpenAI `Quetzal sonriente en la rama-5.webp` y de un
  retoque documentado en `tool/laminas/corregir_e06.py`. El derivado conservado
  `tool/laminas/fuentes_corregidas/E06.png` tiene SHA-256
  `64ca321cd4b9073d1de9dc85016adffffd9bf60596cb87949e2ae0cb47fd6952`.
- Los cambios geométricos de cada plantilla se registran en
  `docs/laminas/REGISTRO_CAMBIOS.md` y en el JSON de validación correspondiente.

## Historial accesible

Se revisaron las conversaciones accesibles “Crear imágenes”, “Crear app
infantil pintar” y “Modelo de monetización”. La primera documenta una propuesta
visual y el pedido de crear rana, quetzal y sendero, pero no contiene una tabla
que vincule las 60 descargas con prompts individuales. M02 sí conserva una
especificación resumida en `ilustraciones/INVENTARIO_TUKI.md`. No se inventaron
prompts faltantes ni se atribuyeron referencias externas.

## Derechos pendientes

ArtwebCR aportó la declaración conservada en
`docs/play/DECLARACION_PRODUCCION_GRAFICA.md`. Esta acredita dirección creativa,
selección temática, revisión, preparación técnica, integración y destino de la
colección completa. También declara expresamente que la documentación de
derechos y referencias sigue en revisión; por ello fortalece la cadena de
producción, pero no convierte por sí sola los recursos en “acreditados para
publicación”.

Los términos de OpenAI vigentes desde el 1 de enero de 2026 establecen que,
entre OpenAI y la persona usuaria y en la medida permitida por la ley, esta
conserva los derechos sobre la entrada y posee la salida. También exigen contar
con los derechos, licencias y permisos necesarios sobre las entradas y advierten
que las salidas pueden no ser únicas.

Para cerrar las 60 filas falta una declaración del propietario que:

1. identifique la cuenta o el responsable que solicitó las generaciones;
2. confirme que no se usaron imágenes de referencia de terceros, o aporte la
   licencia de cada referencia utilizada;
3. autorice a ArtwebCR/TUKI a incorporar, transformar y distribuir los
   resultados en la aplicación y su ficha de Google Play.

## Tucán oficial

El tucán de identidad visual no se confunde con las cuatro láminas de tema
tucán. Se preservan dos copias idénticas del maestro derivado:

- `assets/branding/tuki-icon-master.png`;
- `assets/brand/icon.png`;
- SHA-256 compartido:
  `c9fa00a9232dd8520aad06f3362fb02ed9c83bf66de50de2cda38ed173f76f1e`.

La documentación menciona como referencia entregada
`Cute Toucan Clipart Bundle _ Tropical Bird Nursery Art (digital Download) -
Etsy Israel.jpg`, SHA-256
`82125094a8b7f090d2bf2ce74a8900ac04ff5456413e4a614c1561a7a4ddd66a`,
pero ese JPG, el ZIP adquirido, el recibo y el texto de licencia no están en el
repositorio ni en las carpetas auditadas. Sigue bloqueado hasta aportar esos
documentos y demostrar permiso para uso comercial, modificación, icono de app,
Google Play y distribución del derivado compilado.
