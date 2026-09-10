import 'motor_topografico.dart';

enum TipoEjercicio { poligonalAbierta, sobrerotura, replanteo }

TipoEjercicio _tipoDesde(String s) {
  switch (s) {
    case 'sobrerotura':
      return TipoEjercicio.sobrerotura;
    case 'replanteo':
      return TipoEjercicio.replanteo;
    default:
      return TipoEjercicio.poligonalAbierta;
  }
}

enum Andamiaje { alto, medio, bajo }

Andamiaje _andamiajeDesde(String s) {
  switch (s) {
    case 'alto':
      return Andamiaje.alto;
    case 'medio':
      return Andamiaje.medio;
    default:
      return Andamiaje.bajo;
  }
}

/// Las cuatro acciones posibles del topógrafo ante un levantamiento.
enum Decision { aceptar, compensar, repetir, escalar }

const Map<Decision, String> etiquetaDecision = {
  Decision.aceptar: 'Aceptar',
  Decision.compensar: 'Compensar',
  Decision.repetir: 'Repetir',
  Decision.escalar: 'Escalar',
};

const Map<Decision, String> descripcionDecision = {
  Decision.aceptar: 'Entregar las coordenadas tal como se calcularon.',
  Decision.compensar: 'Repartir el residuo entre los tramos y entregar.',
  Decision.repetir: 'Devolver a campo para reobservar el trabajo.',
  Decision.escalar: 'Informar al jefe de topografía antes de usar el trabajo.',
};

Decision decisionDesde(String s) => Decision.values.firstWhere(
      (d) => d.name == s,
      orElse: () => Decision.aceptar,
    );

class Tolerancia {
  final double? angularSeg;
  final double? linealM;
  final double? cotaM;
  final double? sobreroturaM;
  final int? denominador;
  final int? nAngulos;
  final String fuente;

  const Tolerancia({
    this.angularSeg,
    this.linealM,
    this.cotaM,
    this.sobreroturaM,
    this.denominador,
    this.nAngulos,
    this.fuente = '',
  });

  factory Tolerancia.desdeJson(Map<String, dynamic> j) => Tolerancia(
        angularSeg: (j['angular_seg'] as num?)?.toDouble(),
        linealM: (j['lineal_m'] as num?)?.toDouble(),
        cotaM: (j['cota_m'] as num?)?.toDouble(),
        sobreroturaM: (j['sobrerotura_m'] as num?)?.toDouble(),
        denominador: (j['denominador'] as num?)?.toInt(),
        nAngulos: (j['n_angulos'] as num?)?.toInt(),
        fuente: (j['fuente'] ?? '') as String,
      );
}

class Justificacion {
  final String id;
  final String texto;
  final bool correcta;
  final String? tipoDistractor;

  const Justificacion({
    required this.id,
    required this.texto,
    required this.correcta,
    this.tipoDistractor,
  });

  factory Justificacion.desdeJson(Map<String, dynamic> j) => Justificacion(
        id: j['id'] as String,
        texto: j['texto'] as String,
        correcta: j['correcta'] as bool,
        tipoDistractor: j['tipo_distractor'] as String?,
      );
}

class TextoConsecuencia {
  final String texto;
  final String impacto;
  const TextoConsecuencia(this.texto, this.impacto);
}

class DiagnosticoCaso {
  final String queHabia;
  final String porQue;
  final String comoDetectar;

  const DiagnosticoCaso({
    required this.queHabia,
    required this.porQue,
    required this.comoDetectar,
  });
}

class SeccionProgresiva {
  final double progresiva;
  final double areaReal;
  const SeccionProgresiva(this.progresiva, this.areaReal);
}

class DatosSobrerotura {
  final double areaDiseno;
  final double perimetroSeccion;
  final double anchoDiseno;
  final double altoDiseno;
  final List<SeccionProgresiva> progresivas;
  final List<String> observaciones;

  const DatosSobrerotura({
    required this.areaDiseno,
    required this.perimetroSeccion,
    required this.anchoDiseno,
    required this.altoDiseno,
    required this.progresivas,
    required this.observaciones,
  });
}

class DatosReplanteo {
  final Coord estacion;
  final Coord referencia;
  final Coord objetivo;
  final double alturaInstrumento;
  final double alturaPrisma;
  final List<String> observaciones;

