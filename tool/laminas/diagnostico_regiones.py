"""Inspección visual reproducible de las regiones coloreables de TUKI.

Ejemplos:

    python tool/laminas/diagnostico_regiones.py A10 --touch 359 169
    python tool/laminas/diagnostico_regiones.py A10 --region r002
    python tool/laminas/diagnostico_regiones.py --all

La herramienta usa exactamente la geometría JSON que carga Flutter. Produce
una imagen con la zona seleccionada, un mapa de IDs y un JSON con el toque,
el ID elegido, componentes conectados y cantidad de píxeles visibles afectados.
No modifica plantillas ni ilustraciones.
"""

import argparse
import json
import re
from pathlib import Path

import cv2
import numpy as np


ROOT = Path(__file__).resolve().parents[2]
VALIDATION = ROOT / 'tool/laminas/validacion'
DEFAULT_OUTPUT = ROOT / 'docs/laminas/diagnostico_regiones'
TOKENS = re.compile(r'[MmLlZz]|-?(?:\d+(?:\.\d*)?|\.\d+)')


def _subpaths(path_data):
    """Lee los M/l/Z compactos escritos por convertir.py."""
    tokens = TOKENS.findall(path_data)
    paths, points = [], []
    current = np.array([0.0, 0.0])
    command = None
    i = 0
    while i < len(tokens):
        token = tokens[i]
        if token.isalpha():
            command = token
            i += 1
            if command in 'Zz':
                if len(points) >= 3:
                    paths.append(np.rint(points).astype(np.int32))
                points = []
                continue
        if command in ('M', 'm'):
            if i + 1 >= len(tokens):
                raise ValueError('M incompleto')
            point = np.array([float(tokens[i]), float(tokens[i + 1])])
            current = point if command == 'M' else current + point
            points = [current.copy()]
            command = 'L' if command == 'M' else 'l'
            i += 2
        elif command in ('L', 'l'):
            if i + 1 >= len(tokens):
                raise ValueError('L incompleto')
            point = np.array([float(tokens[i]), float(tokens[i + 1])])
            current = point if command == 'L' else current + point
            points.append(current.copy())
            i += 2
        else:
            raise ValueError(f'Comando no soportado en plantilla generada: {command}')
    return paths


def _signed_area(contour):
    x, y = contour[:, 0], contour[:, 1]
    return float(np.sum(x * np.roll(y, -1) - np.roll(x, -1) * y))


def _mask(path_data, width, height):
    contours = _subpaths(path_data)
    mask = np.zeros((height, width), np.uint8)
    exterior = [c for c in contours if _signed_area(c) > 0]
    holes = [c for c in contours if _signed_area(c) < 0]
    if exterior:
        cv2.fillPoly(mask, exterior, 1)
    if holes:
        cv2.fillPoly(mask, holes, 0)
    return mask


def _load(art_id):
    validation = json.loads(
        (VALIDATION / f'{art_id}.json').read_text(encoding='utf-8'))
    template = json.loads(
        (ROOT / validation['plantilla']).read_text(encoding='utf-8'))
    return validation, template


def _encode(path, image, quality=90):
    path.parent.mkdir(parents=True, exist_ok=True)
    extension = path.suffix.lower()
    params = ([cv2.IMWRITE_JPEG_QUALITY, quality]
              if extension in ('.jpg', '.jpeg')
              else [cv2.IMWRITE_PNG_COMPRESSION, 9])
    cv2.imencode(extension, image, params)[1].tofile(str(path))


