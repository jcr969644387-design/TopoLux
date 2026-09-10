import 'dart:math' as math;

/// Motor topográfico — dominio puro.
///
/// NO importa flutter/material.dart a propósito: esto permite probar toda la
/// matemática con `flutter test` sin levantar interfaz, que es la defensa
/// principal contra el riesgo de que la aplicación enseñe cálculos erróneos.
///
/// Convenciones (idénticas a tool/topo.py, la fuente de verdad usada para
/// generar los casos):
///   - Ángulos en grados decimales.
///   - Azimut desde el Norte, horario, normalizado a [0, 360).
///   - Ángulo horizontal horario desde el punto de atrás al punto de adelante.
///   - Ángulo cenital desde el cenit (90 grados = visual horizontal).
///   - Norte = Y, Este = X.

const double _radianes = math.pi / 180.0;

double norm360(double a) {
  final r = a % 360.0;
  return r < 0 ? r + 360.0 : r;
}

double norm180(double a) {
  final r = norm360(a);
  return r > 180.0 ? r - 360.0 : r;
}

double gradosARadianes(double g) => g * _radianes;

/// Formatea grados decimales como GG°MM'SS.SS".
String formatoGms(double grados, {int decimales = 2}) {
  final signo = grados < 0 ? '-' : '';
  var g = grados.abs();
  var d = g.floor();
  var mf = (g - d) * 60.0;
  var m = mf.floor();
  var s = (mf - m) * 60.0;
  if (double.parse(s.toStringAsFixed(decimales)) >= 60.0) {
    s -= 60.0;
    m += 1;
  }
  if (m >= 60) {
    m -= 60;
    d += 1;
  }
  final ss = s.toStringAsFixed(decimales).padLeft(decimales + 3, '0');
  return "$signo$d°${m.toString().padLeft(2, '0')}'$ss\"";
}

/// Convierte grados, minutos y segundos a grados decimales.
double gmsAGrados(int g, int m, double s) => g + m / 60.0 + s / 3600.0;

class Coord {
  final String id;
  final double norte;
  final double este;
  final double cota;

  const Coord({
    this.id = '',
    required this.norte,
    required this.este,
    required this.cota,
  });

  factory Coord.desdeJson(Map<String, dynamic> j) => Coord(
        id: (j['id'] ?? '') as String,
        norte: (j['norte'] as num).toDouble(),
        este: (j['este'] as num).toDouble(),
        cota: (j['cota'] as num).toDouble(),
      );

  Coord copiaCon({String? id, double? norte, double? este, double? cota}) => Coord(
        id: id ?? this.id,
        norte: norte ?? this.norte,
        este: este ?? this.este,
        cota: cota ?? this.cota,
      );
}

double azimut(Coord desde, Coord hacia) {
  final dn = hacia.norte - desde.norte;
  final de = hacia.este - desde.este;
  return norm360(math.atan2(de, dn) / _radianes);
}

double distanciaHorizontal(Coord a, Coord b) {
  final dn = b.norte - a.norte;
  final de = b.este - a.este;
  return math.sqrt(dn * dn + de * de);
}

/// Una fila de la libreta de campo tal como la anotó la brigada.
class FilaLibreta {
  final String estacion;
  final String puntoAtras;
  final String puntoVisado;
  final double anguloHorizontal;
  final double? anguloCenital;
  final double? distanciaInclinada;
  final double? alturaInstrumento;
  final double? alturaPrisma;
  final String observaciones;

  const FilaLibreta({
    required this.estacion,
    required this.puntoAtras,
    required this.puntoVisado,
    required this.anguloHorizontal,
    this.anguloCenital,
    this.distanciaInclinada,
    this.alturaInstrumento,
    this.alturaPrisma,
    this.observaciones = '',
  });

  bool get esVisualDeCierre => distanciaInclinada == null;

  factory FilaLibreta.desdeJson(Map<String, dynamic> j) => FilaLibreta(
        estacion: j['estacion'] as String,
        puntoAtras: j['punto_atras'] as String,
        puntoVisado: j['punto_visado'] as String,
        anguloHorizontal: (j['angulo_horizontal'] as num).toDouble(),
        anguloCenital: (j['angulo_cenital'] as num?)?.toDouble(),
        distanciaInclinada: (j['distancia_inclinada'] as num?)?.toDouble(),
        alturaInstrumento: (j['altura_instrumento'] as num?)?.toDouble(),
        alturaPrisma: (j['altura_prisma'] as num?)?.toDouble(),
        observaciones: (j['observaciones'] ?? '') as String,
      );
}

/// Resultado del cálculo de un tramo.
class TramoCalculado {
  final int indice;
  final String desde;
  final String hasta;
  final double azimutAtras;
  final double azimut;
  final double distanciaHorizontal;
  final double desnivel;
  final Coord punto;

  const TramoCalculado({
    required this.indice,
    required this.desde,
    required this.hasta,
    required this.azimutAtras,
    required this.azimut,
    required this.distanciaHorizontal,
    required this.desnivel,
    required this.punto,
  });
}

