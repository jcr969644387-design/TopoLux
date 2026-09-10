#!/usr/bin/env python3
"""
Generador y validador de casos — TopoLux
=========================================
El autor escribe intención (geometría limpia, error a inducir, textos).
Este programa:
  1. Deriva las lecturas de campo verdaderas.
  2. Aplica perturbaciones deterministas (error accidental realista).
  3. Aplica el error inducido declarado.
  4. Resuelve la poligonal como lo hará la app y congela la solución.
  5. VERIFICA que la firma numérica del error sea la declarada y sea
     distinguible de la de los demás errores del catálogo.
  6. Escribe assets/casos/*.json

Uso:  python3 tool/generar_casos.py
"""

import json
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import topo
from contenido import CASOS, TOL_STD, ARRANQUE, ORIENTACION, CIERRE_REF
from contenido_d import CASOS_D

SALIDA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "casos")
SEG = 1.0 / 3600.0

ERRORES_FATALES = []
ADVERTENCIAS = []


def fatal(caso_id, msg):
    ERRORES_FATALES.append(f"[{caso_id}] {msg}")


def aviso(caso_id, msg):
    ADVERTENCIAS.append(f"[{caso_id}] {msg}")


# ---------------------------------------------------------------------------
# Perturbaciones y errores inducidos
# ---------------------------------------------------------------------------


def perturbar(filas, sigma):
    rnd = random.Random(sigma["semilla"])
    for f in filas:
        f["angulo_horizontal"] = topo.norm360(
            f["angulo_horizontal"] + rnd.gauss(0, sigma["ang_seg"]) * SEG
        )
        if f["angulo_cenital"] is not None:
            f["angulo_cenital"] += rnd.gauss(0, sigma["cen_seg"]) * SEG
            f["distancia_inclinada"] += rnd.gauss(0, sigma["dist_mm"]) / 1000.0
    return filas


def aplicar_error(filas, err, arranque, orientacion):
    """Devuelve (filas, arranque_declarado, orientacion_declarada)."""
    t = err["tipo"]
    if t == "ninguno":
        pass
    elif t == "error_lectura_angulo":
        k = err["estacion"]
        filas[k]["angulo_horizontal"] = topo.norm360(
            filas[k]["angulo_horizontal"] + err["delta_grados"]
        )
    elif t == "confusion_cenital_vertical":
        k = err["estacion"]
        filas[k]["angulo_cenital"] = 180.0 - filas[k]["angulo_cenital"]
    elif t == "altura_instrumento":
        k = err["estacion"]
        filas[k]["altura_instrumento"] += err["delta_m"]
    elif t == "orientacion_inicial":
        filas[0]["angulo_horizontal"] = topo.norm360(
            filas[0]["angulo_horizontal"] + err["delta_grados"]
        )
    elif t == "distancia_sistematica":
        for f in filas:
            if f["distancia_inclinada"] is not None:
                f["distancia_inclinada"] += err["delta_m"]
    elif t == "brujula_ferromagnetica":
        for k in err["estaciones"]:
            filas[k]["angulo_horizontal"] = topo.norm360(
                filas[k]["angulo_horizontal"] + err["delta_grados"]
            )
    elif t == "punto_amarre_incorrecto":
        # El punto de arranque y su referencia provienen de un plano antiguo:
        # ambos desplazados el mismo vector, de modo que el azimut inicial
        # NO cambia y el efecto es una traslación pura.
        d = (err["d_norte"], err["d_este"], err.get("d_cota", 0.0))
        arranque = {
            "id": arranque["id"],
            "norte": arranque["norte"] + d[0],
            "este": arranque["este"] + d[1],
            "cota": arranque["cota"] + d[2],
        }
        orientacion = {
            "id": orientacion["id"],
            "norte": orientacion["norte"] + d[0],
            "este": orientacion["este"] + d[1],
            "cota": orientacion["cota"] + d[2],
        }
    else:
        raise ValueError(f"Tipo de error desconocido: {t}")
    return filas, arranque, orientacion


# ---------------------------------------------------------------------------
# Determinación automática de la firma del error
# ---------------------------------------------------------------------------


