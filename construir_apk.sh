#!/usr/bin/env bash
# Genera el APK de TopoLux a partir de este código fuente.
# Requisitos: Flutter 3.x y Android SDK instalados y en el PATH.
set -e

echo "== 1. Regenerando los 12 casos =="
python3 tool/generar_casos.py

echo "== 2. Creando el andamiaje de plataforma (android/, ios/) =="
flutter create --org pe.topolux --project-name topolux --platforms=android .

echo "== 3. Dependencias =="
flutter pub get

echo "== 4. Pruebas del motor topográfico =="
flutter test

echo "== 5. Compilando APK de release =="
flutter build apk --release

echo
echo "APK generado en: build/app/outputs/flutter-apk/app-release.apk"
