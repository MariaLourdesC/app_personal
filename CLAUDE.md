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

**C4 (Motor de prioridad) — done, closed at 6 pieces.**

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

**C2 (Inbox) — done.**

Built, all tested:
- `lib/models/` — `Task` (§106, excludes `actual_duration`/`alternative_responsible` per Fase 1 scope) and `Pillar` (§105) as plain data classes, no persistence knowledge. Supporting enums: `ConsequenceLevel` (moved here from C4's `lib/logic/priority/`, since both C2 and C4 need it — models is the shared layer, logic shouldn't own something repositories also depend on), `StrategicValue` (alta/media/baja — the user's own call, not PRD-defined: the PRD's only two examples use "alto"/"bajo", but she confirmed a real "media" case exists for her), `TaskStatus` (porIniciar/enProgreso/terminada), `TaskSource` (capturaNl/cajaRapida), and `EnergyRequired` — a composite of `EnergyIntensity` (alta/media/baja) × `EnergyType` (fisica/administrativa), because §22 conflates two independent dimensions in one field and the user confirmed with a concrete example (gym vs. a complex ticket, same intensity, different tiredness). `EnergyType` is deliberately extensible — she plans to add `social` later; no need to ask again when that happens, just add the enum case.
- `lib/repositories/task_repository.dart` — `TaskRepository` abstract interface (`save`/`getAll`/`getById`/`getPillars`), one method (`save`) doing upsert for both create and update, matching the "minúscula interfaz" style the Arquitectura doc already used for `CompletionRepository`.
- `lib/repositories/task_mapper.dart` + `database_schema.dart` + `sqlite_task_repository.dart` — SQLite implementation. Enums stored as `TEXT` (`.name`/`.byName`), `DateTime` as epoch millis, `Duration` as minutes, `bool` as 0/1. Tested against a real `sqflite_common_ffi` in-memory database (not mocked) — same engine as production `sqflite`, different binding for platforms/tests without native plugin channels.
- `lib/screens/inbox_screen.dart` (list, `StatefulWidget` so it can refresh after returning from edit) and `edit_task_screen.dart` (form: consequence/energy-intensity/energy-type segmented pickers, duration text field, deadline via `showDatePicker`). Styled to match the approved design mockup (playful pink/purple palette, Baloo 2 via `google_fonts` — see below). Manually verified end-to-end in Chrome with a throwaway fake repository (not committed).
- Design mockup published as a Claude Artifact (4 screens: Inbox list, edit task, AHORA, "¿por qué ahora?" sheet) — **not yet updated** to reflect the edit form's second energy selector (tipo física/administrativa) added after the mockup was approved; sync if it matters before C5 needs its own mockup review.

**Windows-specific dev notes, not project decisions:** Windows desktop builds need Visual Studio C++ tools (not installed, not pursued — Chrome is the visual-testing target on this machine). `google_fonts`/`path_provider`'s native plugin setup needed Windows Developer Mode enabled (`ms-settings:developers`) — a one-time system setting, now on. Real iOS builds need a Mac + Xcode (available to her) — no paid Apple Developer account needed for her own use: free personal-team signing to a physical device (re-sign every 7 days) or the iOS Simulator, both free; paid account only needed for TestFlight/App Store distribution.

**C5 + C6 (AHORA + Cierre) — done, and the three follow-up gaps are closed too (see below). Next component is C1, the last one.**

