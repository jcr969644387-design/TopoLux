import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'datos/repositorios.dart';
import 'ui/pantalla_inicio.dart';
import 'ui/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Borde a borde con las barras del sistema transparentes. Android 15 dibuja
  // así de forma obligatoria, de modo que la alternativa no es una app con
  // barras opacas sino una app que no sabe dónde están: cada pantalla resuelve
  // el hueco del notch y el de la barra de navegación con SafeArea o con el
  // relleno inferior de su lista.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(barrasDelSistema);

  final progreso = RepositorioProgreso();
  await progreso.cargar();

  runApp(AppTopoLux(
    casos: RepositorioCasos(),
    progreso: progreso,
  ));
}

class AppTopoLux extends StatelessWidget {
  final RepositorioCasos casos;
  final RepositorioProgreso progreso;

  const AppTopoLux({super.key, required this.casos, required this.progreso});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TopoLux',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      // El tamaño de letra del sistema se respeta, pero se acota: por encima
      // de 1,3 los rótulos de dos líneas de la cabecera y de los botones se
      // salen de su caja en pantallas estrechas.
      builder: (context, child) {
        final escala = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: escala),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: PantallaInicio(casos: casos, progreso: progreso),
    );
  }
}
