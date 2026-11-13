"""Retoque de E06: sustituye el pico grande y curvo (de loro) por el pico
corto del quetzal. El original no se modifica; el resultado se guarda en
tool/laminas/fuentes_corregidas/E06.png y es lo que lee convertir.py.

    python tool/laminas/corregir_e06.py <E06_quetzal.webp>
"""

import sys
from pathlib import Path

import cv2
import numpy as np

GROSOR = 13  # grosor del trazo original, en píxeles de la fuente
NEGRO = 0


def curva(p0, p1, p2, n=40):
    t = np.linspace(0, 1, n)[:, None]
    p = (1 - t) ** 2 * np.array(p0) + 2 * (1 - t) * t * np.array(p1) \
        + t ** 2 * np.array(p2)
    return np.round(p * 8).astype(np.int32)  # subpíxel (shift=3)


def trazo(img, puntos):
    cv2.polylines(img, [puntos], False, NEGRO, GROSOR, cv2.LINE_AA, shift=3)
    for x, y in (puntos[0], puntos[-1]):
        cv2.circle(img, (int(x), int(y)), GROSOR * 4, NEGRO, -1, cv2.LINE_AA,
                   shift=3)


def main(fuente):
    img = cv2.imdecode(np.fromfile(fuente, np.uint8), cv2.IMREAD_GRAYSCALE)
    assert img.shape == (1402, 1122), img.shape
    # 1. Se borra el pico original (ambas mandíbulas y la comisura).
    borrar = np.array([(634, 228), (688, 198), (722, 176), (800, 176),
                       (800, 312), (700, 314), (660, 302), (634, 292)])
    cv2.fillPoly(img, [borrar], 255)
    # 2. Se cierra el perfil de la cara donde estaba el pico.
    trazo(img, curva((708, 160), (742, 250), (684, 326)))
    # 3. Pico corto y recto, con la línea de la boca.
    trazo(img, curva((723, 222), (752, 228), (776, 252)))
    trazo(img, curva((776, 252), (750, 268), (722, 276)))
    trazo(img, curva((726, 250), (750, 250), (774, 252)))
    destino = Path(__file__).parent / 'fuentes_corregidas' / 'E06.png'
    destino.parent.mkdir(exist_ok=True)
    cv2.imencode('.png', img)[1].tofile(str(destino))
    print(destino)


if __name__ == '__main__':
    main(sys.argv[1])
