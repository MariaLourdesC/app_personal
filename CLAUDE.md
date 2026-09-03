# App_Personal

Personal assistant app (task capture, prioritization engine, focus screen, habits, finance, study tracking). Flutter/Dart + local SQLite for Phase 1; Python (FastAPI/Django) backend planned for later, not built yet.

Full spec lives in `docs/`: `Product_Requirements_v1.md` (PRD, sections numbered §1–§126), `Fase_1_Nucleo_de_decision.md` (Phase 1 scope, components C1–C6, decisions D1–D3), `Arquitectura_Fase_1.md` (layering, repositories), `Casos_de_prueba_Fase_1.md` (test cases CP-01..CP-12, referenced from code comments/tests).

## How the user wants to work

The user is QA automation background (Python/Java), new to Dart/Flutter, building this to maintain for years — she wants to understand every piece, not receive a finished app. Per component:

1. Explain in prose what will be built, what files, how it connects — before writing code. Wait for approval.
2. Write code in small chunks (one class/function at a time). Pause after each. **If a prerequisite or side-change turns up mid-piece (e.g. "to build X I first need to change Y that we already built"), stop and present that as its own explicit step — don't just mention it in passing and keep going. She was explicit about this after it happened once during C4.**
3. Explain Dart-specific decisions a Java dev wouldn't find obvious (null safety, `final` vs `const`, named params, top-level functions, library-private `_name`, operator overloading). Skip what's already familiar from Java.
4. End each chunk with a concrete comprehension question. Don't proceed until answered.
5. Don't move to the next component until the current one's relevant test cases pass.

**Decision levels:** Crítico (business logic, cross-layer contracts, data model) → present options, let her decide. Relevante pero reversible → recommend with a brief reason, ask if she objects, proceed. Rutina (boilerplate, imports, config) → decide and explain only what's needed after.

**Don't:** implement anything marked Phase 2+. Invent business rules not in the docs — ask instead. Generate a whole component at once. Change the layering without flagging it first.

**Folder structure is a teaching topic, not routine** — she's explicitly said understanding *why* a structure reflects a design pattern is a standing gap. Explain new folders before creating them, even though structure would normally count as "rutina."

**Installations / system changes** (SDK installs, PATH edits, package managers): hand her the exact commands with a line-by-line explanation; she runs them herself. This does not apply to project-scoped actions (`flutter create`, editing files, running tests) — those follow the normal small-chunks workflow above.

## Build order

**C3 → C4 → C2 → C5 + C6 → C1** (capacity/windows → priority engine → inbox → AHORA screen + task close → NL capture). Not the data-flow order — it's ordered by what can be tested with fake inputs first. See `Arquitectura_Fase_1.md` for why.

Layering: `lib/logic/` (pure Dart, no `package:flutter` imports) → `lib/repositories/` → SQLite. `lib/screens/` talks only to `lib/logic/`, never directly to repositories. Tests mirror `lib/` under `test/`.

## Status (as of this file's last update)

**C3 (Capacidad y Ventanas) — done, closed at 4 pieces.**

Built, all tested (see `test/logic/capacity/`):
- `lib/logic/capacity/buffer_calculator.dart` — `calculateBuffer`, D1 tiered buffer (CP-04 edge cases).
- `lib/logic/capacity/task_weight_calculator.dart` — `calculateTaskWeight` (duration + prepTime/travelTime, both always zero in Phase 1 + buffer), tested against TB-01.
- `lib/logic/capacity/time_window.dart` — `TimeWindow` (start/end `DateTime`, `duration` getter). Constructor **throws `ArgumentError`** (real runtime check, not a debug-only `assert`) if `end` isn't strictly after `start` — chosen deliberately because a window's start/end will eventually come from real-world data (device clock, calendar), not just trusted hand-written code, and a silently-corrupt window (negative duration) could produce wrong "cabe/no cabe" decisions downstream, which matters given C3 protects hard constraints (§34/§35).
- `lib/logic/capacity/fit_checker.dart` — `taskFits({taskWeight, window})`, boolean only (`taskWeight <= window.duration`). Deliberately does **not** implement the PRD §8 "ventana posible" vs "ventana segura" distinction as two separate outputs — no CP test case and no consumer (C4/C5) in Fase 1 docs reads a separate "posible" signal; D1's buffer is Fase 1's actual answer to §8's safety concern. Cheap to add a sibling function later if a real need shows up.
- Skipped on purpose (piece 3 in the original plan): a dedicated "C3 input" wrapper class — the functions ended up taking `Duration`/`TimeWindow` params directly, so a wrapper would have been speculative.

**C4 (Motor de prioridad) — done, closed at 6 pieces.** Next component is **C2**.

