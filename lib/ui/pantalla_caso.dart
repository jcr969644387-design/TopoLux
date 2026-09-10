import 'package:flutter/material.dart';

import '../datos/repositorios.dart';
import '../dominio/modelos.dart';
import '../dominio/motor_progresion.dart';
import '../sesion/sesion_caso.dart';
import 'pasos/pasos_analisis.dart';
import 'pasos/pasos_cierre.dart';
import 'pasos/pasos_juicio.dart';
import 'tema.dart';
import 'widgets/marca.dart';

class PantallaCaso extends StatefulWidget {
  final String casoId;
  final RepositorioCasos casos;
  final RepositorioProgreso progreso;

  const PantallaCaso({
    super.key,
    required this.casoId,
    required this.casos,
    required this.progreso,
  });

  @override
  State<PantallaCaso> createState() => _PantallaCasoState();
}

class _PantallaCasoState extends State<PantallaCaso> {
  SesionCaso? _sesion;
  List<ResumenCaso> _indice = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final caso = await widget.casos.cargar(widget.casoId);
      final indice = await widget.casos.indice();
      if (!mounted) return;
      setState(() {
        _indice = indice;
        _sesion = SesionCaso(caso: caso, progreso: widget.progreso);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo abrir el caso ${widget.casoId}. '
          'Comprueba que el archivo está en assets/casos/.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TopoLux')),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }
    final s = _sesion;
    if (s == null) return const PantallaCarga();

    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final rec = MotorProgresion(
          intentos: widget.progreso.intentos,
          indice: _indice,
        ).siguiente();

        return Scaffold(
            appBar: AppBar(
              titleSpacing: 8,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.caso.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Paleta.sobreTinta,
                      )),
                  // El paso va sobre la cabecera oscura, así que lleva la
                  // variante clara de la cifra pequeña.
                  Text(tituloPaso[s.paso]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cifraPequenaClara),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Salir del caso',
                onPressed: () => _confirmarSalida(context, s),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: (s.indicePaso + 1) / s.totalPasos,
                  minHeight: 3,
                  backgroundColor: Paleta.tintaSuave,
                  color: Paleta.latonClaro,
                ),
              ),
            ),
            // El hueco de arriba lo cubre la cabecera. El de abajo lo cubre la
            // barra de acciones; cuando no la hay (el resumen), lo reserva la
            // propia SafeArea para que el último botón no quede debajo de los
            // botones del teléfono.
            body: SafeArea(
              top: false,
              bottom: s.paso == PasoCaso.resumen,
              child: _cuerpo(s, rec),
            ),
            bottomNavigationBar: s.paso == PasoCaso.resumen
                ? null
                : _barra(context, s),
        );
      },
    );
  }

  Widget _cuerpo(SesionCaso s, ({ResumenCaso? caso, String motivo}) rec) {
    switch (s.paso) {
      case PasoCaso.encargo:
        return PasoEncargo(s);
      case PasoCaso.libreta:
        return PasoLibreta(s);
      case PasoCaso.calculo:
        return PasoCalculo(s);
      case PasoCaso.cierre:
        return PasoCierre(s);
      case PasoCaso.veredicto:
        return PasoVeredicto(s);
      case PasoCaso.decision:
        return PasoDecision(s);
      case PasoCaso.consecuencia:
        return PasoConsecuencia(s);
      case PasoCaso.explicacion:
        return PasoExplicacion(s);
      case PasoCaso.resumen:
        return PasoResumen(
          s: s,
          siguiente: rec.caso,
          motivo: rec.motivo,
          alSiguiente: () {
            final id = rec.caso?.id;
            if (id == null) return;
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => PantallaCaso(
                casoId: id,
                casos: widget.casos,
                progreso: widget.progreso,
              ),
            ));
          },
          alInicio: () => Navigator.of(context).pop(),
        );
    }
  }

  Widget _barra(BuildContext context, SesionCaso s) {
    // La SafeArea va dentro del Container y no fuera: así el color de la barra
    // se pinta también detrás de la franja de navegación del teléfono, en vez
    // de dejar ahí una banda del fondo de la página.
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Paleta.linea)),
        color: Paleta.papelAlto,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (s.puedeRetroceder) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: s.retroceder,
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: s.puedeAvanzar ? () => s.avanzar() : null,
                  // El rótulo más largo ("Verifica cada tramo") no cabe en
                  // pantallas de 320 dp: encoge antes que desbordar el botón.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_etiquetaAvance(s), maxLines: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _etiquetaAvance(SesionCaso s) {
    switch (s.paso) {
      case PasoCaso.encargo:
        return 'Ver la libreta';
      case PasoCaso.libreta:
        return 'Calcular';
      case PasoCaso.calculo:
        return s.calculoCompleto ? 'Verificar cierres' : 'Verifica cada tramo';
      case PasoCaso.cierre:
        return 'Dar mi veredicto';
      case PasoCaso.veredicto:
        return 'Decidir';
      case PasoCaso.decision:
        return 'Confirmar decisión';
      case PasoCaso.consecuencia:
        return 'Ver el diagnóstico';
      case PasoCaso.explicacion:
        return 'Ver resumen';
      case PasoCaso.resumen:
        return '';
    }
  }

  Future<void> _confirmarSalida(BuildContext context, SesionCaso s) async {
    if (s.paso == PasoCaso.resumen) {
      Navigator.of(context).pop();
      return;
    }
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Paleta.papelAlto,
        title: const Text('¿Salir del caso?'),
        content: const Text(
          'El avance de este caso no se guarda a medias. Al volver a abrirlo '
          'empezarás desde el encargo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir aquí'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (salir == true && context.mounted) Navigator.of(context).pop();
  }
}
