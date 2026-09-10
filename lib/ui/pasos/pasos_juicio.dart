import 'package:flutter/material.dart';

import '../../dominio/catalogo_errores.dart';
import '../../dominio/modelos.dart';
import '../../sesion/sesion_caso.dart';
import '../tema.dart';

// -------------------------------------------------------------- 5. Veredicto

/// Detección y diagnóstico en una sola pregunta.
///
/// La app no ha dicho todavía si hay un error. Elegir "sin error" cuando lo
/// hay, o inventarse uno cuando no lo hay, son fallos distintos y ambos se
/// registran: sobre-diagnosticar es tan costoso en una operación como no ver
/// el problema.
class PasoVeredicto extends StatelessWidget {
  final SesionCaso s;
  const PasoVeredicto(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('¿Qué explica el resultado?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Una sola respuesta. Apóyate en la firma numérica: qué cierres se '
          'salen, cuáles no, y qué se conserva intacto.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        _Recordatorio(s),
        const SizedBox(height: 14),
        for (final e in s.opcionesDiagnostico)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OpcionDiagnostico(
              tipo: e,
              elegida: s.diagnosticoElegido == e.clave,
              alElegir: () => s.elegirDiagnostico(e.clave),
            ),
          ),
      ],
    );
  }
}

class _Recordatorio extends StatelessWidget {
  final SesionCaso s;
  const _Recordatorio(this.s);

  @override
  Widget build(BuildContext context) {
    if (s.caso.tipo == TipoEjercicio.sobrerotura) {
      return Ficha(
        fondo: Paleta.nota,
        child: Column(children: [
          Dato('Sobrerotura media',
              '${s.sobreroturaLinealMedia!.toStringAsFixed(3)} m'),
          Dato('Tolerancia',
              '± ${s.caso.tolerancia.sobreroturaM!.toStringAsFixed(2)} m'),
        ]),
      );
    }
    if (s.caso.tipo == TipoEjercicio.replanteo) {
      return Ficha(
        fondo: Paleta.nota,
        child: Text(
          'La estación de control está verificada contra el arrastre del nivel '
          'y los datos se derivan de coordenadas conocidas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final r = s.resultado!;
    final t = s.caso.tolerancia;
    return Ficha(
      fondo: Paleta.nota,
      child: Column(children: [
        Dato('Error angular',
            '${r.errorAngularSegundos.toStringAsFixed(1)}"  /  '
            '± ${t.angularSeg!.toStringAsFixed(1)}"'),
        Dato('Error lineal',
            '${r.errorLinealM.toStringAsFixed(3)}  /  '
            '± ${t.linealM!.toStringAsFixed(3)} m'),
        Dato('Error de cota',
            '${r.errorCotaM.toStringAsFixed(3)}  /  '
            '± ${t.cotaM!.toStringAsFixed(3)} m'),
      ]),
    );
  }
}

class _OpcionDiagnostico extends StatelessWidget {
  final TipoError tipo;
  final bool elegida;
  final VoidCallback alElegir;

  const _OpcionDiagnostico({
    required this.tipo,
    required this.elegida,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alElegir,
      borderRadius: BorderRadius.circular(4),
      child: Ficha(
        resaltada: elegida,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              elegida ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: elegida ? Paleta.laton : Paleta.grafito,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tipo.nombre,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(tipo.firma, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- 6. Decisión

/// Las cuatro acciones con el mismo peso visual: destacar una sería sugerirla.
/// La justificación se pide después de elegir, y separa a quien acierta por
/// criterio de quien acierta por azar.
class PasoDecision extends StatelessWidget {
  final SesionCaso s;
  const PasoDecision(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('¿Qué haces con este trabajo?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        for (final d in Decision.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BotonDecision(
              decision: d,
              elegida: s.decisionElegida == d,
              alElegir: () => s.elegirDecision(d),
            ),
          ),
        if (s.decisionElegida != null) ...[
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          Text('¿Por qué?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Sustentar la decisión es parte del trabajo: un topógrafo tiene que '
            'explicar ante el jefe de mina por qué manda repetir un turno.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final j in s.caso.justificaciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OpcionJustificacion(
                texto: j.texto,
                elegida: s.justificacionElegida == j.id,
                alElegir: () => s.elegirJustificacion(j.id),
              ),
            ),
        ],
      ],
    );
  }
}

class _BotonDecision extends StatelessWidget {
  final Decision decision;
  final bool elegida;
  final VoidCallback alElegir;

  const _BotonDecision({
    required this.decision,
    required this.elegida,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alElegir,
      borderRadius: BorderRadius.circular(4),
      child: Ficha(
        resaltada: elegida,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(
              elegida ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: elegida ? Paleta.laton : Paleta.grafito,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiquetaDecision[decision]!,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(descripcionDecision[decision]!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionJustificacion extends StatelessWidget {
  final String texto;
  final bool elegida;
  final VoidCallback alElegir;

  const _OpcionJustificacion({
    required this.texto,
    required this.elegida,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alElegir,
      borderRadius: BorderRadius.circular(4),
      child: Ficha(
        resaltada: elegida,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              elegida ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: elegida ? Paleta.laton : Paleta.grafito,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