def firma_calculada(sol, puntos_verdaderos, tramos, err, tol):
    """Deduce la anomalía a partir de la comparación con la geometría verdadera."""
    ang_ok = abs(sol["error_angular_segundos"]) <= tol["angular_seg"]
    lin_ok = sol["error_lineal_m"] <= tol["lineal_m"]
    cota_ok = abs(sol["error_cota_m"]) <= tol["cota_m"]

    d_az, d_dh, d_dv = [], [], []
    for i, det in enumerate(sol["detalle"]):
        d_az.append(topo.norm180(det["azimut"] - tramos[i]["azimut"]) * 3600.0)
        dh_v = tramos[i]["distancia_horizontal"]
        dv_v = dh_v * tramos[i]["pendiente_pct"] / 100.0
        d_dh.append(det["distancia_horizontal"] - dh_v)
        d_dv.append(det["desnivel"] - dv_v)

    forma_ok = max(abs(x) for x in d_dh) < 0.010
    az_ctes = max(d_az) - min(d_az) < 30.0  # todos los tramos girados igual
    giro_medio = sum(d_az) / len(d_az)

    if ang_ok and lin_ok and cota_ok:
        anomalia = "ninguna"
    elif not cota_ok and ang_ok and lin_ok:
        invertido = any(
            (a * b < 0 and abs(abs(a) - abs(b)) < 0.5)
            for a, b in zip(
                [d["desnivel"] for d in sol["detalle"]],
                [t["distancia_horizontal"] * t["pendiente_pct"] / 100.0 for t in tramos],
            )
        )
        anomalia = "desnivel_invertido" if invertido else "cota_desplazada_constante"
    elif ang_ok and not lin_ok:
        if forma_ok and max(abs(x) for x in d_az) < 30.0:
            anomalia = "desplazamiento_constante"
        else:
            anomalia = "error_proporcional_longitud"
    elif not ang_ok:
        if err["tipo"] == "brujula_ferromagnetica":
            anomalia = "desvio_en_tramos_metalicos"
        elif forma_ok and az_ctes and abs(giro_medio) > 30.0:
            anomalia = "rotacion_total"
        elif forma_ok:
            anomalia = "rotacion_parcial"
        else:
            anomalia = "indeterminada"
    else:
        anomalia = "indeterminada"

    return {
        "cierre_angular_dentro_tolerancia": ang_ok,
        "cierre_lineal_dentro_tolerancia": lin_ok,
        "cierre_cota_dentro_tolerancia": cota_ok,
        "anomalia": anomalia,
    }


ANOMALIA_ESPERADA = {
    "ninguno": "ninguna",
    "error_lectura_angulo": ("rotacion_parcial", "ninguna"),
    "confusion_cenital_vertical": "desnivel_invertido",
    "altura_instrumento": "cota_desplazada_constante",
    "orientacion_inicial": "rotacion_total",
    "distancia_sistematica": "error_proporcional_longitud",
    "punto_amarre_incorrecto": "desplazamiento_constante",
    "brujula_ferromagnetica": "desvio_en_tramos_metalicos",
}


# ---------------------------------------------------------------------------
# Construcción de un caso de poligonal
# ---------------------------------------------------------------------------


