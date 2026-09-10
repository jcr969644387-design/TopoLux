import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema.dart';

/// Marca de TopoLux: retícula de control con el punto de control en latón.
///
/// Es el mismo dibujo que el icono del lanzador (android/app/src/main/res),
/// redibujado con el pintor de Flutter para que dentro de la aplicación se
/// adapte al tamaño y al color de cada sitio donde aparece. Las proporciones
/// están tomadas del icono para que ambos se lean como la misma marca.
class LogoTopoLux extends StatelessWidget {
  final double tam;
  final Color trazo;
  final Color punto;

  const LogoTopoLux({
    super.key,
    this.tam = 28,
    this.trazo = Paleta.tinta,
    this.punto = Paleta.laton,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tam,
      height: tam,
      child: CustomPaint(painter: _PintorLogo(trazo, punto)),
    );
  }
}

class _PintorLogo extends CustomPainter {
  final Color trazo;
  final Color punto;

  _PintorLogo(this.trazo, this.punto);

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);

    final lapiz = Paint()
      ..color = trazo
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 0.06
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawCircle(c, u * 0.29, lapiz);

    const direcciones = [
      Offset(0, -1),
      Offset(0, 1),
      Offset(-1, 0),
      Offset(1, 0),
    ];
    for (final d in direcciones) {
      canvas.drawLine(c + d * (u * 0.345), c + d * (u * 0.452), lapiz);
    }

    final triangulo = Path()
      ..moveTo(c.dx, c.dy - u * 0.138)
      ..lineTo(c.dx + u * 0.142, c.dy + u * 0.098)
      ..lineTo(c.dx - u * 0.142, c.dy + u * 0.098)
      ..close();
    canvas.drawPath(
      triangulo,
      Paint()
        ..color = punto
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorLogo anterior) =>
      anterior.trazo != trazo || anterior.punto != punto;
}

/// Marca completa: logotipo y nombre. El nombre se escribe siempre TopoLux.
class MarcaTopoLux extends StatelessWidget {
  final double tamLogo;
  final double tamTexto;
  final Color trazo;
  final Color punto;

  const MarcaTopoLux({
    super.key,
    this.tamLogo = 24,
    this.tamTexto = 19,
    this.trazo = Paleta.sobreTinta,
    this.punto = Paleta.latonClaro,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoTopoLux(tam: tamLogo, trazo: trazo, punto: punto),
        SizedBox(width: tamLogo * 0.36),
        Flexible(
          child: Text(
            'TopoLux',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tamTexto,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: trazo,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pantalla de espera mientras se leen los casos.
///
/// Va en tinta, no en blanco: enlaza con la pantalla de arranque de Android,
/// que usa ese mismo color, de modo que al abrir la app no hay un destello
/// blanco entre una y otra.
class PantallaCarga extends StatelessWidget {
  final String mensaje;

  const PantallaCarga({super.key, this.mensaje = 'Abriendo la libreta…'});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Paleta.tinta,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LogoTopoLux(
                    tam: 68,
                    trazo: Paleta.sobreTinta,
                    punto: Paleta.latonClaro,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TopoLux',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Paleta.sobreTinta,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mensaje,
                    textAlign: TextAlign.center,
                    style: cifraPequenaClara.copyWith(
                      color: Paleta.sobreTinta.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Paleta.latonClaro,
                      backgroundColor: Paleta.tintaSuave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