  const DatosReplanteo({
    required this.estacion,
    required this.referencia,
    required this.objetivo,
    required this.alturaInstrumento,
    required this.alturaPrisma,
    required this.observaciones,
  });
}

/// Un caso completo, tal como lo produce tool/generar_casos.py
class Caso {
  final String id;
  final String titulo;
  final String bloque;
  final int orden;
  final TipoEjercicio tipo;
  final Andamiaje andamiaje;

  final String labor;
  final String solicitante;
  final String contexto;
  final String objetivo;

  final Tolerancia tolerancia;

  final Coord? arranque;
  final Coord? orientacion;
  final Coord? cierreConocido;
  final double? azimutCierreReferencia;
  final String idReferenciaCierre;

  final List<FilaLibreta> libreta;
  final List<Coord> ejeDiseno;

  final DatosSobrerotura? sobrerotura;
  final DatosReplanteo? replanteo;

  final String tipoErrorInducido;
  final String diagnosticoEsperado;
  final String? estacionAfectada;
  final String anomalia;

  final Map<String, dynamic> solucionReferencia;

  final Decision decisionCorrecta;
  final List<Justificacion> justificaciones;
  final Map<Decision, TextoConsecuencia> consecuencias;
  final DiagnosticoCaso diagnostico;

  const Caso({
    required this.id,
    required this.titulo,
    required this.bloque,
    required this.orden,
    required this.tipo,
    required this.andamiaje,
    required this.labor,
    required this.solicitante,
    required this.contexto,
    required this.objetivo,
    required this.tolerancia,
    required this.arranque,
    required this.orientacion,
    required this.cierreConocido,
    required this.azimutCierreReferencia,
    required this.idReferenciaCierre,
    required this.libreta,
    required this.ejeDiseno,
    required this.sobrerotura,
    required this.replanteo,
    required this.tipoErrorInducido,
    required this.diagnosticoEsperado,
    required this.estacionAfectada,
    required this.anomalia,
    required this.solucionReferencia,
    required this.decisionCorrecta,
    required this.justificaciones,
    required this.consecuencias,
    required this.diagnostico,
  });

  bool get tieneErrorInducido => tipoErrorInducido != 'ninguno';