def construir_poligonal(c):
    puntos_v = topo.construir_geometria(ARRANQUE, ORIENTACION, c["tramos"])
    cierre_conocido = dict(puntos_v[-1])
    cierre_conocido["id"] = "BM-20"

    filas = topo.lecturas_verdaderas(
        puntos_v, ORIENTACION, CIERRE_REF["azimut"], c["alturas"]
    )
    filas = perturbar(filas, c["sigma"])
    filas, arranque_dec, orient_dec = aplicar_error(
        filas, c["error"], ARRANQUE, ORIENTACION
    )

    sol = topo.resolver_poligonal(
        arranque_dec, orient_dec, filas, CIERRE_REF["azimut"], cierre_conocido
    )

    n_ang = len(filas)
    tol = {
        "angular_seg": TOL_STD["ang_base_seg"] * math.sqrt(n_ang),
        "lineal_m": sol["perimetro"] / TOL_STD["denominador"],
        "cota_m": TOL_STD["cota_m"],
        "denominador": TOL_STD["denominador"],
        "n_angulos": n_ang,
    }

    firma = firma_calculada(sol, puntos_v, c["tramos"], c["error"], tol)

    # ---- Verificaciones -----------------------------------------------
    esperada = ANOMALIA_ESPERADA[c["error"]["tipo"]]
    esperadas = esperada if isinstance(esperada, tuple) else (esperada,)
    if firma["anomalia"] not in esperadas:
        fatal(c["id"], f"anomalía calculada '{firma['anomalia']}' "
                       f"no coincide con la esperada para '{c['error']['tipo']}'")

    dentro = (
        firma["cierre_angular_dentro_tolerancia"]
        and firma["cierre_lineal_dentro_tolerancia"]
        and firma["cierre_cota_dentro_tolerancia"]
    )
    if c["error"]["tipo"] == "ninguno" and not dentro:
        fatal(c["id"], "caso declarado limpio pero algún cierre excede la tolerancia")

    # coherencia decisión / resultado
    if dentro and c["decision"] in ("repetir", "escalar"):
        fatal(c["id"], f"todos los cierres dentro de tolerancia pero la decisión "
                       f"correcta es '{c['decision']}'")
    if not dentro and c["decision"] == "aceptar":
        fatal(c["id"], "hay cierres fuera de tolerancia pero la decisión correcta "
                       "es 'aceptar'")

    # margen de uso de la tolerancia (para distinguir aceptar de compensar)
    uso = max(
        abs(sol["error_angular_segundos"]) / tol["angular_seg"],
        sol["error_lineal_m"] / tol["lineal_m"],
        abs(sol["error_cota_m"]) / tol["cota_m"],
    )
    if dentro and c["decision"] == "aceptar" and uso > 0.25:
        aviso(c["id"], f"decisión 'aceptar' con {uso:.0%} de la tolerancia consumida")
    if dentro and c["decision"] == "compensar" and uso < 0.25:
        aviso(c["id"], f"decisión 'compensar' con sólo {uso:.0%} de la tolerancia "
                       f"consumida")

    libreta = []
    nombres = ["BM-12"] + [f"E-{i}" for i in range(1, len(c["tramos"]))] + ["BM-20"]
    for i, f in enumerate(filas):
        visado = nombres[i + 1] if i + 1 < len(nombres) else CIERRE_REF["id"]
        atras = ORIENTACION["id"] if i == 0 else nombres[i - 1]
        obs = c["observaciones"][i] if i < len(c["observaciones"]) else ""
        libreta.append(
            {
                "estacion": nombres[i],
                "punto_atras": atras,
                "punto_visado": visado,
                "angulo_horizontal": round(f["angulo_horizontal"], 6),
                "angulo_cenital": None if f["angulo_cenital"] is None
                else round(f["angulo_cenital"], 6),
                "distancia_inclinada": None if f["distancia_inclinada"] is None
                else round(f["distancia_inclinada"], 4),
                "altura_instrumento": f["altura_instrumento"],
                "altura_prisma": f["altura_prisma"],
                "observaciones": obs,
            }
        )

    solucion = {
        "generada_por_validador": True,
        "puntos": [
            {
                "id": nombres[i],
                "norte": round(p["norte"], 4),
                "este": round(p["este"], 4),
                "cota": round(p["cota"], 4),
            }
            for i, p in enumerate(sol["puntos"])
        ],
        "tramos": [
            {
                "azimut": round(d["azimut"], 6),
                "distancia_horizontal": round(d["distancia_horizontal"], 4),
                "desnivel": round(d["desnivel"], 4),
            }
            for d in sol["detalle"]
        ],
        "perimetro_m": round(sol["perimetro"], 4),
        "azimut_cierre_calculado": round(sol["azimut_cierre_calculado"], 6),
        "error_angular_segundos": round(sol["error_angular_segundos"], 2),
        "error_lineal_m": round(sol["error_lineal_m"], 4),
        "error_norte_m": round(sol["error_norte_m"], 4),
        "error_este_m": round(sol["error_este_m"], 4),
        "error_cota_m": round(sol["error_cota_m"], 4),
        "relacion_cierre": round(sol["relacion_cierre"], 1)
        if sol["relacion_cierre"] != float("inf") else None,
        "uso_tolerancia": round(uso, 3),
    }

    return {
        "libreta": libreta,
        "solucion": solucion,
        "tolerancia": {k: (round(v, 4) if isinstance(v, float) else v)
                       for k, v in tol.items()},
        "firma": firma,
        "control": {
            "punto_arranque": {"id": arranque_dec["id"],
                               "norte": round(arranque_dec["norte"], 4),
                               "este": round(arranque_dec["este"], 4),
                               "cota": round(arranque_dec["cota"], 4)},
            "punto_orientacion": {"id": orient_dec["id"],
                                  "norte": round(orient_dec["norte"], 4),
                                  "este": round(orient_dec["este"], 4),
                                  "cota": round(orient_dec["cota"], 4)},
            "punto_cierre": {"id": "BM-20",
                             "norte": round(cierre_conocido["norte"], 4),
                             "este": round(cierre_conocido["este"], 4),
                             "cota": round(cierre_conocido["cota"], 4)},
            "referencia_cierre": {"id": CIERRE_REF["id"],
                                  "azimut": CIERRE_REF["azimut"]},
        },
        "diseno": {
            "eje": [
                {"id": f"D-{i}", "norte": round(p["norte"], 4),
                 "este": round(p["este"], 4), "cota": round(p["cota"], 4)}
                for i, p in enumerate(puntos_v)
            ]
        },
    }


