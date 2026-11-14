# Privacidad y seguridad infantil

Estado al 14 de noviembre de 2026. Este documento describe la compilación de
QA; no sustituye la política de privacidad pública ni la revisión legal previa
a distribuir la aplicación.

## Datos y conectividad

- TUKI funciona sin cuentas, anuncios, analítica, rastreo ni servicios en
  línea.
- No solicita nombre, correo, fecha de nacimiento ni ubicación. La edad es un
  rango opcional y se guarda solo en el dispositivo para ordenar sugerencias.
- Los dibujos, preferencias y derechos simulados se guardan localmente. La app
  no los transmite.
- La exportación ocurre solo cuando una persona adulta elige guardar o compartir
  un PNG mediante el diálogo del sistema.
- La compilación de depuración de Android incluye `INTERNET` para las herramientas
  de Flutter. La aplicación no contiene clientes ni destinos de red. La
  compilación de publicación debe volver a auditarse antes de distribuirse.

## Compras

La arquitectura admite derechos y restauración simulados para preparar una
etapa futura, siempre detrás del control de adultos. En esta versión no hay SDK
de tienda, productos, precios, cobros ni botones de compra. Activar compras
requiere una autorización explícita y una revisión nueva de privacidad, familias
y restauración.

## Lista previa a publicación

1. Confirmar los identificadores definitivos, firma y propietario de las fichas.
2. Revisar las políticas vigentes de Google Play Families y Apple Kids Category.
3. Publicar una política de privacidad con responsable y canal de contacto.
4. Verificar el manifiesto final y las declaraciones de privacidad de cada SDK.
5. Completar pruebas de accesibilidad, compra/restauración y control de adultos.
6. No publicar arte, audio ni iconos sin procedencia y licencia comercial
   documentadas en `docs/RECURSOS.md`.