Built, all tested (see `test/logic/priority/`):
- `lib/logic/priority/priority_candidate.dart` — `ConsequenceLevel` enum + `PriorityCandidate` (id, nullable consequenceLevel, estimatedDuration, nullable deadline). Lightweight input scoped to C4, not the full `Task` (§106) — same reasoning as C3's skipped wrapper, except here a class was justified since C4 compares several fields at once (TB-01 exercises 4 of them). `consequenceLevel` is nullable to represent D2 "not declared yet" (needed for CP-09); `null` is a real distinct state, not a stand-in for a default.
- `lib/logic/priority/window_filter.dart` — `candidatesThatFit`, reuses C3's `calculateTaskWeight`/`taskFits`, tested against TB-01 (T2 excluded, T1/T3/T4/T5 fit).
- `lib/logic/priority/priority_ranking.dart` — `pickWinner`: ranks by consequence tier (explicit `switch`-based rank, deliberately not `.index`) then deadline (has > hasn't; nearer beats farther). Two explicit, tested tie/edge rules, not accidents of statement order:
  - Same tier, neither has a deadline → first candidate in the input list wins.
  - **A default-assumed consequence (D2, `null` → treated as "media") never outranks a real, declared lower value** — e.g. an undeclared task (defaulted to "media") loses to a real "baja" task, even though "media" would normally beat "baja". An assumption isn't allowed to out-compete confirmed data. This was a deliberate correction after the user caught the counter-intuitive default behavior — see `_compareConsequence` in the file for the exact mechanism.
- `lib/logic/priority/reason.dart` — `Reason` (structured facts: resolved consequenceLevel, hasDeadline, deadline) + `reasonFor(candidate)`. Deliberately **not** a natural-language string — C4 is pure logic and shouldn't own Spanish phrasing for CP-08; that's C5's job when it's built ("la pantalla no decide, solo muestra").
- `lib/logic/priority/decision_result.dart` — `DecisionResult` (candidate + reason + assumed), the contract from `Arquitectura_Fase_1.md`, using `PriorityCandidate` instead of `Task` for the same reason as above.
- `lib/logic/priority/priority_engine.dart` — `decide(candidates, window)`, the public entry point chaining all of the above. Covers CP-03 (via TB-01), CP-09, and CP-06's literal fixture.
- `test/logic/priority/cp06_test.dart` — confirms CP-06's literal scenario (TX beats TY) already passes with plain ranking alone, **but see the open question below**: this doesn't actually exercise §23's real protective mechanism.

**Open question, still unresolved — surface it again before C2/C5 need real windows/scheduling:** both CP-07 and CP-06/§23's *real* mechanism are blocked by the same missing data-model piece.

- CP-07 ("no hay ninguna ventana disponible") needs: (1) a reason string — trivial, already available via `taskFits` returning `false`; (2) **"se muestra la siguiente ventana en la que sí habrá espacio"** — needs enumerating multiple windows across the rest of the day.
- CP-06/§23 ("si la #1 no cabe, elegir la que sí quepa sin destruir la última ventana segura de una tarea superior") — the literal CP-06 fixture passes with plain consequence-ranking alone (TX beats TY on consequence, no special logic needed), so it does **not** actually test §23's real mechanism. That mechanism only matters when a *lower*-ranked candidate would otherwise win but doing so would remove a *higher*-ranked candidate's only remaining window today — detecting that requires knowing whether the higher candidate has another window later today.

Both needs boil down to the same thing: knowledge of the day's remaining free windows, which requires knowing fixed calendar events/commitments (e.g. "recoger a Sami a las 15:40" from the CP-03/CP-07 fixtures). **No entity for this exists anywhere in the PRD's data model (§104–124).** This is a real gap, not a deferred nice-to-have. Resolving it needs either (a) a new data entity for fixed events, defined with the user (Crítico decision, do not invent it), or (b) some other resolution she chooses.

## Decisions made that aren't fully spelled out in the docs

- **Duration type:** durations are `Duration`, never raw `int` minutes — avoids unit ambiguity, matches Dart/Flutter convention.
- **Buffer rounding:** fractional buffer minutes (media/larga tramos, e.g. 31 min × 5%) round **up** (`.ceil()`), following D1's asymmetric-cost reasoning. Note: this makes the 2h1min case compute to 134 min total, not the "133 min" the CP-04 table shows by hand — that's expected, not a bug (see conversation history / commit context if this needs re-justifying).
- **`prepTime`/`travelTime`:** `Task` (§106) has no such fields. `calculateTaskWeight` takes them as its own named parameters (`Duration prepTime = Duration.zero`, `travelTime` same), always zero in Phase 1. Not a promise that `Task` will ever gain these fields.
- **`User.default_buffer_minutes` (§104):** unused in Phase 1. C3 only implements the D1 tiered table. That field belongs to the §9 adaptive-buffer-learning feature (later phase).
- **Capacity config (§19 segmentation):** the PRD defines no separate entity for it. CP-11 protects sleep/personal time using `User` fields directly (`sleep_target`, `wake_target`, `protected_personal_minutes`), suggesting Phase 1 "capacity config" is just `User` — not yet confirmed with her; confirm when building that piece.
