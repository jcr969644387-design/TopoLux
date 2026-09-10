"""
Motor topográfico de referencia — TopoLux
==========================================
Implementación en Python de la misma matemática que ejecuta el motor Dart
de la aplicación. Sirve para dos cosas:

  1. Generar los datos observados (libreta) y la solución de referencia
     de cada caso, de forma determinista.
  2. Actuar como fuente de verdad contra la cual se prueba el motor Dart.

Convenciones (idénticas a lib/dominio/motor_topografico.dart):
  - Ángulos en GRADOS DECIMALES internamente.
  - Azimut medido desde el Norte, sentido horario, normalizado a [0, 360).
  - Ángulo horizontal medido en sentido horario desde el punto de atrás
    (backsight) hacia el punto de adelante (foresight).
  - Ángulo cenital medido desde el cenit (90 grados = visual horizontal).
  - Norte = Y, Este = X.
"""

import math

# ---------------------------------------------------------------------------
# Utilidades angulares
# ---------------------------------------------------------------------------


def norm360(a: float) -> float:
    """Normaliza un ángulo a [0, 360)."""
    r = math.fmod(a, 360.0)
    return r + 360.0 if r < 0 else r


def norm180(a: float) -> float:
    """Normaliza una diferencia angular a (-180, 180]."""
    r = norm360(a)
    return r - 360.0 if r > 180.0 else r


def grados_a_gms(g: float):
    """Convierte grados decimales a (grados, minutos, segundos)."""
    signo = -1 if g < 0 else 1
    g = abs(g)
    d = int(g)
    m_f = (g - d) * 60.0
    m = int(m_f)
    s = (m_f - m) * 60.0
    if round(s, 3) >= 60.0:
        s -= 60.0
        m += 1
    if m >= 60:
        m -= 60
        d += 1
    return signo * d if d else signo * d, m, s


def fmt_gms(g: float) -> str:
    d, m, s = grados_a_gms(g)
    signo = "-" if g < 0 else ""
    return f"{signo}{abs(d)}\u00b0{m:02d}'{s:05.2f}\""


def azimut(desde, hacia) -> float:
    """Azimut de 'desde' hacia 'hacia'. Puntos como dict con 'norte' y 'este'."""
    dn = hacia["norte"] - desde["norte"]
    de = hacia["este"] - desde["este"]
    return norm360(math.degrees(math.atan2(de, dn)))


def distancia_horizontal(a, b) -> float:
    dn = b["norte"] - a["norte"]
    de = b["este"] - a["este"]
    return math.hypot(dn, de)


# ---------------------------------------------------------------------------
# Cálculo de poligonal
# ---------------------------------------------------------------------------


def resolver_poligonal(arranque, orientacion, filas, az_cierre_ref, cierre_conocido):
    """
    Resuelve una poligonal abierta con comprobación sobre punto conocido.

    arranque, orientacion, cierre_conocido: dict con norte, este, cota.
    filas: lista de dict con
        angulo_horizontal, angulo_cenital, distancia_inclinada,
        altura_instrumento, altura_prisma
        (la ÚLTIMA fila es la visual de cierre: solo angulo_horizontal).
    az_cierre_ref: azimut verdadero de la visual de cierre.

    Devuelve dict con coordenadas calculadas y los tres cierres.
    """
    puntos = [dict(arranque)]
    az_atras = azimut(arranque, orientacion)
    perimetro = 0.0
    az_tramo = None
    detalle = []

    n_tramos = len(filas) - 1

    for i in range(n_tramos):
        f = filas[i]
        az_tramo = norm360(az_atras + f["angulo_horizontal"])
        z = f["angulo_cenital"]
        sd = f["distancia_inclinada"]
        dh = sd * math.sin(math.radians(z))
        dv = sd * math.cos(math.radians(z)) + f["altura_instrumento"] - f["altura_prisma"]

        actual = puntos[-1]
        nuevo = {
            "norte": actual["norte"] + dh * math.cos(math.radians(az_tramo)),
            "este": actual["este"] + dh * math.sin(math.radians(az_tramo)),
            "cota": actual["cota"] + dv,
        }
        puntos.append(nuevo)
        perimetro += dh
        detalle.append(
            {
                "azimut": az_tramo,
                "distancia_horizontal": dh,
                "desnivel": dv,
                "norte": nuevo["norte"],
                "este": nuevo["este"],
                "cota": nuevo["cota"],
            }
        )
        az_atras = norm360(az_tramo + 180.0)

    # Visual de cierre (última fila): sólo ángulo horizontal.
    az_cierre_calc = norm360(az_atras + filas[-1]["angulo_horizontal"])
    err_ang_seg = norm180(az_cierre_calc - az_cierre_ref) * 3600.0

    final = puntos[-1]
    d_norte = final["norte"] - cierre_conocido["norte"]
    d_este = final["este"] - cierre_conocido["este"]
    d_cota = final["cota"] - cierre_conocido["cota"]
    err_lin = math.hypot(d_norte, d_este)
    relacion = (perimetro / err_lin) if err_lin > 1e-9 else float("inf")

    return {
        "puntos": puntos,
        "detalle": detalle,
        "perimetro": perimetro,
        "azimut_cierre_calculado": az_cierre_calc,
        "error_angular_segundos": err_ang_seg,
        "error_lineal_m": err_lin,
        "error_norte_m": d_norte,
        "error_este_m": d_este,
        "error_cota_m": d_cota,
        "relacion_cierre": relacion,
    }


