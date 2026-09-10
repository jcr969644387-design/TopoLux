import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:topolux/dominio/modelos.dart';
import 'package:topolux/dominio/motor_topografico.dart';

/// Esta batería es la defensa principal del producto.
///
/// Los casos se generan con tool/topo.py y el motor de la app está escrito en
/// Dart: son dos implementaciones independientes de la misma matemática. Si
/// divergen, la app estaría enseñando cálculos erróneos con total apariencia
/// de corrección, que es el peor fallo posible en una herramienta educativa.
/// Estas pruebas comparan una contra otra en los doce casos publicados.

List<Map<String, dynamic>> _cargarCasos() {
  final dir = Directory('assets/casos');
  if (!dir.existsSync()) {
    throw StateError('No existe assets/casos. Ejecuta primero '
        'python3 tool/generar_casos.py');
  }
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json') && !f.path.endsWith('indice.json'))
      .map((f) => json.decode(f.readAsStringSync()) as Map<String, dynamic>)
      .toList();
}

void main() {
  group('utilidades angulares', () {
    test('norm360 lleva cualquier ángulo al rango [0, 360)', () {
      expect(norm360(370), closeTo(10, 1e-9));
      expect(norm360(-10), closeTo(350, 1e-9));
      expect(norm360(0), 0);
      expect(norm360(720.5), closeTo(0.5, 1e-9));
    });

    test('norm180 devuelve la diferencia más corta', () {
      expect(norm180(350), closeTo(-10, 1e-9));
      expect(norm180(190), closeTo(-170, 1e-9));
      expect(norm180(10), closeTo(10, 1e-9));
      expect(norm180(180), closeTo(180, 1e-9));
    });

    test('gms y grados decimales son inversos', () {
      const g = 128.2358333333;
      final texto = formatoGms(g);
      expect(texto.startsWith('128°14'), isTrue, reason: texto);
      expect(gmsAGrados(128, 14, 9.0), closeTo(128.2358333, 1e-6));
    });

    test('formatoGms no produce 60 minutos ni 60 segundos', () {
      expect(formatoGms(45.9999999), isNot(contains("60'")));
      expect(formatoGms(45.9999999), isNot(contains('60.00"')));
    });
  });

  group('poligonal contra la solución de referencia', () {
    final casos = _cargarCasos()
        .where((j) => j['identificacion']['tipo_ejercicio'] == 'poligonal_abierta')
        .toList()
      ..sort((a, b) => (a['identificacion']['orden'] as int)
          .compareTo(b['identificacion']['orden'] as int));

    test('hay casos de poligonal publicados', () {
      expect(casos.length, greaterThanOrEqualTo(10));
    });

    for (final j in casos) {
      final caso = Caso.desdeJson(j);
      test('${caso.orden}. ${caso.id}', () {
        final r = MotorTopografico.resolverPoligonal(
          arranque: caso.arranque!,
          orientacion: caso.orientacion!,
          filas: caso.libreta,
          azimutCierreReferencia: caso.azimutCierreReferencia!,
          cierreConocido: caso.cierreConocido!,
        );
        final ref = caso.solucionReferencia;

        expect(r.errorAngularSegundos,
            closeTo((ref['error_angular_segundos'] as num).toDouble(), 0.05),
            reason: 'cierre angular');
        expect(r.errorLinealM,
            closeTo((ref['error_lineal_m'] as num).toDouble(), 0.001),
            reason: 'cierre lineal');
        expect(r.errorCotaM,
            closeTo((ref['error_cota_m'] as num).toDouble(), 0.001),
            reason: 'cierre de cota');
        expect(r.perimetro,
            closeTo((ref['perimetro_m'] as num).toDouble(), 0.001),
            reason: 'perímetro');

        final puntosRef = (ref['puntos'] as List).cast<Map<String, dynamic>>();
        expect(r.puntos.length, puntosRef.length);
        for (var i = 0; i < puntosRef.length; i++) {
          expect(r.puntos[i].norte,
              closeTo((puntosRef[i]['norte'] as num).toDouble(), 0.001),
              reason: 'norte del punto $i');
          expect(r.puntos[i].este,
              closeTo((puntosRef[i]['este'] as num).toDouble(), 0.001),
              reason: 'este del punto $i');
          expect(r.puntos[i].cota,
              closeTo((puntosRef[i]['cota'] as num).toDouble(), 0.001),
              reason: 'cota del punto $i');
        }

        final tramosRef = (ref['tramos'] as List).cast<Map<String, dynamic>>();
        for (var i = 0; i < tramosRef.length; i++) {
          expect(
            norm180(r.tramos[i].azimut -
                    (tramosRef[i]['azimut'] as num).toDouble())
                .abs(),
            lessThan(1e-4),
            reason: 'azimut del tramo $i',
          );
          expect(r.tramos[i].distanciaHorizontal,
              closeTo((tramosRef[i]['distancia_horizontal'] as num).toDouble(), 0.001),
              reason: 'distancia horizontal del tramo $i');
        }
      });
    }

    test('la compensación de Bowditch anula el error de cierre', () {
      final caso = Caso.desdeJson(casos.first);
      final r = MotorTopografico.resolverPoligonal(
        arranque: caso.arranque!,
        orientacion: caso.orientacion!,
        filas: caso.libreta,
        azimutCierreReferencia: caso.azimutCierreReferencia!,
        cierreConocido: caso.cierreConocido!,
      );
      final comp = compensarBowditch(r);
      expect(comp.last.norte, closeTo(caso.cierreConocido!.norte, 1e-6));
      expect(comp.last.este, closeTo(caso.cierreConocido!.este, 1e-6));
      expect(comp.first.norte, closeTo(caso.arranque!.norte, 1e-9));
    });
  });

  group('sobrerotura y replanteo', () {
    test('el volumen por áreas medias coincide con la referencia', () {
      final j = _cargarCasos().firstWhere(
          (c) => c['identificacion']['tipo_ejercicio'] == 'sobrerotura');
      final caso = Caso.desdeJson(j);
      final d = caso.sobrerotura!;
      final real = d.progresivas
          .map((e) => (progresiva: e.progresiva, area: e.areaReal))
          .toList();
      final disenio = d.progresivas
          .map((e) => (progresiva: e.progresiva, area: d.areaDiseno))
          .toList();
      final vReal = MotorTopografico.volumenAreasMedias(real);
      final vDis = MotorTopografico.volumenAreasMedias(disenio);
      expect(vReal,
          closeTo((caso.solucionReferencia['volumen_real_m3'] as num).toDouble(), 0.01));
      expect(vDis,
          closeTo((caso.solucionReferencia['volumen_diseno_m3'] as num).toDouble(), 0.01));

      final longitud = d.progresivas.last.progresiva - d.progresivas.first.progresiva;
      final lineal = (vReal - vDis) / (d.perimetroSeccion * longitud);
      expect(
        lineal,
        closeTo(
            (caso.solucionReferencia['sobrerotura_lineal_media_m'] as num).toDouble(),
            0.0005),
      );
    });

    test('el replanteo coincide con la referencia', () {
      final j = _cargarCasos()
          .firstWhere((c) => c['identificacion']['tipo_ejercicio'] == 'replanteo');
      final caso = Caso.desdeJson(j);
      final rep = caso.replanteo!;
      final r = MotorTopografico.resolverReplanteo(
        estacion: rep.estacion,
        referencia: rep.referencia,
        objetivo: rep.objetivo,
        alturaInstrumento: rep.alturaInstrumento,
        alturaPrisma: rep.alturaPrisma,
      );
      final ref = caso.solucionReferencia;
      expect(r.anguloAGirar,
          closeTo((ref['angulo_a_girar'] as num).toDouble(), 1e-5));
      expect(r.distanciaHorizontal,
          closeTo((ref['distancia_horizontal'] as num).toDouble(), 0.001));
      expect(r.desnivel, closeTo((ref['desnivel'] as num).toDouble(), 0.001));
    });
  });

  group('coherencia del contenido publicado', () {
    final casos = _cargarCasos();

    test('cada caso tiene exactamente una justificación correcta', () {
      for (final j in casos) {
        final c = Caso.desdeJson(j);
        expect(c.justificaciones.where((x) => x.correcta).length, 1,
            reason: c.id);
      }
    });

    test('cada caso tiene consecuencia para las cuatro decisiones', () {
      for (final j in casos) {
        final c = Caso.desdeJson(j);
        expect(c.consecuencias.length, Decision.values.length, reason: c.id);
      }
    });

    test('ningún caso publicado se declara validado sin revisor', () {
      for (final j in casos) {
        final m = j['metadatos'] as Map<String, dynamic>;
        if ((m['estado'] as String) == 'publicado') {
          expect((m['validado_por'] as String).contains('PENDIENTE'), isFalse,
              reason: j['identificacion']['id'] as String);
        }
      }
    });
  });
}
