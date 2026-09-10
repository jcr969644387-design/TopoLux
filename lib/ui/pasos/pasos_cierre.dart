import 'package:flutter/material.dart';

import '../../dominio/catalogo_errores.dart';
import '../../dominio/modelos.dart';
import '../../sesion/sesion_caso.dart';
import '../tema.dart';
import '../widgets/vista_planta.dart';

// ----------------------------------------------------------- 7. Consecuencia

/// Lo que pasó en la mina por la decisión tomada.
///
/// Sin puntajes y sin "incorrecto": el impacto operativo es la
/// retroalimentación. La explicación técnica llega después, no antes.
class PasoConsecuencia extends StatelessWidget {
  final SesionCaso s;
  const PasoConsecuencia(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = s.decisionElegida!;
    final c = s.caso.consecuencias[d];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Decidiste: ${etiquetaDecision[d]!.toLowerCase()}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text('Lo que ocurrió', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Ficha(
          resaltada: true,
          child: Text(
            c == null ? 'Sin consecuencia registrada.' : s.rellenar(c.texto),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (s.caso.tipo == TipoEjercicio.poligonalAbierta) ...[
          const SizedBox(height: 18),
          Ficha(
            child: Column(children: [
              Dato('Desviación en el punto de cierre',
                  '${s.resultado!.errorLinealM.toStringAsFixed(3)} m',
                  destacado: true),
              Dato('Desviación en cota',
                  '${s.resultado!.errorCotaM.toStringAsFixed(3)} m'),
            ]),
          ),
          const SizedBox(height: 16),
          VistaPlanta(
            diseno: s.caso.ejeDiseno,
            real: s.resultado!.puntos,
            cierreConocido: s.caso.cierreConocido,
            alto: 260,
          ),
        ],
        if (s.caso.tipo == TipoEjercicio.sobrerotura) ...[
          const SizedBox(height: 18),
          Ficha(
            child: Column(children: [
              Dato('Sobreexcavación',
                  '${s.volumenSobrerotura!.toStringAsFixed(2)} m³',
                  destacado: true),
              Dato('Sobrerotura media',
                  '${s.sobreroturaLinealMedia!.toStringAsFixed(3)} m'),
            ]),
          ),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------ 8. Diagnóstico

class PasoExplicacion extends StatelessWidget {
  final SesionCaso s;
  const PasoExplicacion(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = s.caso;
    final tipo = errorPorClave(c.diagnosticoEsperado);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Diagnóstico', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Ficha(
          resaltada: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tipo.nombre, style: Theme.of(context).textTheme.titleMedium),
              if (c.estacionAfectada != null) ...[
                const SizedBox(height: 6),
                Dato('Estación afectada', c.estacionAfectada!),
              ],
              if (c.anomalia != 'ninguna') ...[
                const SizedBox(height: 6),
                Text(descripcionAnomalia[c.anomalia] ?? '',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Bloque('Qué había', c.diagnostico.queHabia),
        _Bloque('Por qué se produce', c.diagnostico.porQue),
        _Bloque('Cómo detectarlo la próxima vez', c.diagnostico.comoDetectar),
        const SizedBox(height: 6),
        Ficha(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Titulo('Decisión correcta'),
              Text(
                '${etiquetaDecision[c.decisionCorrecta]}. '
                '${descripcionDecision[c.decisionCorrecta]}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                c.justificaciones.firstWhere((j) => j.correcta).texto,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bloque extends StatelessWidget {
  final String titulo;
  final String texto;
  const _Bloque(this.titulo, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Ficha(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Titulo(titulo),
            Text(texto, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 9. Resumen

class PasoResumen extends StatelessWidget {
  final SesionCaso s;
  final ResumenCaso? siguiente;
  final String motivo;
  final VoidCallback alSiguiente;
  final VoidCallback alInicio;

  const PasoResumen({
    super.key,
    required this.s,
    required this.siguiente,
    required this.motivo,
    required this.alSiguiente,
    required this.alInicio,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cómo resolviste este caso',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Ficha(
          child: Column(children: [
            _Dimension('Detección',
                '¿Viste que el trabajo cumplía o no cumplía?', s.deteccionCorrecta),
            const Divider(height: 20),
            _Dimension('Diagnóstico', '¿Identificaste qué lo explicaba?',
                s.diagnosticoCorrecto),
            const Divider(height: 20),
            _Dimension(
                'Decisión', '¿Elegiste la acción correcta?', s.decisionCorrecta),
            const Divider(height: 20),
            _Dimension('Sustento', '¿La razón elegida era la técnica?',
                s.justificacionCorrecta),
          ]),
        ),
        const SizedBox(height: 12),
        Ficha(
          fondo: Paleta.papel,
          child: Column(children: [
            Dato('Ayudas usadas', '${s.ayudas}'),
            Dato('Error de este caso', errorPorClave(s.caso.diagnosticoEsperado).nombre),
          ]),
        ),
        if (!s.diagnosticoCorrecto) ...[
          const SizedBox(height: 12),
          Ficha(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Titulo('Para la próxima'),
                Text(errorPorClave(s.caso.diagnosticoEsperado).pista,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        if (siguiente != null) ...[
          Ficha(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Titulo('Siguiente caso'),
                Text(siguiente!.titulo,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(motivo, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: alSiguiente, child: const Text('Abrir el siguiente caso')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: alInicio, child: const Text('Volver a los casos')),
        ] else ...[
          Ficha(child: Text(motivo, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 12),
          FilledButton(onPressed: alInicio, child: const Text('Volver a los casos')),
        ],
      ],
    );
  }
}

class _Dimension extends StatelessWidget {
  final String titulo;
  final String pregunta;
  final bool acierto;

  const _Dimension(this.titulo, this.pregunta, this.acierto);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(acierto ? Icons.check : Icons.remove, size: 20, color: Paleta.grafito),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
              Text(pregunta, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Text(acierto ? 'Correcto' : 'Fallado', style: cifraPequena),
      ],
    );
  }
}
