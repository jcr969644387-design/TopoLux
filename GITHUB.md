# Publicar TopoLux en GitHub

El repositorio Git ya está creado, con historial y con la integración continua
configurada. Faltan dos pasos que tienes que dar tú, porque requieren tu cuenta.

## 1. Crear el repositorio vacío

En GitHub: **New repository** → nombre `TopoLux` → **sin** README, sin
.gitignore y sin licencia (ya vienen en el paquete). Cópiate la URL.

## 2. Conectar y subir

```bash
cd TopoLux
git remote add origin https://github.com/TU-USUARIO/TopoLux.git
git push -u origin main
```

Si usas SSH:

```bash
git remote add origin git@github.com:TU-USUARIO/TopoLux.git
git push -u origin main
```

## 3. Lo que ocurre automáticamente al subir

`.github/workflows/ci.yml` se ejecuta en cada push a `main`:

| Trabajo | Qué hace |
|---|---|
| `validar` | Regenera y valida los 12 casos, comprueba que no difieren de los versionados, corre `flutter analyze` y las pruebas del motor |
| `apk` | **Compila el APK de release y lo publica como artefacto descargable** |

Esto resuelve la limitación que te mencioné: yo no puedo compilar el APK aquí,
pero los runners de GitHub sí, y gratis en repositorios públicos. Tras el push,
entra en la pestaña **Actions**, abre la ejecución más reciente y descarga el
artefacto `topolux-apk`.

## Sugerencias de configuración

- **Topics**: `flutter`, `dart`, `educacion`, `topografia`, `mineria`, `edtech`
- **Descripción**: «Entrenador de criterio topográfico para Ingeniería de Minas»
- Protege `main` exigiendo que la CI pase antes de fusionar.

## Si `git push` pide usuario y contraseña

GitHub ya no acepta contraseñas por HTTPS. Usa un *personal access token* como
contraseña, o configura una clave SSH. No compartas ese token con nadie, yo
incluido.
