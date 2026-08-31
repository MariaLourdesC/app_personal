# Fase 1 — Núcleo de decisión

> Derivada del PRD v1 aplicando tres reglas de faseo:
> 1. Una fase no puede consumir lo que ninguna fase anterior produce.
> 2. Los productores de evidencia van temprano aunque no den valor visible; los consumidores van tarde.
> 3. Cadena base sin ciclos: **capacidad/ventanas → motor de prioridad → planificador diario**.

---

## Objetivo

Que la app pueda responder **"esto es lo que tienes que hacer ahora"** (§126) de extremo a extremo, con el mínimo de componentes, **y que empiece a acumular evidencia desde el primer día** aunque nadie la consuma todavía.

Fase 1 **no** busca acertar bien. Busca cerrar el circuito y empezar a medir.

---

## Componentes

### C1 — Captura por lenguaje natural (básica) — §10, §11

Extrae del texto libre únicamente lo que el texto permite (§11): acción, entidad, fecha objetivo, deadline explícito.

**No incluye en esta fase:** inferencia de consecuencia, de pilar, de complejidad (§67) ni preguntas adaptativas (§12). Los campos que no se infieren quedan vacíos y se completan a mano en C2.

### C2 — Inbox / almacén de tareas — §14, §42

Persistencia de `Task` (§106) y edición manual de todos sus campos. En fase 1 el Inbox es más "formulario asistido" que "inbox inteligente": la usuaria completa consecuencia, energía y duración estimada porque nada las infiere todavía.

### C3 — Capacidad y ventanas — §7, §8, §19, §23

Componente que **no ordena nada**. Solo responde: *¿esta tarea cabe ahora?*

Consume tres grupos de datos:
- **Peso de la tarea:** duración + preparación + traslado + buffer de seguridad (§7)
- **Espacio disponible:** capacidad real segmentada — necesidades fijas / foco / tareas ligeras / pausas activas / buffer / tiempo personal / sueño (§19)
- **Ancla:** hora real

Devuelve: ventana posible, ventana segura, cabe / no cabe (§8).

En fase 1 la segmentación de capacidad se **configura a mano**. §21 (capacidad aprendida) queda fuera.

### C4 — Motor de prioridad — §4, §5, §6, §125

Aplica primero restricciones duras: emergencia → necesidades esenciales → sueño y compromisos protegidos → deadlines y ventanas seguras. Después evalúa consecuencia + deadline + ventana + energía + duración + valor estratégico.

Consulta a C3 para su factor 3 ("ventana segura disponible") y para la regla de §23: si la #1 no cabe, elegir la de mayor prioridad que sí quepa **sin destruir la última ventana segura de una tarea superior**.

Devuelve un orden, no un horario.

### C5 — Pantalla AHORA — §39, §40

Muestra únicamente: tarea actual, tiempo estimado, deadline, timer, botón Terminar, caja rápida (§15), botón "¿Por qué ahora?".

"¿Por qué ahora?" en fase 1 puede ser una explicación plana de los factores que ganaron. No expone el algoritmo (§40).

### C6 — Cierre de tarea — §64

**Productor silencioso.** No tiene UI propia más allá del botón Terminar. Al cerrar una tarea escribe: inicio, fin, duración real, estimación original, interrupciones, distracciones.

No sirve para nada en fase 1. Es el input de §9, §66, §68 y §69 en fases posteriores. **No es recortable.**

---

## Datos necesarios

| Entidad | Alcance en fase 1 |
|---|---|
| `User` (§104) | timezone, focus_block_minutes, break_minutes, protected_personal_minutes, default_buffer_minutes, sleep_target, wake_target |
| `Task` (§106) | todos los campos excepto `actual_duration` (lo escribe C6) y `alternative_responsible` |
| `Pillar` (§105) | los 4 pilares precargados |
| Registro de cierre | los seis campos de §64 |
| Configuración de capacidad | la segmentación de §19, ingresada a mano |

**Fuera:** `FocusSession`, `Interruption`, `DailyPlan`, `Project`, `Habit`, `StudyTopic`, todo lo financiero, `StockItem`, `SleepSession`, `PetProgress`.

---

## Diferido, no eliminado

Planificador diario y recalculación (§16–19) · Focus tracker y detección de distracción (§27–32) · Interrupciones (§25, §26) · Sueño y siesta (§35–38) · Proyectos (§43–49) · Dependencias y desbloqueadores (§50–52) · Hábitos (§53–58) · Mascota y XP (§59–63) · Aprendizaje de estimación (§66–69) · Estudio y repasos (§70–78) · Recordatorios y recurrencias (§79–81) · Finanzas (§82–91) · Stock y compras (§92–97) · Estadísticas (§98–101) · Chat global multicontexto (§13).

---

## Riesgos

**R1 — El motor va a decidir mal las primeras semanas.**
Las estimaciones no están calibradas (§68 asume subestimación) y la capacidad está configurada a ojo. Comportamiento esperado, no bug. Mitigación: buffer por defecto conservador (ver decisión abierta) y §40 visible para poder auditar por qué eligió mal.

**R2 — Tentación de recortar C6.**
Es el único componente sin valor visible. Si se pospone, la fase de aprendizaje arranca con la tabla vacía y hay que esperar meses de uso.

