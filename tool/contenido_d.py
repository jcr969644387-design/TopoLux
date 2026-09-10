"""Casos del bloque D — aplicación: sobrerotura y replanteo."""

CASOS_D = [
    # ------------------------------------------------------------------ D11
    {
        "id": "gal-118-sobrerotura-11",
        "titulo": "Sobrerotura del avance — Galería 118 N",
        "bloque": "D",
        "orden": 11,
        "andamiaje": "bajo",
        "tipo": "sobrerotura",
        "labor": "Galería 118 N — avance de guardia",
        "contexto": "Se levantaron secciones transversales cada 5 metros sobre los 25 "
        "metros avanzados en la guardia. La sección de diseño es de 4,00 m de ancho por "
        "4,00 m de alto. El contratista solicita la valorización del avance.",
        "objetivo": "Calcula el volumen excavado por el método de áreas medias, determina "
        "la sobrerotura respecto del diseño y decide qué informar.",
        "seccion_diseno": {"ancho_m": 4.00, "alto_m": 4.00, "area_m2": 16.00,
                           "perimetro_m": 16.00},
        "secciones": [
            {"progresiva_m": 0.0, "area_real_m2": 17.10},
            {"progresiva_m": 5.0, "area_real_m2": 18.40},
            {"progresiva_m": 10.0, "area_real_m2": 19.80},
            {"progresiva_m": 15.0, "area_real_m2": 20.60},
            {"progresiva_m": 20.0, "area_real_m2": 19.20},
            {"progresiva_m": 25.0, "area_real_m2": 18.10},
        ],
        "tolerancia": {"sobrerotura_m": 0.10},
        "observaciones": [
            "Voladura ejecutada con malla estándar de la operación.",
            "Progresivas 10 a 20 con presencia de fracturamiento visible en el techo.",
        ],
        "decision": "escalar",
        "justificaciones": [
            ("La sobrerotura media supera la tolerancia del estándar y se concentra en un "
             "tramo identificable: debe informarse porque afecta al consumo de "
             "sostenimiento, al acarreo y a la dilución.", True, None),
            ("El volumen excavado es mayor al de diseño, lo que significa mayor avance y "
             "debe valorizarse a favor del contratista.", False, "tecnicamente_falso"),
            ("La diferencia entre volumen real y de diseño se compensa promediando con las "
             "guardias anteriores.", False, "confusion_frecuente"),
            ("El fracturamiento del macizo explica la sobrerotura, por lo que no "
             "corresponde ninguna acción.", False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Valorizaste {{volumen_sobrerotura_m3}} m3 de sobrerotura como "
                        "avance útil. Se pagó excavación no requerida y el sobreconsumo de "
                        "shotcrete apareció después sin explicación.", "alto"),
            "compensar": ("Promediaste con guardias anteriores. La señal de un problema de "
                          "voladura o de sostenimiento quedó diluida en el promedio "
                          "mensual.", "alto"),
            "repetir": ("Mandaste a relevar las secciones. El resultado fue el mismo: la "
                        "sobrerotura es real, no un error de medición.", "medio"),
            "escalar": ("Informaste la sobrerotura de {{sobrerotura_lineal_media_m}} m "
                        "media, con el tramo identificado. Perforación y voladura revisó "
                        "la malla y geomecánica evaluó el sostenimiento del tramo "
                        "fracturado.", "bajo"),
        },
        "diagnostico": {
            "que_habia": "Sobrerotura por encima de la tolerancia, concentrada en el tramo "
            "con fracturamiento visible.",
            "por_que": "La sobrerotura tiene tres consecuencias que se pagan: más metros "
            "cúbicos de shotcrete y sostenimiento, más material estéril que acarrear, y "
            "dilución del mineral cuando ocurre en labores de producción. Por eso es un "
            "indicador de control, no un dato administrativo.",
            "como_detectar": "Calcula el volumen por áreas medias y compáralo con el "
            "volumen de diseño del mismo tramo. Convierte la diferencia a sobrerotura "
            "lineal media dividiendo entre el perímetro de la sección y la longitud, para "
            "poder compararla con la tolerancia del estándar.",
        },
    },
    # ------------------------------------------------------------------ D12
    {
        "id": "gal-118-replanteo-12",
        "titulo": "Dar línea al frente — Galería 118 N",
        "bloque": "D",
        "orden": 12,
        "andamiaje": "bajo",
        "tipo": "replanteo",
        "labor": "Galería 118 N — frente de avance",
        "contexto": "El jumbo está en el frente esperando la línea de perforación. Debes "
        "entregar los datos de replanteo desde la estación de control E-3, orientando a "
        "BM-20, hacia el punto de diseño del eje de la galería.",
        "objetivo": "Calcula el ángulo a girar desde la referencia, la distancia "
        "horizontal y el desnivel al punto de diseño, y decide si entregas la línea.",
        "estacion": {"id": "E-3", "norte": 1101.560, "este": 1108.240, "cota": 3850.720},
        "referencia": {"id": "BM-20", "norte": 1132.180, "este": 1141.070, "cota": 3850.900},
        "objetivo_diseno": {"id": "D-14", "norte": 1128.400, "este": 1136.900,
                            "cota": 3850.910},
        "alturas": {"instrumento": 1.482, "prisma": 1.500},
        "tolerancia": {"angular_seg": 30.0, "lineal_m": 0.010},
        "observaciones": [
            "Estación E-3 verificada contra el arrastre de control del nivel.",
            "Jumbo en posición. Frente ventilado y sostenido.",
        ],
        "decision": "aceptar",
        "justificaciones": [
            ("La estación de control está verificada, los datos de replanteo se calculan "
             "directamente de las coordenadas y no hay ninguna observación que impida "
             "entregar la línea.", True, None),
            ("Antes de replantear hay que reobservar la poligonal completa del nivel.",
             False, "confusion_frecuente"),
            ("El replanteo debe entregarse en azimut absoluto, no como ángulo a girar "
             "desde la referencia.", False, "tecnicamente_falso"),
            ("El frente está ventilado y sostenido, condición suficiente para entregar la "
             "línea.", False, "cierto_pero_irrelevante"),
        ],
        "consecuencias": {
            "aceptar": ("Entregaste la línea. El jumbo perforó sobre el eje de diseño y el "
                        "avance de la guardia quedó dentro de tolerancia.", "bajo"),
            "compensar": ("No hay nada que compensar en un replanteo: los datos se derivan "
                          "de coordenadas conocidas. El jumbo esperó sin línea.", "medio"),
            "repetir": ("Mandaste a reobservar una estación verificada. El jumbo perdió "
                        "media guardia esperando la línea.", "alto"),
            "escalar": ("Escalaste una tarea de rutina. El frente esperó y el jefe de "
                        "topografía indicó que entregaras la línea.", "medio"),
        },
        "diagnostico": {
            "que_habia": "No había ningún problema. Este caso evalúa si sabes resolver el "
            "problema inverso y entregar la línea sin demorar el frente.",
            "por_que": "El replanteo es aproximadamente la mitad del trabajo real de un "
            "topógrafo de mina: no sólo documentar lo ejecutado, sino ubicar dónde debe "
            "ejecutarse. Un error de replanteo desvía la labor; un error de levantamiento "
            "sólo la documenta mal.",
            "como_detectar": "El replanteo es el problema inverso del levantamiento: de "
            "coordenadas a azimut y distancia. Se entrega como ángulo a girar desde una "
            "referencia visible, porque es lo que el operador puede materializar con el "
            "instrumento.",
        },
    },
]
