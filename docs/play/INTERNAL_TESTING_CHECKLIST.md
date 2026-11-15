# Checklist de Google Play Internal Testing

## Decisiones irreversibles antes del primer AAB

- [x] Confirmar que `dev.tukiapp.tuki_little_adventures` es el package name
  definitivo. El primer artefacto lo fija en Play Console.
- [x] Confirmar cuenta (`ArtwebCR`) y administrador autorizado
  (`henguido@gmail.com`).
- [x] Confirmar contacto público (`contact@artwebcr.com`).
- [ ] Confirmar los datos legales que solicite Play Console.
- [ ] Confirmar que `versionCode` 1 no fue utilizado por una versión previa.

## Cuenta y aplicación

- [x] Acceso activo a la cuenta de desarrollador verificado.
- [ ] Aplicación creada en Play Console sin publicar.
- [ ] Idioma predeterminado y tipo app/juego confirmados.
- [ ] Declaraciones de app gratuita y público objetivo confirmadas.
- [x] Acceso autorizado a Play Console disponible para el responsable.

## Firma y artefacto

- [ ] Crear clave de carga con contraseña elegida y custodiada por el
  propietario; no inventarla ni guardarla en Git.
- [ ] Usar una clave exclusiva de TUKI; no reutilizar ni exportar la clave
  privada de FutBeat.
- [ ] Guardar al menos dos respaldos cifrados y documentar custodios.
- [ ] Completar `android/key.properties` solo con ruta y alias; suministrar las
  contraseñas desde el almacén seguro mediante las variables `TUKI_UPLOAD_*`.
- [ ] Probar que uno de los respaldos cifrados permite recuperar la clave.
- [ ] Activar Play App Signing.
- [ ] Generar AAB firmado desde un commit limpio.
- [ ] Verificar certificado, SHA-256, package, versión, permisos y tamaño.
- [ ] Conservar mapa de símbolos si en el futuro se activa ofuscación.

## Contenido y cumplimiento

- [ ] Aportar licencia comercial verificable del tucán oficial; no cambiar su
  diseño sin una instrucción nueva del propietario.
- [ ] Adjuntar evidencia de derechos para las 60 ilustraciones y audios.
- [x] Publicar `docs/play/privacy-site/tuki.artwebcr.com/privacy/index.html` en
  `https://tuki.artwebcr.com/privacy`.
- [x] Enlazar la política desde el área adulta de TUKI, con control parental y
  apertura exclusiva de `https://tuki.artwebcr.com/privacy`.
- [ ] Completar Data Safety, público objetivo/Families e IARC.
- [ ] Confirmar que no hay anuncios, compras ni SDK de rastreo en el AAB final.
- [ ] Completar TalkBack manual sin conceder permisos inesperados.

## Pista interna

- [ ] Crear lista de hasta 100 personas de prueba autorizadas.
- [ ] Proporcionar correo o URL de retroalimentación.
- [ ] Crear release interna y cargar el AAB **solo con autorización explícita**.
- [ ] Revisar advertencias del pre-launch report y catálogo de dispositivos.
- [ ] Compartir el enlace de aceptación únicamente con testers autorizados.
- [ ] Registrar versión, SHA-256, certificado, testers y resultados.

Para cuentas personales creadas después del 13 de noviembre de 2023, la salida
a producción puede exigir una prueba cerrada con al menos 12 testers inscritos
continuamente durante 14 días. La pista interna por sí sola no satisface ese
requisito de producción.