**R3 — Fricción de captura.**
Con C1 básico y sin preguntas adaptativas, cada tarea exige completar campos a mano. Riesgo real de abandono. Mitigación: defaults agresivos (consecuencia media, energía media) y permitir que el motor opere con campos incompletos degradando en lugar de bloquear.

**R4 — Confundir C3 con C4 al implementar.**
Costó separarlos conceptualmente; si se implementan en el mismo módulo vuelve el ciclo y el planificador de fase 2 no tendrá dónde engancharse. Deben ser interfaces separadas desde el día 1.

**R5 — Capacidad estática.**
C3 asume una segmentación fija de §19. Un día atípico rompe la estimación y no hay recalculación (§17, §18) hasta fase 2.

---

## Criterio de terminado

La fase 1 está terminada cuando, con la app instalada vacía:

1. Escribo *"comprar comida para los perros mañana"* en texto libre y queda una tarea persistida con acción, entidad y fecha objetivo extraídas.
2. Puedo completar a mano consecuencia, energía, duración estimada y deadline de esa tarea.
3. Con 5 tareas cargadas y siendo las 3 p. m., la app me muestra **una sola** tarea en AHORA.
4. Si la tarea de mayor prioridad no cabe en el hueco disponible, la app muestra la siguiente que sí cabe, y no lo hace si eso destruye la última ventana segura de una superior (§23).
5. "¿Por qué ahora?" devuelve los factores que ganaron, sin exponer el algoritmo.
6. Al pulsar Terminar queda escrito un registro con los seis campos de §64, verificable en base de datos.
7. Ninguna propuesta del motor invade el bloque de sueño ni los 45 min de tiempo personal protegido (§34, §35).
8. La caja rápida guarda un título en el Inbox sin mostrar categoría, análisis ni prioridad (§15).

---

## Decisiones tomadas

### D1 — Buffer por defecto: generoso, por tramos

**Motivo (asimetría de costos):** buffer corto + subestimación → la app promete que cabe, no cabe, y se come sueño o tiempo personal, rompiendo §34 y §35 que son restricciones duras. Buffer largo + subestimación → sobra tiempo y la app ofrece otra tarea; costo casi nulo. Además §9 permite *bajar* buffers con evidencia, lo que es más fácil que subirlos después de semanas de planes rotos.

| Tramo | Duración estimada | Buffer |
|---|---|---|
| Corta | ≤ 30 min | +10 min |
| Media | 30 min – 2 h | +5% |
| Larga | > 2 h | +10% |

**Por qué la tarea corta lleva proporcionalmente más aire:** el buffer aquí no modela error de estimación sino **probabilidad de interrupción** (§33: retrasos, imprevistos, desviaciones, distracción ocasional). Las tareas cortas ocurren en contextos interrumpibles; las largas ocurren en sesión de computadora, donde el entorno ya sabe no interrumpir.

**Implicación para §9 (fase posterior):** si la variable real es la probabilidad de interrupción, el buffer aprendido debe segmentarse por **contexto** (hora del día, Sami presente o en colegio, tipo de entorno), no solo por duración. La duración es un proxy provisional.

**No cubierto por el buffer, aunque se le parezca:**
- *Sobrecarga* (meter 10 tareas donde caben 2) — lo resuelven §18 y §19, capacidad y planificador.
- *Hiperfoco* (no saber parar) — lo resuelve §20, bloques con pausa obligatoria.

### D2 — Campos incompletos: el motor asume, no inventa

En fase 1 casi todas las tareas tendrán campos vacíos, porque C1 solo extrae acción, entidad y fecha. El motor **decide igual, degradando**, sin bloquear. Esto no contradice el principio 3 ("no inventar contexto"), con esta línea:

- **Asumir** = aplicar un default declarado, marcarlo como asumido y tratar la decisión como provisional. *Consecuencia desconocida → media, marcada.*
- **Inventar** = fabricar una razón y presentarla como dato de la usuaria. *"Es urgente porque se te acaba mañana"* cuando nadie lo dijo. Prohibido.

**Consecuencia sobre §40 ("¿Por qué ahora?"):** cuando el motor decidió sobre campos asumidos, debe decirlo y señalar cuáles. No puede sonar igual de seguro con datos reales que con defaults. Esto sostiene el principio 11 (la IA recomienda, la usuaria conserva el criterio): sin ver sobre qué decidió, la usuaria no puede corregirlo ni calibrarlo.

**Añadir al criterio de terminado:** la pantalla AHORA distingue visiblemente entre una decisión tomada con datos completos y una tomada con defaults asumidos.

### D3 — Dejar espacio para la jerarquía (decidido durante el diseño de Fase 2)

La Fase 2 introduce un nivel opcional de **subtask** bajo `Task`, y el timer se engancha siempre al nivel más profundo que exista. La Fase 1 **no necesita construir subtasks** —la jerarquía es opcional y una task suelta funciona igual—, pero el modelo de datos debe dejar el espacio previsto para evitar una migración después:

- El registro de §64 debe poder indicar **a qué nivel** corrió el timer.
- C3 debe medir huecos contra "la unidad que tiene el timer", no contra `Task` de forma rígida.

Motivo: los registros por subtask son lo que hace viable §66 más adelante. Las tasks grandes casi nunca tienen comparables; las subtasks sí se repiten.
