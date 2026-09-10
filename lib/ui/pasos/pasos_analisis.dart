import 'package:flutter/material.dart';

import '../../dominio/modelos.dart';
import '../../dominio/motor_topografico.dart';
import '../../sesion/sesion_caso.dart';
import '../tema.dart';
import '../widgets/cinta_estaciones.dart';
import '../widgets/entrada_gms.dart';
import '../widgets/vista_planta.dart';

// ---------------------------------------------------------------- 1. Encargo

class PasoEncargo extends StatelessWidget {
  final SesionCaso s;
  const PasoEncargo(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = s.caso;
    final t = c.tolerancia;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(c.labor, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Solicita: ${c.solicitante}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Ficha(child: Text(c.contexto, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(height: 12),
        Ficha(
          resaltada: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Titulo('Tu encargo'),
              Text(c.objetivo, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Ficha(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Titulo('Tolerancias de este escenario'),
              if (t.angularSeg != null)
                Dato('Cierre angular',
                    '± ${t.angularSeg!.toStringAsFixed(1)}"  (30"·√${t.nAngulos})'),
              if (t.linealM != null)
                Dato('Cierre lineal',
                    '± ${t.linealM!.toStringAsFixed(3)} m  (1:${t.denominador})'),
              if (t.cotaM != null)
                Dato('Cierre de cota', '± ${t.cotaM!.toStringAsFixed(3)} m'),
              if (t.sobreroturaM != null)
                Dato('Sobrerotura media', '± ${t.sobreroturaM!.toStringAsFixed(2)} m'),
              const SizedBox(height: 8),
              Text(
                'La tolerancia la fija la operación, no es un valor universal. '
                'Cámbiala de mina y cambia el criterio de aceptación.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- 2. Libreta

class PasoLibreta extends StatefulWidget {
  final SesionCaso s;
  const PasoLibreta(this.s, {super.key});

  @override
  State<PasoLibreta> createState() => _PasoLibretaState();
}

class _PasoLibretaState extends State<PasoLibreta> {
  final _pc = PageController();
  int _actual = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.s.caso;
    if (c.tipo == TipoEjercicio.sobrerotura) return _Secciones(widget.s);
    if (c.tipo == TipoEjercicio.replanteo) return _DatosReplanteo(widget.s);

    final nombres = c.libreta.map((f) => f.estacion).toList();
    return Column(
      children: [
        const SizedBox(height: 8),
        CintaEstaciones(
          nombres: nombres,
          actual: _actual,
          procesadas: {for (var i = 0; i < _actual; i++) i},
          alTocar: (i) => _pc.animateToPage(i,
              duration: const Duration(milliseconds: 220), curve: Curves.easeOut),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pc,
            itemCount: c.libreta.length,
            onPageChanged: (i) => setState(() => _actual = i),
            itemBuilder: (context, i) => _TarjetaEstacion(c.libreta[i], i + 1,
                c.libreta.length, c.arranque!, c.orientacion!),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Desliza para recorrer la poligonal. Cada estación se apoya en la '
            'anterior: ese es el orden en que se camina la labor y en que se '
            'calcula.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _TarjetaEstacion extends StatelessWidget {
  final FilaLibreta f;
  final int n;
  final int total;
  final Coord arranque;
  final Coord orientacion;

  const _TarjetaEstacion(this.f, this.n, this.total, this.arranque, this.orientacion);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // El nombre de la estación cede antes que el contador: con el
            // cuerpo de letra del sistema al máximo, ambos no caben.
            Expanded(
              child: Text('Estación ${f.estacion}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(width: 10),
            Text('$n de $total', style: cifraPequena),
          ],
        ),
        const SizedBox(height: 12),
        Ficha(
          child: Column(
            children: [
              Dato('Punto de atrás', f.puntoAtras),
              Dato('Punto visado', f.puntoVisado),
              const Divider(height: 18),
              Dato('Ángulo horizontal', formatoGms(f.anguloHorizontal),
                  destacado: true),
              if (f.anguloCenital != null)
                Dato('Ángulo cenital', formatoGms(f.anguloCenital!)),
              if (f.distanciaInclinada != null)
                Dato('Distancia inclinada',
                    '${f.distanciaInclinada!.toStringAsFixed(4)} m'),
              if (f.alturaInstrumento != null)
                Dato('Altura de instrumento',
                    '${f.alturaInstrumento!.toStringAsFixed(3)} m'),
              if (f.alturaPrisma != null)
                Dato('Altura de prisma', '${f.alturaPrisma!.toStringAsFixed(3)} m'),
              if (f.esVisualDeCierre) ...[
                const Divider(height: 18),
                Text(
                  'Visual de cierre: sólo ángulo, sin distancia. Sirve para '
                  'comprobar el cierre angular contra la referencia conocida.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (f.observaciones.isNotEmpty) ...[
          const SizedBox(height: 12),
          Ficha(
            fondo: Paleta.nota,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.edit_note, size: 18, color: Paleta.grafito),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(f.observaciones,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        ],
        if (n == 1) ...[
          const SizedBox(height: 12),
          Ficha(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Titulo('Control de partida'),
                Dato(arranque.id,
                    '${arranque.norte.toStringAsFixed(3)} N  '
                    '${arranque.este.toStringAsFixed(3)} E'),
                Dato('Cota', arranque.cota.toStringAsFixed(3)),
                Dato('Orientación a ${orientacion.id}',
                    formatoGms(azimut(arranque, orientacion))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Secciones extends StatelessWidget {
  final SesionCaso s;
  const _Secciones(this.s);

  @override
  Widget build(BuildContext context) {
    final d = s.caso.sobrerotura!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Secciones levantadas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Ficha(
          child: Column(
            children: [
              Dato('Sección de diseño',
                  '${d.anchoDiseno.toStringAsFixed(2)} × '
                  '${d.altoDiseno.toStringAsFixed(2)} m'),
              Dato('Área de diseño', '${d.areaDiseno.toStringAsFixed(2)} m²'),
              Dato('Perímetro de sección',
                  '${d.perimetroSeccion.toStringAsFixed(2)} m'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Ficha(
          child: Column(
            children: [
              const Titulo('Áreas reales por progresiva'),
              for (final p in d.progresivas)
                Dato('Progresiva ${p.progresiva.toStringAsFixed(0)} m',
                    '${p.areaReal.toStringAsFixed(2)} m²'),
            ],
          ),
        ),
        for (final o in d.observaciones) ...[
          const SizedBox(height: 12),
          Ficha(
            fondo: Paleta.nota,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.edit_note, size: 18, color: Paleta.grafito),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(o, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DatosReplanteo extends StatelessWidget {
  final SesionCaso s;
  const _DatosReplanteo(this.s);

  @override
  Widget build(BuildContext context) {
    final r = s.caso.replanteo!;
    Widget punto(String rol, Coord c) => Ficha(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Titulo('$rol — ${c.id}'),
              Dato('Norte', c.norte.toStringAsFixed(3)),
              Dato('Este', c.este.toStringAsFixed(3)),
              Dato('Cota', c.cota.toStringAsFixed(3)),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Datos de partida', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        punto('Estación ocupada', r.estacion),
        const SizedBox(height: 10),
        punto('Referencia de orientación', r.referencia),
        const SizedBox(height: 10),
        punto('Punto de diseño a replantear', r.objetivo),
        const SizedBox(height: 10),
        Ficha(
          child: Column(children: [
            Dato('Altura de instrumento',
                '${r.alturaInstrumento.toStringAsFixed(3)} m'),
            Dato('Altura de prisma', '${r.alturaPrisma.toStringAsFixed(3)} m'),
          ]),
        ),
        for (final o in r.observaciones) ...[
          const SizedBox(height: 10),
          Ficha(
            fondo: Paleta.nota,
            child: Text(o, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- 3. Cálculo

class PasoCalculo extends StatelessWidget {
  final SesionCaso s;
  const PasoCalculo(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    switch (s.caso.tipo) {
      case TipoEjercicio.poligonalAbierta:
        return _CalculoPoligonal(s);
      case TipoEjercicio.sobrerotura:
        return _CalculoSobrerotura(s);
      case TipoEjercicio.replanteo:
        return _CalculoReplanteo(s);
    }
  }
}

class _CalculoPoligonal extends StatelessWidget {
  final SesionCaso s;
  const _CalculoPoligonal(this.s);

  @override
  Widget build(BuildContext context) {
    final r = s.resultado!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          s.caso.andamiaje == Andamiaje.alto
              ? 'Revisa el cálculo tramo por tramo. Cada azimut se obtiene del '
                  'azimut de atrás más el ángulo horizontal medido.'
              : 'Calcula cada tramo y verifica. Tienes la libreta disponible en '
                  'el paso anterior.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        for (final t in r.tramos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TarjetaTramo(s: s, tramo: t),
          ),
      ],
    );
  }
}

class _TarjetaTramo extends StatefulWidget {
  final SesionCaso s;
  final TramoCalculado tramo;
  const _TarjetaTramo({required this.s, required this.tramo});

  @override
  State<_TarjetaTramo> createState() => _TarjetaTramoState();
}

class _TarjetaTramoState extends State<_TarjetaTramo> {
  double? _az;
  double? _dh;
  bool _mostrarProcedimiento = false;
  String? _mensaje;

  bool get _revelado =>
      widget.s.caso.andamiaje == Andamiaje.alto ||
      (widget.s.tramosVerificados[widget.tramo.indice] ?? false);

  bool get _pideDistancia => widget.s.caso.andamiaje == Andamiaje.bajo;

  void _verificar() {
    final t = widget.tramo;
    final okAz = _az != null && (norm180(_az! - t.azimut)).abs() <= 0.01;
    final okDh = !_pideDistancia ||
        (_dh != null && (_dh! - t.distanciaHorizontal).abs() <= 0.02);

    if (okAz && okDh) {
      widget.s.marcarTramoVerificado(t.indice);
      setState(() => _mensaje = null);
    } else {
      setState(() {
        if (!okAz && _az == null) {
          _mensaje = 'Completa el azimut del tramo.';
        } else if (!okAz) {
          _mensaje = 'El azimut no coincide. Recuerda: azimut de atrás más '
              'ángulo horizontal, normalizado a 360°.';
        } else {
          _mensaje = 'La distancia horizontal no coincide. Proyecta la '
              'distancia inclinada con el ángulo cenital.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tramo;
    return Ficha(
      resaltada: _revelado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t.desde} → ${t.hasta}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (_revelado)
                const Icon(Icons.check_circle_outline,
                    size: 18, color: Paleta.laton),
            ],
          ),
          const SizedBox(height: 6),
          Dato('Azimut de atrás', formatoGms(t.azimutAtras)),
          if (_revelado) ...[
            Dato('Azimut del tramo', formatoGms(t.azimut), destacado: true),
            Dato('Distancia horizontal',
                '${t.distanciaHorizontal.toStringAsFixed(4)} m'),
            Dato('Desnivel', '${t.desnivel.toStringAsFixed(4)} m'),
            const Divider(height: 18),
            Dato('Norte', t.punto.norte.toStringAsFixed(4)),
            Dato('Este', t.punto.este.toStringAsFixed(4)),
            Dato('Cota', t.punto.cota.toStringAsFixed(4)),
          ] else ...[
            const SizedBox(height: 10),
            EntradaGms(etiqueta: 'Azimut del tramo', alCambiar: (v) => _az = v),
            if (_pideDistancia) ...[
              const SizedBox(height: 10),
              EntradaNumero(
                  etiqueta: 'Distancia horizontal', alCambiar: (v) => _dh = v),
            ],
            if (_mensaje != null) ...[
              const SizedBox(height: 10),
              Text(_mensaje!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Paleta.laton)),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (!_mostrarProcedimiento) widget.s.usarAyuda();
                    setState(() => _mostrarProcedimiento = !_mostrarProcedimiento);
                  },
                  child: Text(_mostrarProcedimiento
                      ? 'Ocultar'
                      : 'Procedimiento'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                    onPressed: _verificar, child: const Text('Verificar')),
              ),
            ]),
            if (_mostrarProcedimiento) ...[
              const SizedBox(height: 12),
              Ficha(
                fondo: Paleta.nota,
                child: Text(
                  'Azimut del tramo = azimut de atrás + ángulo horizontal, '
                  'normalizado a [0°, 360°).\n'
                  'Distancia horizontal = distancia inclinada × sen(cenital).\n'
                  'Desnivel = distancia inclinada × cos(cenital) + altura de '
                  'instrumento − altura de prisma.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CalculoSobrerotura extends StatefulWidget {
  final SesionCaso s;
  const _CalculoSobrerotura(this.s);

  @override
  State<_CalculoSobrerotura> createState() => _CalculoSobreroturaState();
}

class _CalculoSobreroturaState extends State<_CalculoSobrerotura> {
  double? _vol;
  double? _sob;
  String? _mensaje;
  bool _ayuda = false;

  void _verificar() {
    final s = widget.s;
    final okV = _vol != null && (_vol! - s.volumenReal!).abs() <= 0.5;
    final okS = _sob != null && (_sob! - s.sobreroturaLinealMedia!).abs() <= 0.005;
    if (okV && okS) {
      s.marcarSobreroturaVerificada();
      setState(() => _mensaje = null);
    } else {
      setState(() => _mensaje = !okV
          ? 'El volumen real no coincide. Aplica áreas medias entre progresivas '
              'consecutivas.'
          : 'La sobrerotura lineal media no coincide. Divide el volumen '
              'sobreexcavado entre el perímetro de la sección y la longitud.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final hecho = s.sobreroturaVerificada || s.caso.andamiaje == Andamiaje.alto;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Calcula el volumen excavado y la sobrerotura.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        if (hecho)
          Ficha(
            resaltada: true,
            child: Column(children: [
              Dato('Volumen real', '${s.volumenReal!.toStringAsFixed(2)} m³'),
              Dato('Volumen de diseño',
                  '${s.volumenDiseno!.toStringAsFixed(2)} m³'),
              Dato('Volumen sobreexcavado',
                  '${s.volumenSobrerotura!.toStringAsFixed(2)} m³',
                  destacado: true),
              Dato('Sobrerotura lineal media',
                  '${s.sobreroturaLinealMedia!.toStringAsFixed(3)} m',
                  destacado: true),
            ]),
          )
        else
          Ficha(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EntradaNumero(
                    etiqueta: 'Volumen real por áreas medias',
                    sufijo: 'm³',
                    alCambiar: (v) => _vol = v),
                const SizedBox(height: 12),
                EntradaNumero(
                    etiqueta: 'Sobrerotura lineal media',
                    alCambiar: (v) => _sob = v),
                if (_mensaje != null) ...[
                  const SizedBox(height: 10),
                  Text(_mensaje!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Paleta.laton)),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (!_ayuda) s.usarAyuda();
                        setState(() => _ayuda = !_ayuda);
                      },
                      child: Text(_ayuda ? 'Ocultar' : 'Procedimiento'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                        onPressed: _verificar, child: const Text('Verificar')),
                  ),
                ]),
                if (_ayuda) ...[
                  const SizedBox(height: 12),
                  Ficha(
                    fondo: Paleta.nota,
                    child: Text(
                      'Volumen por áreas medias: suma, entre progresivas '
                      'consecutivas, el promedio de sus áreas multiplicado por '
                      'la distancia entre ellas.\n'
                      'Sobrerotura lineal media = volumen sobreexcavado ÷ '
                      '(perímetro de sección × longitud del tramo).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CalculoReplanteo extends StatefulWidget {
  final SesionCaso s;
  const _CalculoReplanteo(this.s);

  @override
  State<_CalculoReplanteo> createState() => _CalculoReplanteoState();
}

class _CalculoReplanteoState extends State<_CalculoReplanteo> {
  double? _ang;
  double? _dh;
  double? _dz;
  String? _mensaje;
  bool _ayuda = false;

  void _verificar() {
    final r = widget.s.replanteo!;
    final okA = _ang != null && norm180(_ang! - r.anguloAGirar).abs() <= 0.0167;
    final okD = _dh != null && (_dh! - r.distanciaHorizontal).abs() <= 0.02;
    final okZ = _dz != null && (_dz! - r.desnivel).abs() <= 0.02;
    if (okA && okD && okZ) {
      widget.s.marcarReplanteoVerificado();
      setState(() => _mensaje = null);
    } else {
      setState(() => _mensaje = !okA
          ? 'El ángulo a girar no coincide. Es la diferencia entre el azimut al '
              'objetivo y el azimut a la referencia.'
          : (!okD
              ? 'La distancia horizontal no coincide.'
              : 'El desnivel no coincide. Es la diferencia de cotas entre punto '
                  'objetivo y estación.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final r = s.replanteo!;
    final hecho = s.replanteoVerificado || s.caso.andamiaje == Andamiaje.alto;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Calcula los datos que el operador puede materializar con el '
          'instrumento: un ángulo a girar desde una referencia visible, una '
          'distancia y un desnivel.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        if (hecho)
          Ficha(
            resaltada: true,
            child: Column(children: [
              Dato('Azimut a la referencia', formatoGms(r.azimutReferencia)),
              Dato('Azimut al objetivo', formatoGms(r.azimutObjetivo)),
              const Divider(height: 18),
              Dato('Ángulo a girar', formatoGms(r.anguloAGirar), destacado: true),
              Dato('Distancia horizontal',
                  '${r.distanciaHorizontal.toStringAsFixed(3)} m',
                  destacado: true),
              Dato('Desnivel', '${r.desnivel.toStringAsFixed(3)} m',
                  destacado: true),
              Dato('Ángulo cenital', formatoGms(r.anguloCenital)),
            ]),
          )
        else
          Ficha(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EntradaGms(etiqueta: 'Ángulo a girar', alCambiar: (v) => _ang = v),
                const SizedBox(height: 12),
                EntradaNumero(
                    etiqueta: 'Distancia horizontal', alCambiar: (v) => _dh = v),
                const SizedBox(height: 12),
                EntradaNumero(etiqueta: 'Desnivel', alCambiar: (v) => _dz = v),
                if (_mensaje != null) ...[
                  const SizedBox(height: 10),
                  Text(_mensaje!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Paleta.laton)),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (!_ayuda) s.usarAyuda();
                        setState(() => _ayuda = !_ayuda);
                      },
                      child: Text(_ayuda ? 'Ocultar' : 'Procedimiento'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                        onPressed: _verificar, child: const Text('Verificar')),
                  ),
                ]),
                if (_ayuda) ...[
                  const SizedBox(height: 12),
                  Ficha(
                    fondo: Paleta.nota,
                    child: Text(
                      'Azimut entre dos puntos = arcotangente de (ΔEste / ΔNorte), '
                      'resolviendo el cuadrante y normalizando a [0°, 360°).\n'
                      'Ángulo a girar = azimut al objetivo − azimut a la '
                      'referencia.\n'
                      'Distancia horizontal = raíz de (ΔNorte² + ΔEste²).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------ 4. Verificación

class PasoCierre extends StatelessWidget {
  final SesionCaso s;
  const PasoCierre(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    switch (s.caso.tipo) {
      case TipoEjercicio.poligonalAbierta:
        return _CierrePoligonal(s);
      case TipoEjercicio.sobrerotura:
        return _CierreSobrerotura(s);
      case TipoEjercicio.replanteo:
        return _CierreReplanteo(s);
    }
  }
}

/// Sin semáforo: los valores y la tolerancia se muestran uno junto al otro y
/// la comparación la hace el estudiante. Colorearla sería resolverla.
class _FilaCierre extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final String tolerancia;

  const _FilaCierre(this.etiqueta, this.valor, this.tolerancia);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(valor, style: cifraGrande),
              const SizedBox(width: 12),
              Expanded(
                child: Text('tolerancia $tolerancia',
                    style: cifraPequena, textAlign: TextAlign.end),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CierrePoligonal extends StatelessWidget {
  final SesionCaso s;
  const _CierrePoligonal(this.s);

  @override
  Widget build(BuildContext context) {
    final r = s.resultado!;
    final t = s.caso.tolerancia;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Cierres del levantamiento',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Ficha(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilaCierre(
                'Error angular sobre ${s.caso.idReferenciaCierre}',
                '${r.errorAngularSegundos.toStringAsFixed(1)}"',
                '± ${t.angularSeg!.toStringAsFixed(1)}"',
              ),
              const Divider(height: 1),
              _FilaCierre(
                'Error lineal en ${s.caso.cierreConocido!.id}',
                '${r.errorLinealM.toStringAsFixed(3)} m',
                '± ${t.linealM!.toStringAsFixed(3)} m',
              ),
              const Divider(height: 1),
              _FilaCierre(
                'Error de cota',
                '${r.errorCotaM.toStringAsFixed(3)} m',
                '± ${t.cotaM!.toStringAsFixed(3)} m',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Ficha(
          child: Column(children: [
            Dato('Longitud levantada', '${r.perimetro.toStringAsFixed(2)} m'),
            Dato('Relación de cierre',
                r.relacionCierre == null
                    ? '—'
                    : '1 : ${r.relacionCierre!.toStringAsFixed(0)}'),
            Dato('Componente Norte', '${r.errorNorteM.toStringAsFixed(3)} m'),
            Dato('Componente Este', '${r.errorEsteM.toStringAsFixed(3)} m'),
          ]),
        ),
        const SizedBox(height: 16),
        VistaPlanta(
          diseno: s.caso.ejeDiseno,
          real: r.puntos,
          cierreConocido: s.caso.cierreConocido,
        ),
      ],
    );
  }
}

class _CierreSobrerotura extends StatelessWidget {
  final SesionCaso s;
  const _CierreSobrerotura(this.s);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Resultado del control',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Ficha(
          child: _FilaCierre(
            'Sobrerotura lineal media',
            '${s.sobreroturaLinealMedia!.toStringAsFixed(3)} m',
            '± ${s.caso.tolerancia.sobreroturaM!.toStringAsFixed(2)} m',
          ),
        ),
        const SizedBox(height: 12),
        Ficha(
          child: Column(children: [
            Dato('Volumen real', '${s.volumenReal!.toStringAsFixed(2)} m³'),
            Dato('Volumen de diseño', '${s.volumenDiseno!.toStringAsFixed(2)} m³'),
            Dato('Sobreexcavación',
                '${s.volumenSobrerotura!.toStringAsFixed(2)} m³',
                destacado: true),
          ]),
        ),
      ],
    );
  }
}

class _CierreReplanteo extends StatelessWidget {
  final SesionCaso s;
  const _CierreReplanteo(this.s);

  @override
  Widget build(BuildContext context) {
    final r = s.replanteo!;
    final rep = s.caso.replanteo!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Datos a entregar al frente',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Ficha(
          resaltada: true,
          child: Column(children: [
            Dato('Desde estación', rep.estacion.id),
            Dato('Orientando a', rep.referencia.id),
            const Divider(height: 18),
            Dato('Ángulo a girar', formatoGms(r.anguloAGirar), destacado: true),
            Dato('Distancia horizontal',
                '${r.distanciaHorizontal.toStringAsFixed(3)} m',
                destacado: true),
            Dato('Desnivel', '${r.desnivel.toStringAsFixed(3)} m', destacado: true),
          ]),
        ),
        const SizedBox(height: 16),
        VistaPlanta(
          diseno: [rep.estacion, rep.objetivo],
          real: [rep.estacion, rep.referencia],
          cierreConocido: rep.objetivo,
          mostrarDesviacion: false,
          alto: 240,
        ),
      ],
    );
  }
}
