# Cierre integral para Internal Testing — 15 de noviembre de 2026

Este informe registra comprobaciones técnicas; no autoriza una carga ni una
publicación en Google Play.

## Línea base y cambio preparado

- Base verificada: `master` en
  `367508d6ec567542f027620dde64261327cc7a43`.
- Rama de trabajo: `codex/tuki-internal-finalization`.
- La política pública se enlazó desde el área adulta. El código nativo acepta
  únicamente HTTPS con host `tuki.artwebcr.com` y entrega la apertura al
  navegador del sistema.
- No se añadieron anuncios, compras, cuentas, analítica ni rastreo.
- No se modificaron el tucán, las 60 ilustraciones, dibujos instalados,
  respaldos, reservas de Git ni worktrees.

## Validación local

- Formato: 62 archivos comprobados, 0 cambios requeridos.
- `flutter analyze`: sin incidencias.
- `flutter test`: 202/202 aprobadas.
- Las pruebas automatizadas siguen validando 60/60 plantillas y miniaturas.
- APK QA compilado de forma reproducible con las dependencias Android ya
  almacenadas localmente. El acceso remoto de Gradle presentó un error de
  confianza TLS; no fue un fallo de código y la compilación offline terminó
  correctamente.

### APK QA

- Archivo: `build/app/outputs/flutter-apk/app-debug.apk`.
- SHA-256:
  `25A6C9EA8A8AD7F00F671755B84819E93E547B0C875ED84AD7D7AE38FA931A73`.
- Package: `dev.tukiapp.tuki_little_adventures.qa`.
- Versión: `1.0.0-qa` (`versionCode` 1).
- SDK mínimo 24; objetivo 36.
- Firma verificada: certificado Android Debug, válido exclusivamente para QA;
  no es un artefacto de publicación.

## Firma y AAB

La configuración release continúa fallando de forma cerrada si no existen las
credenciales externas `TUKI_UPLOAD_*`. No se generó `tuki-upload`: faltan la
bóveda elegida por el propietario, dos destinos cifrados independientes,
custodios, contraseñas y una prueba de recuperación. No se generó un AAB
publicable ni se reutilizó una clave de FutBeat.

## Procedencia y recursos

- Matriz de 60/60 conservada en `docs/play/inventario-licencias-60.csv` y
  ampliada en `docs/play/PROCEDENCIA_60.md`.
- 33 recursos tienen indicios documentales de generación con OpenAI; M02 además
  conserva su especificación de generación para TUKI. Falta vincular la cuenta,
  entradas y evidencia aplicable para cerrar la autorización.
- 27 recursos fueron entregados sin proveedor o licencia demostrados. No se
  declaran ilícitos ni autorizados: permanecen pendientes de evidencia.
- El tucán oficial se conservó sin alteración. No se encontró factura, paquete
  original ni licencia efectiva que pruebe adquisición y uso como icono.

## Servicios externos y bloqueos

- `https://tuki.artwebcr.com/privacy` respondió públicamente por HTTPS con 200 y
  coincide con la copia versionada.
- La regresión física posterior se intentó con el paquete aislado
  `.qa.integration`, pero no llegó a instalar ni ejecutar porque Gradle no pudo
  validar la cadena TLS de Maven. No se tocaron aplicaciones ni datos del
  dispositivo. Se conserva como evidencia vigente la prueba física anterior de
  60/60 láminas; el cambio actual queda cubierto por pruebas automatizadas y la
  compilación Android, no por una nueva ejecución física.
- El DNS de `contact@artwebcr.com` publica MX, SPF, DKIM y DMARC. La sesión SMTP
  terminó con 421 antes de validar destinatario; sin acceso al buzón no fue
  posible demostrar recepción ni respuesta.
- El acceso a la cuenta Play Console fue comprobado, pero TUKI no se creó, no se
  configuró Play App Signing y no se cargó ningún AAB porque esas operaciones no
  están autorizadas en esta misión.

## Decisión

Código y APK QA: **GO técnico para revisión**. Internal Testing: **NO-GO** hasta
cerrar derechos de recursos, generar y recuperar de forma segura la clave de
carga exclusiva, producir y verificar el AAB firmado, completar las
declaraciones de Console y recibir autorización expresa para crear/cargar la
versión.
