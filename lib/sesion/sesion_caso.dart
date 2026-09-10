import 'package:flutter/foundation.dart';

import '../datos/repositorios.dart';
import '../dominio/catalogo_errores.dart';
import '../dominio/modelos.dart';
import '../dominio/motor_topografico.dart';

/// Los ocho pasos del ciclo de aprendizaje.
///
/// El orden es una invariante pedagógica, no sólo de navegación:
///   - la app no revela que hay un error antes de [veredicto];
///   - la [consecuencia] precede siempre a la [explicacion].
/// Por eso las transiciones están controladas aquí y no en los widgets.
enum PasoCaso {
  encargo,
  libreta,
  calculo,
  cierre,
  veredicto,
  decision,
  consecuencia,
  explicacion,
  resumen,
}

const Map<PasoCaso, String> tituloPaso = {
  PasoCaso.encargo: 'Encargo',
  PasoCaso.libreta: 'Libreta de campo',
  PasoCaso.calculo: 'Cálculo',
  PasoCaso.cierre: 'Verificación',
  PasoCaso.veredicto: 'Veredicto',
  PasoCaso.decision: 'Decisión',
  PasoCaso.consecuencia: 'Consecuencia',
  PasoCaso.explicacion: 'Diagnóstico',
  PasoCaso.resumen: 'Resumen',
};

class SesionCaso extends ChangeNotifier {
  final Caso caso;
  final RepositorioProgreso progreso;

  PasoCaso _paso = PasoCaso.encargo;
  int _ayudas = 0;
  bool _registrado = false;

  // Poligonal
  ResultadoPoligonal? resultado;
  final Map<int, bool> tramosVerificados = {};

  // Sobrerotura
  double? volumenReal;
  double? volumenDiseno;
  double? volumenSobrerotura;
  double? sobreroturaLinealMedia;
  bool sobreroturaVerificada = false;

  // Replanteo
  ({
    double azimutReferencia,
    double azimutObjetivo,
    double anguloAGirar,
    double distanciaHorizontal,
    double desnivel,
    double anguloCenital,
  })? replanteo;
  bool replanteoVerificado = false;

  // Respuestas del estudiante
  String? diagnosticoElegido;
  Decision? decisionElegida;
  String? justificacionElegida;

  SesionCaso({required this.caso, required this.progreso}) {
    _calcular();
  }

  PasoCaso get paso => _paso;
  int get ayudas => _ayudas;
  int get indicePaso => PasoCaso.values.indexOf(_paso);
  int get totalPasos => PasoCaso.values.length;

  void _calcular() {
    switch (caso.tipo) {
      case TipoEjercicio.poligonalAbierta:
        resultado = MotorTopografico.resolverPoligonal(
          arranque: caso.arranque!,
          orientacion: caso.orientacion!,
          filas: caso.libreta,
          azimutCierreReferencia: caso.azimutCierreReferencia!,
          cierreConocido: caso.cierreConocido!,
        );
        break;
      case TipoEjercicio.sobrerotura:
        final s = caso.sobrerotura!;
        final reales = s.progresivas
            .map((e) => (progresiva: e.progresiva, area: e.areaReal))
            .toList();
        final disenio = s.progresivas
            .map((e) => (progresiva: e.progresiva, area: s.areaDiseno))
            .toList();
        volumenReal = MotorTopografico.volumenAreasMedias(reales);
        volumenDiseno = MotorTopografico.volumenAreasMedias(disenio);
        volumenSobrerotura = volumenReal! - volumenDiseno!;
        final longitud =
            s.progresivas.last.progresiva - s.progresivas.first.progresiva;
        sobreroturaLinealMedia =
            volumenSobrerotura! / (s.perimetroSeccion * longitud);
        break;
      case TipoEjercicio.replanteo:
        final r = caso.replanteo!;
        replanteo = MotorTopografico.resolverReplanteo(
          estacion: r.estacion,
          referencia: r.referencia,
          objetivo: r.objetivo,
          alturaInstrumento: r.alturaInstrumento,
          alturaPrisma: r.alturaPrisma,
        );
        break;
    }
  }

  // ------------------------------------------------------------------ estado

  /// ¿Los cierres del trabajo están dentro de tolerancia?
  bool get cumpleTolerancia {
    switch (caso.tipo) {
      case TipoEjercicio.poligonalAbierta:
        final r = resultado!;
        final t = caso.tolerancia;
        return r.errorAngularSegundos.abs() <= (t.angularSeg ?? double.infinity) &&
            r.errorLinealM <= (t.linealM ?? double.infinity) &&
            r.errorCotaM.abs() <= (t.cotaM ?? double.infinity);
      case TipoEjercicio.sobrerotura:
        return sobreroturaLinealMedia! <=
            (caso.tolerancia.sobreroturaM ?? double.infinity);
      case TipoEjercicio.replanteo:
        return true;
    }
  }

  bool get anguloOk =>
      resultado!.errorAngularSegundos.abs() <=
      (caso.tolerancia.angularSeg ?? double.infinity);
  bool get linealOk =>
      resultado!.errorLinealM <= (caso.tolerancia.linealM ?? double.infinity);
  bool get cotaOk =>
      resultado!.errorCotaM.abs() <= (caso.tolerancia.cotaM ?? double.infinity);

