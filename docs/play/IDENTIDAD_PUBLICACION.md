# Identidad de publicación de TUKI

Estado verificado el 14 de noviembre de 2026. Este documento no autoriza crear
la aplicación, cargar un AAB ni publicar en Google Play.

## Campos confirmados

| Campo | Valor |
| --- | --- |
| Aplicación | TUKI — Little Adventures |
| Nombre público del desarrollador | ArtwebCR |
| Cuenta de Play Console | 6969012525407382944 |
| Administrador/contacto autorizado | henguido@gmail.com |
| Estado del usuario | Activo, sin caducidad |
| Tipo de cuenta | Personal |
| Application ID definitivo | `dev.tukiapp.tuki_little_adventures` |
| Tipo de producto propuesto | Aplicación gratuita |
| Publicidad | No |
| Compras integradas | No |
| URL de privacidad propuesta | https://tuki.artwebcr.com/privacy |

Play Console muestra acceso a la gestión de cuenta, usuarios y permisos, y la
opción de crear una aplicación. Por tanto, la cuenta puede registrar TUKI como
una aplicación independiente. No se creó ninguna aplicación durante esta
verificación.

## Separación respecto de FutBeat

- Solo se reutilizan la cuenta de desarrollador, su nombre público y el contacto
  autorizado.
- TUKI conserva su propio package name, ficha, política, declaraciones, artefactos
  y clave de carga.
- No se copian servicios, SDK, configuración comercial, credenciales ni claves
  privadas de FutBeat.
- La política de TUKI declara expresamente que solo cubre TUKI.

## Sitio HTTPS independiente

`https://artwebcr.com` responde por HTTPS y está servido por Vercel. El subdominio
`https://tuki.artwebcr.com` alcanza la plataforma Artweb, pero actualmente
`/privacy` responde 404: todavía no está asociado a un sitio o ruta de TUKI. El
archivo listo para desplegar está en
`docs/play/privacy-site/tuki.artwebcr.com/privacy/index.html`.

El repositorio privado `henguido/artweb-studio` implementa enrutamiento por host
para subdominios de `artwebcr.com`; los hosts no registrados se resuelven mediante
`/site-by-host`. La publicación debe crear/asociar un sitio exclusivo para
`tuki.artwebcr.com` o añadir una ruta estática específica, sin tocar FutBeat. No
se modificaron DNS, Vercel, Artweb Studio ni ningún servicio productivo.

## Pendientes del propietario

- Aprobar que `ArtwebCR` y `henguido@gmail.com` sean visibles públicamente.
- Confirmar los datos legales/territoriales que Play Console solicite; no se
  deducen del nombre público.
- Crear TUKI en Play Console y reservar el package name, solo con autorización.
- Elegir si la política se sirve como sitio Artweb o como ruta estática dedicada,
  y autorizar el cambio correspondiente en Artweb/Vercel.
- Aprobar el texto legal antes de hacerlo público.