# ---------------------------------------------------------------------------
# Ensamblado del JSON final
# ---------------------------------------------------------------------------


def justificaciones(lista):
    salida = []
    correctas = 0
    for i, (texto, ok, tipo) in enumerate(lista, start=1):
        item = {"id": f"j{i}", "texto": texto, "correcta": ok}
        if not ok:
            item["tipo_distractor"] = tipo
        else:
            correctas += 1
        salida.append(item)
    return salida, correctas


def consecuencias(d):
    return {k: {"texto": v[0], "impacto": v[1]} for k, v in d.items()}


def ensamblar(c):
    base = {
        "schema_version": "1.0",
        "identificacion": {
            "id": c["id"],
            "titulo": c["titulo"],
            "bloque": c["bloque"],
            "orden": c["orden"],
            "tipo_ejercicio": c["tipo"],
            "andamiaje": c["andamiaje"],
        },
        "encargo": {
            "labor": c["labor"],
            "solicitante": "Jefe de Topografía",
            "contexto": c["contexto"],
            "objetivo": c["objetivo"],
        },
        "parametros": {
            "unidad_angular": "grados_decimales",
            "unidad_lineal": "metros",
            "sistema_coordenadas": "local_mina",
        },
    }

    js, n_correctas = justificaciones(c["justificaciones"])
    if n_correctas != 1:
        fatal(c["id"], f"debe haber exactamente 1 justificación correcta, hay {n_correctas}")
    tipos = [j.get("tipo_distractor") for j in js if not j["correcta"]]
    if len(set(tipos)) == 1 and len(tipos) > 1:
        aviso(c["id"], "los tres distractores son del mismo tipo")

    base["decision"] = {"correcta": c["decision"], "justificaciones": js}
    base["consecuencia"] = consecuencias(c["consecuencias"])
    base["diagnostico"] = c["diagnostico"]
    base["metadatos"] = {
        "autor": "equipo TopoLux",
        "validado_por": "PENDIENTE — requiere topógrafo de mina",
        "origen": "manual",
        "estado": "borrador",
    }

    for k in ("aceptar", "compensar", "repetir", "escalar"):
        if k not in base["consecuencia"]:
            fatal(c["id"], f"falta la consecuencia para la decisión '{k}'")

    if c["tipo"] == "poligonal_abierta":
        p = construir_poligonal(c)
        base["parametros"]["tolerancia"] = p["tolerancia"]
        base["parametros"]["tolerancia"]["fuente"] = (
            "Estándar de la operación — PENDIENTE de validación por topógrafo de mina"
        )
        base["control"] = p["control"]
        base["diseno"] = p["diseno"]
        base["libreta"] = {"generada_por_validador": True, "estaciones": p["libreta"]}
        # Lo que el estudiante PUEDE diagnosticar a partir de los cierres.
        # Si el error existe pero no se manifiesta (queda dentro de tolerancia),
        # el diagnóstico esperado es "ninguno": exigir lo contrario sería pedir
        # que detecte algo sin evidencia disponible.
        esperado = ("ninguno" if p["firma"]["anomalia"] == "ninguna"
                    else c["error"]["tipo"])
        base["error_inducido"] = {
            "tipo": c["error"]["tipo"],
            "diagnostico_esperado": esperado,
            "estacion": estacion_afectada(c),
            "firma": p["firma"],
        }
        base["solucion_referencia"] = p["solucion"]

    elif c["tipo"] == "sobrerotura":
        reales = [{"progresiva_m": s["progresiva_m"], "area_m2": s["area_real_m2"]}
                  for s in c["secciones"]]
        disenio = [{"progresiva_m": s["progresiva_m"],
                    "area_m2": c["seccion_diseno"]["area_m2"]} for s in c["secciones"]]
        r = topo.analizar_sobrerotura(reales, disenio,
                                      c["seccion_diseno"]["perimetro_m"])
        base["parametros"]["tolerancia"] = dict(c["tolerancia"])
        base["parametros"]["tolerancia"]["fuente"] = (
            "Estándar de la operación — PENDIENTE de validación por topógrafo de mina"
        )
        base["secciones"] = {
            "metodo": "areas_medias",
            "seccion_diseno": c["seccion_diseno"],
            "progresivas": c["secciones"],
            "observaciones": c["observaciones"],
        }
        base["solucion_referencia"] = {
            "generada_por_validador": True,
            "volumen_real_m3": round(r["volumen_real_m3"], 3),
            "volumen_diseno_m3": round(r["volumen_diseno_m3"], 3),
            "volumen_sobrerotura_m3": round(r["volumen_sobrerotura_m3"], 3),
            "longitud_m": r["longitud_m"],
            "sobrerotura_lineal_media_m": round(r["sobrerotura_lineal_media_m"], 4),
        }
        fuera = r["sobrerotura_lineal_media_m"] > c["tolerancia"]["sobrerotura_m"]
        base["error_inducido"] = {
            "tipo": "sobrerotura_excedida" if fuera else "ninguno",
            "diagnostico_esperado": "sobrerotura_excedida" if fuera else "ninguno",
            "firma": {"sobrerotura_dentro_tolerancia": not fuera,
                      "anomalia": "sobrerotura_excedida" if fuera else "ninguna"},
        }
        if fuera and c["decision"] == "aceptar":
            fatal(c["id"], "sobrerotura fuera de tolerancia con decisión 'aceptar'")
        if not fuera and c["decision"] in ("repetir", "escalar"):
            fatal(c["id"], "sobrerotura dentro de tolerancia con decisión de rechazo")

    elif c["tipo"] == "replanteo":
        r = topo.resolver_replanteo(
            c["estacion"], c["referencia"], c["objetivo_diseno"],
            c["alturas"]["instrumento"], c["alturas"]["prisma"],
        )
        base["parametros"]["tolerancia"] = dict(c["tolerancia"])
        base["replanteo"] = {
            "estacion": c["estacion"],
            "referencia": c["referencia"],
            "objetivo": c["objetivo_diseno"],
            "alturas": c["alturas"],
            "observaciones": c["observaciones"],
            "entregable": ["angulo_a_girar", "distancia_horizontal", "desnivel"],
        }
        base["solucion_referencia"] = {
            "generada_por_validador": True,
            "azimut_referencia": round(r["azimut_referencia"], 6),
            "azimut_objetivo": round(r["azimut_objetivo"], 6),
            "angulo_a_girar": round(r["angulo_a_girar"], 6),
            "distancia_horizontal": round(r["distancia_horizontal"], 4),
            "desnivel": round(r["desnivel"], 4),
            "angulo_cenital": round(r["angulo_cenital"], 6),
        }
        base["error_inducido"] = {"tipo": "ninguno",
                                  "diagnostico_esperado": "ninguno",
                                  "firma": {"anomalia": "ninguna"}}

    # Verificación de marcadores de plantilla
    campos = set(base["solucion_referencia"].keys())
    for k, v in base["consecuencia"].items():
        import re
        for m in re.findall(r"\{\{(\w+)\}\}", v["texto"]):
            if m not in campos:
                fatal(c["id"], f"la consecuencia '{k}' referencia el campo "
                               f"inexistente '{m}'")

    for campo in ("que_habia", "por_que", "como_detectar"):
        if not base["diagnostico"].get(campo, "").strip():
            fatal(c["id"], f"diagnóstico incompleto: falta '{campo}'")

    return base


