import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../datos/repositorios.dart';
import '../dominio/catalogo_errores.dart';
import '../dominio/modelos.dart';
import '../dominio/motor_progresion.dart';
import 'tema.dart';

/// Mapa de dominio de errores.
///
/// Sustituye a puntos, insignias y rachas: dice qué te falta, que es
/// información accionable, en lugar de cuánto has jugado. El tiempo no se
/// puntúa a propósito: premiar la rapidez empeora justo la habilidad que se
/// entrena, que es detenerse a verificar.
class PantallaProgreso extends StatefulWidget {
  final RepositorioCasos casos;
  final RepositorioProgreso progreso;

  const PantallaProgreso({super.key, required this.casos, required this.progreso});

  @override
  State<PantallaProgreso> createState() => _PantallaProgresoState();
}

class _PantallaProgresoState extends State<PantallaProgreso> {
  List<ResumenCaso> _indice = const [];

  @override
  void initState() {
    super.initState();
    widget.casos.indice().then((i) {
      if (mounted) setState(() => _indice = i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final motor =
        MotorProgresion(intentos: widget.progreso.intentos, indice: _indice);
    final mapa = motor.mapaDominio;
    final intentos = widget.progreso.intentos;

    final detecciones = intentos.where((i) => i.deteccionCorrecta).length;
    final diagnosticos = intentos.where((i) => i.diagnosticoCorrecto).length;
    final decisiones = intentos.where((i) => i.decisionCorrecta).length;
    final sustentos = intentos.where((i) => i.justificacionCorrecta).length;
    final n = intentos.length;

    String pct(int x) => n == 0 ? '—' : '${(100 * x / n).round()} %';

    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Ficha(
            child: Column(children: [
              Dato('Casos resueltos',
                  '${intentos.map((e) => e.casoId).toSet().length} de ${_indice.length}'),
              Dato('Errores dominados', '${motor.dominados} de ${mapa.length}'),
              const Divider(height: 20),
              Dato('Detección', pct(detecciones)),
              Dato('Diagnóstico', pct(diagnosticos)),
              Dato('Decisión', pct(decisiones)),
              Dato('Sustento', pct(sustentos)),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Errores tipificados', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Dominado significa haber diagnosticado ese error correctamente dos '
            'veces.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final e in erroresEvaluables)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FilaDominio(
                  tipo: e, estado: mapa[e.clave] ?? EstadoDominio.noVisto),
            ),
          const SizedBox(height: 20),
          Ficha(
            fondo: Paleta.papel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Titulo('Pilotaje'),
                Text(
                  'La app no envía nada por internet. Si tu docente está '
                  'midiendo el uso del curso, exporta tu progreso y entrégalo '
                  'por el canal que él indique. No contiene tu nombre.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Dato('Código de participante', widget.progreso.participante),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: widget.progreso.exportarJson()));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Progreso copiado al portapapeles'),
                    ));
                  },
                  child: const Text('Copiar mi progreso'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Paleta.papelAlto,
                  title: const Text('¿Borrar todo el progreso?'),
                  content: const Text(
                      'Se borran tus intentos y el mapa de dominio. Los casos '
                      'quedan disponibles desde el principio.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Borrar')),
                  ],
                ),
              );
              if (ok == true) {
                await widget.progreso.reiniciar();
                if (mounted) setState(() {});
              }
            },
            child: const Text('Borrar mi progreso'),
          ),
        ],
      ),
    );
  }
}

class _FilaDominio extends StatelessWidget {
  final TipoError tipo;
  final EstadoDominio estado;

  const _FilaDominio({required this.tipo, required this.estado});

  @override
  Widget build(BuildContext context) {
    final visto = estado != EstadoDominio.noVisto;
    return Ficha(
      resaltada: estado == EstadoDominio.dominado,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icono(estado), size: 18, color: Paleta.grafito),
              const SizedBox(width: 10),
              Expanded(
                child: Text(tipo.nombre,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(etiquetaDominio[estado]!, style: cifraPequena),
            ],
          ),
          if (visto) ...[
            const SizedBox(height: 6),
            Text(tipo.firma, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  static IconData _icono(EstadoDominio e) => switch (e) {
        EstadoDominio.noVisto => Icons.circle_outlined,
        EstadoDominio.visto => Icons.visibility_outlined,
        EstadoDominio.detectado => Icons.adjust,
        EstadoDominio.dominado => Icons.verified_outlined,
      };
}
