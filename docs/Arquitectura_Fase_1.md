# Arquitectura — Fase 1

> Responde al **cómo**. El PRD responde al qué, los documentos de fases al cuándo, y los casos de prueba al cómo sé que está bien.
> Alcance: solo Fase 1 (C1–C6). Fase 2 se anota donde impacta, no se diseña aquí.

---

## Stack

| Capa | Elección | Motivo |
|---|---|---|
| App | **Flutter (Dart)** | iPhone hoy, Android después, un solo código. Dart es tipado y orientado a objetos: viniendo de Java se lee casi solo. |
| Datos (Fase 1) | **SQLite local** | Nada en Fase 1 requiere servidor. El dispositivo real de uso es el iPhone. |
| Backend (futuro) | **Python — FastAPI o Django** | Lenguaje ya dominado. No se construye en Fase 1. |

**Descartado: React Native.** Su ventaja principal es reutilizar JavaScript, que aquí no aplica.

**Descartado: backend desde el día 1.** Servidor, base remota, autenticación, deploy, estados de red y modo sin conexión suman fácilmente el doble de trabajo de la Fase 1, y ninguno acerca al objetivo de la fase (*"esto es lo que tienes que hacer ahora"*).

**Lo que sí se hace desde el día 1:** las interfaces se definen como si hablaran con un servidor. Cambiar la implementación después no toca la lógica ni las pantallas.

### Nota sobre "escalable"

La palabra tiene dos sentidos y solo uno aplica aquí:

- *Aguantar muchos usuarios* — no aplica. Hay una usuaria.
- *Poder cambiar piezas sin rehacer todo* — **este es el objetivo.**

Lo segundo no se consigue con infraestructura sino con separación de capas e interfaces.

---

## Capas

```
+---------------------------------------+
|  PANTALLAS                            |
|  AHORA · Lista del día · Captura      |
+---------------------------------------+
               | pide decisiones, no datos
               v
+---------------------------------------+
|  LOGICA                               |
|  C3 Capacidad/Ventanas                |
|  C4 Motor de prioridad                |
+---------------------------------------+
               | interfaces
               v
+---------------------------------------+
|  REPOSITORIES                         |
|  TaskRepository                       |
|  ConfigRepository                     |
|  CompletionRepository                 |
+---------------------------------------+
               |
               v
        SQLite local  ->  (futuro: API Python)
```

**Regla única:** cada capa habla solo con la de abajo, y siempre a través de interfaces.

### Por qué las pantallas no llaman a los repositories

1. **Duplicación.** AHORA y la lista del día necesitan tareas priorizadas. Si cada pantalla lee del repositorio, la lógica de decidir se replica en las dos y diverge.
2. **Testabilidad.** Con la lógica en la pantalla, probar el motor exige abrir la app y mirar. Con la lógica separada, se le pasan cinco tareas de fixture y se verifica el orden en un test.

**La pantalla no decide, solo muestra lo que le dan.**

---

## Repositories

Tres, agrupados por comportamiento y no por entidad.

### `TaskRepository`
Guarda `Task` (§106) y `Pillar` (§105). Lectura y escritura constante. Es el dato central.

### `ConfigRepository`
Guarda `User` (§104) y la configuración de capacidad de §19. Un solo registro de cada uno, se lee en cada cálculo, se escribe casi nunca. Van juntos porque son la misma naturaleza —configuración estable—; separarlos sería ruido.

### `CompletionRepository`
Guarda los registros de cierre de §64. **Solo escribe.** Nadie lee en Fase 1: es el productor silencioso que alimenta §9, §66, §68 y §69 más adelante.

Dos consecuencias de ese comportamiento:

- **Su interfaz es minúscula** — un método `save()`. Las consultas se añaden en la fase de aprendizaje sin tocar nada más.
- **Es el primer candidato a irse al servidor.** Es el que más crece y el único que no necesita ser instantáneo: se escribe local y se sincroniza después sin que la app se entere.

---

## Contrato de la decisión

C4 no devuelve una lista de tareas ordenadas. Devuelve la decisión ya tomada, para que la pantalla no tenga que pensar:

```dart
class DecisionResult {
  final Task task;              // la tarea a mostrar
  final Reason reason;          // factores que ganaron — "¿Por qué ahora?"
  final List<String> assumed;   // campos resueltos con defaults — D2
}
```

**`reason`** existe porque la pantalla no sabe de consecuencias ni de ventanas: solo el motor sabe por qué eligió. Sin este campo, §40 sería imposible sin duplicar lógica en la UI.

**`assumed`** implementa D2 de la Fase 1: si el motor decidió sobre defaults, AHORA debe marcarlo. La pantalla no lo calcula, lo recibe y lo pinta.

---

## Contenido de la pantalla AHORA (§39)

Solo esto, y nada más:

- Tarea actual
- Tiempo estimado
- Deadline
- Timer
- Botón Terminar
- Caja rápida (§15)
- Botón "¿Por qué ahora?"

**Explícitamente fuera de AHORA en Fase 1:** mascota y XP (§59–63, gamificación), registro de distracciones (C8, Fase 2), plan del día con horarios (C7, Fase 2). La lista del día en Fase 1 es una vista simple de tareas priorizadas, sin horarios.

---

## Orden de construcción

> **C3 → C4 → C2 → C5 + C6 → C1**

El orden de construcción **no es** el orden del flujo de datos. Lo que manda es qué se puede probar con entradas falsas.

| Paso | Componente | Por qué aquí |
|---|---|---|
| 1 | **C3 Capacidad/Ventanas** | Único que se prueba completamente solo: una tarea, una hora, una configuración — cabe o no cabe. Y no se puede falsear, porque es un cálculo en tiempo real, no un dato de entrada. |
| 2 | **C4 Motor** | Necesita C3 vivo. Sus tareas sí se falsean con fixtures, así que no necesita C1 ni C2. |
| 3 | **C2 Inbox** | Persistencia real y edición manual de campos. |
| 4 | **C5 AHORA + C6 Cierre** | Se entregan juntos. C6 no se deja para el final: es el componente invisible que R2 advierte que se cae de las listas. |
| 5 | **C1 Captura NL** | Lo último a propósito: es la pieza más difícil y la única prescindible. Si el parser falla, las tareas se meten a mano y la app sigue siendo usable. |

---

## Decisiones abiertas

**Captura NL: reglas locales o llamada a un modelo.** Con reglas es limitado pero gratis y funciona sin conexión; con un LLM es mucho mejor pero añade costo por tarea capturada y dependencia de red. Como C1 va al final del orden de construcción, la decisión puede posponerse sin bloquear nada.

---

## Preparado para Fase 2, no construido

- **Subtask** (D3 de Fase 1): el timer se engancha al nivel más profundo que exista. El registro de §64 debe poder indicar a qué nivel corrió, y C3 debe medir huecos contra "la unidad que tiene el timer", no contra `Task` de forma rígida.
- **Sincronización:** las interfaces de los tres repositories se definen sin asumir que la fuente es local.
