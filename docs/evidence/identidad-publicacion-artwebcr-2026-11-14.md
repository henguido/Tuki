# Evidencia de identidad de publicación ArtwebCR

Fecha: 14 de noviembre de 2026. Rama base del trabajo: PR #8. No se creó una
aplicación, no se cargó un AAB y no se modificó ningún servicio productivo.

## Google Play Console

- Cuenta de desarrollador visible: `ArtwebCR`.
- ID de cuenta: `6969012525407382944`.
- Tipo: cuenta personal.
- Usuario `henguido@gmail.com`: activo y sin caducidad.
- La cuenta expone gestión de usuarios/permisos y la acción para crear una
  aplicación nueva.
- FutBeat permanece como aplicación separada, paquete
  `com.futbeat.futbeat`, en prueba interna.
- TUKI se preparó como otra aplicación con
  `dev.tukiapp.tuki_little_adventures`. No se intentó reutilizar el registro de
  FutBeat.

No se leyeron, copiaron ni mostraron secretos. La inspección del repositorio
FutBeat confirmó que su clave real está fuera de Git; esa clave no se reutiliza
para TUKI.

## Privacidad y dominio

- `https://artwebcr.com` responde por HTTPS y redirige a `www` mediante Vercel.
- `https://tuki.artwebcr.com/privacy` llega a la plataforma, pero responde 404;
  el subdominio/ruta todavía no está publicado.
- `henguido/artweb-studio` ya contiene enrutamiento por host para subdominios de
  `artwebcr.com`. No se cambió ese repositorio ni su despliegue.
- Se preparó una política independiente en
  `docs/play/privacy-site/tuki.artwebcr.com/privacy/index.html`.

## Verificación técnica

- Formato: 61 archivos, 0 cambios.
- `flutter analyze`: sin incidencias.
- `flutter test`: 201/201 aprobadas.
- Samsung SM-A325M autorizado: 60/60 láminas aprobadas en el paquete aislado
  `dev.tukiapp.tuki_little_adventures.qa.integration`, con base de datos propia.
- TUKI QA instalada no fue reemplazada ni se tocaron sus dibujos o ajustes.
- APK QA regenerado: `build/app/outputs/flutter-apk/app-debug.apk`.
- Paquete: `dev.tukiapp.tuki_little_adventures.qa`.
- Versión: `1.0.0-qa` (`versionCode` 1), target API 36, min API 24.
- Firma: certificado Android Debug, válida para QA y no publicable.
- SHA-256 del APK: `4F4EF97C9F286C3314124F07A83E5CD3074B3C581A7349F5D28DDD1FC18FA304`.

## Bloqueos

1. Crear TUKI como aplicación nueva en Play Console requiere autorización
   explícita porque reserva estado externo y el package name.
2. Publicar/configurar `tuki.artwebcr.com` requiere elegir el mecanismo dentro
   de Artweb/Vercel y autorizar el cambio productivo.
3. Generar la clave de carga exclusiva de TUKI requiere almacén seguro,
   contraseñas, custodios y dos destinos de respaldo definidos por el propietario.
4. El AAB release no puede generarse como publicable hasta disponer de esa firma.
5. Siguen pendientes las evidencias de licencia del tucán y de las 60
   ilustraciones, además de las declaraciones de Play Console.