class ResultadoPoligonal {
  final List<Coord> puntos;
  final List<TramoCalculado> tramos;
  final double perimetro;
  final double azimutCierreCalculado;
  final double errorAngularSegundos;
  final double errorLinealM;
  final double errorNorteM;
  final double errorEsteM;
  final double errorCotaM;
  final double? relacionCierre;

  const ResultadoPoligonal({
    required this.puntos,
    required this.tramos,
    required this.perimetro,
    required this.azimutCierreCalculado,
    required this.errorAngularSegundos,
    required this.errorLinealM,
    required this.errorNorteM,
    required this.errorEsteM,
    required this.errorCotaM,
    required this.relacionCierre,
  });

  Coord get puntoFinal => puntos.last;
}

/// Compensación por el método de Bowditch (proporcional a la longitud).
List<Coord> compensarBowditch(ResultadoPoligonal r) {
  if (r.perimetro <= 0) return r.puntos;
  var acumulada = 0.0;
  final salida = <Coord>[r.puntos.first];
  for (var i = 0; i < r.tramos.length; i++) {
    acumulada += r.tramos[i].distanciaHorizontal;
    final f = acumulada / r.perimetro;
    final p = r.puntos[i + 1];
    salida.add(Coord(
      id: p.id,
      norte: p.norte - r.errorNorteM * f,
      este: p.este - r.errorEsteM * f,
      cota: p.cota - r.errorCotaM * f,
    ));
  }
  return salida;
}

class MotorTopografico {
  /// Resuelve una poligonal abierta con comprobación sobre punto conocido.
  static ResultadoPoligonal resolverPoligonal({
    required Coord arranque,
    required Coord orientacion,
    required List<FilaLibreta> filas,
    required double azimutCierreReferencia,
    required Coord cierreConocido,
  }) {
    final puntos = <Coord>[arranque];
    final tramos = <TramoCalculado>[];
    var azAtras = azimut(arranque, orientacion);
    var perimetro = 0.0;

    final nTramos = filas.length - 1;
    for (var i = 0; i < nTramos; i++) {
      final f = filas[i];
      final azTramo = norm360(azAtras + f.anguloHorizontal);
      final z = f.anguloCenital!;
      final sd = f.distanciaInclinada!;
      final dh = sd * math.sin(gradosARadianes(z));
      final dv = sd * math.cos(gradosARadianes(z)) +
          (f.alturaInstrumento ?? 0) -
          (f.alturaPrisma ?? 0);

      final actual = puntos.last;
      final nuevo = Coord(
        id: f.puntoVisado,
        norte: actual.norte + dh * math.cos(gradosARadianes(azTramo)),
        este: actual.este + dh * math.sin(gradosARadianes(azTramo)),
        cota: actual.cota + dv,
      );
      puntos.add(nuevo);
      perimetro += dh;
      tramos.add(TramoCalculado(
        indice: i,
        desde: f.estacion,
        hasta: f.puntoVisado,
        azimutAtras: azAtras,
        azimut: azTramo,
        distanciaHorizontal: dh,
        desnivel: dv,
        punto: nuevo,
      ));
      azAtras = norm360(azTramo + 180.0);
    }

    final azCierre = norm360(azAtras + filas.last.anguloHorizontal);
    final errAng = norm180(azCierre - azimutCierreReferencia) * 3600.0;

    final fin = puntos.last;
    final dN = fin.norte - cierreConocido.norte;
    final dE = fin.este - cierreConocido.este;
    final dC = fin.cota - cierreConocido.cota;
    final errLin = math.sqrt(dN * dN + dE * dE);

    return ResultadoPoligonal(
      puntos: puntos,
      tramos: tramos,
      perimetro: perimetro,
      azimutCierreCalculado: azCierre,
      errorAngularSegundos: errAng,
      errorLinealM: errLin,
      errorNorteM: dN,
      errorEsteM: dE,
      errorCotaM: dC,
      relacionCierre: errLin > 1e-9 ? perimetro / errLin : null,
    );
  }

  /// Volumen por el método de áreas medias.
  static double volumenAreasMedias(List<({double progresiva, double area})> s) {
    var v = 0.0;
    for (var i = 0; i < s.length - 1; i++) {
      v += (s[i].area + s[i + 1].area) / 2.0 * (s[i + 1].progresiva - s[i].progresiva);
    }
    return v;
  }

  /// Problema inverso: datos de replanteo desde una estación a un punto.
  static ({
    double azimutReferencia,
    double azimutObjetivo,
    double anguloAGirar,
    double distanciaHorizontal,
    double desnivel,
    double anguloCenital,
  }) resolverReplanteo({
    required Coord estacion,
    required Coord referencia,
    required Coord objetivo,
    required double alturaInstrumento,
    required double alturaPrisma,
  }) {
    final azRef = azimut(estacion, referencia);
    final azObj = azimut(estacion, objetivo);
    final dh = distanciaHorizontal(estacion, objetivo);
    final v = (objetivo.cota + alturaPrisma) - (estacion.cota + alturaInstrumento);
    return (
      azimutReferencia: azRef,
      azimutObjetivo: azObj,
      anguloAGirar: norm360(azObj - azRef),
      distanciaHorizontal: dh,
      desnivel: objetivo.cota - estacion.cota,
      anguloCenital: math.atan2(dh, v) / _radianes,
    );
  }
}
