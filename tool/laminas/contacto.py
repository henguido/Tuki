"""Hojas de contacto de las vistas previas (una por nivel), para revisión.

    python tool/laminas/contacto.py
"""

from pathlib import Path

import cv2
import numpy as np

RAIZ = Path(__file__).resolve().parents[2]
PREVIAS = RAIZ / 'docs/laminas/previas'
CELDA, COLUMNAS = 420, 5

for letra, nombre in (('E', 'facil'), ('M', 'medio'), ('D', 'detallado'),
                      ('A', 'avanzado')):
    filas = []
    fila = []
    for i in range(1, 16):
        ruta = PREVIAS / f'{letra}{i:02d}.jpg'
        img = cv2.imdecode(np.fromfile(str(ruta), np.uint8), cv2.IMREAD_COLOR)
        h, w = img.shape[:2]
        k = (CELDA - 30) / max(h, w)
        img = cv2.resize(img, (round(w * k), round(h * k)),
                         interpolation=cv2.INTER_AREA)
        celda = np.full((CELDA, CELDA, 3), 255, np.uint8)
        y, x = (CELDA - 24 - img.shape[0]) // 2 + 24, (CELDA - img.shape[1]) // 2
        celda[y:y + img.shape[0], x:x + img.shape[1]] = img
        cv2.putText(celda, f'{letra}{i:02d}', (8, 20),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)
        fila.append(celda)
        if len(fila) == COLUMNAS:
            filas.append(np.hstack(fila))
            fila = []
    hoja = np.vstack(filas)
    cv2.imencode('.jpg', hoja, [cv2.IMWRITE_JPEG_QUALITY, 82])[1].tofile(
        str(RAIZ / f'docs/laminas/contacto_{nombre}.jpg'))
    print(nombre, hoja.shape)
