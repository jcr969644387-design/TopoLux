import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/motor_topografico.dart';
import '../tema.dart';

/// Entrada de ángulos sexagesimales.
///
/// Un solo campo de texto libre para "128°14'30\"" genera errores de formato
/// que después se confunden con errores topográficos. Tres campos segmentados
/// con avance automático y validación de rango eliminan esa fuente de ruido:
/// el estudiante sólo teclea números.
class EntradaGms extends StatefulWidget {
  final String etiqueta;
  final ValueChanged<double?> alCambiar;
  final bool habilitado;

  const EntradaGms({
    super.key,
    required this.etiqueta,
    required this.alCambiar,
    this.habilitado = true,
  });

  @override
  State<EntradaGms> createState() => _EntradaGmsState();
}

class _EntradaGmsState extends State<EntradaGms> {
  final _g = TextEditingController();
  final _m = TextEditingController();
  final _s = TextEditingController();
  final _fm = FocusNode();
  final _fs = FocusNode();
  String? _aviso;

  @override
  void dispose() {
    _g.dispose();
    _m.dispose();
    _s.dispose();
    _fm.dispose();
    _fs.dispose();
    super.dispose();
  }

  void _recalcular() {
    final g = int.tryParse(_g.text);
    final m = int.tryParse(_m.text) ?? 0;
    final s = double.tryParse(_s.text.replaceAll(',', '.')) ?? 0;

    String? aviso;
    if (m >= 60) aviso = 'Los minutos deben ser menores que 60.';
    if (s >= 60) aviso = 'Los segundos deben ser menores que 60.';
    if (g != null && (g < 0 || g > 360)) aviso = 'El azimut va de 0 a 360 grados.';

    setState(() => _aviso = aviso);
    if (g == null || aviso != null) {
      widget.alCambiar(null);
    } else {
      widget.alCambiar(gmsAGrados(g, m, s));
    }
  }

  Widget _campo(
    TextEditingController c,
    String sufijo,
    int maxLargo, {
    FocusNode? foco,
    FocusNode? siguiente,
    bool decimal = false,
  }) {
    return SizedBox(
      width: decimal ? 84 : 72,
      child: TextField(
        controller: c,
        focusNode: foco,
        enabled: widget.habilitado,
        keyboardType:
            TextInputType.numberWithOptions(decimal: decimal, signed: false),
        inputFormatters: [
          LengthLimitingTextInputFormatter(maxLargo),
          FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
        ],
        style: cifra,
        textAlign: TextAlign.end,
        decoration: InputDecoration(suffixText: sufijo),
        onChanged: (v) {
          if (!decimal && v.length == maxLargo && siguiente != null) {
            siguiente.requestFocus();
          }
          _recalcular();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.etiqueta, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Row(
          children: [
            _campo(_g, '°', 3, siguiente: _fm),
            const SizedBox(width: 6),
            _campo(_m, "'", 2, foco: _fm, siguiente: _fs),
            const SizedBox(width: 6),
            _campo(_s, '"', 5, foco: _fs, decimal: true),
          ],
        ),
        if (_aviso != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_aviso!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Paleta.laton)),
          ),
      ],
    );
  }
}

/// Campo numérico simple para distancias y cotas.
class EntradaNumero extends StatelessWidget {
  final String etiqueta;
  final String sufijo;
  final ValueChanged<double?> alCambiar;
  final bool habilitado;

  const EntradaNumero({
    super.key,
    required this.etiqueta,
    required this.alCambiar,
    this.sufijo = 'm',
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        SizedBox(
          width: 150,
          child: TextField(
            enabled: habilitado,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
            ],
            style: cifra,
            textAlign: TextAlign.end,
            decoration: InputDecoration(suffixText: sufijo),
            onChanged: (v) =>
                alCambiar(double.tryParse(v.replaceAll(',', '.'))),
          ),
        ),
      ],
    );
  }
}
