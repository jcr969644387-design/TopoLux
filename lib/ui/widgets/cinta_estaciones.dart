import 'package:flutter/material.dart';

import '../tema.dart';

/// La poligonal es una cadena: cada estación depende de la anterior.
///
/// Mostrar la libreta como tabla en un móvil es ilegible, y además esconde
/// esa dependencia. La cinta la hace visible y sirve de índice del recorrido.
class CintaEstaciones extends StatelessWidget {
  final List<String> nombres;
  final int actual;
  final Set<int> procesadas;
  final ValueChanged<int>? alTocar;

  const CintaEstaciones({
    super.key,
    required this.nombres,
    required this.actual,
    this.procesadas = const {},
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: nombres.length,
        itemBuilder: (context, i) {
          final esActual = i == actual;
          final hecha = procesadas.contains(i);
          return Row(
            children: [
              GestureDetector(
                onTap: alTocar == null ? null : () => alTocar!(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: esActual ? Paleta.tinta : Paleta.papelAlto,
                    border: Border.all(
                      color: esActual
                          ? Paleta.tinta
                          : (hecha ? Paleta.laton : Paleta.lineaFuerte),
                      width: hecha && !esActual ? 1.6 : 1,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hecha && !esActual)
                        const Padding(
                          padding: EdgeInsets.only(right: 5),
                          child: Icon(Icons.check, size: 14, color: Paleta.laton),
                        ),
                      Text(
                        nombres[i],
                        style: cifraPequena.copyWith(
                          color: esActual ? Paleta.papelAlto : Paleta.tinta,
                          fontWeight:
                              esActual ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < nombres.length - 1)
                Container(width: 18, height: 1, color: Paleta.linea),
            ],
          );
        },
      ),
    );
  }
}
