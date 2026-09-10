"""
Contenido de los 12 casos de TopoLux.

El autor escribe INTENCIÓN (geometría limpia, error a inducir, textos).
Los datos observados y la solución de referencia los calcula el generador.
Ningún número de resultado se escribe a mano aquí.
"""

TOL_STD = {"ang_base_seg": 30.0, "denominador": 3000, "cota_m": 0.05, "sobrerotura_m": 0.10}

ARRANQUE = {"id": "BM-12", "norte": 1000.000, "este": 1000.000, "cota": 3850.000}
ORIENTACION = {"id": "BM-11", "norte": 1042.180, "este": 955.640, "cota": 3849.120}
CIERRE_REF = {"id": "BM-21", "azimut": 132.400}

H = (1.482, 1.500)  # (altura instrumento, altura prisma) por defecto


def tramos(*specs):
    """specs: (azimut, distancia_horizontal, pendiente_pct)"""
    return [
        {"azimut": a, "distancia_horizontal": d, "pendiente_pct": p} for a, d, p in specs
    ]


CASOS = [
    # ------------------------------------------------------------------ A1
    {
        "id": "gal-118-limpio-01",
        "titulo": "Arrastre de control — Galería 118 N",
        "bloque": "A",
        "orden": 1,
        "andamiaje": "alto",
        "tipo": "poligonal_abierta",
        "labor": "Galería 118 N — Nivel 3850",
        "contexto": "Se arrastró la poligonal de control desde BM-12, en la bocamina, "
        "hasta BM-20, en el crucero principal. La brigada entrega la libreta al "
        "cierre de guardia.",
        "objetivo": "Procesa la poligonal, verifica los cierres contra la tolerancia "
        "del estándar y decide si el trabajo se entrega.",
        "tramos": tramos((46.500, 48.200, 0.5), (47.100, 52.600, 0.5), (46.800, 44.900, 0.4)),
        "alturas": [H, H, H],
        "observaciones": [
            "Estación sobre pilar de concreto. Visibilidad buena.",
            "Labor con sostenimiento de shotcrete.",
            "Prisma sobre trípode. Sin vibración de equipos.",
        ],
        "sigma": {"ang_seg": 2.0, "cen_seg": 3.0, "dist_mm": 1.5, "semilla": 11},
        "error": {"tipo": "ninguno"},
        "decision": "aceptar",
        "justificaciones": [
            ("Los tres cierres están holgadamente dentro de tolerancia y el residuo es "
             "despreciable frente a la longitud levantada.", True, None),
            ("El cierre angular es exactamente cero, lo que confirma que no hubo errores.",
             False, "tecnicamente_falso"),
            ("La poligonal es corta, y en poligonales cortas no se verifica el cierre.",
             False, "tecnicamente_falso"),
            ("La labor tiene sostenimiento de shotcrete, lo que garantiza estabilidad de "
             "los puntos.", False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste el arrastre. Las coordenadas de BM-20 quedan como "
                        "control del nivel y el planeamiento las usa sin observaciones.", "bajo"),
            "compensar": ("Compensaste un residuo de {{error_lineal_m}} m. No es un error, "
                          "pero invertiste tiempo de gabinete en repartir una diferencia "
                          "irrelevante para la escala de la labor.", "bajo"),
            "repetir": ("Mandaste a la brigada a repetir un levantamiento correcto. Un turno "
                        "de topografía perdido y el frente sin control por 8 horas.", "medio"),
            "escalar": ("Reportaste al jefe de topografía un trabajo que estaba bien. "
                        "Perdiste credibilidad para cuando reportes algo real.", "medio"),
        },
        "diagnostico": {
            "que_habia": "No había ningún error. Los residuos de cierre corresponden a la "
            "precisión normal del instrumento y del operador.",
            "por_que": "Todo levantamiento tiene error residual. Un cierre de cero exacto "
            "sería sospechoso, no ideal: sugeriría datos forzados.",
            "como_detectar": "Compara el cierre contra la tolerancia, no contra cero. Si el "
            "residuo es una fracción pequeña de la tolerancia, el trabajo está bien.",
        },
    },
    # ------------------------------------------------------------------ A2
    {
        "id": "gal-118-lectura-02",
        "titulo": "Arrastre con lectura dudosa — Galería 118 N",
        "bloque": "A",
        "orden": 2,
        "andamiaje": "alto",
        "tipo": "poligonal_abierta",
        "labor": "Galería 118 N — Nivel 3850",
        "contexto": "Nuevo arrastre sobre la misma galería, con brigada de turno noche. "
        "El ayudante anotó las lecturas a mano en libreta de campo.",
        "objetivo": "Procesa la poligonal y determina si el trabajo es utilizable para "
        "dar línea al frente.",
        "tramos": tramos((46.500, 48.200, 0.5), (47.100, 52.600, 0.5), (46.800, 44.900, 0.4)),
        "alturas": [H, H, H],
        "observaciones": [
            "Estación sobre pilar de concreto.",
            "Anotación manual, turno noche.",
            "Prisma sobre trípode.",
        ],
        "sigma": {"ang_seg": 2.0, "cen_seg": 3.0, "dist_mm": 1.5, "semilla": 22},
        "error": {"tipo": "error_lectura_angulo", "estacion": 1, "delta_grados": 0.5},
        "decision": "repetir",
        "justificaciones": [
            ("El cierre angular excede la tolerancia y el error se concentra en una sola "
             "estación: es una equivocación de lectura que no se puede recuperar en gabinete.",
             True, None),
            ("El error se puede repartir entre todas las estaciones aplicando compensación "
             "proporcional.", False, "confusion_frecuente"),
            ("Basta con descartar la última estación y usar las anteriores.",
             False, "tecnicamente_falso"),
            ("El trabajo se hizo en turno noche, y el turno noche siempre tiene menor "
             "precisión.", False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Diste línea al frente con un error de {{error_lineal_m}} m. "
                        "La galería avanzó desviada del eje de diseño y hubo que reperfilar "
                        "el tramo ejecutado.", "alto"),
            "compensar": ("Repartiste entre todas las estaciones un error que estaba en una "
                          "sola. Ninguna coordenada quedó correcta y el error se propagó "
                          "disimulado a todo el nivel.", "alto"),
            "repetir": ("La brigada reobservó la poligonal en el turno siguiente. Costó un "
                        "turno de topografía y evitó un desvío del frente.", "bajo"),
            "escalar": ("Reportaste sin resolver. El jefe de topografía ordenó exactamente "
                        "lo que ya podías decidir: repetir. Se perdió medio turno.", "medio"),
        },
        "diagnostico": {
            "que_habia": "Una equivocación de lectura en el ángulo horizontal de la estación "
            "señalada, del orden de medio grado.",
            "por_que": "Es el error más común en anotación manual: se transpone una cifra o "
            "se lee el limbo en la graduación equivocada. No es falta de precisión del "
            "instrumento, es una equivocación puntual.",
            "como_detectar": "Un error angular grande con el resto de la poligonal coherente "
            "indica equivocación concentrada. Si el error fuera de precisión, se repartiría "
            "entre todas las estaciones en magnitudes pequeñas.",
        },
    },
    # ------------------------------------------------------------------ A3
    {
        "id": "cx-220-limpio-03",
        "titulo": "Poligonal de crucero — Cx 220 E",
        "bloque": "A",
        "orden": 3,
        "andamiaje": "alto",
        "tipo": "poligonal_abierta",
        "labor": "Crucero 220 E — Nivel 3850",
        "contexto": "Arrastre de cuatro tramos hacia el crucero de exploración. La labor "
        "es más larga que la anterior y la tolerancia angular se calcula sobre el número "
        "de ángulos observados.",
        "objetivo": "Procesa la poligonal y decide qué hacer antes de entregar las "
        "coordenadas al área de planeamiento.",
        "tramos": tramos(
            (46.500, 58.400, 0.6), (48.200, 61.700, 0.6), (47.500, 55.300, 0.5),
            (46.900, 49.800, 0.5),
        ),
        "alturas": [H, H, H, H],
        "observaciones": [
            "Estación sobre pilar de concreto.",
            "Tramo con goteo de agua; se protegió el instrumento.",
            "Visual larga, buena visibilidad.",
            "Prisma sobre trípode.",
        ],
        "sigma": {"ang_seg": 9.0, "cen_seg": 8.0, "dist_mm": 4.0, "semilla": 33},
        "error": {"tipo": "ninguno"},
        "decision": "compensar",
        "justificaciones": [
            ("Los cierres están dentro de tolerancia pero el residuo es significativo: "
             "debe repartirse antes de publicar las coordenadas.", True, None),
            ("El residuo excede la tolerancia y obliga a reobservar la poligonal.",
             False, "tecnicamente_falso"),
            ("Al estar dentro de tolerancia, las coordenadas se entregan tal cual sin "
             "ningún tratamiento.", False, "confusion_frecuente"),
            ("El goteo de agua en el tramo intermedio degrada la medición electrónica de "
             "distancias.", False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste sin compensar. El residuo de {{error_lineal_m}} m quedó "
                        "íntegro en el último punto, y todo lo que se replantee desde ahí "
                        "arrastra ese desplazamiento.", "medio"),
            "compensar": ("Repartiste el residuo entre los tramos. Las coordenadas quedaron "
                          "consistentes con los puntos de control del nivel.", "bajo"),
            "repetir": ("Mandaste a repetir un trabajo que cumplía el estándar. Un turno "
                        "perdido y el crucero sin control topográfico.", "medio"),
            "escalar": ("Escalaste una decisión de rutina. El jefe de topografía respondió "
                        "que compensaras, que es lo que correspondía.", "medio"),
        },
        "diagnostico": {
            "que_habia": "No había equivocaciones. El residuo corresponde a errores "
            "accidentales acumulados en una poligonal más larga.",
            "por_que": "El error accidental crece con el número de estaciones. Por eso la "
            "tolerancia angular se calcula con la raíz del número de ángulos y no como un "
            "valor fijo.",
            "como_detectar": "Residuo dentro de tolerancia pero no despreciable, repartido "
            "y sin concentración en ninguna estación: caso típico de compensación.",
        },
    },
    # ------------------------------------------------------------------ B4
    {
        "id": "rp-340-cenital-04",
        "titulo": "Rampa 340 — control de gradiente",
        "bloque": "B",
        "orden": 4,
        "andamiaje": "medio",
        "tipo": "poligonal_abierta",
        "labor": "Rampa 340 — acceso a Nivel 3820",
        "contexto": "Control topográfico de la rampa de acceso. La gradiente es crítica: "
        "la rampa debe bajar de forma continua para que los equipos de bajo perfil "
        "puedan transitar cargados.",
        "objetivo": "Procesa la poligonal, verifica planimetría y cota, y decide si el "
        "control de gradiente es utilizable.",
        "tramos": tramos(
            (46.500, 51.300, -12.0), (49.800, 47.900, -12.0), (52.400, 44.200, -11.5),
        ),
        "alturas": [H, H, H],
        "observaciones": [
            "Estación al inicio de la rampa.",
            "Fuerte pendiente descendente. Visuales muy inclinadas.",
            "Prisma sobre bastón con bípode.",
        ],
        "sigma": {"ang_seg": 3.0, "cen_seg": 4.0, "dist_mm": 2.0, "semilla": 44},
        "error": {"tipo": "confusion_cenital_vertical", "estacion": 1},
        "decision": "repetir",
        "justificaciones": [
            ("La planimetría cierra correctamente pero la cota queda fuera de tolerancia "
             "con el desnivel invertido en un tramo: el dato vertical no es recuperable "
             "en gabinete.", True, None),
            ("El error de cota se corrige aplicando la corrección por curvatura y "
             "refracción.", False, "tecnicamente_falso"),
            ("Como la planimetría cierra, el levantamiento se acepta y la cota se "
             "interpola.", False, "confusion_frecuente"),
            ("La rampa tiene fuerte pendiente, y a mayor pendiente mayor error de "
             "distancia inclinada.", False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste un control con la cota errada en {{error_cota_m}} m. "
                        "La gradiente replanteada dejó un tramo contrapendiente y la rampa "
                        "acumuló agua en la curva.", "alto"),
            "compensar": ("Compensaste un desnivel invertido. La compensación repartió un "
                          "disparate entre todos los tramos y ninguna cota quedó utilizable.",
                          "alto"),
            "repetir": ("La brigada reobservó el tramo. Se confirmó que la lectura vertical "
                        "estaba mal anotada y el control de gradiente quedó correcto.", "bajo"),
            "escalar": ("Reportaste sin resolver. La respuesta fue reobservar, que era la "
                        "decisión disponible desde el inicio.", "medio"),
        },
        "diagnostico": {
            "que_habia": "En la estación señalada se anotó el ángulo vertical donde la "
            "libreta pedía el ángulo cenital, con el complemento tomado al revés.",
            "por_que": "La estación total puede configurarse para entregar ángulo cenital "
            "(desde el cenit) o vertical (desde la horizontal). Al cambiar de equipo o de "
            "configuración, la confusión es frecuente, y en visuales muy inclinadas el "
            "efecto es grande.",
            "como_detectar": "Firma inconfundible: la distancia horizontal y toda la "
            "planimetría quedan intactas, porque el seno del ángulo no cambia, pero el "
            "desnivel aparece con el signo invertido.",
        },
    },
    # ------------------------------------------------------------------ B5
    {
        "id": "gal-455-altura-05",
        "titulo": "Galería 455 S — control de avance mensual",
        "bloque": "B",
        "orden": 5,
        "andamiaje": "medio",
        "tipo": "poligonal_abierta",
        "labor": "Galería 455 S — Nivel 3850",
        "contexto": "Levantamiento del avance del mes para la valorización del "
        "contratista. La brigada cambió de instrumento a mitad del trabajo.",
        "objetivo": "Procesa la poligonal y decide si el levantamiento sirve para "
        "valorizar el avance.",
        "tramos": tramos((216.400, 46.800, 0.4), (218.100, 51.200, 0.4), (217.300, 48.500, 0.5)),
        "alturas": [H, (1.182, 1.500), H],
        "observaciones": [
            "Estación inicial sobre pilar.",
            "Cambio de instrumento por falla de batería. Se rehizo el estacionamiento.",
            "Prisma sobre trípode.",
        ],
        "sigma": {"ang_seg": 3.0, "cen_seg": 4.0, "dist_mm": 2.0, "semilla": 55},
        "error": {"tipo": "altura_instrumento", "estacion": 1, "delta_m": 0.300},
        "decision": "repetir",
        "justificaciones": [
            ("La planimetría cierra pero la cota sale desplazada en una cantidad constante, "
             "compatible con una altura de instrumento mal anotada que ya no puede "
             "verificarse.", True, None),
            ("El desplazamiento de cota se debe a error de esfericidad acumulado en la "
             "poligonal.", False, "tecnicamente_falso"),
            ("Como el error de cota es constante, basta restarlo a todos los puntos.",
             False, "confusion_frecuente"),
            ("El cambio de instrumento por falla de batería invalida automáticamente todo "
             "el levantamiento.", False, "tecnicamente_falso"),
        ],
        "consecuencias": {
            "aceptar": ("Valorizaste con una cota desplazada {{error_cota_m}} m. El avance "
                        "reportado no coincidió con el control del área de planeamiento y "
                        "la valorización se observó.", "alto"),
            "compensar": ("Repartiste un desplazamiento constante como si fuera error "
                          "accidental. La cota quedó mal en todos los puntos, unos más que "
                          "otros.", "alto"),
            "repetir": ("Se reobservó el tramo con la altura de instrumento verificada. "
                        "La valorización salió sin observaciones.", "bajo"),
            "escalar": ("Escalaste un problema que podías diagnosticar tú. Se perdió tiempo "
                        "de valorización.", "medio"),
        },
        "diagnostico": {
            "que_habia": "La altura de instrumento anotada en la estación señalada no "
            "corresponde a la real; hay una diferencia de unos 30 centímetros.",
            "por_que": "Ocurre al cambiar de instrumento o rehacer el estacionamiento sin "
            "volver a medir la altura, o al copiar la altura de la estación anterior.",
            "como_detectar": "Planimetría intacta y cota desplazada en un valor constante "
            "y de magnitud 'redonda'. A diferencia de la confusión cenital/vertical, aquí "
            "el desnivel no cambia de signo: sólo se corre.",
        },
    },
    # ------------------------------------------------------------------ B6
    {
        "id": "gal-118-orient-06",
        "titulo": "Reinicio de arrastre — Galería 118 N",
        "bloque": "B",
        "orden": 6,
        "andamiaje": "medio",
        "tipo": "poligonal_abierta",
        "labor": "Galería 118 N — Nivel 3850",
        "contexto": "La brigada retomó el arrastre tras una parada de guardia. Hay dos "
        "puntos de control cerca de la bocamina, BM-11 y BM-13, con monumentación "
        "parecida.",
        "objetivo": "Procesa la poligonal y decide qué hacer con el trabajo.",
        "tramos": tramos((46.500, 48.200, 0.5), (47.100, 52.600, 0.5), (46.800, 44.900, 0.4)),
        "alturas": [H, H, H],
        "observaciones": [
            "Orientación tomada al punto de control cercano a la bocamina.",
            "Sin novedad.",
            "Prisma sobre trípode.",
        ],
        "sigma": {"ang_seg": 2.5, "cen_seg": 3.0, "dist_mm": 1.5, "semilla": 66},
        "error": {"tipo": "orientacion_inicial", "delta_grados": 2.750},
        "decision": "escalar",
        "justificaciones": [
            ("La poligonal conserva su forma y todas las distancias, pero aparece girada "
             "un valor constante: es un problema de orientación que se recalcula en "
             "gabinete, sin volver a campo, y debe informarse porque afecta a todo lo "
             "replanteado desde ese arrastre.", True, None),
            ("La forma correcta y el giro constante indican error de lectura en la última "
             "estación.", False, "confusion_frecuente"),
            ("Debe reobservarse toda la poligonal porque el giro no es recuperable.",
             False, "confusion_frecuente"),
            ("El giro se elimina aplicando la convergencia de meridianos del sistema UTM.",
             False, "tecnicamente_falso"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste una poligonal girada. El frente recibió línea con "
                        "{{error_lineal_m}} m de desviación y el crucero no intersectó la "
                        "estructura proyectada.", "alto"),
            "compensar": ("Compensar no elimina un giro: repartiste entre los tramos un "
                          "error que está en el origen. Las coordenadas quedaron peor que "
                          "sin compensar.", "alto"),
            "repetir": ("Mandaste a la brigada a repetir un trabajo cuyas mediciones eran "
                        "correctas. Un turno perdido para corregir algo que se resolvía "
                        "en gabinete.", "medio"),
            "escalar": ("Reportaste el problema de orientación. Se recalculó con el azimut "
                        "correcto sin volver a campo y se revisaron los replanteos "
                        "derivados.", "bajo"),
        },
        "diagnostico": {
            "que_habia": "La orientación inicial se tomó a un punto de control distinto "
            "del declarado, lo que gira toda la poligonal un valor constante.",
            "por_que": "Con varios puntos de control monumentados de forma parecida cerca "
            "de la bocamina, tomar el punto equivocado es un error clásico, y no deja "
            "ninguna huella en las mediciones: todas son correctas.",
            "como_detectar": "Firma característica: las distancias entre puntos consecutivos "
            "son correctas y la forma de la poligonal es exacta, pero está girada. Si el "
            "error fuera de lectura en una estación intermedia, sólo giraría el tramo "
            "posterior a esa estación, no el conjunto.",
        },
    },
    # ------------------------------------------------------------------ B7
    {
        "id": "cx-220-prisma-07",
        "titulo": "Crucero 220 E — verificación de equipo",
        "bloque": "B",
        "orden": 7,
        "andamiaje": "medio",
        "tipo": "poligonal_abierta",
        "labor": "Crucero 220 E — Nivel 3850",
        "contexto": "Primer trabajo tras el retorno del instrumento de mantenimiento. "
        "Se usó un prisma de repuesto de otro modelo.",
        "objetivo": "Procesa la poligonal y decide qué hacer con el levantamiento y con "
        "el equipo.",
        "tramos": tramos(
            (46.500, 58.400, 0.6), (48.200, 61.700, 0.6), (47.500, 55.300, 0.5),
            (46.900, 49.800, 0.5),
        ),
        "alturas": [H, H, H, H],
        "observaciones": [
            "Instrumento recién retornado de mantenimiento.",
            "Prisma de repuesto, modelo distinto al habitual.",
            "Sin novedad.",
            "Sin novedad.",
        ],
        "sigma": {"ang_seg": 2.5, "cen_seg": 3.0, "dist_mm": 1.5, "semilla": 77},
        "error": {"tipo": "distancia_sistematica", "delta_m": 0.030},
        "decision": "escalar",
        "justificaciones": [
            ("El cierre angular es correcto y el error lineal se acumula de forma "
             "proporcional a la longitud: apunta a un error sistemático de distancias que "
             "afecta a todos los trabajos hechos con ese equipo, no sólo a este.",
             True, None),
            ("El error lineal proporcional se debe a errores accidentales acumulados y se "
             "resuelve compensando.", False, "confusion_frecuente"),
            ("El cierre angular correcto demuestra que el levantamiento es válido.",
             False, "tecnicamente_falso"),
            ("El instrumento retornó de mantenimiento, por lo que sus mediciones están "
             "certificadas.", False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste el trabajo. El error de {{error_lineal_m}} m se propagó "
                        "y, peor, el equipo siguió midiendo con la constante equivocada "
                        "durante todo el mes.", "alto"),
            "compensar": ("Compensaste un error sistemático como si fuera accidental. "
                          "Ocultaste el síntoma y el equipo siguió descalibrado.", "alto"),
            "repetir": ("Reobservaste con el mismo equipo y el mismo prisma. El error se "
                        "repitió idéntico: un turno perdido sin resolver nada.", "medio"),
            "escalar": ("Reportaste la sospecha de constante de prisma. Se verificó en base "
                        "calibrada, se corrigió la configuración y se revisaron los trabajos "
                        "del período.", "bajo"),
        },
        "diagnostico": {
            "que_habia": "Un error sistemático constante en cada distancia medida, "
            "compatible con una constante de prisma mal configurada en el instrumento.",
            "por_que": "Cada modelo de prisma tiene su propia constante. Al usar un prisma "
            "de repuesto sin actualizar la configuración, cada distancia sale desplazada "
            "siempre en el mismo sentido y la misma magnitud.",
            "como_detectar": "Cierre angular correcto (los ángulos no se ven afectados) "
            "junto a un error lineal que crece con el número de tramos y la longitud "
            "total. El error sistemático se acumula; el accidental se compensa entre sí.",
        },
    },
    # ------------------------------------------------------------------ C8
    {
        "id": "gal-455-amarre-08",
        "titulo": "Galería 455 S — amarre al control del nivel",
        "bloque": "C",
        "orden": 8,
        "andamiaje": "bajo",
        "tipo": "poligonal_abierta",
        "labor": "Galería 455 S — Nivel 3850",
        "contexto": "El plano de control del nivel tiene dos puntos con nomenclatura "
        "similar, monumentados en campañas distintas. La brigada tomó las coordenadas "
        "del plano antiguo.",
        "objetivo": "Procesa la poligonal, interpreta el resultado y decide.",
        "tramos": tramos((216.400, 46.800, 0.4), (218.100, 51.200, 0.4), (217.300, 48.500, 0.5)),
        "alturas": [H, H, H],
        "observaciones": [
            "Coordenadas de arranque tomadas del plano de control disponible en campo.",
            "Sin novedad.",
            "Prisma sobre trípode.",
        ],
        "sigma": {"ang_seg": 2.5, "cen_seg": 3.0, "dist_mm": 1.5, "semilla": 88},
        "error": {"tipo": "punto_amarre_incorrecto", "d_norte": -3.400, "d_este": 2.100,
                  "d_cota": 0.000},
        "decision": "escalar",
        "justificaciones": [
            ("El cierre angular es correcto y el error lineal es un desplazamiento "
             "constante, sin relación con la longitud: la poligonal está bien medida pero "
             "arrancó de coordenadas equivocadas, lo que compromete otros trabajos "
             "amarrados al mismo punto.", True, None),
            ("Un desplazamiento constante con angular correcto indica error sistemático de "
             "distancias.", False, "confusion_frecuente"),
            ("El desplazamiento se elimina compensando el cierre lineal entre los tramos.",
             False, "confusion_frecuente"),
            ("El levantamiento debe repetirse íntegramente porque las coordenadas "
             "calculadas no sirven.", False, "confusion_frecuente"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste coordenadas desplazadas {{error_lineal_m}} m. Todo lo "
                        "replanteado desde ese arrastre quedó corrido, incluidas las "
                        "labores de otra brigada.", "alto"),
            "compensar": ("Compensaste un desplazamiento del origen. La forma de la "
                          "poligonal se deformó y ahora ni siquiera las distancias "
                          "relativas son correctas.", "alto"),
            "repetir": ("Mandaste a repetir mediciones que eran correctas. El error no "
                        "estaba en el campo, estaba en el plano: la repetición dio el "
                        "mismo desplazamiento.", "medio"),
            "escalar": ("Reportaste la discrepancia de coordenadas del punto de amarre. Se "
                        "verificó el plano vigente, se recalculó desde las coordenadas "
                        "correctas y se revisaron los demás trabajos del nivel.", "bajo"),
        },
        "diagnostico": {
            "que_habia": "Las coordenadas del punto de arranque no corresponden al punto "
            "de control vigente: hay un desplazamiento constante en planta.",
            "por_que": "Convivencia de planos de campañas distintas con nomenclatura "
            "parecida. Es un error de gabinete, no de campo, y por eso todas las "
            "mediciones son correctas.",
            "como_detectar": "Cierre angular correcto y error lineal constante, "
            "independiente de la longitud recorrida. Compáralo con el error sistemático "
            "de distancias, que sí crece con la longitud.",
        },
    },
    # ------------------------------------------------------------------ C9
    {
        "id": "ch-780-brujula-09",
        "titulo": "Chimenea 780 — levantamiento con brújula",
        "bloque": "C",
        "orden": 9,
        "andamiaje": "bajo",
        "tipo": "poligonal_abierta",
        "labor": "Acceso a Chimenea 780 — Nivel 3850",
        "contexto": "Labor angosta sin espacio para estación total en dos tramos. Se "
        "levantó con brújula de suspensión. El tramo intermedio tiene cerchas metálicas "
        "y tubería de aire comprimido.",
        "objetivo": "Procesa la poligonal y decide si el levantamiento sirve para "
        "proyectar la chimenea.",
        "tramos": tramos((46.500, 42.300, 1.0), (44.800, 38.600, 1.0), (45.900, 40.100, 0.8)),
        "alturas": [H, H, H],
        "observaciones": [
            "Levantamiento con brújula de suspensión por falta de espacio.",
            "Tramo con cerchas metálicas y tubería de aire comprimido.",
            "Tramo con cerchas metálicas. Riel de scooptram a 2 m.",
        ],
        "sigma": {"ang_seg": 20.0, "cen_seg": 20.0, "dist_mm": 6.0, "semilla": 99},
        "error": {"tipo": "brujula_ferromagnetica", "estaciones": [1, 2],
                  "delta_grados": 0.900},
        "decision": "repetir",
        "justificaciones": [
            ("El desvío aparece precisamente en los tramos con elementos metálicos "
             "próximos: la brújula no es confiable ahí y el tramo debe reobservarse con "
             "un método no magnético.", True, None),
            ("El desvío se corrige aplicando la declinación magnética de la zona.",
             False, "confusion_frecuente"),
            ("El error se compensa proporcionalmente porque afecta a dos estaciones "
             "consecutivas.", False, "confusion_frecuente"),
            ("La labor es angosta, y en labores angostas la precisión siempre es menor.",
             False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Proyectaste la chimenea con {{error_lineal_m}} m de desviación. "
                        "La chimenea no coincidió con la labor del nivel superior y hubo "
                        "que ejecutar un tramo de conexión.", "alto"),
            "compensar": ("Compensaste un desvío magnético concentrado en dos tramos. El "
                          "error se repartió y quedó oculto en toda la poligonal.", "alto"),
            "repetir": ("Se reobservó el tramo arrastrando poligonal desde el punto de "
                        "control con estación total. La proyección de la chimenea quedó "
                        "correcta.", "bajo"),
            "escalar": ("Reportaste sin proponer solución. La respuesta fue la esperable: "
                        "reobservar sin brújula.", "medio"),
        },
        "diagnostico": {
            "que_habia": "Desvío del azimut en los tramos observados con brújula junto a "
            "cerchas metálicas, tubería y riel.",
            "por_que": "La brújula mide el campo magnético local. Cerchas, rieles, tuberías "
            "y mineralización ferromagnética lo alteran. Por eso el control subterráneo se "
            "arrastra con poligonal desde superficie o se orienta con giroteodolito, y la "
            "brújula queda para trabajos de detalle donde no hay metal cerca.",
            "como_detectar": "El desvío aparece sólo en los tramos con metal próximo, y las "
            "notas de campo lo anuncian. Lee siempre las observaciones de la libreta antes "
            "de interpretar los números.",
        },
    },
    # ------------------------------------------------------------------ C10
    {
        "id": "cx-220-limite-10",
        "titulo": "Crucero 220 E — cierre al límite",
        "bloque": "C",
        "orden": 10,
        "andamiaje": "bajo",
        "tipo": "poligonal_abierta",
        "labor": "Crucero 220 E — Nivel 3850",
        "contexto": "Arrastre de rutina. La brigada reporta que una visual se tomó con "
        "el instrumento en una sola posición por falta de tiempo.",
        "objetivo": "Procesa la poligonal y decide. Fíjate en la magnitud del error "
        "respecto de la tolerancia, no sólo en su existencia.",
        "tramos": tramos(
            (46.500, 58.400, 0.6), (48.200, 61.700, 0.6), (47.500, 55.300, 0.5),
            (46.900, 49.800, 0.5),
        ),
        "alturas": [H, H, H, H],
        "observaciones": [
            "Sin novedad.",
            "Visual tomada en una sola posición del instrumento por falta de tiempo.",
            "Sin novedad.",
            "Prisma sobre trípode.",
        ],
        "sigma": {"ang_seg": 4.0, "cen_seg": 5.0, "dist_mm": 2.5, "semilla": 101},
        "error": {"tipo": "error_lectura_angulo", "estacion": 1, "delta_grados": 0.0125},
        "decision": "compensar",
        "justificaciones": [
            ("Los cierres, aunque no son despreciables, se mantienen dentro de la "
             "tolerancia del estándar: corresponde compensar y entregar, dejando "
             "constancia de la observación de campo.", True, None),
            ("Cualquier error atribuible a una sola posición del instrumento obliga a "
             "reobservar.", False, "confusion_frecuente"),
            ("El cierre supera la tolerancia y el trabajo debe rechazarse.",
             False, "tecnicamente_falso"),
            ("Al estar dentro de tolerancia, las coordenadas pueden entregarse sin "
             "compensar.", False, "confusion_frecuente"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste sin compensar. El residuo de {{error_lineal_m}} m quedó "
                        "concentrado en el último punto en lugar de repartido.", "medio"),
            "compensar": ("Compensaste y entregaste, dejando registrada la observación "
                          "sobre la visual en una sola posición. El trabajo cumplió el "
                          "estándar.", "bajo"),
            "repetir": ("Rechazaste un trabajo que cumplía la tolerancia. La brigada "
                        "perdió un turno y el crucero quedó sin control mientras tanto.",
                        "medio"),
            "escalar": ("Escalaste una decisión que estaba dentro de tus atribuciones. El "
                        "jefe de topografía indicó compensar.", "medio"),
        },
        "diagnostico": {
            "que_habia": "Un error pequeño en la lectura angular de una estación, "
            "compatible con la visual tomada en una sola posición del instrumento.",
            "por_que": "Medir en dos posiciones elimina errores instrumentales de "
            "colimación y de eje. Con una sola posición, esos errores quedan en la "
            "medición, aunque su magnitud suele mantenerse dentro de tolerancia en "
            "poligonales cortas.",
            "como_detectar": "Lo importante aquí no es detectar el error, sino dimensionarlo. "
            "Un error existente que no supera la tolerancia no justifica reobservar: "
            "justifica compensar y dejar constancia.",
        },
    },
]
