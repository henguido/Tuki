"""Genera la matriz de aprobación y el registro de cambios por ilustración.

    python tool/laminas/informe.py

Lee tool/laminas/validacion/*.json (conversor) y tool/laminas/aprobacion.json
(pruebas con el motor del editor) y escribe en docs/laminas/:
  MATRIZ_APROBACION.md, matriz_aprobacion.csv y REGISTRO_CAMBIOS.md
"""

import csv
import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
VALIDACION = RAIZ / 'tool/laminas/validacion'
DOCS = RAIZ / 'docs/laminas'
NIVEL = {'easy': 'Fácil', 'medium': 'Medio', 'detailed': 'Detallado',
         'advanced': 'Avanzado'}
GUIA = {'easy': (15, 30), 'medium': (30, 55), 'detailed': (55, 90),
        'advanced': (90, 140)}
# Láminas abiertas y pintadas en el Samsung SM-A325M durante esta entrega.
EN_DISPOSITIVO = {
    'E01': 'rendimiento + pintada a mano', 'E02': 'prueba de integración',
    'M06': 'rendimiento', 'D14': 'rendimiento', 'A08': 'pintada a mano',
    'A10': 'rendimiento + pintada a mano', 'A13': 'rendimiento',
}
# Observaciones de arte que no impiden el funcionamiento.
NOTAS = {
    'E06': 'Pico retocado para que se lea como quetzal; pendiente de aprobación artística.',
    'D02': 'Dibujo más sencillo de lo que corresponde a Detallado.',
    'D13': 'Incluye puerta de fantasía y animales secundarios (decisión de arte).',
    'A14': 'Incluye animales secundarios (decisión de arte).',
    'A15': 'Incluye animales secundarios (decisión de arte).',
}


