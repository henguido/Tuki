# Google Play Data Safety — borrador verificable

Responder contra el AAB final firmado, no solo contra el código fuente. Las
respuestas siguientes describen TUKI 1.0 en el commit auditado.

## Respuestas propuestas

- ¿La app recopila o comparte datos obligatorios de usuario? **No**.
- ¿Los datos se cifran en tránsito? **No aplica**, porque TUKI no transmite
  datos a servidores del desarrollador.
- ¿Se puede solicitar eliminación de datos? Los datos son locales; se eliminan
  desde la propia app cuando exista esa acción, desde los ajustes de Android o
  al desinstalar. Confirmar la redacción de Console según las opciones vigentes.
- Cuentas: **no existen**.
- Ubicación, contactos, identificadores, actividad, información financiera,
  salud, mensajes, fotos del dispositivo y audio del usuario: **no recopilados**.
- Dibujos: contenido generado por el usuario almacenado localmente. **No se
  recopila ni comparte automáticamente**.
- Exportación: iniciada por una persona adulta y entregada al destino que esa
  persona selecciona en Android. Revisar si Console la considera transferencia
  iniciada por el usuario, excluida de “sharing”, en el formulario vigente.
- Publicidad, analítica y rastreo: **no incluidos**.

## Verificaciones del artefacto

- Release sin `INTERNET` ni `ACCESS_NETWORK_STATE`.
- Sin permisos sensibles.
- Sin SDK de anuncios, analítica, atribución, cuentas o compras.
- Persistencia SQLite y preferencias locales.

## Datos que debe aportar el propietario

- Nombre legal del desarrollador.
- Correo público y correo de privacidad.
- URL HTTPS pública de política de privacidad.
- País/jurisdicción y, si corresponde, dirección pública exigida por la cuenta.
- Confirmación del público objetivo y edades seleccionadas.
- Respuestas definitivas de contenido/IARC y acceso de revisores.

Aunque una pista interna puede estar exenta de mostrar públicamente Data Safety,
este borrador debe completarse antes de avanzar a pistas públicas o producción.

