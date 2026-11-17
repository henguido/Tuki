# Revisión visual técnica de las 60 láminas

Fecha: 2026-11-16  
Base consolidada: `master` en `8944e721d701d097e58ee65287a0fa9a7e79db00`

## Método

Se comparó individualmente cada ilustración original organizada con la vista
de su plantilla en la que cada región recibió un color artificial. Las 60
comparaciones se distribuyen en 12 hojas de contacto, cinco láminas por hoja,
en `docs/laminas/comparaciones/`.

La revisión comprobó visualmente:

- conservación de contornos exteriores;
- presencia de líneas interiores del original en el mapa de regiones;
- correspondencia entre divisiones dibujadas y cambios de región;
- regiones que atravesaran una línea visible;
- uniones entre partes semánticamente distintas de animales, plantas o paisaje;
- pérdidas evidentes de detalle durante la conversión;
- escenas Detalladas y Avanzadas a mayor densidad.

La matriz individual está en `docs/laminas/matriz_revision_visual_60.csv`. El
test `test/visual_comparison_generator_test.dart` comprueba que cada uno de los
60 pares exista y permite regenerar las hojas con
`TUKI_WRITE_VISUAL_COMPARISONS=1`.

## Resultado

| Nivel | Inspeccionadas | División visual coherente | Unión incorrecta comprobada | Corrección |
|---|---:|---:|---:|---:|
| Fácil | 15 | 15 | 0 | 0 |
| Medio | 15 | 15 | 0 | 0 |
| Detallado | 15 | 15 | 0 | 0 |
| Avanzado | 15 | 15 | 0 | 0 |
| **Total** | **60** | **60** | **0** | **0** |

No se comprobó ninguna región que invadiera visualmente otra zona ni una línea
interior desaparecida que exigiera cambiar la plantilla. Las agrupaciones
multiparte más grandes de las escenas avanzadas corresponden principalmente a
texturas pequeñas y repetidas del bosque. Su representación coloreada no mostró
una propagación continua a través de figuras principales.

Por tanto, no se regeneraron plantillas ni se cambiaron identificadores. Esta
decisión preserva dibujos existentes y evita crear revisiones o migraciones sin
un defecto concreto.

## Alcance y límite de aprobación

Esta es una revisión visual técnica, no una aprobación artística o legal. Las
hojas permiten al propietario comprobar el resultado completo y emitir la
aprobación creativa final. Una coincidencia geométrica o una revisión técnica no
sustituyen esa decisión humana.

Las imágenes de comparación usan colores aleatorios únicamente para distinguir
regiones. No representan una propuesta de paleta, el aspecto final de una obra
ni cambios sobre los originales.

## Preservación

- No se modificaron las 60 ilustraciones originales.
- No se modificaron plantillas, miniaturas ni el tucán oficial.
- No se cambiaron IDs de páginas o regiones.
- No se tocaron dibujos ni preferencias instaladas.
- No se publicó ni cargó ningún artefacto en Google Play.

## Validación posterior

- `flutter analyze`: sin observaciones.
- `flutter test`: 207/207 pruebas aprobadas.
- Catálogo: 60/60 originales y 60/60 mapas de regiones presentes.
- Comparaciones: 12/12 hojas de contacto regenerables y verificadas.
- Geometrías: sin cambios; no se requirió migración de dibujos guardados.
- Android QA: APK compilado e instalado con actualización conservadora (`-r`)
  sobre el dispositivo autorizado SM-A325M; la aplicación inició y mantuvo su
  proceso activo. No se desinstaló la aplicación ni se borraron sus datos.
- SHA-256 del APK QA:
  `9E5A1B02FEC64BF5A2D15554503976A8D26E8DE288D10B394DC50C2CA0D3ACA1`.

