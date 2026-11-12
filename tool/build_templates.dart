// Genera las plantillas vectoriales ORIGINALES del capítulo «El bosque nuboso».
//
//   dart run tool/build_templates.dart
//
// Cada lámina se describe como figuras apiladas de fondo a frente. El script
// emite las regiones coloreables (trazados cerrados) y calcula los contornos
// visibles: la parte de un contorno tapada por una región superior se omite.
//
// IMPORTANTE: una plantilla publicada no se regenera con otra geometría.
// Para cambiar un dibujo se crea una revisión nueva (…-v2.json) y la anterior
// se declara en `previousTemplates` del manifiesto.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class P {
  const P(this.x, this.y);
  final double x, y;
  P operator +(P o) => P(x + o.x, y + o.y);
  P operator -(P o) => P(x - o.x, y - o.y);
  P operator *(double k) => P(x * k, y * k);
  double get length => math.sqrt(x * x + y * y);
}

P p(num x, num y) => P(x.toDouble(), y.toDouble());

class Seg {
  Seg(this.type, this.pts);
  final String type; // L, Q, C
  final List<P> pts;
}

String n(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

class Shape {
  Shape(this.start, this.segs, {this.closed = true});
  final P start;
  final List<Seg> segs;
  final bool closed;

  String get d {
    final b = StringBuffer('M${n(start.x)} ${n(start.y)}');
    for (final s in segs) {
      b.write(s.type);
      b.write(s.pts.map((q) => '${n(q.x)} ${n(q.y)}').join(' '));
    }
    if (closed) b.write('Z');
    return b.toString();
  }

  /// Polilínea densa (paso máximo ~4 unidades).
  List<P> flatten() {
    final out = <P>[start];
    var cur = start;
    for (final s in segs) {
      final ctrl = [cur, ...s.pts];
      var len = 0.0;
      for (var i = 1; i < ctrl.length; i++) {
        len += (ctrl[i] - ctrl[i - 1]).length;
      }
      final steps = math.max(1, (len / 4).ceil());
      for (var k = 1; k <= steps; k++) {
        final t = k / steps;
        out.add(switch (s.type) {
          'L' => cur + (s.pts[0] - cur) * t,
          'Q' => _quad(cur, s.pts[0], s.pts[1], t),
          _ => _cubic(cur, s.pts[0], s.pts[1], s.pts[2], t),
        });
      }
      cur = s.pts.last;
    }
    if (closed && (out.last - start).length > 0.01) {
      final steps = math.max(1, ((out.last - start).length / 4).ceil());
      final from = out.last;
      for (var k = 1; k <= steps; k++) {
        out.add(from + (start - from) * (k / steps));
      }
    }
    return out;
  }

  static P _quad(P a, P c, P b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  static P _cubic(P a, P c1, P c2, P b, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        c1 * (3 * u * u * t) +
        c2 * (3 * u * t * t) +
        b * (t * t * t);
  }
}

// ---------- Figuras ----------

/// Curva cerrada suave (Catmull-Rom) que pasa por los puntos.
Shape blob(List<List<num>> raw) {
  final q = [for (final r in raw) p(r[0], r[1])];
  final m = q.length;
  final segs = <Seg>[];
  for (var i = 0; i < m; i++) {
    final p0 = q[(i - 1 + m) % m], p1 = q[i];
    final p2 = q[(i + 1) % m], p3 = q[(i + 2) % m];
    segs.add(
      Seg('C', [p1 + (p2 - p0) * (1 / 6), p2 - (p3 - p1) * (1 / 6), p2]),
    );
  }
  return Shape(q[0], segs);
}

/// Curva abierta suave que pasa por los puntos.
Shape curve(List<List<num>> raw) {
  final q = [for (final r in raw) p(r[0], r[1])];
  final segs = <Seg>[];
  for (var i = 0; i < q.length - 1; i++) {
    final p0 = q[math.max(0, i - 1)], p1 = q[i];
    final p2 = q[i + 1], p3 = q[math.min(q.length - 1, i + 2)];
    segs.add(
      Seg('C', [p1 + (p2 - p0) * (1 / 6), p2 - (p3 - p1) * (1 / 6), p2]),
    );
  }
  return Shape(q[0], segs, closed: false);
}

Shape poly(List<List<num>> raw) => Shape(p(raw[0][0], raw[0][1]), [
  for (final r in raw.skip(1)) Seg('L', [p(r[0], r[1])]),
]);

Shape ellipse(num cx, num cy, num rx, num ry, {num rot = 0}) {
  const k = 0.5522847498;
  final c = math.cos(rot * math.pi / 180), s = math.sin(rot * math.pi / 180);
  P at(double x, double y) =>
      P(cx + (x * rx) * c - (y * ry) * s, cy + (x * rx) * s + (y * ry) * c);
  return Shape(at(1, 0), [
    Seg('C', [at(1, k), at(k, 1), at(0, 1)]),
    Seg('C', [at(-k, 1), at(-1, k), at(-1, 0)]),
    Seg('C', [at(-1, -k), at(-k, -1), at(0, -1)]),
    Seg('C', [at(k, -1), at(1, -k), at(1, 0)]),
  ]);
}

/// Hoja o pluma con puntas afiladas entre dos puntos.
Shape leaf(num x1, num y1, num x2, num y2, num bulge, {num? bulge2}) {
  final a = p(x1, y1), b = p(x2, y2);
  final mid = (a + b) * 0.5;
  final dir = b - a;
  final nrm = P(-dir.y, dir.x) * (1 / dir.length);
  return Shape(a, [
    Seg('Q', [mid + nrm * (bulge * 2.0), b]),
    Seg('Q', [mid - nrm * ((bulge2 ?? bulge) * 2.0), a]),
  ]);
}

Shape drop(num cx, num cy, num r) => Shape(p(cx, cy - r * 1.7), [
  Seg('C', [p(cx + r * 1.2, cy - r * 0.2), p(cx + r, cy + r), p(cx, cy + r)]),
  Seg('C', [
    p(cx - r, cy + r),
    p(cx - r * 1.2, cy - r * 0.2),
    p(cx, cy - r * 1.7),
  ]),
]);

/// Trazado libre: 'M x y C … Z' escrito con segmentos.
Shape path(num x, num y, List<Seg> segs, {bool closed = true}) =>
    Shape(p(x, y), segs, closed: closed);
Seg c(num a, num b, num cx, num d, num e, num f) =>
    Seg('C', [p(a, b), p(cx, d), p(e, f)]);
Seg l(num x, num y) => Seg('L', [p(x, y)]);
Seg q(num a, num b, num x, num y) => Seg('Q', [p(a, b), p(x, y)]);

Shape line(num x1, num y1, num x2, num y2) =>
    Shape(p(x1, y1), [l(x2, y2)], closed: false);
Shape dot(num x, num y) => Shape(p(x, y), [l(x + 0.1, y)], closed: false);

// ---------- Plantilla ----------

class _Item {
  _Item(this.shape, this.width, {this.id, this.outlined = true});
  final Shape shape;
  final double width;
  final String? id; // null = solo contorno
  final bool outlined;
  late final List<P> flat = shape.flatten();
  late final double minX = flat.map((e) => e.x).reduce(math.min);
  late final double maxX = flat.map((e) => e.x).reduce(math.max);
  late final double minY = flat.map((e) => e.y).reduce(math.min);
  late final double maxY = flat.map((e) => e.y).reduce(math.max);

  bool contains(P pt) {
    if (pt.x < minX || pt.x > maxX || pt.y < minY || pt.y > maxY) return false;
    var inside = false;
    for (var i = 0, j = flat.length - 1; i < flat.length; j = i++) {
      final a = flat[i], b = flat[j];
      if ((a.y > pt.y) != (b.y > pt.y) &&
          pt.x < (b.x - a.x) * (pt.y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
    }
    return inside;
  }
}

class Template {
  Template(this.width, this.height, this.stroke);
  final double width, height, stroke;
  final List<_Item> _items = [];

  /// Región coloreable. Se apila sobre todo lo anterior.
  void region(String id, Shape s, {bool outlined = true, double? w}) {
    assert(s.closed);
    _items.add(_Item(s, w ?? stroke, id: id, outlined: outlined));
  }

  /// Línea de detalle. Las regiones posteriores la tapan.
  void detail(Shape s, [double? w]) => _items.add(_Item(s, w ?? stroke * 0.7));

  Map<String, dynamic> build() {
    final regions = <Map<String, dynamic>>[];
    final outlines = <Map<String, dynamic>>[];
    final ids = <String>{};
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.id != null) {
        if (!ids.add(item.id!)) throw StateError('ID repetido: ${item.id}');
        regions.add({'id': item.id, 'path': item.shape.d});
      }
      if (!item.outlined) continue;
      final above = [
        for (final o in _items.skip(i + 1))
          if (o.id != null) o,
      ];
      for (final d in _visible(item, above)) {
        outlines.add({'path': d, 'width': item.width});
      }
    }
    return {
      'schemaVersion': 1,
      'revision': 1,
      'viewBox': [0, 0, width, height],
      'regions': regions,
      'outlines': outlines,
    };
  }

  List<String> _visible(_Item item, List<_Item> above) {
    final pts = item.flat;
    final segCount = pts.length - 1;
    final vis = List<bool>.generate(segCount, (i) {
      final mid = (pts[i] + pts[i + 1]) * 0.5;
      return !above.any((o) => o.contains(mid));
    });
    if (vis.every((v) => v)) return [item.shape.d];
    if (vis.every((v) => !v)) return [];

    final runs = <List<P>>[];
    List<P>? run;
    for (var i = 0; i < segCount; i++) {
      if (vis[i]) {
        run ??= [pts[i]];
        run.add(pts[i + 1]);
      } else if (run != null) {
        runs.add(run);
        run = null;
      }
    }
    if (run != null) runs.add(run);
    // En figuras cerradas, une el último tramo con el primero.
    if (item.shape.closed && vis.first && vis.last && runs.length > 1) {
      final last = runs.removeLast();
      runs[0] = [...last, ...runs[0].skip(1)];
    }
    return [
      for (final r in runs)
        if (r.length >= 2) _polyline(_simplify(r, 0.35)),
    ];
  }

  static String _polyline(List<P> r) {
    final b = StringBuffer('M${n(r[0].x)} ${n(r[0].y)}L');
    b.write(r.skip(1).map((e) => '${n(e.x)} ${n(e.y)}').join(' '));
    return b.toString();
  }

  /// Douglas-Peucker.
  static List<P> _simplify(List<P> pts, double tol) {
    if (pts.length < 3) return pts;
    final keep = List<bool>.filled(pts.length, false);
    keep[0] = keep[pts.length - 1] = true;
    final stack = <(int, int)>[(0, pts.length - 1)];
    while (stack.isNotEmpty) {
      final (a, b) = stack.removeLast();
      var worst = -1;
      var worstD = tol;
      final ab = pts[b] - pts[a];
      final len = ab.length;
      for (var i = a + 1; i < b; i++) {
        final ap = pts[i] - pts[a];
        final dist = len < 1e-9
            ? ap.length
            : (ab.x * ap.y - ab.y * ap.x).abs() / len;
        if (dist > worstD) {
          worstD = dist;
          worst = i;
        }
      }
      if (worst > 0) {
        keep[worst] = true;
        stack
          ..add((a, worst))
          ..add((worst, b));
      }
    }
    return [
      for (var i = 0; i < pts.length; i++)
        if (keep[i]) pts[i],
    ];
  }
}

Shape background(double w, double h) => poly([
  [0, 0],
  [w, 0],
  [w, h],
  [0, h],
]);

// ---------- Lámina 1: La rana en la hoja (fácil) ----------

Template rana() {
  final t = Template(1000, 1000, 10);
  t.region('fondo', background(1000, 1000), outlined: false);

  t.region('hojita-izquierda', leaf(70, 440, 215, 500, 30));
  t.detail(line(70, 440, 215, 500));
  t.detail(
    curve([
      [845, 720],
      [870, 640],
      [905, 560],
    ]),
  );
  t.region('hojita-derecha', leaf(880, 610, 955, 440, 38));
  t.detail(line(880, 610, 955, 440));

  t.region('gota-1', drop(235, 300, 30));
  t.region('gota-2', drop(900, 330, 26));
  t.region('gota-3', drop(170, 880, 28));

  // Hoja grande.
  t.region(
    'hoja',
    path(45, 705, [
      c(230, 560, 720, 560, 960, 745),
      c(760, 930, 280, 930, 45, 705),
    ]),
  );
  t.detail(
    curve([
      [45, 705],
      [400, 735],
      [960, 745],
    ]),
  );
  t.detail(
    curve([
      [250, 722],
      [330, 800],
      [400, 850],
    ]),
  );
  t.detail(
    curve([
      [560, 742],
      [640, 810],
      [700, 850],
    ]),
  );
  t.detail(
    curve([
      [760, 745],
      [820, 700],
      [850, 668],
    ]),
  );

  // Rana.
  t.region(
    'cuerpo',
    blob([
      [255, 640],
      [250, 545],
      [315, 445],
      [425, 375],
      [540, 315],
      [630, 262],
      [735, 262],
      [820, 320],
      [856, 385],
      [805, 432],
      [725, 455],
      [695, 525],
      [695, 625],
      [640, 705],
      [450, 722],
      [320, 702],
    ]),
  );
  t.region(
    'panza',
    blob([
      [652, 456],
      [730, 452],
      [702, 522],
      [698, 622],
      [650, 700],
      [600, 640],
      [612, 540],
    ]),
  );
  t.region(
    'pata',
    blob([
      [262, 655],
      [272, 575],
      [345, 518],
      [448, 520],
      [515, 575],
      [530, 650],
      [522, 700],
      [560, 730],
      [550, 760],
      [470, 764],
      [382, 745],
      [290, 712],
    ]),
  );
  t.region(
    'brazo',
    blob([
      [540, 500],
      [596, 496],
      [630, 560],
      [640, 650],
      [690, 694],
      [760, 706],
      [775, 738],
      [705, 756],
      [620, 744],
      [580, 694],
      [570, 610],
      [535, 550],
    ]),
  );
  t.region('ojo', ellipse(700, 342, 60, 60));
  t.detail(dot(716, 344), 52);
  t.detail(
    curve([
      [852, 388],
      [800, 414],
      [742, 412],
    ]),
    9,
  );
  t.detail(dot(822, 345), 12);
  return t;
}

// ---------- Lámina 2: El quetzal (media) ----------

Template quetzal() {
  final t = Template(1000, 1200, 8);
  t.region('fondo', background(1000, 1200), outlined: false);

  t.region(
    'nube-1',
    blob([
      [70, 215],
      [110, 150],
      [195, 125],
      [265, 155],
      [335, 135],
      [395, 175],
      [405, 228],
      [330, 258],
      [200, 262],
      [105, 252],
    ]),
  );
  t.region(
    'nube-2',
    blob([
      [640, 150],
      [688, 100],
      [760, 98],
      [805, 128],
      [872, 122],
      [915, 168],
      [884, 210],
      [760, 220],
      [668, 206],
    ]),
  );

  // Cola larga: cuelga por detrás de la rama.
  t.region(
    'cola-1',
    path(430, 600, [
      c(380, 800, 350, 980, 318, 1150),
      c(430, 1010, 500, 820, 520, 600),
    ]),
  );
  t.detail(
    curve([
      [470, 640],
      [420, 860],
      [330, 1130],
    ]),
  );
  t.region(
    'cola-2',
    path(486, 600, [
      c(480, 800, 492, 970, 486, 1172),
      c(572, 1000, 596, 800, 570, 600),
    ]),
  );
  t.detail(
    curve([
      [528, 640],
      [528, 880],
      [490, 1150],
    ]),
  );

  // Hojas detrás de la rama.
  t.region('hoja-1', leaf(185, 600, 105, 455, 42));
  t.detail(line(185, 600, 105, 455));
  t.region('hoja-2', leaf(245, 596, 318, 462, 40));
  t.detail(line(245, 596, 318, 462));
  t.region('hoja-3', leaf(836, 556, 792, 716, 42));
  t.detail(line(836, 556, 792, 716));
  t.region('hoja-4', leaf(906, 540, 962, 690, 38));
  t.detail(line(906, 540, 962, 690));
  t.region('hoja-5', leaf(915, 530, 968, 392, 36));
  t.detail(line(915, 530, 968, 392));

  // Bromelia sobre la rama.
  t.region('bromelia-1', leaf(740, 572, 680, 452, 28));
  t.region('bromelia-3', leaf(740, 572, 806, 452, 28));
  t.region('bromelia-2', leaf(740, 578, 742, 410, 32));

  t.region(
    'rama',
    path(-20, 602, [
      c(300, 592, 600, 580, 1020, 500),
      l(1020, 574),
      c(620, 642, 300, 662, -20, 670),
    ]),
  );
  t.detail(
    curve([
      [60, 640],
      [200, 634],
      [330, 626],
    ]),
  );
  t.detail(
    curve([
      [620, 604],
      [760, 584],
      [900, 556],
    ]),
  );
  t.region(
    'musgo-1',
    blob([
      [40, 604],
      [78, 576],
      [130, 590],
      [178, 570],
      [232, 588],
      [262, 606],
      [218, 624],
      [150, 618],
      [84, 628],
    ]),
  );
  t.region(
    'musgo-2',
    blob([
      [812, 542],
      [846, 516],
      [888, 526],
      [926, 502],
      [966, 514],
      [978, 534],
      [936, 546],
      [884, 554],
      [838, 566],
    ]),
  );

  // Ave.
  t.region('vientre', ellipse(495, 488, 118, 160));
  t.region(
    'pecho',
    blob([
      [384, 420],
      [420, 372],
      [500, 356],
      [580, 376],
      [612, 430],
      [590, 486],
      [498, 512],
      [408, 484],
    ]),
  );
  t.region(
    'ala',
    blob([
      [535, 392],
      [600, 400],
      [652, 470],
      [676, 570],
      [668, 676],
      [614, 628],
      [560, 552],
      [528, 466],
    ]),
  );
  t.region('pluma-1', leaf(570, 440, 632, 548, 20));
  t.region('pluma-2', leaf(604, 534, 656, 646, 16));
  t.region(
    'cabeza',
    blob([
      [372, 312],
      [378, 250],
      [416, 204],
      [452, 214],
      [478, 176],
      [510, 208],
      [546, 192],
      [562, 240],
      [574, 302],
      [548, 368],
      [470, 396],
      [402, 372],
    ]),
  );
  t.region(
    'pico',
    poly([
      [384, 282],
      [322, 304],
      [386, 326],
    ]),
  );
  t.region('ojo', ellipse(436, 284, 26, 26));
  t.detail(dot(432, 286), 22);
  // Patas.
  t.detail(
    curve([
      [462, 640],
      [456, 600],
      [470, 590],
    ]),
    9,
  );
  t.detail(
    curve([
      [530, 636],
      [526, 596],
      [540, 586],
    ]),
    9,
  );
  return t;
}

// ---------- Lámina 3: El sendero (detallada) ----------

Template sendero() {
  final t = Template(1000, 1200, 6);
  t.region('cielo', background(1000, 1200), outlined: false);
  t.region('sol', ellipse(486, 236, 74, 74));
  t.region(
    'niebla',
    blob([
      [150, 330],
      [240, 290],
      [330, 310],
      [420, 280],
      [520, 305],
      [610, 285],
      [700, 310],
      [800, 295],
      [880, 330],
      [800, 372],
      [640, 380],
      [470, 368],
      [300, 380],
      [200, 368],
    ]),
  );

  // Árboles lejanos.
  t.region(
    'tronco-1',
    poly([
      [285, 450],
      [318, 450],
      [330, 660],
      [272, 660],
    ]),
  );
  t.region(
    'copa-1',
    blob([
      [200, 430],
      [232, 362],
      [300, 334],
      [372, 358],
      [410, 428],
      [362, 470],
      [250, 474],
    ]),
  );
  t.region(
    'tronco-2',
    poly([
      [634, 430],
      [668, 430],
      [684, 660],
      [620, 660],
    ]),
  );
  t.region(
    'copa-2',
    blob([
      [530, 400],
      [566, 322],
      [650, 292],
      [736, 326],
      [768, 402],
      [706, 442],
      [592, 446],
    ]),
  );
  t.region(
    'tronco-3',
    poly([
      [852, 520],
      [878, 520],
      [888, 670],
      [842, 670],
    ]),
  );
  t.region(
    'copa-3',
    blob([
      [768, 482],
      [802, 420],
      [868, 406],
      [930, 442],
      [944, 506],
      [868, 536],
      [796, 528],
    ]),
  );

  t.region(
    'colina',
    path(-20, 648, [
      c(200, 596, 400, 626, 520, 616),
      c(700, 604, 850, 636, 1020, 606),
      l(1020, 830),
      l(-20, 830),
    ]),
  );
  t.region(
    'suelo',
    path(-20, 772, [
      c(250, 730, 700, 742, 1020, 760),
      l(1020, 1220),
      l(-20, 1220),
    ]),
  );
  t.region(
    'sendero',
    path(498, 640, [
      c(560, 700, 640, 760, 560, 842),
      c(480, 922, 420, 1000, 520, 1220),
      l(905, 1220),
      c(765, 1040, 722, 940, 762, 860),
      c(802, 780, 640, 700, 548, 640),
    ]),
  );
  t.region('piedra-1', ellipse(680, 1118, 74, 30));
  t.region('piedra-2', ellipse(612, 978, 58, 24));
  t.region('piedra-3', ellipse(668, 866, 46, 19));
  t.region('piedra-4', ellipse(604, 768, 36, 15));

  // Mariposa.
  t.region('mariposa-1', ellipse(770, 262, 36, 26, rot: 35));
  t.region('mariposa-2', ellipse(822, 262, 36, 26, rot: -35));
  t.detail(line(796, 244, 796, 298), 8);

  // Helechos a la derecha.
  t.region('helecho-1', leaf(1010, 830, 800, 660, 44));
  t.detail(line(1010, 830, 800, 660));
  t.region('helecho-2', leaf(1010, 920, 770, 790, 48));
  t.detail(line(1010, 920, 770, 790));
  t.region('helecho-3', leaf(1010, 1020, 800, 930, 46));
  t.detail(line(1010, 1020, 800, 930));

  // Rama superior con hojas colgantes.
  t.region('hoja-colgante-1', leaf(336, 124, 318, 256, 30));
  t.region('hoja-colgante-2', leaf(566, 124, 596, 250, 30));
  t.region('hoja-colgante-3', leaf(726, 126, 706, 244, 28));
  t.region('hoja-colgante-4', leaf(890, 150, 922, 262, 28));
  t.region(
    'rama',
    path(140, 56, [
      c(400, 118, 650, 88, 1020, 150),
      l(1020, 204),
      c(650, 140, 400, 178, 150, 134),
    ]),
  );

  // Árbol grande a la izquierda.
  t.region(
    'tronco-grande',
    path(-20, -20, [
      l(196, -20),
      c(172, 300, 204, 600, 262, 860),
      c(292, 934, 362, 962, 428, 992),
      l(300, 1014),
      c(240, 994, 200, 1004, 160, 1046),
      l(-20, 1046),
    ]),
  );
  t.detail(
    curve([
      [60, 40],
      [50, 300],
      [80, 520],
    ]),
  );
  t.detail(
    curve([
      [120, 700],
      [150, 840],
      [210, 960],
    ]),
  );
  t.detail(
    curve([
      [40, 760],
      [60, 900],
      [50, 1020],
    ]),
  );
  t.region(
    'musgo-tronco',
    path(-20, 566, [
      c(60, 532, 150, 540, 210, 592),
      l(224, 664),
      c(150, 694, 60, 702, -20, 684),
    ]),
  );
  // Bromelia sobre el tronco.
  t.region('bromelia-1', leaf(178, 340, 70, 262, 24));
  t.region('bromelia-5', leaf(182, 340, 300, 276, 24));
  t.region('bromelia-2', leaf(178, 340, 112, 196, 26));
  t.region('bromelia-4', leaf(182, 340, 262, 204, 26));
  t.region('bromelia-3', leaf(180, 344, 186, 172, 28));

  // Rocas.
  t.region(
    'roca-1',
    blob([
      [352, 1094],
      [384, 1040],
      [450, 1024],
      [512, 1052],
      [522, 1104],
      [440, 1124],
    ]),
  );
  t.region(
    'musgo-roca',
    blob([
      [378, 1052],
      [420, 1026],
      [470, 1028],
      [506, 1052],
      [452, 1066],
      [410, 1072],
    ]),
  );

  // Flor junto al sendero.
  t.region('petalo-1', ellipse(440, 838, 22, 22));
  t.region('petalo-2', ellipse(478, 866, 22, 22));
  t.region('petalo-3', ellipse(464, 910, 22, 22));
  t.region('petalo-4', ellipse(416, 910, 22, 22));
  t.region('petalo-5', ellipse(402, 866, 22, 22));
  t.region('centro-flor', ellipse(440, 878, 20, 20));

  // Hojas grandes en primer plano y la rana escondida.
  t.region('hoja-grande-2', leaf(-10, 1130, 214, 872, 78));
  t.detail(line(-10, 1130, 214, 872));
  t.region('hoja-grande-1', leaf(40, 1215, 340, 950, 104));
  t.detail(line(40, 1215, 340, 950));
  t.region('hoja-grande-3', leaf(210, 1225, 480, 1150, 60));
  t.detail(line(210, 1225, 480, 1150));
  t.region('hoja-grande-4', leaf(1010, 1215, 780, 1010, 84));
  t.detail(line(1010, 1215, 780, 1010));
  t.region(
    'roca-2',
    blob([
      [770, 1152],
      [796, 1102],
      [852, 1088],
      [902, 1112],
      [908, 1160],
      [836, 1176],
    ]),
  );
  t.region(
    'rana',
    blob([
      [150, 1092],
      [160, 1050],
      [196, 1024],
      [236, 1008],
      [272, 1016],
      [292, 1044],
      [284, 1070],
      [250, 1092],
      [200, 1104],
    ]),
  );
  t.region('ojo-rana', ellipse(250, 1012, 24, 24));
  t.detail(dot(256, 1012), 18);
  t.detail(
    curve([
      [290, 1052],
      [272, 1062],
      [252, 1060],
    ]),
    5,
  );
  return t;
}

void main() {
  const dir = 'assets/chapters/bosque-nuboso/pages';
  Directory(dir).createSync(recursive: true);
  final pages = {
    'rana-en-la-hoja-v1.json': rana(),
    'quetzal-v1.json': quetzal(),
    'sendero-v1.json': sendero(),
  };
  for (final e in pages.entries) {
    final json = e.value.build();
    final file = File('$dir/${e.key}')..writeAsStringSync(jsonEncode(json));
    stdout.writeln(
      '${e.key}: ${(json['regions'] as List).length} regiones, '
      '${(json['outlines'] as List).length} contornos, '
      '${file.lengthSync()} bytes',
    );
  }
}
