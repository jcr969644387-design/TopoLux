import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/modelos.dart';

/// Acceso a los casos empaquetados en assets/casos/. Sólo lectura.
class RepositorioCasos {
  static const _rutaIndice = 'assets/casos/indice.json';
  List<ResumenCaso>? _indice;
  final Map<String, Caso> _cache = {};

  Future<List<ResumenCaso>> indice() async {
    if (_indice != null) return _indice!;
    final texto = await rootBundle.loadString(_rutaIndice);
    final j = json.decode(texto) as Map<String, dynamic>;
    final lista = (j['casos'] as List)
        .map((e) => ResumenCaso.desdeJson(e as Map<String, dynamic>))
        .toList();
    lista.sort((a, b) => a.orden.compareTo(b.orden));
    _indice = lista;
    return lista;
  }

  Future<Caso> cargar(String id) async {
    final enCache = _cache[id];
    if (enCache != null) return enCache;
    final texto = await rootBundle.loadString('assets/casos/$id.json');
    final caso = Caso.desdeJson(json.decode(texto) as Map<String, dynamic>);
    _cache[id] = caso;
    return caso;
  }
}

/// Resultado registrado de un intento sobre un caso.
class IntentoCaso {
  final String casoId;
  final String tipoError;
  final bool deteccionCorrecta;
  final bool diagnosticoCorrecto;
  final bool decisionCorrecta;
  final bool justificacionCorrecta;
  final int ayudasUsadas;
  final String fecha;

  const IntentoCaso({
    required this.casoId,
    required this.tipoError,
    required this.deteccionCorrecta,
    required this.diagnosticoCorrecto,
    required this.decisionCorrecta,
    required this.justificacionCorrecta,
    required this.ayudasUsadas,
    required this.fecha,
  });

  Map<String, dynamic> aJson() => {
        'caso_id': casoId,
        'tipo_error': tipoError,
        'deteccion': deteccionCorrecta,
        'diagnostico': diagnosticoCorrecto,
        'decision': decisionCorrecta,
        'justificacion': justificacionCorrecta,
        'ayudas': ayudasUsadas,
        'fecha': fecha,
      };

  factory IntentoCaso.desdeJson(Map<String, dynamic> j) => IntentoCaso(
        casoId: j['caso_id'] as String,
        tipoError: (j['tipo_error'] ?? 'ninguno') as String,
        deteccionCorrecta: j['deteccion'] as bool,
        diagnosticoCorrecto: j['diagnostico'] as bool,
        decisionCorrecta: j['decision'] as bool,
        justificacionCorrecta: j['justificacion'] as bool,
        ayudasUsadas: (j['ayudas'] as num?)?.toInt() ?? 0,
        fecha: (j['fecha'] ?? '') as String,
      );
}

/// Progreso local del estudiante. Sin cuentas, sin red, sin datos personales.
class RepositorioProgreso {
  static const _claveIntentos = 'topolux_intentos_v1';
  static const _claveParticipante = 'topolux_participante_v1';
  static const _claveSesion = 'topolux_sesion_v1';

  List<IntentoCaso> _intentos = [];
  String _participante = '';

  List<IntentoCaso> get intentos => List.unmodifiable(_intentos);
  String get participante => _participante;

  Future<void> cargar() async {
    final p = await SharedPreferences.getInstance();
    final crudo = p.getString(_claveIntentos);
    if (crudo != null) {
      _intentos = (json.decode(crudo) as List)
          .map((e) => IntentoCaso.desdeJson(e as Map<String, dynamic>))
          .toList();
    }
    _participante = p.getString(_claveParticipante) ?? '';
    if (_participante.isEmpty) {
      _participante = _generarCodigo();
      await p.setString(_claveParticipante, _participante);
    }
  }

  static String _generarCodigo() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final ms = DateTime.now().microsecondsSinceEpoch;
    final a = letras[(ms ~/ 7) % letras.length];
    final b = letras[(ms ~/ 131) % letras.length];
    final n = (ms % 10000).toString().padLeft(4, '0');
    return 'TPX-$a$b$n';
  }

  Future<void> registrar(IntentoCaso i) async {
    _intentos.add(i);
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _claveIntentos,
      json.encode(_intentos.map((e) => e.aJson()).toList()),
    );
  }

  Future<void> reiniciar() async {
    _intentos = [];
    final p = await SharedPreferences.getInstance();
    await p.remove(_claveIntentos);
    await p.remove(_claveSesion);
  }

  /// Exportación anónima para el pilotaje. No incluye ningún dato personal.
  String exportarJson() => const JsonEncoder.withIndent('  ').convert({
        'participante': _participante,
        'exportado': DateTime.now().toIso8601String(),
        'version': 1,
        'intentos': _intentos.map((e) => e.aJson()).toList(),
      });

  bool completado(String casoId) => _intentos.any((i) => i.casoId == casoId);

  IntentoCaso? mejorIntento(String casoId) {
    final propios = _intentos.where((i) => i.casoId == casoId).toList();
    if (propios.isEmpty) return null;
    propios.sort((a, b) => _puntos(b).compareTo(_puntos(a)));
    return propios.first;
  }

  static int _puntos(IntentoCaso i) =>
      (i.deteccionCorrecta ? 1 : 0) +
      (i.diagnosticoCorrecto ? 1 : 0) +
      (i.decisionCorrecta ? 1 : 0) +
      (i.justificacionCorrecta ? 1 : 0);
}
