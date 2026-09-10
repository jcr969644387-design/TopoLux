/// Catálogo de errores tipificados.
///
/// Cada error debe tener una firma numérica distinguible de las demás; el
/// validador de casos (tool/generar_casos.py) comprueba esa condición antes
/// de publicar cualquier caso. Si dos errores compartieran firma, el
/// estudiante enfrentaría casos con dos diagnósticos igualmente defendibles.
library;

class TipoError {
  final String clave;
  final String nombre;
  final String firma;
  final String pista;

  const TipoError({
    required this.clave,
    required this.nombre,
    required this.firma,
    required this.pista,
  });
}

const List<TipoError> catalogoErrores = [
  TipoError(
    clave: 'ninguno',
    nombre: 'Sin error — el trabajo cumple',
    firma: 'Los tres cierres dentro de tolerancia.',
    pista: 'No todo residuo es un error. Compara contra la tolerancia, no contra cero.',
  ),
  TipoError(
    clave: 'error_lectura_angulo',
    nombre: 'Equivocación de lectura angular',
    firma: 'Error angular concentrado en una estación; la poligonal gira sólo '
        'a partir de ella.',
    pista: 'La forma se conserva antes de la estación afectada y se desvía después.',
  ),
  TipoError(
    clave: 'confusion_cenital_vertical',
    nombre: 'Confusión ángulo cenital / vertical',
    firma: 'Planimetría intacta; el desnivel de un tramo aparece con el signo '
        'invertido.',
    pista: 'El seno del ángulo no cambia al confundirlos: la distancia horizontal '
        'queda igual.',
  ),
  TipoError(
    clave: 'altura_instrumento',
    nombre: 'Altura de instrumento mal anotada',
    firma: 'Planimetría intacta; la cota se desplaza un valor constante, sin '
        'cambiar de signo.',
    pista: 'Un desplazamiento de magnitud redonda en cota suele venir de una altura.',
  ),
  TipoError(
    clave: 'orientacion_inicial',
    nombre: 'Orientación inicial equivocada',
    firma: 'Forma y distancias correctas; toda la poligonal girada un valor '
        'constante.',
    pista: 'Si el giro afecta a todos los tramos por igual, el problema está en '
        'el origen.',
  ),
  TipoError(
    clave: 'distancia_sistematica',
    nombre: 'Error sistemático de distancias',
    firma: 'Cierre angular correcto; error lineal que crece con la longitud '
        'recorrida.',
    pista: 'Constante de prisma o calibración: el error se acumula siempre en el '
        'mismo sentido.',
  ),
  TipoError(
    clave: 'punto_amarre_incorrecto',
    nombre: 'Punto de amarre incorrecto',
    firma: 'Cierre angular correcto; desplazamiento constante e independiente de '
        'la longitud.',
    pista: 'Las mediciones son correctas: el error está en las coordenadas de '
        'partida.',
  ),
  TipoError(
    clave: 'brujula_ferromagnetica',
    nombre: 'Brújula afectada por material ferromagnético',
    firma: 'Desvío del azimut sólo en los tramos con cerchas, rieles o tubería '
        'próximos.',
    pista: 'Lee las observaciones de campo: la libreta anuncia dónde hay metal.',
  ),
];

const TipoError errorSobrerotura = TipoError(
  clave: 'sobrerotura_excedida',
  nombre: 'Sobrerotura por encima de la tolerancia',
  firma: 'Volumen excavado superior al de diseño más allá del estándar.',
  pista: 'Convierte el volumen sobreexcavado a sobrerotura lineal media antes de '
      'compararlo con la tolerancia.',
);

TipoError errorPorClave(String clave) => catalogoErrores.firstWhere(
      (e) => e.clave == clave,
      orElse: () => clave == errorSobrerotura.clave
          ? errorSobrerotura
          : const TipoError(
              clave: 'desconocido',
              nombre: 'No tipificado',
              firma: '',
              pista: '',
            ),
    );

/// Errores que el estudiante puede llegar a dominar (excluye el caso limpio,
/// que se evalúa como "no sobre-diagnosticar" y no como dominio de un error).
List<TipoError> get erroresEvaluables =>
    catalogoErrores.where((e) => e.clave != 'ninguno').toList();

/// Descripción legible de una anomalía calculada por el motor.
const Map<String, String> descripcionAnomalia = {
  'ninguna': 'Sin anomalía: los cierres están dentro de tolerancia.',
  'rotacion_parcial': 'La poligonal conserva su forma pero gira a partir de una '
      'estación intermedia.',
  'rotacion_total': 'La poligonal conserva forma y distancias, pero está girada '
      'por completo.',
  'desnivel_invertido': 'Un tramo presenta el desnivel con el signo invertido y '
      'la planimetría intacta.',
  'cota_desplazada_constante': 'La cota está desplazada un valor constante con la '
      'planimetría intacta.',
  'error_proporcional_longitud': 'El error lineal crece con la longitud recorrida.',
  'desplazamiento_constante': 'Desplazamiento constante en planta, independiente '
      'de la longitud.',
  'desvio_en_tramos_metalicos': 'El desvío se concentra en los tramos con presencia '
      'de metal.',
};
