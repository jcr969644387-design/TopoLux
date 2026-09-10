import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../dominio/motor_topografico.dart';
import '../tema.dart';

/// Vista en planta de la labor: eje de diseño contra poligonal calculada.
///
/// Se dibuja con CustomPainter, no con una librería 3D: la planta y el perfil
/// resuelven el objetivo educativo, funcionan sin conexión y se depuran como
/// código Dart normal. El 3D se reevaluará cuando el producto esté validado.
class VistaPlanta extends StatelessWidget {
  final List<Coord> diseno;
  final List<Coord> real;
  final Coord? cierreConocido;
  final bool mostrarDesviacion;
  final double alto;

  const VistaPlanta({
    super.key,
    required this.diseno,
    required this.real,
    this.cierreConocido,
    this.mostrarDesviacion = true,
    this.alto = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: alto,
          decoration: BoxDecoration(
            color: Paleta.papelAlto,
            border: Border.all(color: Paleta.linea),
            borderRadius: BorderRadius.circular(6),
          ),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 12,
            child: CustomPaint(
              size: Size.infinite,
              painter: _PintorPlanta(
                diseno: diseno,
                real: real,
                cierreConocido: cierreConocido,
                mostrarDesviacion: mostrarDesviacion,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 16, runSpacing: 4, children: const [
          _Leyenda(color: Paleta.diseno, texto: 'Eje de diseño', punteado: true),
          _Leyenda(color: Paleta.real, texto: 'Levantamiento calculado'),
          _Leyenda(color: Paleta.control, texto: 'Punto de control conocido'),
        ]),
        const SizedBox(height: 4),
        Text('Pellizca para acercar. La desviación en el punto de cierre suele '
            'ser invisible a escala completa.',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;
  final bool punteado;

  const _Leyenda({required this.color, required this.texto, this.punteado = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(22, 8), painter: _PintorLeyenda(color, punteado)),
        const SizedBox(width: 6),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PintorLeyenda extends CustomPainter {
  final Color color;
  final bool punteado;
  _PintorLeyenda(this.color, this.punteado);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2;
    final y = size.height / 2;
    if (punteado) {
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
        x += 7;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PintorPlanta extends CustomPainter {
  final List<Coord> diseno;
  final List<Coord> real;
  final Coord? cierreConocido;
  final bool mostrarDesviacion;

  _PintorPlanta({
    required this.diseno,
    required this.real,
    required this.cierreConocido,
    required this.mostrarDesviacion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final todos = <Coord>[...diseno, ...real, if (cierreConocido != null) cierreConocido!];
    if (todos.isEmpty) return;

    var minN = todos.first.norte, maxN = todos.first.norte;
    var minE = todos.first.este, maxE = todos.first.este;
    for (final p in todos) {
      minN = math.min(minN, p.norte);
      maxN = math.max(maxN, p.norte);
      minE = math.min(minE, p.este);
      maxE = math.max(maxE, p.este);
    }
    final anchoM = math.max(maxE - minE, 1.0);
    final altoM = math.max(maxN - minN, 1.0);
    const margen = 34.0;
    final escala = math.min(
      (size.width - 2 * margen) / anchoM,
      (size.height - 2 * margen) / altoM,
    );
    final despX = (size.width - anchoM * escala) / 2;
    final despY = (size.height - altoM * escala) / 2;

    Offset aPantalla(Coord p) => Offset(
          despX + (p.este - minE) * escala,
          size.height - despY - (p.norte - minN) * escala,
        );

    _reticula(canvas, size);

    // Eje de diseño (punteado).
    _polilinea(canvas, diseno.map(aPantalla).toList(),
        Paleta.diseno, 2.0, punteado: true);

    // Levantamiento calculado.
    final ptsReal = real.map(aPantalla).toList();
    _polilinea(canvas, ptsReal, Paleta.real, 2.4);

    final punto = Paint()..color = Paleta.real;
    for (final o in ptsReal) {
      canvas.drawCircle(o, 3.4, punto);
    }

    // Punto de control conocido y desviación.
    if (cierreConocido != null) {
      final c = aPantalla(cierreConocido!);
      final marco = Paint()
        ..color = Paleta.control
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(Rect.fromCenter(center: c, width: 11, height: 11), marco);
      canvas.drawLine(Offset(c.dx - 8, c.dy), Offset(c.dx + 8, c.dy), marco);
      canvas.drawLine(Offset(c.dx, c.dy - 8), Offset(c.dx, c.dy + 8), marco);

      if (mostrarDesviacion && ptsReal.isNotEmpty) {
        final f = ptsReal.last;
        if ((f - c).distance > 1.5) {
          _polilinea(canvas, [c, f], Paleta.laton, 1.6, punteado: true);
        }
      }
    }

    _escala(canvas, size, escala);
    _norte(canvas, size);
  }

  void _reticula(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Paleta.linea.withValues(alpha: 0.55)
      ..strokeWidth = 0.6;
    const paso = 28.0;
    for (var x = 0.0; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _polilinea(Canvas canvas, List<Offset> pts, Color color, double grosor,
      {bool punteado = false}) {
    if (pts.length < 2) return;
    final p = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < pts.length - 1; i++) {
      if (punteado) {
        _segmentoPunteado(canvas, pts[i], pts[i + 1], p);
      } else {
        canvas.drawLine(pts[i], pts[i + 1], p);
      }
    }
  }

  void _segmentoPunteado(Canvas canvas, Offset a, Offset b, Paint p) {
    const trazo = 6.0, hueco = 5.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final fin = math.min(d + trazo, total);
      canvas.drawLine(a + dir * d, a + dir * fin, p);
      d = fin + hueco;
    }
  }

  void _escala(Canvas canvas, Size size, double escala) {
    final metros = _metrosRedondos(80 / escala);
    final px = metros * escala;
    final y = size.height - 16;
    final p = Paint()
      ..color = Paleta.grafito
      ..strokeWidth = 2;
    canvas.drawLine(Offset(14, y), Offset(14 + px, y), p);
    canvas.drawLine(Offset(14, y - 4), Offset(14, y + 4), p);
    canvas.drawLine(Offset(14 + px, y - 4), Offset(14 + px, y + 4), p);
    _texto(canvas, '${metros.toStringAsFixed(metros < 1 ? 2 : 0)} m',
        Offset(14, y - 20), 11);
  }

  double _metrosRedondos(double aprox) {
    const opciones = [0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10, 20, 25, 50, 100, 200];
    for (final o in opciones) {
      if (aprox <= o) return o.toDouble();
    }
    return 500;
  }

  void _norte(Canvas canvas, Size size) {
    final x = size.width - 22;
    final p = Paint()
      ..color = Paleta.grafito
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x, 40), Offset(x, 16), p);
    canvas.drawLine(Offset(x, 16), Offset(x - 4, 23), p);
    canvas.drawLine(Offset(x, 16), Offset(x + 4, 23), p);
    _texto(canvas, 'N', Offset(x - 4, 42), 11);
  }

  void _texto(Canvas canvas, String s, Offset o, double tam) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
            fontFamily: 'monospace', fontSize: tam, color: Paleta.grafito),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _PintorPlanta old) =>
      old.real != real || old.diseno != diseno;
}
