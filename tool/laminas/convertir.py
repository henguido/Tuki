"""Convierte las ilustraciones B/N de TUKI en plantillas del editor.

    python tool/laminas/convertir.py <carpeta organizadas> [ID ...]

Por cada ilustración escribe:
  assets/chapters/bosque-nuboso/pages/<pagina>-v<rev>.json   plantilla
  assets/chapters/bosque-nuboso/thumbs/<pagina>.png          miniatura
  tool/laminas/validacion/<ID>.json                          sondas y medidas
  docs/laminas/previas/<ID>.jpg                              regiones coloreadas

Los originales solo se leen. Requiere numpy, opencv, scipy y scikit-image.

Qué hace, en orden:
  1. Normaliza a 1600 px de lado mayor y separa tinta de papel.
  2. Limpia motas, cierra huecos de trazo y, en Fácil, engrosa contornos finos.
  3. Cierra contornos abiertos: un paso estrecho entre dos zonas amplias se
     corta con una línea de tinta.
  4. Reparte la tinta entre las zonas vecinas, de modo que las regiones
     cubren todo el lienzo y un toque sobre una línea rellena la zona más
     cercana.
  5. Agrupa las zonas demasiado pequeñas para el dedo con la vecina con la que
     comparten más frontera, hasta cumplir los mínimos y el tope del nivel.
     Una región puede tener varias partes: se rellenan juntas.
  6. Vectoriza regiones y tinta como polígonos cerrados (regla nonZero).
  7. Comprueba el resultado rasterizando los polígonos escritos.
"""

import csv
import hashlib
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from scipy import ndimage
from skimage.segmentation import watershed

RAIZ = Path(__file__).resolve().parents[2]
PAGINAS = RAIZ / 'assets/chapters/bosque-nuboso/pages'
MINIATURAS = RAIZ / 'assets/chapters/bosque-nuboso/thumbs'
VALIDACION = RAIZ / 'tool/laminas/validacion'
PREVIAS = RAIZ / 'docs/laminas/previas'
CORREGIDAS = RAIZ / 'tool/laminas/fuentes_corregidas'

LADO = 1600

# Mínimos táctiles como fracción del lado corto de la lámina. En un teléfono
# de 360 dp de ancho: Fácil 20 dp sin ampliar; Avanzado 24 dp con zoom ×3,5.
NIVELES = {
    'E': dict(nombre='easy', diametro=0.055, area=0.0040, tope=36, cierre=5,
              trazo_min=13),
    'M': dict(nombre='medium', diametro=0.040, area=0.0022, tope=60, cierre=3,
              trazo_min=0),
    'D': dict(nombre='detailed', diametro=0.028, area=0.0011, tope=95,
              cierre=3, trazo_min=0),
    'A': dict(nombre='advanced', diametro=0.020, area=0.0006, tope=140,
              cierre=3, trazo_min=0),
}

# Páginas que ya existían en la app conservan su identificador.
PAGINAS_PREVIAS = {'E01': ('rana-en-la-hoja', 2), 'M06': ('quetzal', 2),
                   'D15': ('sendero', 2)}


def pagina_de(art_id, tema_id):
    if art_id in PAGINAS_PREVIAS:
        return PAGINAS_PREVIAS[art_id]
    return f'{art_id.lower()}-{tema_id}', 1


def leer_gris(ruta):
    datos = np.fromfile(str(ruta), dtype=np.uint8)
    img = cv2.imdecode(datos, cv2.IMREAD_UNCHANGED)
    if img.ndim == 3 and img.shape[2] == 4:  # transparencia sobre blanco
        alfa = img[:, :, 3:4].astype(np.float32) / 255
        img = (img[:, :, :3] * alfa + 255 * (1 - alfa)).astype(np.uint8)
    if img.ndim == 3:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    return img


def elipse(k):
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k))


def grosor_trazo(tinta):
    """Mediana del grosor de línea (px) medida sobre el esqueleto."""
    dist = cv2.distanceTransform(tinta.astype(np.uint8), cv2.DIST_L2, 5)
    cresta = (dist == ndimage.maximum_filter(dist, size=3)) & (dist > 1)
    return float(np.median(dist[cresta]) * 2) if cresta.any() else 0.0


