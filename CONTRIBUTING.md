# Cómo contribuir

## Añadir un caso nuevo

Los archivos de `assets/casos/` **se generan**; no se editan a mano. Un caso
nuevo se escribe como intención en `tool/contenido.py`:

1. Define la geometría **limpia**: tramos con azimut, distancia horizontal y
   pendiente, más las alturas de instrumento y prisma por estación.
2. Declara el error a inducir como una regla (`tipo`, estación afectada,
   magnitud), no como un dato ya alterado.
3. Escribe los textos: encargo, cuatro consecuencias, cuatro justificaciones
   con una sola correcta, y el diagnóstico en tres partes.
4. Ejecuta `python3 tool/generar_casos.py`.

El validador rechaza el caso si la geometría limpia no cierra, si la firma
numérica no corresponde al error declarado, si esa firma se confunde con la de
otro error del catálogo, si la decisión correcta es incoherente con el
resultado calculado, o si algún texto referencia un campo inexistente.

Commitea `tool/contenido.py` **y** los JSON regenerados: la CI comprueba que
coincidan.

## Tocar la matemática

Si modificas `lib/dominio/motor_topografico.dart`, aplica el mismo cambio en
`tool/topo.py`. Son dos implementaciones independientes a propósito, y
`flutter test` las compara contra los doce casos. Si divergen, la prueba falla.

## Antes de abrir un PR

```bash
python3 tool/generar_casos.py
flutter analyze
flutter test
```
