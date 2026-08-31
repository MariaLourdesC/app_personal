# Casos de prueba — Fase 1

> Derivados de los ocho criterios de terminado de `Fase_1_Nucleo_de_decision.md`.
> Responden al **cómo sé que está bien**.
> Principio: los pasos describen lo que hace la usuaria y lo que observa, **nunca el algoritmo interno**. Si el motor cambia por dentro pero sigue eligiendo bien, el caso debe seguir pasando.

---

## Datos base

**Contexto fijo para los casos del motor:** martes, 15:00. Ventana disponible: **40 minutos** (evento fijo a las 15:40, recoger a Sami).

**Buffers configurados (D1):** corta ≤ 30 min → +10 min fijos · media 30 min–2 h → +5% · larga > 2 h → +10%.

### Juego de tareas TB-01

Cada tarea existe para descartar una hipótesis distinta de fallo.

| ID | Tarea | Consecuencia | Deadline | Duración | Peso real | ¿Cabe? | Verifica |
|---|---|---|---|---|---|---|---|
| T1 | Enviar informe al cliente | Alta | Hoy 18:00 | 25 min | 35 min | Sí | **Ganadora esperada** |
| T2 | Preparar propuesta comercial | Alta | Hoy 18:00 | 60 min | 63 min | No | Que no gane algo prioritario que no cabe |
| T3 | Revisar arquitectura del proyecto | Alta | — | 20 min | 30 min | Sí | Que el deadline pese más que la consecuencia sola |
| T4 | Actualizar CV | Baja | En 2 semanas | 15 min | 25 min | Sí | Que no gane por ser corta |
| T5 | Responder mensaje de WhatsApp | Baja | — | 5 min | 15 min | Sí | **Trampa**: si gana, el motor ordena por duración |

**Resultado esperado del juego:** gana **T1**.
T2 se descarta por ventana, T3 por no tener deadline, T4 y T5 por consecuencia baja.

---

## CP-01 · Captura por lenguaje natural
**Criterio 1** · Componente C1

**Precondición:** app instalada, sin tareas.

**Pasos:**
1. Abrir la captura.
2. Escribir *"comprar comida para los perros mañana"*.
3. Guardar.

**Resultado esperado:**
- Existe una tarea persistida.
- Acción extraída: comprar. Entidad: comida para los perros. Fecha objetivo: mañana (fecha resuelta, no el literal "mañana").
- Los campos no inferibles (consecuencia, energía, duración, deadline) quedan **vacíos**, no rellenados con valores fabricados.

**Variantes a cubrir:** texto sin fecha · fecha relativa ("el viernes") · fecha explícita ("el 3 de septiembre") · texto sin verbo reconocible.

---

## CP-02 · Completar campos manualmente
**Criterio 2** · Componente C2

**Precondición:** existe la tarea creada en CP-01, con campos vacíos.

**Pasos:**
1. Abrir la tarea desde el Inbox.
2. Asignar consecuencia, energía, duración estimada y deadline.
3. Guardar.

**Resultado esperado:** los cuatro valores quedan persistidos y son visibles al reabrir la tarea.

---

## CP-03 · AHORA muestra una sola tarea, y es la correcta
**Criterio 3** · Componentes C3, C4, C5

**Precondición:** juego **TB-01** cargado. Hora del sistema: martes 15:00. Evento fijo a las 15:40.

**Pasos:**
1. Abrir la pantalla AHORA.

**Resultado esperado:**
- Se muestra **exactamente una** tarea.
- La tarea mostrada es **T1**.
- No se muestran las otras cuatro ni un listado.

**Fallos que este caso detecta:**
- Muestra T2 — el motor ignora la ventana disponible.
- Muestra T5 — el motor ordena por duración.
- Muestra T3 — el deadline no está pesando sobre la consecuencia.
- Muestra más de una — AHORA no está cumpliendo §39.

---

## CP-04 · Buffer por tramos — casos de borde
**Criterio 3 / D1** · Componente C3

**Precondición:** ventana de 40 minutos.

| Duración | Tramo esperado | Buffer | Peso | ¿Cabe en 40? |
|---|---|---|---|---|
| 29 min | Corta | +10 fijos | 39 min | Sí |
| **30 min** | **Corta** (≤ 30) | +10 fijos | 40 min | Sí, exacto |
| 31 min | Media | +5% | 32,5 min | Sí |
| 2 h 0 min | Media | +5% | 126 min | No |
| 2 h 1 min | Larga | +10% | 133 min | No |

**Foco del caso:** la frontera de 30 min. Al ser el límite superior del tramo corto, un error de `<` vs `<=` cambia el buffer de 10 min a 1,5 min. Debe probarse explícitamente.

---

## CP-05 · La prioridad #1 no cabe
**Criterio 4** · Componentes C3, C4

**Precondición:** juego TB-01 **sin T1** (se elimina la ganadora). Ventana de 40 min.

**Pasos:**
1. Abrir AHORA.

**Resultado esperado:** se muestra **T3** — la de mayor prioridad entre las que sí caben. T2 no se muestra pese a ser superior, porque no cabe.

---

