# Preparación de Google Play Internal Testing

Estado al 14 de noviembre de 2026. Esta fase no cambió código, iconos ni
recursos de ejecución y no publicó ni cargó artefactos.

## Base verificada

- PR #4, #5 y #6 abiertos en borrador, sin conflictos y con CI aprobado.
- Cadena preservada: #4 → #5 → #6 → esta rama.
- Base: `6bd581a`, PR #6.
- Los resultados físicos y automatizados de PR #6 continúan vigentes porque
  esta fase solo añade documentación e inventario de publicación.

## Entregables

- Ficha de tienda en español e inglés, limitada a funciones comprobadas.
- Borrador de Data Safety y campos pendientes del propietario.
- Checklist de Internal Testing, firma, Play App Signing y decisiones
  irreversibles.
- Inventario de 60/60 ilustraciones con fuente, SHA-256, procedencia conocida y
  estado jurídico.
- Seis capturas reales preservadas como fuentes de publicación.

## Identidad

El propietario confirmó que el tucán entregado es el diseño oficial y no debe
cambiarse. No se modificaron los mipmaps, el maestro ni los iconos iOS. La
propuesta alternativa anterior no está integrada y no se usará para reemplazar
el diseño. El icono oficial continúa bloqueado para publicación mientras no se
adjunte la licencia completa que autorice su uso comercial y derivado.

## Resultado de licencias

- 60/60 fuentes tienen trazabilidad técnica y SHA-256.
- 33 se identifican como generación asistida por OpenAI; requieren vincular
  cuenta, términos, prompt/registro y derechos sobre cualquier entrada.
- 27 fueron entregadas al proyecto sin autor/proveedor/licencia documentados.
- 60/60: NO-GO jurídico para publicación hasta adjuntar evidencia suficiente.

## Recursos visuales

Las seis capturas son reales y no representan funciones ficticias. Sus fuentes
1080 × 2400 superan la relación máxima 2:1 publicada por Google Play; se
conservan sin recorte engañoso y quedan pendientes de recaptura o preparación
visual aprobada. El icono Play y el gráfico promocional están bloqueados por la
licencia del diseño oficial.

## Internal Testing

Google Play permite una prueba interna con hasta 100 testers y puede iniciarse
antes de terminar toda la ficha. No se accedió a Play Console ni se creó una
release: faltan autorización expresa para cargarla, cuenta verificada, package
name confirmado, clave de carga y AAB firmado. Para ciertas cuentas personales
nuevas, la futura salida a producción requiere además prueba cerrada con 12
testers durante 14 días; la pista interna no sustituye ese requisito.

Referencias oficiales: [recursos de ficha](https://support.google.com/googleplay/android-developer/answer/9866151),
[pruebas internas](https://support.google.com/googleplay/android-developer/answer/9845334),
[requisito de pruebas para cuentas personales](https://support.google.com/googleplay/android-developer/answer/14151465),
[Families](https://support.google.com/googleplay/android-developer/answer/9893335)
y [User Data](https://support.google.com/googleplay/android-developer/answer/10144311).

## Decisión

- **GO** para revisar e integrar esta documentación después de #6.
- **NO-GO** para cargar un AAB o iniciar la pista hasta confirmar package name,
  firma, cuenta y autorización.
- **NO-GO** para publicación mientras falten licencias, política HTTPS,
  identidad/contacto, declaraciones de Console y pruebas humanas pendientes.
