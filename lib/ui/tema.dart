import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta anclada al objeto que la app imita: la libreta de campo de un
/// topógrafo de mina. Papel técnico frío, tinta azul muy oscura, retícula
/// tenue y un único acento en latón, del color de los instrumentos.
///
/// El papel no es blanco. Un fondo blanco con fichas casi blancas encima borra
/// la jerarquía y deja los textos secundarios flotando sin sostén. Aquí el
/// fondo es un gris azulado (`papel`), las fichas son blancas (`papelAlto`) y
/// las notas quedan en un tono intermedio (`nota`), de modo que cada nivel se
/// distingue del anterior tanto sobre la página como dentro de una ficha.
///
/// Los dos colores de datos (diseño y real) sólo aparecen en la vista en
/// planta. En la pantalla de verificación NO hay semáforo: comparar el cierre
/// con la tolerancia es la habilidad que se evalúa, y colorearla la sustituye.
class Paleta {
  /// Fondo de pantalla.
  static const papel = Color(0xFFDDE5ED);

  /// Fichas y campos: el nivel que sostiene el contenido.
  static const papelAlto = Color(0xFFFFFFFF);

  /// Notas y recordatorios. Legible tanto sobre `papel` como sobre `papelAlto`.
  static const nota = Color(0xFFEBF1F7);

  /// Relleno de las fichas resaltadas y de la opción elegida.
  static const papelCalido = Color(0xFFFDF5E8);

  /// Tinta: texto principal, cabeceras y botón primario. Es el mismo tono del
  /// icono de la aplicación y de la pantalla de arranque de Android.
  static const tinta = Color(0xFF0F2334);

  /// Superficie oscura secundaria (pantalla de carga, marca).
  static const tintaSuave = Color(0xFF1B3A50);

  /// Texto secundario. Contraste 6,5:1 sobre blanco.
  static const grafito = Color(0xFF4A5A6A);

  /// Bordes y retículas.
  static const linea = Color(0xFFC3CFDB);

  /// Borde de los elementos interactivos en reposo.
  static const lineaFuerte = Color(0xFF7C8FA3);

  /// Acento sobre superficies claras. Contraste 5,9:1 sobre blanco.
  static const laton = Color(0xFF8A5E1C);

  /// El mismo acento sobre superficies oscuras (marca, carga, cabeceras).
  static const latonClaro = Color(0xFFE0A03E);

  /// Texto y trazo sobre superficies oscuras.
  static const sobreTinta = Color(0xFFE9F0F6);

  // Sólo para la vista en planta.
  static const diseno = Color(0xFF27446E);
  static const real = Color(0xFF96631F);
  static const control = Color(0xFF0F2334);
}

/// Estilo de las barras del sistema: transparentes, con los iconos de arriba
/// en claro porque detrás va la cabecera oscura, y los de abajo en oscuro
/// porque detrás va el papel.
const SystemUiOverlayStyle barrasDelSistema = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

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

/// La misma cifra pequeña, para cuando va sobre una superficie oscura.
const TextStyle cifraPequenaClara = TextStyle(
  fontFamily: 'monospace',
  fontSize: 14,
  height: 1.3,
  color: Paleta.sobreTinta,
);

ThemeData construirTema() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Paleta.papel,
    colorScheme: base.colorScheme.copyWith(
      primary: Paleta.tinta,
      onPrimary: Paleta.sobreTinta,
      secondary: Paleta.laton,
      onSecondary: Paleta.sobreTinta,
      surface: Paleta.papelAlto,
      onSurface: Paleta.tinta,
      outline: Paleta.lineaFuerte,
      outlineVariant: Paleta.linea,
      surfaceTint: Colors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.tinta,
      foregroundColor: Paleta.sobreTinta,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: barrasDelSistema,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: Paleta.sobreTinta,
      ),
      iconTheme: IconThemeData(color: Paleta.sobreTinta),
      actionsIconTheme: IconThemeData(color: Paleta.sobreTinta),
    ),
    iconTheme: const IconThemeData(color: Paleta.grafito),
    dividerTheme:
        const DividerThemeData(color: Paleta.linea, thickness: 1, space: 1),
    textTheme: base.textTheme
        .apply(bodyColor: Paleta.tinta, displayColor: Paleta.tinta)
        .copyWith(
          titleLarge: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: Paleta.tinta),
          titleMedium: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: Paleta.tinta),
          bodyMedium:
              const TextStyle(fontSize: 15, height: 1.5, color: Paleta.tinta),
          bodySmall: const TextStyle(
              fontSize: 14, height: 1.45, color: Paleta.grafito),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.tinta,
        foregroundColor: Paleta.sobreTinta,
        // El botón deshabilitado conserva contraste propio: con el gris que
        // pone el tema por defecto se confunde con el fondo y parece un fallo
        // de pintado en lugar de un paso que aún no está completo.
        disabledBackgroundColor: Paleta.linea,
        disabledForegroundColor: Paleta.grafito,
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Paleta.tinta,
        backgroundColor: Paleta.papelAlto,
        disabledForegroundColor: Paleta.grafito,
        side: const BorderSide(color: Paleta.lineaFuerte, width: 1.4),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Paleta.tinta,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Paleta.laton,
      linearTrackColor: Paleta.linea,
      circularTrackColor: Paleta.linea,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Paleta.tinta,
      contentTextStyle: TextStyle(color: Paleta.sobreTinta, fontSize: 15),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Paleta.papelAlto,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      suffixStyle: const TextStyle(color: Paleta.grafito),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Paleta.lineaFuerte),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Paleta.lineaFuerte),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Paleta.laton, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Paleta.linea),
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
        color: fondo ?? (resaltada ? Paleta.papelCalido : Paleta.papelAlto),
        border: Border.all(
          color: resaltada ? Paleta.laton : Paleta.linea,
          width: resaltada ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2334),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
            child: Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 10),
          // La cifra manda sobre la etiqueta, pero cede antes que desbordar la
          // ficha en pantallas estrechas.
          Flexible(
            child: Text(
              valor,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              textAlign: TextAlign.end,
              style: destacado
                  ? cifra.copyWith(fontWeight: FontWeight.w700)
                  : cifra,
            ),
          ),
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
