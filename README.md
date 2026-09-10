# TopoLux

Entrenador de criterio topográfico para estudiantes de Ingeniería de Minas.

No es un simulador de estación total ni un repositorio de teoría. El ciclo es
siempre el mismo: **recibes una libreta de campo → la procesas → detectas si
algo está mal → decides qué hacer → asumes la consecuencia**.

---

## Cómo generar el APK

Este código está completo, pero **el APK debe compilarse en tu máquina**: la
compilación necesita el SDK de Flutter y el SDK de Android.

### Requisitos

- Flutter 3.10 o superior (`flutter --version`)
- Android SDK configurado (`flutter doctor` sin errores en la sección Android)
- Python 3.10 o superior (sólo para regenerar los casos; no hace falta para compilar)

### Camino corto

```bash
cd topolux
./construir_apk.sh
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

### Camino paso a paso

```bash
cd topolux

# 1. Crear el andamiaje de plataforma (android/), que no viaja en este paquete
flutter create --org pe.topolux --project-name topolux --platforms=android .

# 2. Dependencias
flutter pub get

# 3. Pruebas del motor de cálculo
flutter test

# 4. Ejecutar en un dispositivo conectado
flutter run

# 5. O compilar el APK de release
flutter build apk --release
```

`flutter create` sobre un directorio existente **no toca** `lib/`, `test/`,
`assets/` ni `pubspec.yaml`: sólo añade las carpetas de plataforma que faltan.

---

## Estructura

```
topolux/
├── tool/                      Generador y validador de casos (Python)
│   ├── topo.py                Motor topográfico de referencia
│   ├── contenido.py           Los 10 casos de poligonal
│   ├── contenido_d.py         Sobrerotura y replanteo
│   └── generar_casos.py       Genera y VALIDA assets/casos/*.json
├── assets/casos/              12 casos + índice (generados, no editar a mano)
├── lib/
│   ├── dominio/               Sin dependencias de Flutter: se prueba solo
│   │   ├── motor_topografico.dart
│   │   ├── modelos.dart
│   │   ├── catalogo_errores.dart
│   │   └── motor_progresion.dart
│   ├── datos/repositorios.dart
│   ├── sesion/sesion_caso.dart   Máquina de estados del ciclo
│   └── ui/                    Tema, pantallas, los 9 pasos y widgets
└── test/motor_topografico_test.dart
```

---

## La decisión de diseño más importante

El contenido **no se escribe a mano**. El autor declara la geometría limpia y
qué error inducir; `tool/generar_casos.py` deriva las lecturas de campo, aplica
el error, resuelve la poligonal y congela la solución de referencia.

Después **valida**, y se niega a publicar un caso si:

1. la geometría limpia no cierra dentro de tolerancia antes de inducir el error;
2. la firma numérica resultante no es la que corresponde a ese tipo de error;
3. **la firma no es distinguible de la de los otros errores del catálogo**;
4. la decisión correcta declarada no es coherente con el resultado calculado;
5. no hay exactamente una justificación correcta y tres distractores;
6. un texto de consecuencia referencia un campo que no existe;
7. el diagnóstico está incompleto.

La regla 3 es la que ningún autor humano puede verificar solo. Sin ella
aparecerían casos con dos diagnósticos igualmente defendibles, y la app
calificaría mal a quien razona bien.

Regenerar los casos:

```bash
python3 tool/generar_casos.py
```

Imprime una tabla con los cierres reales de los 12 casos y falla con código
distinto de cero si alguno no valida.

### Doble implementación deliberada

La matemática está escrita **dos veces**: en Python (`tool/topo.py`, que genera
los casos) y en Dart (`lib/dominio/motor_topografico.dart`, que ejecuta la app).
`test/motor_topografico_test.dart` compara una contra otra en los doce casos.

Es redundancia intencional. El peor fallo posible en esta app no es que se
caiga: es que calcule mal con apariencia de corrección y enseñe el error.

---

## Integración continua

Cada push a `main` ejecuta `.github/workflows/ci.yml`:

1. Regenera y **valida** los 12 casos, y comprueba que no difieren de los
   versionados.
2. Corre `flutter analyze` y las pruebas que comparan el motor Dart contra las
   soluciones de referencia generadas en Python.
3. **Compila el APK de release y lo publica como artefacto descargable** en la
   pestaña Actions.

Instrucciones de publicación en `GITHUB.md`.

---

## Los 12 casos

| # | Caso | Error diagnosticable | Decisión correcta |
|---|---|---|---|
| 1 | Galería 118 N — arrastre limpio | ninguno | aceptar |
| 2 | Galería 118 N — lectura dudosa | lectura angular | repetir |
| 3 | Crucero 220 E — poligonal larga | ninguno | compensar |
| 4 | Rampa 340 — gradiente | cenital/vertical | repetir |
| 5 | Galería 455 S — avance mensual | altura de instrumento | repetir |
| 6 | Galería 118 N — reinicio | orientación inicial | escalar |
| 7 | Crucero 220 E — equipo | distancias sistemático | escalar |
| 8 | Galería 455 S — amarre | punto de amarre | escalar |
| 9 | Chimenea 780 — brújula | brújula ferromagnética | repetir |
| 10 | Crucero 220 E — al límite | ninguno (error dentro de tolerancia) | compensar |
| 11 | Galería 118 N — sobrerotura | sobrerotura excedida | escalar |
| 12 | Galería 118 N — dar línea | ninguno | aceptar |

El caso 10 es deliberado: existe un error real, pero no supera la tolerancia.
Lo esperado es **no** diagnosticarlo. Sobre-diagnosticar cuesta turnos.

---

## Advertencias antes de usarlo con estudiantes

**Las tolerancias no están validadas.** Los valores usados (30"·√n angular,
1:3000 lineal, ±0,05 m en cota, ±0,10 m de sobrerotura) son plausibles pero
provienen de esta construcción, no de un estándar verificado de una operación
real. Los doce casos llevan `metadatos.estado: "borrador"` y
`validado_por: "PENDIENTE"`. Un topógrafo de mina en ejercicio debe revisarlos
antes de cualquier uso en aula. El catálogo de errores y las firmas numéricas
son sólidos; los números de tolerancia son el punto débil.

**No hay IA en esta versión.** El diagnóstico se hace por reglas deterministas:
es exacto, funciona sin conexión y no cuesta nada. La IA tiene su lugar en la
autoría de casos, no en el juicio que se le pide al estudiante.

**No hay backend ni cuentas.** La app no envía nada por internet. El progreso se
guarda en el dispositivo con un código anónimo (`TPX-XXnnnn`) y se exporta al
portapapeles si el docente lo pide. Si el pilotaje se hace con datos
identificables, hace falta consentimiento informado conforme a la Ley N.° 29733.

---

## Qué falta para llegar a producción

1. Validación de tolerancias y textos por un topógrafo de mina en ejercicio.
2. Pilotaje con 20–30 estudiantes en un curso real. Umbrales fijados en el
   análisis previo: detección ≥ 80 %, diagnóstico ≥ 60 %, decisión ≥ 70 %.
3. Ampliar el catálogo a 25–30 casos. El cuello de botella es el contenido, no
   el código: cada caso nuevo son datos, no programación.
4. Tajo abierto, perfil longitudinal y modo examen, sólo si el pilotaje
   confirma que el ciclo funciona.
