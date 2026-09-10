import 'package:flutter/material.dart';

import '../datos/repositorios.dart';
import '../dominio/modelos.dart';
import '../dominio/motor_progresion.dart';
import 'pantalla_caso.dart';
import 'pantalla_progreso.dart';
import 'tema.dart';

class PantallaInicio extends StatefulWidget {
  final RepositorioCasos casos;
  final RepositorioProgreso progreso;

  const PantallaInicio({super.key, required this.casos, required this.progreso});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  List<ResumenCaso> _indice = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final i = await widget.casos.indice();
    if (!mounted) return;
    setState(() {
      _indice = i;
      _cargando = false;
    });
  }

  Future<void> _abrir(String id) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PantallaCaso(
        casoId: id,
        casos: widget.casos,
        progreso: widget.progreso,
      ),
    ));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final motor =
        MotorProgresion(intentos: widget.progreso.intentos, indice: _indice);
    final rec = motor.siguiente();
    final bloques = <String, List<ResumenCaso>>{};
    for (final c in _indice) {
      bloques.putIfAbsent(c.bloque, () => []).add(c);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TopoLux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Mi progreso',
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PantallaProgreso(
                  casos: widget.casos,
                  progreso: widget.progreso,
                ),
              ));
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Topografía de mina',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Procesa levantamientos reales, decide si sirven para operar y '
            'asume la consecuencia. Doce casos, siete errores típicos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (rec.caso != null)
            Ficha(
              resaltada: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Titulo('Continuar'),
                  Text(rec.caso!.titulo,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(rec.motivo, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => _abrir(rec.caso!.id),
                    child: const Text('Abrir caso'),
                  ),
                ],
              ),
            )
          else
            Ficha(child: Text(rec.motivo)),
          const SizedBox(height: 8),
          Ficha(
            fondo: Paleta.papel,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Errores dominados: ${motor.dominados} de '
                    '${motor.mapaDominio.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${widget.progreso.intentos.map((e) => e.casoId).toSet().length}'
                  '/${_indice.length} casos',
                  style: cifraPequena,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (final entrada in bloques.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 6),
              child: Text(
                'Bloque ${entrada.key} · ${nombreBloque[entrada.key] ?? ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final c in entrada.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FilaCaso(
                  caso: c,
                  intento: widget.progreso.mejorIntento(c.id),
                  alAbrir: () => _abrir(c.id),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FilaCaso extends StatelessWidget {
  final ResumenCaso caso;
  final IntentoCaso? intento;
  final VoidCallback alAbrir;

  const _FilaCaso({required this.caso, required this.intento, required this.alAbrir});

  @override
  Widget build(BuildContext context) {
    final hecho = intento != null;
    return InkWell(
      onTap: alAbrir,
      borderRadius: BorderRadius.circular(4),
      child: Ficha(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text('${caso.orden}', style: cifraPequena),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caso.titulo,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    hecho
                        ? '${_aciertos(intento!)} de 4 correctas · '
                            '${intento!.ayudasUsadas} ayudas'
                        : _descripcionTipo(caso),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              hecho ? Icons.check_circle_outline : Icons.chevron_right,
              size: 20,
              color: hecho ? Paleta.laton : Paleta.grafito,
            ),
          ],
        ),
      ),
    );
  }

  static int _aciertos(IntentoCaso i) =>
      (i.deteccionCorrecta ? 1 : 0) +
      (i.diagnosticoCorrecto ? 1 : 0) +
      (i.decisionCorrecta ? 1 : 0) +
      (i.justificacionCorrecta ? 1 : 0);

  static String _descripcionTipo(ResumenCaso c) {
    final tipo = switch (c.tipo) {
      'sobrerotura' => 'Sobrerotura por áreas medias',
      'replanteo' => 'Replanteo desde estación de control',
      _ => 'Poligonal con comprobación',
    };
    final ayuda = switch (c.andamiaje) {
      'alto' => 'cálculo asistido',
      'medio' => 'calculas el azimut',
      _ => 'calculas azimut y distancia',
    };
    return '$tipo · $ayuda';
  }
}