def cerrar_contornos(tinta, area_min):
    """Corta con tinta los pasos estrechos que unen dos zonas amplias."""
    papel = ~tinta
    etiquetas, _ = ndimage.label(papel)
    dist = ndimage.distance_transform_edt(papel)
    nucleo = dist > 4.0  # pasos de menos de ~8 px de ancho
    semillas, n = ndimage.label(nucleo)
    if n == 0:
        return tinta, 0
    areas = np.bincount(semillas.ravel())
    grandes = np.flatnonzero(areas >= area_min)
    grandes = grandes[grandes != 0]
    marcadores = np.where(np.isin(semillas, grandes), semillas, 0)
    # ¿Qué componentes contienen más de una semilla grande?
    pares = np.unique(
        np.stack([etiquetas[marcadores > 0], marcadores[marcadores > 0]]),
        axis=1)
    por_comp = np.bincount(pares[0])
    partidas = np.flatnonzero(por_comp > 1)
    if len(partidas) == 0:
        return tinta, 0
    mascara = np.isin(etiquetas, partidas)
    marcadores = np.where(mascara, marcadores, 0)
    cuenca = watershed(-dist, marcadores, mask=mascara, watershed_line=True)
    linea = mascara & (cuenca == 0)
    # Solo cuenta como cierre la línea que cruza un paso estrecho.
    linea &= dist <= 5.0
    trozos, cortes = ndimage.label(linea, structure=np.ones((3, 3)))
    if cortes == 0:
        return tinta, 0
    linea = cv2.dilate(linea.astype(np.uint8), elipse(5)).astype(bool)
    return tinta | linea, int(cortes)


class Grupos:
    """Unión de zonas en regiones, con fronteras compartidas acumuladas."""

    def __init__(self, n, areas, diametros, vecinos):
        self.padre = list(range(n + 1))
        self.area = dict(enumerate(areas))
        self.diam = dict(enumerate(diametros))
        self.vec = vecinos
        del self.area[0], self.diam[0]

    def raiz(self, a):
        while self.padre[a] != a:
            self.padre[a] = self.padre[self.padre[a]]
            a = self.padre[a]
        return a

    def unir(self, chico, grande):
        self.padre[chico] = grande
        self.area[grande] += self.area.pop(chico)
        self.diam[grande] = max(self.diam[grande], self.diam.pop(chico))
        for otro, peso in self.vec.pop(chico, {}).items():
            self.vec[otro].pop(chico, None)
            if otro == grande:
                continue
            self.vec[grande][otro] = self.vec[grande].get(otro, 0) + peso
            self.vec[otro][grande] = self.vec[grande][otro]

    def mejor_vecino(self, a):
        v = self.vec.get(a)
        if not v:
            return None
        return max(v, key=lambda o: (v[o], self.area[o]))