def main():
    aprobacion = json.loads(
        (RAIZ / 'tool/laminas/aprobacion.json').read_text(encoding='utf-8'))
    filas, cambios = [], []
    por_tema = {}
    for art in sorted(aprobacion, key=lambda a: ('EMDA'.index(a[0]), a)):
        m = json.loads((VALIDACION / f'{art}.json').read_text(encoding='utf-8'))
        a = aprobacion[art]
        utiles = a['regiones'] - a['brillos_exentos']
        lo, hi = GUIA[m['nivel']]
        notas = []
        if art in NOTAS:
            notas.append(NOTAS[art])
        if utiles < lo:
            notas.append(f'{utiles} regiones: por debajo de la guía del nivel ({lo}–{hi}).')
        if utiles > hi:
            notas.append(f'{utiles} regiones: por encima de la guía del nivel ({lo}–{hi}).')
        por_tema.setdefault(art[1:], {})[art[0]] = utiles
        filas.append({
            'id': art, 'pagina': m['pagina'], 'nivel': NIVEL[m['nivel']],
            'orientacion': m['orientacion'],
            'zonas_originales': m['zonas_detectadas'],
            'regiones': a['regiones'], 'brillos_exentos': a['brillos_exentos'],
            'multiparte': m['regiones_multiparte'],
            'min_dp_360': a['diametro_min_dp_en_360dp'],
            'kb': a['kb'],
            **{'prueba_' + k: v for k, v in a['pruebas'].items()},
            'motor': 'aprobada' if a['aprobada'] else 'FALLA',
            'dispositivo': EN_DISPOSITIVO.get(art, 'pendiente'),
            'notas': ' '.join(notas),
        })
        cambios.append((art, m))
    for tema, n in por_tema.items():
        orden = [n[k] for k in 'EMDA']
        if orden != sorted(orden):
            for f in filas:
                if f['id'][1:] == tema and f['id'][0] == 'D' and n['D'] < n['M']:
                    f['notas'] = (f['notas'] + ' Menos regiones que la versión Medio del mismo tema.').strip()
                if f['id'][1:] == tema and f['id'][0] == 'M' and n['M'] < n['E']:
                    f['notas'] = (f['notas'] + ' Menos regiones que la versión Fácil del mismo tema.').strip()

    DOCS.mkdir(parents=True, exist_ok=True)
    with open(DOCS / 'matriz_aprobacion.csv', 'w', encoding='utf-8-sig',
              newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0]))
        w.writeheader()
        w.writerows(filas)

    ok = sum(1 for f in filas if f['motor'] == 'aprobada')
    lineas = [
        '# Matriz de aprobación de las 60 láminas', '',
        f'Generada por `tool/laminas/informe.py`. Motor del editor: **{ok} de {len(filas)}** aprobadas.',
        '',
        '- **Motor**: las ocho comprobaciones de `test/laminas_test.dart` con el motor real de Flutter (carga, regiones, relleno individual, sin fugas, deshacer, guardado, zoom y orientación, tacto del nivel).',
        '- **Dispositivo**: qué se hizo con esa lámina en el Samsung SM-A325M. «pendiente» = nadie la ha abierto en un dispositivo.',
        '- **Mín. dp**: diámetro de la región más estrecha en un teléfono de 360 dp de ancho, sin ampliar (los brillos de ojos están exentos).',
        '- **Partes**: regiones formadas por varias zonas que se rellenan juntas.',
        '',
        '| ID | Página | Nivel | Orient. | Zonas → regiones | Partes | Mín. dp | KB | Motor | Dispositivo | Observaciones |',
        '|---|---|---|---|---|---|---|---|---|---|---|',
    ]
    for f in filas:
        lineas.append(
            f"| {f['id']} | `{f['pagina']}` | {f['nivel']} | {f['orientacion'][:4]}. | "
            f"{f['zonas_originales']} → {f['regiones']} | {f['multiparte']} | "
            f"{f['min_dp_360']} | {f['kb']} | {f['motor']} | {f['dispositivo']} | {f['notas']} |")
    (DOCS / 'MATRIZ_APROBACION.md').write_text('\n'.join(lineas) + '\n',
                                                encoding='utf-8', newline='\n')

    lineas = [
        '# Registro de cambios respecto a cada original', '',
        'Los originales no se modifican: están en `ilustraciones/` y se identifican aquí por su SHA-256.',
        'Todas las láminas se normalizan a 1600 px de lado mayor y se vectorizan; debajo solo figura lo que cambia el dibujo o su comportamiento.',
        '',
    ]
    for art, m in cambios:
        lineas += [
            f"## {art} · `{m['pagina']}` (revisión {m['revision']})", '',
            f"- Original: `{m['original']}` → `{m['fuente']}` ({m['fuente_px'][0]} × {m['fuente_px'][1]} px), SHA-256 `{m['sha256_fuente'][:16]}…`",
            f"- Lienzo: {m['viewBox'][2]} × {m['viewBox'][3]} ({m['orientacion']}); trazo {m['grosor_trazo_px']} px; tinta que toca el marco: {m['tinta_en_borde'] * 100:.1f} %",
        ]
        if art == 'E06':
            lineas.append('- **Retoque de arte** (`tool/laminas/corregir_e06.py`): se sustituyó el pico grande y curvo por un pico corto y se cerró el perfil de la cara. Fuente retocada: `tool/laminas/fuentes_corregidas/E06.png`.')
        lineas += [f'- {c}' for c in m['cambios']] or ['- Sin cambios más allá de la vectorización.']
        lineas.append('')
    (DOCS / 'REGISTRO_CAMBIOS.md').write_text('\n'.join(lineas),
                                               encoding='utf-8', newline='\n')
    print(ok, 'de', len(filas))
    por_nivel = {}
    for f in filas:
        por_nivel.setdefault(f['nivel'], []).append(f['regiones'] - f['brillos_exentos'])
    for k, v in por_nivel.items():
        print(k, min(v), round(sum(v) / len(v)), max(v))
    print([f['id'] for f in filas if f['notas']])


if __name__ == '__main__':
    main()
