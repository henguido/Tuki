# Auditoría de geometría y fugas de color — 60 láminas

> **Auditoría histórica, sustituida parcialmente:** esta ejecución comprobó
> que hit testing y render coincidían para cada `region.id`, pero no verificó
> que sus componentes fueran zonas coloreables independientes. Esa limitación
> permitió el defecto multiparte. La corrección vigente y su prueba visual
> están en
> [INFORME_MOTOR_COLOREADO_CONECTADO.md](INFORME_MOTOR_COLOREADO_CONECTADO.md).

Fecha: 2026-11-15  
Rama: `codex/tuki-geometry-leak-audit`

## Alcance y criterio

Se validaron las 60 plantillas que utiliza el catálogo de producción con el
mismo parser, selección de región, controlador y renderizador de la app. La
prueba automatizada pinta cada región con un color de auditoría único y compara
el resultado con la región que seleccionaría un toque real.

Además de las sondas centrales existentes, se añadieron tres anillos de
muestreo (3, 7 y 13 unidades) alrededor de cada componente documentado. Los
puntos cubiertos por tinta visible y el último píxel del marco se excluyen: no
son interior coloreable y el suavizado del recorte puede mezclar transparencia.
En papel visible, el color renderizado debe coincidir con la región elegida por
el motor. El límite de aceptación es inferior a 0,1 % de discrepancias; una
concentración superior bloquea la lámina y CI.

Este control detecta incoherencias entre hit testing, trazados vectoriales y
rasterización cerca de divisores. No sustituye una revisión artística humana ni
afirma que cada agrupación multiparte represente una decisión semántica ideal.

## Resultado verificable

| Nivel | Láminas | Regiones | Regiones multiparte | Muestras cercanas | Discrepancias subpíxel | Máximo de partes en una región |
|---|---:|---:|---:|---:|---:|---:|
| Fácil | 15 | 231 | 53 | 12.833 | 0 | 13 |
| Medio | 15 | 483 | 139 | 28.206 | 0 | 17 |
| Detallado | 15 | 1.134 | 346 | 62.168 | 0 | 34 |
| Avanzado | 15 | 2.096 | 1.296 | 179.112 | 18 | 95 |
| **Total** | **60** | **3.944** | **1.834** | **282.319** | **18 (0,0064 %)** | **95** |

- 60/60 plantillas cargaron y aprobaron la suite.
- 0 fugas interiores reproducibles superaron el límite.
- 0 sondas centrales seleccionaron una región ajena.
- 0 discrepancias cercanas al contorno aparecieron en Fácil, Medio o Detallado.
- Las 18 diferencias de Avanzado son píxeles aislados de borde vectorial; no
  forman una propagación continua ni justifican alterar las ilustraciones.
- La cobertura sin región máxima sigue por debajo de 0,1 % y el solape visible
  máximo es `0,000002`.

La matriz individual está en
`docs/laminas/matriz_auditoria_geometria_60.csv`. Las vistas de agrupaciones que
ya genera el conversor permanecen en `docs/laminas/previas/` y corresponden a
las plantillas verificadas.

## Agrupaciones multiparte

Las agrupaciones son una decisión explícita del conversor para que los detalles
pequeños sean utilizables con el dedo y para limitar el coste de renderizado.
Por eso una región puede contener varias islas separadas por tinta. La prueba
confirma que todas reciben el mismo color previsto y que ese color no invade
otra región, pero no las presenta como equivalentes a una revisión artística.

El mayor grupo tiene 95 partes. Cambiar ahora los identificadores de esas zonas
podría invalidar rellenos guardados; por esa razón no se regeneró ninguna
plantilla sin un defecto interior reproducible. Cualquier futura separación
debe crear una revisión nueva de la plantilla y conservar la anterior en
`previousTemplates`, con migración o apertura compatible de dibujos existentes.

## Automatización

La verificación vive en `test/laminas_test.dart`, por lo que forma parte de
`flutter test` y del flujo Flutter CI existente. La evidencia JSON solo se
reescribe cuando se define `TUKI_WRITE_APPROVAL_EVIDENCE=1`; una ejecución
normal de CI no ensucia el repositorio.

## Límites pendientes

- La prueba es geométrica y raster; no equivale a 60 revisiones visuales humanas.
- El tacto real y el rendimiento por lámina requieren un dispositivo Android
  autorizado. No se modificaron instalaciones ni datos durante esta auditoría.
- No se cambiaron originales, plantillas, miniaturas, identificadores estables,
  dibujos guardados ni el tucán oficial.

## Validación técnica de cierre

- `dart format`: sin cambios pendientes.
- `flutter analyze`: sin hallazgos.
- `flutter test`: 206/206 pruebas aprobadas.
- Samsung SM-A325M (Android 13): el paquete QA se actualizó con `install -r`,
  conservó `firstInstallTime=2026-11-14 10:19:17`, abrió `MainActivity` y quedó
  como actividad visible. No se desinstaló ni se ejecutó limpieza de datos.
- APK QA: `build/app/outputs/flutter-apk/app-debug.apk`, paquete
  `dev.tukiapp.tuki_little_adventures.qa`, versión `1.0.0-qa` (`versionCode` 1),
  `minSdk` 24, `targetSdk` 36.
- SHA-256 del APK QA:
  `9E5A1B02FEC64BF5A2D15554503976A8D26E8DE288D10B394DC50C2CA0D3ACA1`.
- La firma APK v2 es válida y corresponde a `Android Debug`; el artefacto es
  exclusivamente QA y no es apto para Google Play.

La prueba física exhaustiva de 60/60 y las medidas profile de A10/A13 previas
siguen documentadas en `docs/evidence/`. Como esta rama no modifica código de
producción ni plantillas, no se repitió una prueba que escribiera 60 dibujos en
el dispositivo; la actualización y apertura actuales comprobaron instalación y
arranque preservando los datos existentes.