def procesar(art_id, tema_id, fuente, original):
    nivel = NIVELES[art_id[0]]
    pagina, revision = pagina_de(art_id, tema_id)
    cambios = []

    gris = leer_gris(fuente)
    alto0, ancho0 = gris.shape
    escala = LADO / max(alto0, ancho0)
    ancho, alto = round(ancho0 * escala), round(alto0 * escala)
    gris = cv2.resize(gris, (ancho, alto), interpolation=cv2.INTER_LANCZOS4)
    gris = cv2.GaussianBlur(gris, (0, 0), 0.7)
    corto = min(ancho, alto)

    # 1-2. Tinta limpia.
    tinta = gris < 150
    et, n = ndimage.label(tinta, structure=np.ones((3, 3)))
    motas = np.flatnonzero(np.bincount(et.ravel()) < 14)
    motas = motas[motas != 0]
    if len(motas):
        tinta[np.isin(et, motas)] = False
        cambios.append(f'{len(motas)} motas de tinta eliminadas')
    cerrada = cv2.morphologyEx(tinta.astype(np.uint8), cv2.MORPH_CLOSE,
                               elipse(nivel['cierre'])).astype(bool)
    if (cerrada & ~tinta).sum():
        cambios.append(
            f'huecos de trazo cerrados ({int((cerrada & ~tinta).sum())} px)')
    tinta = cerrada
    grosor = grosor_trazo(tinta)
    if grosor < nivel['trazo_min']:
        pasos = int(np.ceil((nivel['trazo_min'] - grosor) / 2))
        tinta = cv2.dilate(tinta.astype(np.uint8), elipse(3),
                           iterations=pasos).astype(bool)
        cambios.append(
            f'contorno engrosado de {grosor:.1f} a {grosor_trazo(tinta):.1f} px')
        grosor = grosor_trazo(tinta)

    # 3. Contornos abiertos.
    area_min = nivel['area'] * ancho * alto
    tinta, cortes = cerrar_contornos(tinta, max(area_min, 250))
    if cortes:
        cambios.append(f'{cortes} contornos abiertos cerrados con tinta')

    # Zonas de papel; las motas blancas dentro de la tinta se ennegrecen.
    zonas, n = ndimage.label(~tinta)
    areas = np.bincount(zonas.ravel())
    polvo = np.flatnonzero(areas < 36)
    polvo = polvo[polvo != 0]
    if len(polvo):
        tinta[np.isin(zonas, polvo)] = True
        cambios.append(f'{len(polvo)} huecos diminutos absorbidos por la tinta')
        zonas, n = ndimage.label(~tinta)
        areas = np.bincount(zonas.ravel())
    zonas_iniciales = n
    # El marco cuenta como límite: el centro de una zona nunca cae en el borde.
    dist_papel = ndimage.distance_transform_edt(
        np.pad(~tinta, 1, constant_values=False))[1:-1, 1:-1]
    indices = np.arange(1, n + 1)
    diametros = np.concatenate(
        [[0], 2 * ndimage.maximum(dist_papel, zonas, indices)])
    polos = ndimage.maximum_position(dist_papel, zonas, indices)

    # 4. La tinta se reparte entre las zonas vecinas.
    _, (iy, ix) = ndimage.distance_transform_edt(zonas == 0,
                                                 return_indices=True)
    completo = zonas[iy, ix]

    vecinos = {i: {} for i in range(1, n + 1)}
    # Tinta que le toca a cada zona frente a la que tendría si solo la
    # rodeara un trazo normal. Mucho más = está dentro de una mancha maciza.
    tinta_propia = np.bincount(completo[tinta], minlength=n + 1)
    orilla = (~tinta) & cv2.dilate(tinta.astype(np.uint8),
                                   np.ones((3, 3), np.uint8)).astype(bool)
    perimetro = np.bincount(zonas[orilla], minlength=n + 1)
    esperado = perimetro * grosor / 2 + np.pi * grosor ** 2 / 4
    macizo = tinta_propia / np.maximum(esperado, 1)
    for a, b in ((completo[:, :-1], completo[:, 1:]),
                 (completo[:-1, :], completo[1:, :])):
        dif = a != b
        pares, cuenta = np.unique(
            np.stack([a[dif], b[dif]]), axis=1, return_counts=True)
        for (p, q), c in zip(pares.T, cuenta):
            vecinos[p][q] = vecinos[p].get(q, 0) + int(c)
            vecinos[q][p] = vecinos[p][q]

    # 5. Agrupación de zonas pequeñas.
    g = Grupos(n, areas.astype(np.int64).tolist(), diametros.tolist(), vecinos)
    diam_min = nivel['diametro'] * corto

    def pequeno(a):
        return g.diam[a] < diam_min or g.area[a] < area_min

    # Brillos: detalles blancos rodeados de tinta maciza (el reflejo de un
    # ojo). No se agrupan con nadie: quedarían del color de otra zona. Siguen
    # siendo regiones propias, exentas del mínimo táctil.
    brillos = [a for a in list(g.area)
               if pequeno(a) and macizo[a] > 2.0]
    for a in brillos:
        for otro in g.vec.pop(a, {}):
            g.vec[otro].pop(a, None)
    if brillos:
        cambios.append(
            f'{len(brillos)} brillos sobre tinta conservados como regiones propias')

    while True:
        chicos = [a for a in g.area if pequeno(a) and g.vec.get(a)]
        if not chicos:
            break
        a = min(chicos, key=lambda k: g.area[k])
        g.unir(a, g.mejor_vecino(a))
    por_minimo = n - len(g.area)
    while len(g.area) - len(brillos) > nivel['tope']:
        candidatos = [k for k in g.area if g.vec.get(k)]
        if not candidatos:
            break
        a = min(candidatos, key=lambda k: g.area[k])
        g.unir(a, g.mejor_vecino(a))
    por_tope = n - por_minimo - len(g.area)
    if por_minimo:
        cambios.append(
            f'{por_minimo} zonas pequeñas agrupadas con su vecina')
    if por_tope:
        cambios.append(
            f'{por_tope} zonas más agrupadas para no superar {nivel["tope"]} regiones')

    brillos_set = set(brillos)
    raices = np.array([0] + [g.raiz(i) for i in range(1, n + 1)])
    orden = sorted(g.area, key=lambda k: -g.area[k])
    numero = {r: i + 1 for i, r in enumerate(orden)}
    region_de_zona = np.array([0] + [numero[r] for r in raices[1:]])
    mapa = region_de_zona[completo]  # región (1..R) de cada píxel

    # 6. Vectorización. Los contornos se estiran medio píxel para que los
    # polígonos lleguen al borde del lienzo.
    fx, fy = ancho / (ancho - 1), alto / (alto - 1)

    def trazado(mascara, eps):
        contornos, jer = cv2.findContours(
            mascara.astype(np.uint8), cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
        partes, puntos, poligonos = [], 0, []
        for c, h in zip(contornos, jer[0] if jer is not None else []):
            p = cv2.approxPolyDP(c, eps, True).reshape(-1, 2)
            if len(p) < 3:
                continue
            p = np.round(p * [fx, fy]).astype(np.int64)
            area2 = np.sum(p[:, 0] * np.roll(p[:, 1], -1)
                           - np.roll(p[:, 0], -1) * p[:, 1])
            if area2 == 0:
                continue
            hueco = h[3] != -1
            if (area2 < 0) != hueco:  # exterior positivo, hueco negativo
                p = p[::-1]
            d = np.diff(p, axis=0)
            texto = f'M{p[0, 0]} {p[0, 1]}l' + ' '.join(
                f'{dx} {dy}' for dx, dy in d).replace(' -', '-') + 'Z'
            partes.append(texto)
            puntos += len(p)
            poligonos.append(p)
        return partes, puntos, poligonos

    regiones, sondas, poligonos_region, puntos_region = [], [], [], 0
    for r in range(1, len(orden) + 1):
        partes, puntos, pols = trazado(mapa == r, 1.0)
        puntos_region += puntos
        rid = f'r{r:03d}'
        regiones.append({'id': rid, 'path': ''.join(partes)})
        poligonos_region.append(pols)
        miembros = np.flatnonzero(region_de_zona == r)
        miembros = sorted(miembros, key=lambda z: -areas[z])
        sondas.append({
            'id': rid,
            'partes': len(miembros),
            'area': round(float(g.area[orden[r - 1]]) / (ancho * alto), 5),
            'diametro': round(float(g.diam[orden[r - 1]]) / corto, 4),
            'brillo': orden[r - 1] in brillos_set,
            # Centro de cada parte (hasta 6): debe pertenecer a la región.
            'puntos': [[int(polos[z - 1][1]), int(polos[z - 1][0])]
                       for z in miembros[:6]],
        })

    partes_tinta, puntos_tinta, pols_tinta = trazado(tinta, 0.8)
    # Un único trazado: los huecos deben ir en el mismo trazado que su
    # contorno para que la regla nonZero los reste.
    inks = [{'path': ''.join(partes_tinta)}]

    plantilla = {
        'schemaVersion': 1,
        'revision': revision,
        'viewBox': [0, 0, ancho, alto],
        'regions': regiones,
        'outlines': [],
        'inks': inks,
    }
    PAGINAS.mkdir(parents=True, exist_ok=True)
    destino = PAGINAS / f'{pagina}-v{revision}.json'
    destino.write_text(json.dumps(plantilla, separators=(',', ':')),
                       encoding='utf-8', newline='\n')

    # 7. Comprobación sobre los polígonos escritos.
    lienzo = np.zeros((alto, ancho), np.int32)
    veces = np.zeros((alto, ancho), np.uint8)
    for r, pols in enumerate(poligonos_region, start=1):
        capa = np.zeros((alto, ancho), np.uint8)
        cv2.fillPoly(capa, [p.astype(np.int32) for p in pols], 1)
        lienzo[capa == 1] = r
        veces += capa
    tinta_vec = np.zeros((alto, ancho), np.uint8)
    cv2.fillPoly(tinta_vec, [p.astype(np.int32) for p in pols_tinta], 1)
    visible = tinta_vec == 0
    sin_region = float(((veces == 0) & visible).mean())
    solape = float(((veces > 1) & visible).mean())
    # Fuga: papel visible que quedó asignado a una región distinta de la suya.
    interior = (~tinta) & visible & (dist_papel > 2)
    fuga = float((lienzo[interior] != mapa[interior]).mean()) if interior.any() else 0.0
    fallidas = [[s['id'], x, y, int(lienzo[y, x]), bool(tinta_vec[y, x])]
                for i, s in enumerate(sondas) for x, y in s['puntos']
                if lienzo[y, x] != i + 1]
    sondas_ok = not fallidas
    fidelidad = float((tinta_vec.astype(bool) == tinta).mean())
    # Tinta que toca el marco: formas que se cierran contra el borde.
    borde = np.concatenate([tinta[0], tinta[-1], tinta[:, 0], tinta[:, -1]])

    medidas = {
        'id': art_id,
        'pagina': pagina,
        'plantilla': destino.relative_to(RAIZ).as_posix(),
        'revision': revision,
        'nivel': nivel['nombre'],
        'original': original,
        'fuente': Path(fuente).name,
        'sha256_fuente': hashlib.sha256(Path(fuente).read_bytes()).hexdigest(),
        'fuente_px': [ancho0, alto0],
        'viewBox': [0, 0, ancho, alto],
        'orientacion': 'horizontal' if ancho > alto else 'vertical',
        'zonas_detectadas': int(zonas_iniciales),
        'regiones': len(regiones),
        'regiones_multiparte': sum(1 for s in sondas if s['partes'] > 1),
        'brillos': len(brillos),
        'diametro_min': min(s['diametro'] for s in sondas if not s['brillo']),
        'diametro_min_exigido': nivel['diametro'],
        'tope_regiones': nivel['tope'],
        'grosor_trazo_px': round(grosor, 1),
        'tinta_en_borde': round(float(borde.mean()), 4),
        'puntos_regiones': puntos_region,
        'puntos_tinta': puntos_tinta,
        'bytes': destino.stat().st_size,
        'papel_sin_region': round(sin_region, 6),
        'solape_visible': round(solape, 6),
        'fuga': round(fuga, 6),
        'sondas_ok': bool(sondas_ok),
        'sondas_fallidas': fallidas,
        'fidelidad_tinta': round(fidelidad, 5),
        'cambios': cambios,
        'sondas': sondas,
    }
    VALIDACION.mkdir(parents=True, exist_ok=True)
    (VALIDACION / f'{art_id}.json').write_text(
        json.dumps(medidas, ensure_ascii=False, separators=(',', ':')),
        encoding='utf-8', newline='\n')

    # Miniatura: la lámina procesada, no el original.
    MINIATURAS.mkdir(parents=True, exist_ok=True)
    blanco = np.where(tinta_vec == 1, 23, 255).astype(np.uint8)
    lado = 320 / max(ancho, alto)
    mini = cv2.resize(blanco, (round(ancho * lado), round(alto * lado)),
                      interpolation=cv2.INTER_AREA)
    cv2.imencode('.png', mini, [cv2.IMWRITE_PNG_COMPRESSION, 9])[1].tofile(
        str(MINIATURAS / f'{pagina}.png'))

    # Vista previa: cada región con un color, para revisar las agrupaciones.
    rng = np.random.default_rng(7)
    paleta = rng.integers(90, 245, size=(len(regiones) + 1, 3), dtype=np.uint8)
    paleta[0] = 255
    previa = paleta[lienzo]
    previa[tinta_vec == 1] = (20, 20, 20)
    previa = cv2.resize(previa, (round(ancho * 0.5), round(alto * 0.5)),
                        interpolation=cv2.INTER_AREA)
    PREVIAS.mkdir(parents=True, exist_ok=True)
    cv2.imencode('.jpg', previa, [cv2.IMWRITE_JPEG_QUALITY, 86])[1].tofile(
        str(PREVIAS / f'{art_id}.jpg'))
    return medidas


def main():
    organizadas = Path(sys.argv[1])
    solo = set(sys.argv[2:])
    matriz = organizadas.parent / '_auditoria' / 'matriz_60.csv'
    with open(matriz, encoding='utf-8-sig', newline='') as f:
        filas = list(csv.DictReader(f))
    for fila in filas:
        art_id = fila['id']
        if solo and art_id not in solo:
            continue
        fuente = organizadas.parent / fila['archivo_organizado']
        corregida = CORREGIDAS / f'{art_id}.png'
        if corregida.exists():  # arte retocado; el original no se toca
            fuente = corregida
        m = procesar(art_id, fila['tema_id'], fuente,
                     fila['original_preservado'])
        print(f"{art_id} {m['pagina']:<28} zonas {m['zonas_detectadas']:>4} -> "
              f"regiones {m['regiones']:>3}  d_min {m['diametro_min']:.3f}  "
              f"{m['bytes'] // 1024:>4} KB  sin_region {m['papel_sin_region']:.4f} "
              f"solape {m['solape_visible']:.4f} fuga {m['fuga']:.4f} "
              f"sondas {'ok' if m['sondas_ok'] else 'FALLO'}", flush=True)


if __name__ == '__main__':
    main()