def diagnose(art_id, output, touch=None, region_id=None):
    validation, template = _load(art_id)
    _, _, width, height = template['viewBox']
    if touch is not None:
        x, y = touch
        if not (0 <= x < width and 0 <= y < height):
            raise ValueError(f'Toque fuera del lienzo {width}x{height}')
    regions = template['regions']
    ids = [region['id'] for region in regions]
    if region_id is not None and region_id not in ids:
        raise ValueError(f'Región inexistente: {region_id}')

    # Mapa completo con un color determinista por ID.
    rng = np.random.default_rng(7)
    palette = rng.integers(80, 245, size=(len(ids), 3), dtype=np.uint8)
    overview = np.full((height, width, 3), 255, np.uint8)
    selected = region_id
    selected_mask = None
    first_mask = None
    for i, region in enumerate(regions):
        mask = _mask(region['path'], width, height)
        if i == 0:
            first_mask = mask.copy()
        overview[mask == 1] = palette[i]
        if region['id'] == selected or (touch is not None and mask[y, x]):
            # El último acierto reproduce el orden superior del motor Flutter.
            selected = region['id']
            selected_mask = mask.copy()
    if selected is None:
        selected = ids[0]
        selected_mask = first_mask
    assert selected_mask is not None

    ink = np.zeros((height, width), np.uint8)
    for shape in template.get('inks', []):
        ink |= _mask(shape['path'], width, height)
    overview[ink == 1] = (22, 56, 58)

    visible = selected_mask & (ink == 0)
    components, _, stats, _ = cv2.connectedComponentsWithStats(
        visible, connectivity=8)
    component_areas = sorted(
        (int(stats[i, cv2.CC_STAT_AREA]) for i in range(1, components)),
        reverse=True)

    probes = {s['id']: s['puntos'][0] for s in validation['sondas']}
    label_scale = max(0.3, min(width, height) / 2400)
    for rid, point in probes.items():
        if len(ids) > 250 and int(rid[1:]) % 5:
            continue
        cv2.putText(overview, rid, tuple(point), cv2.FONT_HERSHEY_SIMPLEX,
                    label_scale, (0, 0, 0), 1, cv2.LINE_AA)

    highlight = np.full((height, width, 3), 245, np.uint8)
    highlight[ink == 1] = (22, 56, 58)
    highlight[visible == 1] = (52, 75, 230)
    if touch is not None:
        cv2.drawMarker(highlight, touch, (220, 40, 40), cv2.MARKER_CROSS,
                       28, 3)
    cv2.putText(highlight, f'{art_id}  {selected}', (16, 32),
                cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 0), 2, cv2.LINE_AA)

    stem = f'{art_id}_{selected}'
    _encode(output / f'{art_id}_ids.jpg', overview, 88)
    _encode(output / f'{stem}_seleccion.png', highlight)
    evidence = {
        'art_id': art_id,
        'template': validation['plantilla'],
        'revision': template['revision'],
        'region_model': validation.get('modelo_regiones'),
        'touch': list(touch) if touch is not None else None,
        'selected_region': selected,
        'visible_pixels_affected': int(visible.sum()),
        'connected_components_affected': len(component_areas),
        'component_areas': component_areas,
        'highlight': f'{stem}_seleccion.png',
        'region_map': f'{art_id}_ids.jpg',
    }
    (output / f'{stem}.json').write_text(
        json.dumps(evidence, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8', newline='\n')
    return evidence


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('art_id', nargs='?')
    parser.add_argument('--all', action='store_true')
    parser.add_argument('--touch', nargs=2, type=int, metavar=('X', 'Y'))
    parser.add_argument('--region')
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if not args.all and args.art_id is None:
        parser.error('indique un ID o --all')
    ids = ([f'{level}{i:02d}' for level in 'EMDA' for i in range(1, 16)]
           if args.all else [args.art_id.upper()])
    summary = []
    for art_id in ids:
        validation, _ = _load(art_id)
        touch = tuple(args.touch) if args.touch else tuple(
            validation['sondas'][0]['puntos'][0])
        item = diagnose(art_id, args.output, touch, args.region)
        summary.append(item)
        print(art_id, item['selected_region'],
              item['visible_pixels_affected'], 'px',
              item['connected_components_affected'], 'componentes')
    if args.all:
        (args.output / 'resumen.json').write_text(
            json.dumps(summary, ensure_ascii=False, indent=2) + '\n',
            encoding='utf-8', newline='\n')


if __name__ == '__main__':
    main()
