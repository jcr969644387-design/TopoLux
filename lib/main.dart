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
      home: PantallaInicio(casos: casos, progreso: progreso),
    );
  }
}