  /// Opciones de diagnóstico que se presentan, según el tipo de ejercicio.
  List<TipoError> get opcionesDiagnostico {
    switch (caso.tipo) {
      case TipoEjercicio.poligonalAbierta:
        return catalogoErrores;
      case TipoEjercicio.sobrerotura:
        return [catalogoErrores.first, errorSobrerotura];
      case TipoEjercicio.replanteo:
        return [
          catalogoErrores.first,
          errorPorClave('punto_amarre_incorrecto'),
          errorPorClave('orientacion_inicial'),
        ];
    }
  }

  // ------------------------------------------------------------- evaluación

  bool get deteccionCorrecta {
    if (diagnosticoElegido == null) return false;
    final dijoLimpio = diagnosticoElegido == 'ninguno';
    final esLimpio = caso.diagnosticoEsperado == 'ninguno';
    return dijoLimpio == esLimpio;
  }

  bool get diagnosticoCorrecto => diagnosticoElegido == caso.diagnosticoEsperado;

  bool get decisionCorrecta => decisionElegida == caso.decisionCorrecta;

  bool get justificacionCorrecta {
    if (justificacionElegida == null) return false;
    return caso.justificaciones
        .firstWhere((j) => j.id == justificacionElegida,
            orElse: () => const Justificacion(id: '', texto: '', correcta: false))
        .correcta;
  }

  int get aciertos =>
      (deteccionCorrecta ? 1 : 0) +
      (diagnosticoCorrecto ? 1 : 0) +
      (decisionCorrecta ? 1 : 0) +
      (justificacionCorrecta ? 1 : 0);

  // ------------------------------------------------------------ interacción

  void usarAyuda() {
    _ayudas++;
    notifyListeners();
  }

  void marcarTramoVerificado(int i) {
    tramosVerificados[i] = true;
    notifyListeners();
  }

  void marcarSobreroturaVerificada() {
    sobreroturaVerificada = true;
    notifyListeners();
  }

  void marcarReplanteoVerificado() {
    replanteoVerificado = true;
    notifyListeners();
  }

  void elegirDiagnostico(String clave) {
    diagnosticoElegido = clave;
    notifyListeners();
  }

  void elegirDecision(Decision d) {
    decisionElegida = d;
    justificacionElegida = null;
    notifyListeners();
  }

  void elegirJustificacion(String id) {
    justificacionElegida = id;
    notifyListeners();
  }

  /// Con andamiaje alto la app resuelve y el estudiante revisa; con andamiaje
  /// medio y bajo debe verificar cada tramo antes de continuar.
  bool get calculoCompleto {
    if (caso.andamiaje == Andamiaje.alto) return true;
    switch (caso.tipo) {
      case TipoEjercicio.poligonalAbierta:
        return tramosVerificados.length >= resultado!.tramos.length;
      case TipoEjercicio.sobrerotura:
        return sobreroturaVerificada;
      case TipoEjercicio.replanteo:
        return replanteoVerificado;
    }
  }

  bool get puedeAvanzar {
    switch (_paso) {
      case PasoCaso.calculo:
        return calculoCompleto;
      case PasoCaso.veredicto:
        return diagnosticoElegido != null;
      case PasoCaso.decision:
        return decisionElegida != null && justificacionElegida != null;
      case PasoCaso.resumen:
        return false;
      default:
        return true;
    }
  }

  /// Retroceder está permitido sólo antes del veredicto. Después, volver atrás
  /// permitiría rehacer el juicio con la respuesta ya vista.
  bool get puedeRetroceder =>
      indicePaso > 0 && indicePaso <= PasoCaso.values.indexOf(PasoCaso.veredicto);

  Future<void> avanzar() async {
    if (!puedeAvanzar) return;
    final siguiente = PasoCaso.values[indicePaso + 1];
    _paso = siguiente;
    if (siguiente == PasoCaso.consecuencia && !_registrado) {
      _registrado = true;
      await progreso.registrar(IntentoCaso(
        casoId: caso.id,
        tipoError: caso.diagnosticoEsperado,
        deteccionCorrecta: deteccionCorrecta,
        diagnosticoCorrecto: diagnosticoCorrecto,
        decisionCorrecta: decisionCorrecta,
        justificacionCorrecta: justificacionCorrecta,
        ayudasUsadas: _ayudas,
        fecha: DateTime.now().toIso8601String(),
      ));
    }
    notifyListeners();
  }

  void retroceder() {
    if (!puedeRetroceder) return;
    _paso = PasoCaso.values[indicePaso - 1];
    notifyListeners();
  }

  // ------------------------------------------------------------- plantillas

  /// Sustituye los marcadores {{campo}} de los textos de consecuencia por los
  /// valores reales de la solución de referencia.
  String rellenar(String texto) {
    return texto.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (m) {
      final v = caso.solucionReferencia[m.group(1)];
      if (v == null) return m.group(0)!;
      if (v is num) return v.abs().toStringAsFixed(v.abs() < 10 ? 3 : 2);
      return v.toString();
    });
  }
}