  factory Caso.desdeJson(Map<String, dynamic> j) {
    final ident = j['identificacion'] as Map<String, dynamic>;
    final enc = j['encargo'] as Map<String, dynamic>;
    final par = j['parametros'] as Map<String, dynamic>;
    final ctrl = j['control'] as Map<String, dynamic>?;
    final err = (j['error_inducido'] ?? const {}) as Map<String, dynamic>;
    final firma = (err['firma'] ?? const {}) as Map<String, dynamic>;
    final dec = j['decision'] as Map<String, dynamic>;
    final cons = j['consecuencia'] as Map<String, dynamic>;
    final diag = j['diagnostico'] as Map<String, dynamic>;

    final consecuencias = <Decision, TextoConsecuencia>{};
    for (final d in Decision.values) {
      final c = cons[d.name] as Map<String, dynamic>?;
      if (c != null) {
        consecuencias[d] =
            TextoConsecuencia(c['texto'] as String, (c['impacto'] ?? '') as String);
      }
    }

    DatosSobrerotura? sob;
    if (j['secciones'] != null) {
      final s = j['secciones'] as Map<String, dynamic>;
      final sd = s['seccion_diseno'] as Map<String, dynamic>;
      sob = DatosSobrerotura(
        areaDiseno: (sd['area_m2'] as num).toDouble(),
        perimetroSeccion: (sd['perimetro_m'] as num).toDouble(),
        anchoDiseno: (sd['ancho_m'] as num).toDouble(),
        altoDiseno: (sd['alto_m'] as num).toDouble(),
        progresivas: (s['progresivas'] as List)
            .map((e) => SeccionProgresiva(
                  (e['progresiva_m'] as num).toDouble(),
                  (e['area_real_m2'] as num).toDouble(),
                ))
            .toList(),
        observaciones:
            ((s['observaciones'] ?? const []) as List).cast<String>().toList(),
      );
    }

    DatosReplanteo? rep;
    if (j['replanteo'] != null) {
      final r = j['replanteo'] as Map<String, dynamic>;
      final alt = r['alturas'] as Map<String, dynamic>;
      rep = DatosReplanteo(
        estacion: Coord.desdeJson(r['estacion'] as Map<String, dynamic>),
        referencia: Coord.desdeJson(r['referencia'] as Map<String, dynamic>),
        objetivo: Coord.desdeJson(r['objetivo'] as Map<String, dynamic>),
        alturaInstrumento: (alt['instrumento'] as num).toDouble(),
        alturaPrisma: (alt['prisma'] as num).toDouble(),
        observaciones:
            ((r['observaciones'] ?? const []) as List).cast<String>().toList(),
      );
    }

    return Caso(
      id: ident['id'] as String,
      titulo: ident['titulo'] as String,
      bloque: ident['bloque'] as String,
      orden: (ident['orden'] as num).toInt(),
      tipo: _tipoDesde(ident['tipo_ejercicio'] as String),
      andamiaje: _andamiajeDesde(ident['andamiaje'] as String),
      labor: enc['labor'] as String,
      solicitante: (enc['solicitante'] ?? '') as String,
      contexto: enc['contexto'] as String,
      objetivo: enc['objetivo'] as String,
      tolerancia:
          Tolerancia.desdeJson((par['tolerancia'] ?? const {}) as Map<String, dynamic>),
      arranque: ctrl == null
          ? null
          : Coord.desdeJson(ctrl['punto_arranque'] as Map<String, dynamic>),
      orientacion: ctrl == null
          ? null
          : Coord.desdeJson(ctrl['punto_orientacion'] as Map<String, dynamic>),
      cierreConocido: ctrl == null
          ? null
          : Coord.desdeJson(ctrl['punto_cierre'] as Map<String, dynamic>),
      azimutCierreReferencia: ctrl == null
          ? null
          : ((ctrl['referencia_cierre'] as Map<String, dynamic>)['azimut'] as num)
              .toDouble(),
      idReferenciaCierre: ctrl == null
          ? ''
          : ((ctrl['referencia_cierre'] as Map<String, dynamic>)['id'] ?? '') as String,
      libreta: j['libreta'] == null
          ? const []
          : ((j['libreta'] as Map<String, dynamic>)['estaciones'] as List)
              .map((e) => FilaLibreta.desdeJson(e as Map<String, dynamic>))
              .toList(),
      ejeDiseno: j['diseno'] == null
          ? const []
          : ((j['diseno'] as Map<String, dynamic>)['eje'] as List)
              .map((e) => Coord.desdeJson(e as Map<String, dynamic>))
              .toList(),
      sobrerotura: sob,
      replanteo: rep,
      tipoErrorInducido: (err['tipo'] ?? 'ninguno') as String,
      diagnosticoEsperado:
          (err['diagnostico_esperado'] ?? err['tipo'] ?? 'ninguno') as String,
      estacionAfectada: err['estacion'] as String?,
      anomalia: (firma['anomalia'] ?? 'ninguna') as String,
      solucionReferencia:
          (j['solucion_referencia'] ?? const <String, dynamic>{}) as Map<String, dynamic>,
      decisionCorrecta: decisionDesde(dec['correcta'] as String),
      justificaciones: (dec['justificaciones'] as List)
          .map((e) => Justificacion.desdeJson(e as Map<String, dynamic>))
          .toList(),
      consecuencias: consecuencias,
      diagnostico: DiagnosticoCaso(
        queHabia: diag['que_habia'] as String,
        porQue: diag['por_que'] as String,
        comoDetectar: diag['como_detectar'] as String,
      ),
    );
  }
}

/// Entrada del índice de casos.
class ResumenCaso {
  final String id;
  final String titulo;
  final String bloque;
  final int orden;
  final String tipo;
  final String andamiaje;
  final String tipoError;

  const ResumenCaso({
    required this.id,
    required this.titulo,
    required this.bloque,
    required this.orden,
    required this.tipo,
    required this.andamiaje,
    required this.tipoError,
  });

  factory ResumenCaso.desdeJson(Map<String, dynamic> j) => ResumenCaso(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        bloque: j['bloque'] as String,
        orden: (j['orden'] as num).toInt(),
        tipo: j['tipo_ejercicio'] as String,
        andamiaje: j['andamiaje'] as String,
        tipoError: (j['error'] ?? 'ninguno') as String,
      );
}

const Map<String, String> nombreBloque = {
  'A': 'Fundamentos',
  'B': 'Detección',
  'C': 'Decisión',
  'D': 'Aplicación',
};
