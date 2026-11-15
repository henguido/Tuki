# Pulido TUKI 1.0 — Android — 14 de noviembre de 2026

## Aislamiento y preservación

- Base: `codex/tuki-quality-android` en `c19fe97`; trabajo en
  `codex/tuki-1.0-polish`. `master` no se modificó ni fusionó.
- Dispositivo: Samsung SM-A325M, Android 13, serie `RF8R32GQWGL`.
- La base QA instalada conservó el mismo SHA-256 antes y después de actualizar:
  `D49D24CCED6635634E8BE9B4C08A9589CCE05ABC7B91604FD2CADD481A5D3B87`.
- No se desinstaló la app, no se borraron datos/cachés y no se integró el icono
  de tucán sin licencia comercial demostrada.

## Rehacer

- Rehacer restaura rellenos, pincel y borrador, persiste cada resultado y se
  invalida al crear una acción nueva después de Deshacer.
- Botón bilingüe y accesible, deshabilitado cuando la pila está vacía.
- El historial sigue siendo de sesión y el formato persistido no cambió.
- Recorrido físico: 60/60 láminas aprobaron relleno, pincel, borrador,
  Deshacer, Rehacer, zoom, guardado y reapertura en 2 min 44 s.

## Rendimiento en perfil

Control medido en el mismo teléfono:

| Lámina | Apertura | Raster medio / p90 | Relleno |
|---|---:|---:|---:|
| E01 | 399 ms | 11,1 / 14,3 ms | 31,0 ms |
| M06 | 525 ms | 13,7 / 14,7 ms | 34,0 ms |
| D14 | 544 ms | 14,5 / 15,6 ms | 33,4 ms |
| A10 | 620 ms | 32,7 / 33,4 ms | 46,4 ms |
| A13 | 598 ms | 31,1 / 31,8 ms | 48,2 ms |

Se probó grabar fondo y rellenos inmutables en una imagen reutilizable. A10 dio
33,5 ms p90 y A13 31,9 ms: no mejoró el control (33,4/31,8 ms), por lo que se
retiró. A10/A13 siguen cerca de 30 fps durante el pincel; no se conserva código
especulativo.

## Accesibilidad y arte

- Automatización aprobada para texto ×2, teléfono pequeño, tableta horizontal,
  rotación, foco/etiquetas semánticas y objetivos táctiles mínimos de 48 dp.
- Configuración física preservada: escala de fuente 1,1, rotación automática
  activa y TalkBack inicialmente desactivado. La validación humana concluyente
  con TalkBack sigue pendiente; no se atribuye aprobación manual.
- E06 pasa geometría, relleno y dispositivo. La revisión visual confirma pico
  corto, cresta y cola larga, pero la lectura sigue siendo la de un ave infantil
  genérica. No se aplicó otro retoque automático sin dirección artística ni
  licencia comercial verificada.

## Privacidad y Android

- Sin anuncios, analítica, rastreo, cuentas, red de aplicación ni compras
  activas. Los dibujos y el rango de edad opcional permanecen en el dispositivo.
- APK QA: paquete `dev.tukiapp.tuki_little_adventures.qa`, versión `0.1.0-qa`,
  minSdk 24, compile/target SDK 36. Permisos: `INTERNET` de depuración,
  `ACCESS_NETWORK_STATE` y permiso interno de receptor; ninguno sensible.
- La pista interna admite hasta 100 testers y un AAB válido, pero no está lista
  para carga: falta clave de carga/Play App Signing, política HTTPS enlazada y
  declaraciones de público infantil/contenido. `release` aún firma con clave de
  depuración. No se publicó nada.

## Validación y artefacto

- Formato: limpio. Análisis: limpio. Regresión: 200/200.
- APK QA: `build/app/outputs/flutter-apk/app-debug.apk`, 204.567.721 bytes.
- SHA-256:
  `4ECF880107BD77A4A5BE1210D0DBA7B016543D4BFE7BB3746A2DB8C4A579BA8A`.
- Commit funcional: `f6084b8`. PR apilado en borrador: `#5` sobre el PR
  `#4`. CI `43660854732`: aprobado en 6 min 22 s (formato, análisis, catálogo
  y 60 plantillas, 200 pruebas, APK y artefacto).
- Pendientes: TalkBack/texto ampliado/rotación manuales concluyentes, sesión con
  niños, tableta e iOS físicos, dirección artística y licencia de E06, mejora
  demostrable de A10/A13, firma y configuración de Play.
