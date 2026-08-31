# App_Personal

Personal assistant app (task capture, prioritization engine, focus screen, habits, finance, study tracking). Flutter/Dart + local SQLite for Phase 1; Python (FastAPI/Django) backend planned for later, not built yet.

Full spec lives in `docs/`: `Product_Requirements_v1.md` (PRD, sections numbered §1–§126), `Fase_1_Nucleo_de_decision.md` (Phase 1 scope, components C1–C6, decisions D1–D3), `Arquitectura_Fase_1.md` (layering, repositories), `Casos_de_prueba_Fase_1.md` (test cases CP-01..CP-12, referenced from code comments/tests).

## How the user wants to work

The user is QA automation background (Python/Java), new to Dart/Flutter, building this to maintain for years — she wants to understand every piece, not receive a finished app. Per component:

1. Explain in prose what will be built, what files, how it connects — before writing code. Wait for approval.
2. Write code in small chunks (one class/function at a time). Pause after each.
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

**C3 (Capacidad y Ventanas) — in progress.**
- Done: `lib/logic/capacity/buffer_calculator.dart` (`calculateBuffer`, D1 tiered buffer) and `task_weight_calculator.dart` (`calculateTaskWeight`), both tested against CP-04 and TB-01 (see `test/logic/capacity/`).
- Skipped on purpose: a dedicated "C3 input" wrapper class — the functions ended up taking `Duration` params directly, so a wrapper would have been speculative. Revisit only if a real need shows up.
- Next: `TimeWindow` (start/end `DateTime`, `lib/logic/capacity/time_window.dart`) — proposed but not yet approved: whether the `end.isAfter(start)` invariant should be a debug-only `assert` or a real runtime check, and whether to include a `duration` getter now or wait until piece 5 (fit check) needs it.
- Not started: fit-check (peso vs. ventana dada la ancla), and the "no hay ventana disponible" case (CP-07).

## Decisions made that aren't fully spelled out in the docs

- **Duration type:** durations are `Duration`, never raw `int` minutes — avoids unit ambiguity, matches Dart/Flutter convention.
- **Buffer rounding:** fractional buffer minutes (media/larga tramos, e.g. 31 min × 5%) round **up** (`.ceil()`), following D1's asymmetric-cost reasoning. Note: this makes the 2h1min case compute to 134 min total, not the "133 min" the CP-04 table shows by hand — that's expected, not a bug (see conversation history / commit context if this needs re-justifying).
- **`prepTime`/`travelTime`:** `Task` (§106) has no such fields. `calculateTaskWeight` takes them as its own named parameters (`Duration prepTime = Duration.zero`, `travelTime` same), always zero in Phase 1. Not a promise that `Task` will ever gain these fields.
- **`User.default_buffer_minutes` (§104):** unused in Phase 1. C3 only implements the D1 tiered table. That field belongs to the §9 adaptive-buffer-learning feature (later phase).
- **Capacity config (§19 segmentation):** the PRD defines no separate entity for it. CP-11 protects sleep/personal time using `User` fields directly (`sleep_target`, `wake_target`, `protected_personal_minutes`), suggesting Phase 1 "capacity config" is just `User` — not yet confirmed with her; confirm when building that piece.
