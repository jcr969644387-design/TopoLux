// Prueba de humo de la aplicación.
//
// Existe además por una razón de integración continua: el flujo de CI ejecuta
// `flutter create` para reconstruir el andamiaje de Android, y ese comando
// genera una plantilla de prueba que instancia `MyApp`, una clase que este
// proyecto no tiene (la raíz es `AppTopoLux`). `flutter create` no sobrescribe
// archivos existentes, así que mantener este archivo versionado impide que la
// plantilla reaparezca y rompa el analizador.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topolux/datos/repositorios.dart';
import 'package:topolux/main.dart';

void main() {
  testWidgets('La pantalla de inicio carga el índice de casos',
      (WidgetTester tester) async {
    await tester.pumpWidget(AppTopoLux(
      casos: RepositorioCasos(),
      progreso: RepositorioProgreso(),
    ));

    // El índice vive en assets, de modo que el primer fotograma es el
    // indicador de carga.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Se avanza a fotogramas acotados en lugar de pumpAndSettle: el indicador
    // de carga anima en bucle y dejar que la prueba espere a que "se asiente"
    // la colgaría hasta agotar el tiempo límite.
    final cargando = find.byType(CircularProgressIndicator);
    for (var i = 0; i < 40 && cargando.evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.widgetWithText(AppBar, 'TopoLux'), findsOneWidget);
    expect(find.text('Topografía de mina'), findsOneWidget);
  });
}