def estacion_afectada(c):
    e = c["error"]
    if "estacion" in e:
        idx = e["estacion"]
        return "BM-12" if idx == 0 else f"E-{idx}"
    if "estaciones" in e:
        return ", ".join("BM-12" if i == 0 else f"E-{i}" for i in e["estaciones"])
    return None


# ---------------------------------------------------------------------------
# Distinguibilidad entre errores (regla 5 del validador)
# ---------------------------------------------------------------------------


def verificar_distinguibilidad(casos_json):
    firmas = {}
    for c in casos_json:
        ei = c.get("error_inducido", {})
        firma = ei.get("firma", {})
        if not firma or firma.get("anomalia") in (None, "ninguna"):
            continue
        clave = json.dumps(firma, sort_keys=True)
        tipo = ei["tipo"]
        if clave in firmas and firmas[clave] != tipo:
            ERRORES_FATALES.append(
                f"[distinguibilidad] los errores '{firmas[clave]}' y '{tipo}' "
                f"comparten la misma firma numérica: {clave}"
            )
        firmas[clave] = tipo


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    os.makedirs(SALIDA, exist_ok=True)
    for f in os.listdir(SALIDA):
        if f.endswith(".json"):
            os.remove(os.path.join(SALIDA, f))

    generados = []
    for c in CASOS + CASOS_D:
        generados.append(ensamblar(c))

    verificar_distinguibilidad(generados)

    indice = []
    for j in generados:
        ident = j["identificacion"]
        ruta = os.path.join(SALIDA, ident["id"] + ".json")
        with open(ruta, "w", encoding="utf-8") as fh:
            json.dump(j, fh, ensure_ascii=False, indent=2)
        indice.append(
            {
                "id": ident["id"],
                "titulo": ident["titulo"],
                "bloque": ident["bloque"],
                "orden": ident["orden"],
                "tipo_ejercicio": ident["tipo_ejercicio"],
                "andamiaje": ident["andamiaje"],
                "error": j["error_inducido"]["diagnostico_esperado"],
                "decision": j["decision"]["correcta"],
            }
        )
    indice.sort(key=lambda x: x["orden"])
    with open(os.path.join(SALIDA, "indice.json"), "w", encoding="utf-8") as fh:
        json.dump({"schema_version": "1.0", "casos": indice}, fh,
                  ensure_ascii=False, indent=2)

    # ---- informe ------------------------------------------------------
    print("=" * 78)
    print("VALIDADOR DE CASOS — TopoLux")
    print("=" * 78)
    fila = "{:<3} {:<26} {:<26} {:>9} {:>8} {:>8} {:<10}"
    print(fila.format("#", "caso", "error inducido", "err.ang\"", "err.lin", "err.cota",
                      "decisión"))
    print("-" * 78)
    for j in generados:
        s = j.get("solucion_referencia", {})
        print(
            fila.format(
                j["identificacion"]["orden"],
                j["identificacion"]["id"][:26],
                j["error_inducido"]["tipo"][:26],
                f"{s.get('error_angular_segundos', 0):.1f}"
                if "error_angular_segundos" in s else "-",
                f"{s.get('error_lineal_m', 0):.3f}"
                if "error_lineal_m" in s else "-",
                f"{s.get('error_cota_m', 0):.3f}"
                if "error_cota_m" in s else "-",
                j["decision"]["correcta"],
            )
        )
    print("-" * 78)
    for j in generados:
        s = j["solucion_referencia"]
        if "uso_tolerancia" in s:
            t = j["parametros"]["tolerancia"]
            print(
                f"{j['identificacion']['orden']:>2}  tol ang {t['angular_seg']:6.1f}\"  "
                f"tol lin {t['lineal_m']:.3f} m  |  uso {s['uso_tolerancia']:.0%}  "
                f"|  {j['error_inducido']['firma']['anomalia']}"
            )
    print()

    if ADVERTENCIAS:
        print("ADVERTENCIAS:")
        for a in ADVERTENCIAS:
            print("  ! " + a)
        print()
    if ERRORES_FATALES:
        print("ERRORES FATALES — los casos NO se consideran válidos:")
        for e in ERRORES_FATALES:
            print("  X " + e)
        return 1

    print(f"OK — {len(generados)} casos generados y validados en assets/casos/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