Built, all tested:
- `lib/models/task_completion.dart` + `lib/repositories/completion_repository.dart` (interface, `save` only — write-only per Arquitectura doc) + `completion_mapper.dart`/`sqlite_completion_repository.dart`. `interruptions`/`distractions` default to `0` (not nullable) — a real fact ("none happened yet, nothing detects them"), not a D2-style unknown.
- **Filled the CP-06/CP-07 data gap** (flagged above) enough to unblock C5, with the user's explicit sign-off since it's a new entity not in the PRD: `lib/models/fixed_event.dart` (id, title, start, end — deliberately minimal, not the deferred Planificador diario) + `FixedEventRepository`. Justification: CP-03/04/06/07's own fixtures already assume fixed-event data exists, and "eventos fijos" is not on the Fase 1 "diferido" list (only the full day-planner is).
- `lib/models/user.dart` (§104) + `ConfigRepository` — resolves C3's old open question: capacity config is just `User`. Time-of-day fields (`sleepTarget`, `wakeTarget`, etc.) are `Duration` since midnight, not `DateTime` — deliberate reuse to avoid depending on Flutter's `TimeOfDay` from a pure model.
- `lib/logic/capacity/current_window.dart` — `currentWindow()`: now → next fixed event today, or → `User.sleepTarget` if none left. Does not resolve CP-06/07's *real* mechanism (still needs multi-window lookahead), just answers "how big is the gap right now."
- `lib/logic/priority/task_adapter.dart` — `tasksReadyForPriority` (filters out no-duration tasks — e.g. caja-rápida captures — and `terminada` ones) + `priorityCandidateFromTask`. Kept `PriorityCandidate` as C4's own minimal type rather than refactoring C4 to take `Task` directly — C4 already had 30 passing tests and doesn't need most of `Task`'s fields.
- `lib/screens/reason_text.dart` — `reasonText(reason, assumed)`: the actual Spanish phrasing for CP-08, deliberately living in the screen layer (this is the "C5's job" callback from `Reason`'s original design). Marks assumed fields explicitly per CP-09 ("Consecuencia asumida como X (no declarada)") rather than sounding as confident as a real value.
- `lib/screens/now_screen.dart` — `NowScreen`: loads tasks/events/user, calls `decide()`, shows the winner with a live timer (`Timer.periodic`, distinct from `Future` — ticks repeatedly, must be cancelled in `dispose()`/before replacing). "Terminar" writes the `TaskCompletion` and marks the `Task` `terminada`. "¿Por qué ahora?" opens `reasonText` in a bottom sheet. Caja rápida saves a bare `Task` (`source: cajaRapida`) without calling `_load()` — CP-12 requires the current timer to keep running undisturbed. Wraps the `decide()` call in a broad `catch` as a crash-safety net for CP-07 (no candidates fit) and near-CP-11 (already past bedtime) — shows "no hay tarea disponible" instead of throwing, but does **not** implement either case's full UX (motivo + siguiente ventana for CP-07). Manually verified end-to-end in Chrome with throwaway fakes (not committed); one round of real bugs found and fixed this way (caja rápida had no visible send button, "Terminar" had no visible confirmation — it was actually working, just silent).

**The three gaps that were open after C5 — all closed, at the user's request, before starting C1:**

1. **`User` seeding → `lib/screens/config_screen.dart`.** A minimal settings form (sleep/wake time via `showTimePicker`, focus-block/break/personal minutes as number fields) that writes the single `User` record. She chose a real screen over seeding fake values. Pre-filled with the defaults the PRD itself documents (§20: 30 min focus + 5 min break; §34: 45 min personal) — not invented. Sleep/wake are hers to enter; no doc defines them.
2. **Personal time enforced (CP-11).** `currentWindow()` now returns a `CurrentWindowResult`: either a window, or a `CurrentBlock` saying why not (`tiempoPersonal`, `sueno`, `eventoFijo`). `NowScreen` shows the motivo instead of a blank screen, which is what CP-11 actually asks for ("se aplica el comportamiento de CP-07"). **Placement rule is the user's own product decision, not in any doc:** the personal block is the last `protectedPersonalMinutes` before `sleepTarget`. Her words: "la mayoría de los días es al final, no todos". Dynamic placement (weekends, or only after priorities are met) is explicitly hers-for-later and belongs to the deferred Planificador diario (§16-19) — she stated that intent, so don't re-ask, just build it when that phase comes.
3. **CP-06/CP-07's real mechanism.** `remainingWindows()` enumerates every free gap left in the day (now → next event, between events, last event → personal block). `nextWindowWithSpace()` answers CP-07's "se muestra la siguiente ventana en la que sí habrá espacio". `candidateLosingItsLastWindow()` implements §23: `decide()` gained an optional `laterWindows` param (default empty, so C4's existing tests were untouched) and cedes the current window to a lower-ranked candidate when taking it would destroy that candidate's last chance. **Scope chosen by the user:** protection only applies if the displaced candidate is due **today or tomorrow** — a deadline two weeks out doesn't get protected. Also only applies when both tasks can't fit in the window together.

Two real bugs were caught by tests while building gap 3, both worth remembering as the kind of thing to check: filtering fixed events by `start.isAfter(now)` silently ignored an **in-progress** event (you'd get a window overlapping a commitment you're already in), and `remainingWindows` initially bailed out entirely whenever `currentWindow` had no window — which meant "you're in a meeting right now" wrongly became "there are no windows left today", breaking the exact CP-07 answer it exists to give.

## Decisions made that aren't fully spelled out in the docs

- **Duration type:** durations are `Duration`, never raw `int` minutes — avoids unit ambiguity, matches Dart/Flutter convention.
- **Buffer rounding:** fractional buffer minutes (media/larga tramos, e.g. 31 min × 5%) round **up** (`.ceil()`), following D1's asymmetric-cost reasoning. Note: this makes the 2h1min case compute to 134 min total, not the "133 min" the CP-04 table shows by hand — that's expected, not a bug (see conversation history / commit context if this needs re-justifying).
- **`prepTime`/`travelTime`:** `Task` (§106) has no such fields. `calculateTaskWeight` takes them as its own named parameters (`Duration prepTime = Duration.zero`, `travelTime` same), always zero in Phase 1. Not a promise that `Task` will ever gain these fields.
- **`User.default_buffer_minutes` (§104):** unused in Phase 1. C3 only implements the D1 tiered table. That field belongs to the §9 adaptive-buffer-learning feature (later phase).
- **Capacity config (§19 segmentation):** the PRD defines no separate entity for it. CP-11 protects sleep/personal time using `User` fields directly (`sleep_target`, `wake_target`, `protected_personal_minutes`), suggesting Phase 1 "capacity config" is just `User` — not yet confirmed with her; confirm when building that piece.
