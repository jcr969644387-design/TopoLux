import '../datos/repositorios.dart';
import 'catalogo_errores.dart';
import 'modelos.dart';

/// Estado de dominio de un tipo de error. Sustituye a puntos e insignias:
/// hace visible la competencia, no el esfuerzo.
enum EstadoDominio { noVisto, visto, detectado, dominado }

const Map<EstadoDominio, String> etiquetaDominio = {
  EstadoDominio.noVisto: 'No visto',
  EstadoDominio.visto: 'Visto',
  EstadoDominio.detectado: 'Detectado',
  EstadoDominio.dominado: 'Dominado',
};

class MotorProgresion {
  final List<IntentoCaso> intentos;
  final List<ResumenCaso> indice;

  const MotorProgresion({required this.intentos, required this.indice});

  /// Dominado = diagnosticado correctamente dos veces.
  /// Detectado = detectado al menos una vez.
  /// Visto     = apareció en algún caso resuelto.
  EstadoDominio estado(String tipoError) {
    final propios = intentos.where((i) => i.tipoError == tipoError).toList();
    if (propios.isEmpty) return EstadoDominio.noVisto;
    final diagnosticos = propios.where((i) => i.diagnosticoCorrecto).length;
    if (diagnosticos >= 2) return EstadoDominio.dominado;
    if (propios.any((i) => i.deteccionCorrecta)) return EstadoDominio.detectado;
    return EstadoDominio.visto;
  }

  Map<String, EstadoDominio> get mapaDominio => {
        for (final e in erroresEvaluables) e.clave: estado(e.clave),
      };

  int get dominados =>
      mapaDominio.values.where((e) => e == EstadoDominio.dominado).length;

  /// Tipos de error fallados dos o más veces: la app los vuelve a presentar.
  List<String> get puntosDebiles {
    final fallos = <String, int>{};
    for (final i in intentos) {
      if (!i.diagnosticoCorrecto && i.tipoError != 'ninguno') {
        fallos[i.tipoError] = (fallos[i.tipoError] ?? 0) + 1;
      }
    }
    final debiles = fallos.entries.where((e) => e.value >= 2).map((e) => e.key).toList();
    debiles.sort((a, b) => fallos[b]!.compareTo(fallos[a]!));
    return debiles;
  }

  bool completado(String casoId) => intentos.any((i) => i.casoId == casoId);

  /// Siguiente caso recomendado, con el motivo que se le muestra al estudiante.
  ({ResumenCaso? caso, String motivo}) siguiente() {
    final pendientes = indice.where((c) => !completado(c.id)).toList();

    // 1. Refuerzo: un caso pendiente que repita un punto débil.
    for (final debil in puntosDebiles) {
      final refuerzo = pendientes.where((c) => c.tipoError == debil).toList();
      if (refuerzo.isNotEmpty) {
        return (
          caso: refuerzo.first,
          motivo: 'Refuerzo: has fallado el diagnóstico de '
              '"${errorPorClave(debil).nombre.toLowerCase()}" más de una vez.',
        );
      }
    }

    // 2. Avance normal por orden.
    if (pendientes.isNotEmpty) {
      final c = pendientes.first;
      return (
        caso: c,
        motivo: 'Bloque ${c.bloque} — ${nombreBloque[c.bloque] ?? ''}.',
      );
    }

    // 3. Todo completado: repasar el error peor dominado.
    final debiles = mapaDominio.entries
        .where((e) => e.value != EstadoDominio.dominado)
        .toList();
    if (debiles.isNotEmpty) {
      final objetivo = debiles.first.key;
      final repaso = indice.where((c) => c.tipoError == objetivo).toList();
      if (repaso.isNotEmpty) {
        return (
          caso: repaso.first,
          motivo: 'Repaso: te falta dominar '
              '"${errorPorClave(objetivo).nombre.toLowerCase()}".',
        );
      }
    }
    return (caso: null, motivo: 'Has completado y dominado todos los casos.');
  }
}