# ---------------------------------------------------------------------------
# Generación de lecturas observadas a partir de una geometría verdadera
# ---------------------------------------------------------------------------


def construir_geometria(arranque, orientacion, tramos):
    """
    tramos: lista de dict {azimut, distancia_horizontal, pendiente_pct}
    Devuelve los puntos verdaderos del terreno.
    """
    puntos = [dict(arranque)]
    for t in tramos:
        a = puntos[-1]
        dh = t["distancia_horizontal"]
        az = t["azimut"]
        dz = dh * t["pendiente_pct"] / 100.0
        puntos.append(
            {
                "norte": a["norte"] + dh * math.cos(math.radians(az)),
                "este": a["este"] + dh * math.sin(math.radians(az)),
                "cota": a["cota"] + dz,
            }
        )
    return puntos


def lecturas_verdaderas(puntos, orientacion, az_cierre_ref, alturas):
    """
    Deriva las lecturas de campo que produciría la geometría verdadera.
    alturas: lista de (hi, hp) por estación ocupada.
    """
    filas = []
    n = len(puntos) - 1
    for i in range(n):
        est = puntos[i]
        atras = orientacion if i == 0 else puntos[i - 1]
        adelante = puntos[i + 1]
        az_atras = azimut(est, atras)
        az_adelante = azimut(est, adelante)
        ang = norm360(az_adelante - az_atras)

        hi, hp = alturas[i]
        dh = distancia_horizontal(est, adelante)
        dz = adelante["cota"] - est["cota"]
        v = dz - hi + hp  # componente vertical instrumento -> prisma
        sd = math.hypot(dh, v)
        z = math.degrees(math.atan2(dh, v))

        filas.append(
            {
                "angulo_horizontal": ang,
                "angulo_cenital": z,
                "distancia_inclinada": sd,
                "altura_instrumento": hi,
                "altura_prisma": hp,
            }
        )

    # Visual de cierre desde el último punto.
    ultimo = puntos[-1]
    az_atras = azimut(ultimo, puntos[-2])
    filas.append(
        {
            "angulo_horizontal": norm360(az_cierre_ref - az_atras),
            "angulo_cenital": None,
            "distancia_inclinada": None,
            "altura_instrumento": None,
            "altura_prisma": None,
        }
    )
    return filas


# ---------------------------------------------------------------------------
# Sobrerotura por áreas medias
# ---------------------------------------------------------------------------


def volumen_areas_medias(secciones):
    """secciones: lista de dict {progresiva_m, area_m2} ordenada."""
    v = 0.0
    for a, b in zip(secciones, secciones[1:]):
        v += (a["area_m2"] + b["area_m2"]) / 2.0 * (b["progresiva_m"] - a["progresiva_m"])
    return v


def analizar_sobrerotura(secciones_real, secciones_diseno, perimetro_seccion):
    v_real = volumen_areas_medias(secciones_real)
    v_dis = volumen_areas_medias(secciones_diseno)
    longitud = secciones_real[-1]["progresiva_m"] - secciones_real[0]["progresiva_m"]
    v_sobre = v_real - v_dis
    sobre_lineal = v_sobre / (perimetro_seccion * longitud) if longitud else 0.0
    return {
        "volumen_real_m3": v_real,
        "volumen_diseno_m3": v_dis,
        "volumen_sobrerotura_m3": v_sobre,
        "longitud_m": longitud,
        "sobrerotura_lineal_media_m": sobre_lineal,
    }


# ---------------------------------------------------------------------------
# Replanteo (problema inverso)
# ---------------------------------------------------------------------------


def resolver_replanteo(estacion, referencia, objetivo, hi, hp):
    az_ref = azimut(estacion, referencia)
    az_obj = azimut(estacion, objetivo)
    return {
        "azimut_referencia": az_ref,
        "azimut_objetivo": az_obj,
        "angulo_a_girar": norm360(az_obj - az_ref),
        "distancia_horizontal": distancia_horizontal(estacion, objetivo),
        "desnivel": objetivo["cota"] - estacion["cota"],
        "angulo_cenital": math.degrees(
            math.atan2(
                distancia_horizontal(estacion, objetivo),
                (objetivo["cota"] + hp) - (estacion["cota"] + hi),
            )
        ),
    }
