import 'package:flutter/material.dart';

/// Paleta anclada al objeto que la app imita: la libreta de campo de un
/// topógrafo de mina. Papel técnico frío, tinta azul muy oscura, retícula
/// tenue y un único acento en latón, del color de los instrumentos.
///
/// Los dos colores de datos (diseño y real) sólo aparecen en la vista en
/// planta. En la pantalla de verificación NO hay semáforo: comparar el cierre
/// con la tolerancia es la habilidad que se evalúa, y colorearla la sustituye.
class Paleta {
  static const papel = Color(0xFFEEF1F4);
  static const papelAlto = Color(0xFFF7F9FA);
  static const tinta = Color(0xFF16202B);
  static const grafito = Color(0xFF5A6875);
  static const linea = Color(0xFFC9D2DA);
  static const laton = Color(0xFF9A6B24);

  // Sólo para la vista en planta.
  static const diseno = Color(0xFF2E4A73);
  static const real = Color(0xFFA9762A);
  static const control = Color(0xFF16202B);
}

const TextStyle cifra = TextStyle(
  fontFamily: 'monospace',
  fontSize: 17,
  height: 1.35,
  color: Paleta.tinta,
);

const TextStyle cifraGrande = TextStyle(
  fontFamily: 'monospace',
  fontSize: 26,
  height: 1.2,
  color: Paleta.tinta,
);

const TextStyle cifraPequena = TextStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  height: 1.3,
  color: Paleta.grafito,
);

ThemeData construirTema() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Paleta.papel,
    colorScheme: base.colorScheme.copyWith(
      primary: Paleta.tinta,
      secondary: Paleta.laton,
      surface: Paleta.papelAlto,
      onSurface: Paleta.tinta,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.papel,
      foregroundColor: Paleta.tinta,
      elevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(color: Paleta.linea, thickness: 1, space: 1),
    textTheme: base.textTheme
        .apply(bodyColor: Paleta.tinta, displayColor: Paleta.tinta)
        .copyWith(
          titleLarge: const TextStyle(
              fontSize: 21, fontWeight: FontWeight.w600, height: 1.25),
          titleMedium: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
          bodyMedium: const TextStyle(fontSize: 15, height: 1.5),
          bodySmall: TextStyle(fontSize: 13.5, height: 1.45, color: Paleta.grafito),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.tinta,
        foregroundColor: Paleta.papelAlto,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Paleta.tinta,
        side: const BorderSide(color: Paleta.linea),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Paleta.papelAlto,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Paleta.linea),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Paleta.linea),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Paleta.laton, width: 2),
      ),
    ),
  );
}

/// Ficha de papel: la unidad de contenido de toda la app.
class Ficha extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? fondo;
  final bool resaltada;

  const Ficha({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.fondo,
    this.resaltada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: fondo ?? Paleta.papelAlto,
        border: Border.all(
          color: resaltada ? Paleta.laton : Paleta.linea,
          width: resaltada ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }
}

/// Par etiqueta / valor con el valor en cifra monoespaciada.
class Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const Dato(this.etiqueta, this.valor, {super.key, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(etiqueta,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 10),
          Text(valor,
              style: destacado
                  ? cifra.copyWith(fontWeight: FontWeight.w700)
                  : cifra),
        ],
      ),
    );
  }
}

class Titulo extends StatelessWidget {
  final String texto;
  const Titulo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
      );
}
