"""Retoca el perfil, el ojo, la rama y la hoja derecha de E06.

    python tool/laminas/corregir_e06.py <E06_quetzal.webp>
"""

import sys
from pathlib import Path

import cv2
import numpy as np


def curva(p0, p1, p2, p3):
    t = np.linspace(0, 1, 56)[:, None]
    u = 1 - t
    puntos = (u ** 3 * p0 + 3 * u ** 2 * t * p1
              + 3 * u * t ** 2 * p2 + t ** 3 * p3)
    return np.round(puntos * 8).astype(np.int32)


def trazo(img, puntos, grosor):
    cv2.polylines(img, [puntos], False, 0, grosor, cv2.LINE_AA, shift=3)


def main(fuente):
    img = cv2.imdecode(np.fromfile(fuente, np.uint8), cv2.IMREAD_GRAYSCALE)
    assert img.shape == (1402, 1122), img.shape

    # Alinea el perfil nuevo con la frente y la mejilla originales.
    img[154:316, 633:808] = 255
    trazo(img, curva((711, 149), (725, 211), (721, 266), (676, 320)), 13)
    pico = np.concatenate([
        curva((719, 217), (743, 220), (768, 234), (781, 248)),
        curva((781, 248), (764, 265), (741, 273), (705, 277)),
    ])
    trazo(img, pico, 11)

    # Separa el ojo de la ceja y dibuja un reflejo ovalado.
    img[175:273, 525:633] = 255
    ceja = np.concatenate([
        curva((542, 246), (526, 216), (556, 174), (594, 185)),
        curva((594, 185), (566, 190), (541, 213), (542, 246)),
    ])
    cv2.fillPoly(img, [ceja], 0, cv2.LINE_AA, shift=3)
    cv2.ellipse(img, (594, 236), (29, 35), 12, 0, 360, 0, -1, cv2.LINE_AA)
    cv2.ellipse(img, (604, 224), (10, 12), -12, 0, 360, 255, -1, cv2.LINE_AA)

    # Continúa ambos bordes de la rama con la misma dirección y grosor.
    img[780:1015, :52] = 255
    trazo(img, curva((-4, 854), (14, 836), (39, 817), (65, 801)), 12)
    trazo(img, curva((-4, 996), (15, 970), (40, 936), (65, 910)), 13)

    # Prolonga la base de la hoja hasta el borde superior de la rama.
    trazo(img, curva((889, 641), (894, 653), (895, 676), (900, 694)), 11)

    destino = Path(__file__).parent / 'fuentes_corregidas' / 'E06.png'
    cv2.imencode('.png', img)[1].tofile(str(destino))
    print(destino)


if __name__ == '__main__':
    main(sys.argv[1])