## CP-06 · Proteger la última ventana segura
**Criterio 4 / §23** · Componentes C3, C4

**Precondición:**
- **TX** — consecuencia alta, deadline mañana 09:00, duración 90 min. Su **única** ventana restante hoy es 16:00–18:00.
- **TY** — consecuencia media, sin deadline, duración 100 min.
- Hora: 15:55. Ventana libre: 16:00–18:00.

**Pasos:**
1. Abrir AHORA.

**Resultado esperado:** se muestra **TX**, no TY. Aunque TY cabe en el hueco, ocuparlo destruiría la última oportunidad de TX, que vence mañana.

**Por qué importa:** es el caso que distingue "elegir la que cabe" de "elegir la que cabe sin sacrificar una superior". Es el más propenso a fallar en silencio.

---

## CP-07 · No hay ninguna ventana disponible
**Comportamiento nuevo, no estaba en el PRD** · Componentes C3, C4, C5

**Precondición:** juego TB-01 cargado. Hora: 15:38. Evento fijo a las 15:40 (ventana real: 2 minutos).

**Pasos:**
1. Abrir AHORA.

**Resultado esperado:**
- **No se propone ninguna tarea.**
- Se muestra el **motivo**: no hay hueco disponible.
- Se muestra la **siguiente ventana** en la que sí habrá espacio.

**Decisión de diseño:** no mostrar una tarea que no cabe (sería mentir), no mostrar vacío sin explicación (deja a la usuaria sin saber por qué). En Fase 2 este comportamiento se enriquece con el avance mínimo de §22.

---

## CP-08 · "¿Por qué ahora?"
**Criterio 5 / §40** · Componente C5

**Precondición:** CP-03 ejecutado, T1 visible en AHORA.

**Pasos:**
1. Pulsar "¿Por qué ahora?".

**Resultado esperado:**
- Se explican los factores que ganaron, en lenguaje natural (deadline hoy, cabe en la ventana disponible, consecuencia alta).
- **No** se muestran pesos, fórmulas ni nombres internos del algoritmo.

---

## CP-09 · Marcado de campos asumidos
**Criterio 5 / D2** · Componentes C4, C5

**Precondición:** una tarea con **consecuencia vacía**, todo lo demás completo, y que sea la elegida.

**Pasos:**
1. Abrir AHORA.
2. Pulsar "¿Por qué ahora?".

**Resultado esperado:**
- La tarea se muestra igual: el motor **degrada, no bloquea**.
- AHORA indica visiblemente que la decisión se tomó con al menos un campo asumido.
- "¿Por qué ahora?" señala **cuál** campo fue asumido y con qué valor por defecto.
- **No** aparece ninguna justificación fabricada del tipo *"es urgente porque vence mañana"* si nadie declaró ese deadline.

---

## CP-10 · Registro de cierre
**Criterio 6 / §64** · Componente C6

**Precondición:** T1 visible en AHORA, timer corriendo.

**Pasos:**
1. Dejar correr el timer un tiempo conocido.
2. Pulsar Terminar.

**Resultado esperado:** existe un registro persistido con los seis campos: inicio, fin, duración real, estimación original, interrupciones, distracciones.

**Verificación:** directamente en base de datos. En Fase 1 **ninguna pantalla lee este registro**, así que un fallo aquí es invisible desde la interfaz — es exactamente el riesgo R2.

---

## CP-11 · Restricciones duras
**Criterio 7 / §34, §35** · Componentes C3, C4

**Precondición:** bloque de sueño y 45 min de tiempo personal configurados. Tareas cargadas que cabrían dentro de esos bloques.

**Pasos:**
1. Abrir AHORA en un momento en que la única ventana libre esté dentro del bloque de sueño.
2. Repetir con el bloque de tiempo personal.

**Resultado esperado:** en ambos casos, **ninguna tarea se propone dentro de esos bloques**, sin importar su consecuencia o deadline. Se aplica el comportamiento de CP-07.

---

## CP-12 · Caja rápida
**Criterio 8 / §15** · Componentes C2, C5

**Precondición:** AHORA abierto con una tarea en curso.

**Pasos:**
1. Abrir la caja rápida.
2. Escribir *"revisar postulación que vi en la PC"*.
3. Confirmar.

**Resultado esperado:**
- El texto queda guardado en el Inbox.
- **No** se muestra categoría, análisis, prioridad ni confirmación elaborada.
- La tarea en curso **no se interrumpe** y el timer sigue corriendo.

---

## Cobertura

| Criterio | Casos |
|---|---|
| 1 · Captura NL | CP-01 |
| 2 · Completar campos | CP-02 |
| 3 · AHORA una sola tarea | CP-03, CP-04 |
| 4 · Recorte por ventana | CP-05, CP-06 |
| 5 · ¿Por qué ahora? | CP-08, CP-09 |
| 6 · Registro §64 | CP-10 |
| 7 · Restricciones duras | CP-11 |
| 8 · Caja rápida | CP-12 |
| — · Sin ventana disponible | CP-07 |

**Sin cobertura y consciente:** persistencia entre reinicios, comportamiento con Inbox vacío, y tareas con duración estimada nula. Añadir cuando C2 esté construido.
