# Privacidad y seguridad infantil

Estado al 15 de noviembre de 2026. Este documento describe la compilación de
QA; no sustituye la política de privacidad pública ni la revisión legal previa
a distribuir la aplicación.

## Datos y conectividad

- TUKI funciona sin cuentas, anuncios, analítica, rastreo ni servicios en
  línea.
- No solicita nombre, correo, fecha de nacimiento ni ubicación. La edad es un
  rango opcional y se guarda solo en el dispositivo para ordenar sugerencias.
- Los dibujos, preferencias y derechos simulados se guardan localmente. La app
  no los transmite.
- La exportación está protegida por el control de adultos y ocurre solo cuando
  una persona adulta elige guardar o compartir un PNG mediante el diálogo del
  sistema. El destino elegido puede aplicar sus propias prácticas de datos.
- La compilación de depuración de Android incluye `INTERNET` para las herramientas
  de Flutter. La aplicación no contiene clientes de red. Desde el área adulta
  puede abrir en el navegador del sistema únicamente
  `https://tuki.artwebcr.com/privacy`; Android valida esquema y host antes de
  entregar el enlace. La variante release elimina `INTERNET` y
  `ACCESS_NETWORK_STATE`.

## Compras

La arquitectura admite derechos y restauración simulados para preparar una
etapa futura, siempre detrás del control de adultos. En esta versión no hay SDK
de tienda, productos, precios, cobros ni botones de compra. Activar compras
requiere una autorización explícita y una revisión nueva de privacidad, familias
y restauración.

## Lista previa a publicación

1. Declarar con precisión el público infantil, contenido, anuncios, clasificación
   IARC y seguridad de datos en Play Console. Aunque la pista interna está
   exenta de mostrar la sección pública de seguridad de datos, esto no elimina
   la obligación de revisar Families antes de producción.
2. Mantener disponible la política propia publicada en
   `https://tuki.artwebcr.com/privacy`, enlazada en la ficha y desde el área
   adulta de la app. El acceso interno está implementado detrás del control de
   adultos y limitado a ese destino HTTPS.
3. Confirmar identificador definitivo, propietario, clave de carga y Play App
   Signing antes del primer AAB. La configuración `release` rechaza la clave de
   depuración y exige credenciales externas a Git; un artefacto de validación
   explícitamente no firmado no es publicable.
4. Mantener `targetSdkVersion` 36 o superior: es el mínimo para apps nuevas y
   actualizaciones en Google Play desde el 31 de agosto de 2026. La APK QA
   auditada ya compila y apunta a API 36.
5. Verificar el manifiesto final y las declaraciones de privacidad de cada SDK.
   La APK QA solicita `INTERNET` y `ACCESS_NETWORK_STATE` para herramientas de
   depuración; la variante release los elimina. No hay permisos sensibles.
6. Completar pruebas humanas de TalkBack, texto ampliado, rotación y sesión con
   niños antes de producción. La automatización no sustituye esa evaluación.
7. No publicar arte, audio ni iconos sin procedencia y licencia comercial
   documentadas en `docs/RECURSOS.md`.
