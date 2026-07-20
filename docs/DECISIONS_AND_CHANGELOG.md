# DECISIONS & CHANGELOG

Append-only record of decisions (*why*, including roads not taken) and changes (*what*, to code and docs). Newest entries at the top of each section. Never rewrite history; a decision that reverses an earlier one references it by ID.

**Format:**
- Decisions are prefixed `D-###`
- Changelog entries are prefixed `C-###`
- Discrepancy rulings (from `AUDIT_REPORT.md`) are prefixed `R-##` (matching the audit's discrepancy ID)

---

## DECISIONS

### D-009 — Motif tagging (#14/#15) resolved; tag taxonomy is provisional, not a design commitment
**Date:** 2026-07-20
**Decision:** Ruling on the two motif-tagging discrepancies. **#15 (code wrong):** `piano_note_f` and `gourd_percussion` had lost tags the design intended, so `piano_note_f` could **never** be selected for Sleep or Meditate journeys. Restored the missing tags — `meditate` + `sleep` to `piano_note_f`, `meditate` to `gourd_percussion` (additive; the code's other tags were kept). **#14 (doc wrong):** the seven motifs whose code tag sets are strict supersets of the doc are accepted as intended; `CONTENT_PRODUCTION.md` §3 was updated to match the code rather than the code trimmed to the doc.
**Why restore (#15):** With only nine motifs total, an unnecessarily narrow palette meaningfully impoverishes generative variety in the highest-use categories (Sleep, Meditate). The intent — a sleep/meditate-capable piano and gourd — is legible in the doc; the code had drifted from it.
**Provisional, not considered taxonomy:** The current tag vocabulary is a *thin* set over nine motifs. As the library expands toward 20–27 motifs (see `CONTENT_PRODUCTION.md`), the tag vocabulary **and** the way `_selectMotifPalette` queries it are expected to be substantially reworked or replaced in V2. This restoration is therefore a **stopgap that improves the present palette, not a design commitment** — today's tag set should not be read as a settled taxonomy. Restricted to tags only: `MotifMeta` structure and the selection logic in `mood_engine.dart` / `motif_engine.dart` were left untouched.
**References:** Audit items #14, #15; rulings R-14, R-15; `CONTENT_PRODUCTION.md` §3.

### D-008 — Sleep-timer defects (#10) ruled bugs, not design — both fixed
**Date:** 2026-07-20
**Decision:** Ruling on audit #10, both halves. (A) `Journey.sleepTimer` accepts a `motifEngine` and builds a `MotifSource` fading density to 0, but its only call site (`journey_screen.dart` `_startSleepTimer`) never passed one — so motifs kept firing at full density after the mix faded to silence. (B) `toSource()` reconstructed soundscape layers as plain `SampleSource`, dropping `pitchShiftRatio` so the layer reverted to unshifted playback for the timer's duration. **Both are ruled genuine bugs — the feature does not work as designed — and both are fixed now**, not deferred.
**Why bugs-not-design:** The intent is unambiguous in each case. The `motifEngine` parameter exists *precisely* to fade motifs; leaving it unpassed is an unwired call site, not a design choice. `SoundscapeSource` exists *precisely* because pitch matters; reconstructing it as `SampleSource` silently discards the harmonic tuning the whole engine is built to produce. Neither reading survives contact with the code's own structure.
**Reinforced by product direction:** The ruling was strengthened by an emerging product axis (`PRODUCT_DESIGN.md` §3.7, LP / Radio): bounded, *ending* experiences are becoming **more** central to the product, not less. A sleep-timer-like ending is subsumed by the "LP" form (an ending built into the object). Fixing the ending's mechanics now — motifs actually resolve, pitch actually survives — invests in a direction the product is moving toward, which tips a close "fix now vs. defer" call toward fix now.
**Scope discipline:** Surgical fixes only. No fade durations, curves, or timing changed; `harmonic_matcher.dart` untouched. `rootFrequency` on the reconstructed `SoundscapeSource` is defaulted (the engine layer does not track per-layer root, and it is inert on the sleep-timer reload path, which applies only `pitchShiftRatio`).
**References:** Audit item #10; ruling R-10; `PRODUCT_DESIGN.md` §3.7.

### D-007 — `addLayer` gains an optional volume target; journey-engine passing real targets deferred to V2
**Date:** 2026-07-20
**Decision:** Ruling on audit #4 (paired with #27). The hardcoded 0.7 in `AudioEngine.addLayer` is **retained as the default**, but `addLayer` gains an optional `volume:` named parameter (clamped [0.0, 1.0]) so it can express "add this layer at this volume" — matching how `addToneLayer` / `addBinauralLayer` already honor a `volume:` target. This is a capability-adding, behavior-preserving change: with the default in place, every existing call site (journey engine, mixer screen, library screen) behaves identically to today. #27's comment is corrected in the same change to describe the real preload/interpolation sequence.
**Road not taken (deferred to V2):** Having the journey engine pass correct per-layer targets on layer-add — which would eliminate the ~200ms 0.7 transient before `_applyInterpolation`'s first tick, and the tone/sample asymmetry at the `_loadWaypoint` call sites — was considered and **consciously deferred**. It tunes behavior inside the mood/journey generation path that the V2 overhaul will likely rework, so tuning it now risks re-doing (or re-breaking) work the overhaul subsumes. The optional-parameter change, by contrast, adds capability without behavioral risk.
**Guiding principle:** When facing an overhaul, prefer changes that add optionality without changing behavior; defer behavior tuning that lives in a code path the overhaul will rework.
**References:** Audit items #4, #27; rulings R-04, R-27; D-006 (which paired #27 with #4 and moved it to Bucket C).

### D-006 — Discrepancy triage corrected: #17/#18 slotted to C, #27 moved B→C
**Date:** 2026-07-17
**Decision:** After validating the Phase 2 triage line-by-line against `docs/audits/AUDIT_REPORT.md`, three corrections were approved. (1) #17 (the Mixer's separate 25-entry catalog) and #18 (Library "Browse All" advertises 43 sounds but renders 33) are slotted into **Bucket C**, not left in the "to be slotted" note. (2) #27 (`_loadWaypoint`'s "layers preload at volume 0" comment) moves from **Bucket B to Bucket C**, paired with #4. #26 remains in Bucket B. Resulting counts: A = 15, B = 3, C = 11.
**Why:** #17 and #18 are not clerical doc fixes. #17 raises design questions — soundscapes are unreachable from the Mixer, binaural/frequency are served as MP3 samples rather than synthesis, and a second catalog must be hand-synced. #18 is a genuine code bug carrying a product choice (show soundscapes in Browse All vs. correct the count). #27 asserts an *intended invariant* ("volume intentionally left at 0") that the same `addLayer`-fades-to-0.7 behavior #4 is ruling on violates; correcting #27's comment in isolation could enshrine a latent bug as intended behavior — exactly what the drift-resolution protocol (D-003, and `CLAUDE.md`) forbids. #27's fix is therefore comment-or-code depending on #4's ruling.
**References:** D-003 (three-bucket triage); audit items #4, #17, #18, #26, #27.

### D-005 — Documentation is authored in conversation, committed via Claude Code
**Date:** 2026-07-16
**Decision:** Canonical docs are drafted by Claude in conversation, then committed to the repo by Claude Code. Thinking-heavy docs are drafted this way; mechanical updates may be delegated to Claude Code directly.
**Why:** Keeps the design/reasoning layer with the model that has the full conversational context, while keeping the repo as the single source of truth.

### D-004 — Background audio is a known structural risk, flagged during doc-building (not yet actioned)
**Date:** 2026-07-16
**Decision:** The absence of background/lock-screen audio support is recorded as a known structural risk in `TECHNICAL_ARCHITECTURE.md` *now*, before the engine is documented as canonical — even though it will not be actioned until the V2 planning phase.
**Why:** The journey and motif engines are driven by Dart `Timer`s, which are throttled/suspended in background execution. If background support requires reworking the timing model, that affects the very engine we have decided to preserve. The risk must be *visible* while we document the engine so it cannot silently undermine the "preserve the engine" foundation. This is a visibility decision, not a commitment to implement.
**Source:** Raised by the external evaluation (`noisy_independent_evaluation.md`, §2 item #1).

### D-003 — The 29 audit discrepancies will be triaged into three buckets, not treated uniformly
**Date:** 2026-07-16
**Decision:** Before ruling, the 29 catalogued discrepancies are sorted into: (a) trivial doc fixes, (b) code-comment fixes, (c) design-flavored rulings that carry behavioral or product consequences. Bucket (c) items may be *promoted* into the V2 design plan rather than ruled on clerically.
**Why:** Some "discrepancies" are latent bugs or design decisions wearing a documentation costume (e.g. #5 mood→category thresholds, #10 sleep timer not fading motifs, #15 piano_note_f unselectable for Sleep/Meditate). Treating them as uniform clerical fixes would force premature rulings on genuine design questions.

### D-002 — Correctness work (doc/code reconciliation) precedes strategic/V2 work
**Date:** 2026-07-16
**Decision:** Reconcile the codebase and design doc (the 29 discrepancies) before acting on the external evaluation's strategic conclusions or the broader V2 redesign.
**Why:** The source-of-truth document must be *true* before strategic decisions are built on top of it. Exception: background audio is made *visible* early (D-004), though not actioned.

### D-001 — Preserve the engine, reimagine the product/UX layer (rebuild rejected)
**Date:** 2026-07-16
**Decision:** Do not rebuild the app from scratch. Preserve the engine layer (audio engine, tone service, journey engine, motif engine, mood engine, harmonic matcher, LLM service) and reimagine the product/UX layer.
**Why:** Three independent assessments converged: (1) Claude's read of the codebase, (2) the internal audit confirming the engine is clean and accurate to its documentation, (3) the cold external evaluation independently identifying the harmonic system as "a real, implemented differentiator" that "merits continued investment." The engine encodes hard-won empirical audio behavior (Chrome-vs-Android artifacts, equal-power crossfades, binaural carrier placement) that a rebuild would risk re-breaking. All stated dissatisfaction (static/cluttered landing screen, technical-feeling sliders, navigation) lives in the product layer, not the engine.
**Road not taken:** Full from-scratch rebuild using the same concepts. Rejected because it would pay the full cost of re-deriving working audio behavior while the actual desired work (product-layer reinvention) is greenfield either way.

---

## CHANGELOG

### C-008 — Restore missing motif tags; accept code tag superset (Bucket C: R-14, R-15)
**Date:** 2026-07-20
**Change:** Per ruling D-009, edited motif tags in `motif_meta.dart` (tags only — `MotifMeta` structure and `mood_engine.dart` / `motif_engine.dart` selection logic untouched). **R-15:** restored the tags audit #15 flagged as lost — `piano_note_f` `['focus', 'relax', 'energize']` → `['focus', 'relax', 'energize', 'meditate', 'sleep']` (regains Sleep/Meditate selectability); `gourd_percussion` `['energize', 'relax']` → `['energize', 'relax', 'meditate']`. **R-14:** the seven superset motifs from audit #14 are left as-is (broader tagging accepted as intended); `CONTENT_PRODUCTION.md` §3 gained a per-motif tag table matching the code and dropped the "open Bucket-C rulings (audit #14/#15)" annotation. `flutter analyze`: no issues. Checked off #14/#15 in ROADMAP Bucket C.
**Reference:** Decision D-009; rulings R-14, R-15; audit items #14, #15.

### C-007 — Sleep timer fades motifs and preserves pitch (Bucket C: R-10)
**Date:** 2026-07-20
**Change:** Fixed both defects in audit #10 per ruling D-008. **Fix A (motifs):** `JourneyScreen` gained a `motifEngine` field (wired from `main.dart`'s `_motifEngine`), and `_startSleepTimer` now passes it to both `Journey.sleepTimer(...)` (which builds the fading `MotifSource`) and `journeyEngine.start(...)` (which drives the density interpolation). Previously the call site passed neither, so motifs kept firing after the mix faded out. **Fix B (pitch):** `Journey.sleepTimer`'s local `toSource()` now reconstructs soundscape layers (detected by the `soundscapes/` asset path) as `SoundscapeSource`, reading `pitchShiftRatio` from the live `AudioLayer` so the harmonic pitch shift survives the snapshot; previously they became plain `SampleSource` and reverted to unshifted playback. `rootFrequency` is defaulted — the engine layer does not carry it and it is unused on the reload path. No fade durations, curves, or timing changed; `harmonic_matcher.dart` untouched. `flutter analyze`: no issues. Recorded the LP/Radio product axis in `PRODUCT_DESIGN.md` §3.7; checked off #10 in ROADMAP Bucket C.
**Reference:** Decision D-008; ruling R-10; audit item #10.

### C-006 — `addLayer` accepts optional volume target (Bucket C: R-04, R-27)
**Date:** 2026-07-20
**Change:** Per ruling D-007, added an optional `{double volume = 0.7}` parameter to `AudioEngine.addLayer` and routed it (clamped [0.0, 1.0]) through the existing `_startFade(layer, volume, 1500ms)` call in place of the literal 0.7; the 1.5s fade duration is unchanged. Updated the `addLayer` docstring to describe the real behavior. **No behavior change** — the default preserves the prior 0.7, and no existing call site was modified (verified: all `addLayer(` callers in `journey_engine.dart`, `mixer_screen.dart`, `library_screen.dart` still pass `(path, name)`). Corrected the `_loadWaypoint` docstring and inline comment in `journey_engine.dart` (#27) to describe the actual preload/interpolation sequence — tone/binaural layers preload at 0, sample/soundscape layers begin fading toward 0.7 and are pinned by `_applyInterpolation`'s first `setVolume` tick (which cancels the fade). `flutter analyze`: no issues. Updated `TECHNICAL_ARCHITECTURE.md` §3.1 "Smooth transitions"; checked off #4/#27 in ROADMAP Bucket C.
**Reference:** Decision D-007; rulings R-04, R-27; audit items #4, #27.

### C-005 — Bucket B code comments corrected (R-24..R-26)
**Date:** 2026-07-17
**Change:** Corrected three stale code comments/docstrings to match current behavior — comments only, no logic change (`flutter analyze`: no issues). `sound_meta.dart` catalog header (33 → 43 entries, 35 available); `mood_engine.dart` `generateMix` docstring (hardcoded volumes → Remote-Config-driven); `harmonic_matcher.dart` `findBinauralCarrier` docstring (added the `beatFrequencyHz` parameter and the 80–300 / 200–400 Hz range logic). Rulings R-24–R-26 recorded; ROADMAP Bucket B checked off.
**Reference:** Rulings R-24–R-26; audit items #24, #25, #26.

### C-004 — Bucket A discrepancies resolved (R-01..R-23)
**Date:** 2026-07-17
**Change:** Completed the Bucket A correctness pass — 15 trivial doc fixes verified against code. Fourteen were already reflected in the canonical docs from the v2.4 split/reconciliation; one required an edit: `CONTENT_PRODUCTION.md` had `bowl_low_g` mislabeled as G4/392 Hz, corrected to G3/196 Hz to match `motif_meta.dart`. Rulings R-01–R-23 recorded under DISCREPANCY RULINGS; ROADMAP Bucket A items checked off, and the four now-built Tier 2/3 docs checked off in Phase 1.
**Reference:** Rulings R-01–R-23; audit items #1, #2, #3, #6, #7, #9, #11, #12, #13, #16, #19, #20, #21, #22, #23.

### C-003 — Roadmap Phase 2 triage corrected (D-006)
**Date:** 2026-07-17
**Change:** Applied the approved triage correction to `docs/ROADMAP.md` Phase 2: moved #17 and #18 into Bucket C (removed from the "to be slotted" note), moved #27 from Bucket B to Bucket C (annotated as paired with #4), added a "rule after #5" note to #6 in Bucket A, and cleared the stale "to be slotted" note. All 29 discrepancies are now bucketed: A = 15, B = 3, C = 11.
**Reference:** Decision D-006.

### C-002 — Canonical documentation set complete
**Date:** 2026-07-16
**Change:** Added the remaining four canonical documents to `/docs` root: `TECHNICAL_ARCHITECTURE.md` and `PRODUCT_DESIGN.md` (split from the pre-split design doc v2.4, now archived at `docs/archive/noisy_design_document.md`), plus `ENGINEERING_PRINCIPLES.md` and `CONTENT_PRODUCTION.md`. All seven canonical docs are now present in `/docs` root: `DOCMAP.md`, `TECHNICAL_ARCHITECTURE.md`, `PRODUCT_DESIGN.md`, `ENGINEERING_PRINCIPLES.md`, `CONTENT_PRODUCTION.md`, `DECISIONS_AND_CHANGELOG.md`, `ROADMAP.md`. Dropped the "(forthcoming)" markers from the `DOCMAP.md` repository-layout tree now that these docs exist.
**Note:** Completes the incremental documentation build flagged in C-001.

### C-001 — Documentation infrastructure established
**Date:** 2026-07-16
**Change:** Created the canonical documentation set in `/docs`: `DOCMAP.md`, `DECISIONS_AND_CHANGELOG.md`, `TECHNICAL_ARCHITECTURE.md`, `PRODUCT_DESIGN.md`, `ENGINEERING_PRINCIPLES.md`, `CONTENT_PRODUCTION.md`, `ROADMAP.md`. Prior artifacts (`noisy_design_document.md`, `AUDIT_REPORT.md`, `noisy_independent_evaluation.md`) retained as historical inputs.
**Note:** This entry will be updated/split as each doc lands; the set is being built incrementally.

---

## DISCREPANCY RULINGS

Rulings on the 29 items in `AUDIT_REPORT.md`. Each references the audit's discrepancy ID. To be populated during the correctness pass (see `ROADMAP.md`).

### Bucket A — resolved (2026-07-17)

Trivial doc fixes (doc wrong, code right; no judgment needed). Of the 15, fourteen were already corrected in the canonical docs when they were split from v2.4 and reconciled against the audit; one required an edit (R-11, `CONTENT_PRODUCTION.md`). All verified against code.

- **R-01** — doc wrong / code right — `TECHNICAL_ARCHITECTURE.md` §1 already reflects Flutter 3.44.6 / Dart 3.12.2.
- **R-02** — doc wrong / code right — `TECHNICAL_ARCHITECTURE.md` §2 already includes `analytics_service.dart` and `firebase_options.dart`.
- **R-03** — doc wrong / code right — both canonical docs already list `red` (not "yellow") as the 5th available noise.
- **R-06** — doc wrong / code right — `TECHNICAL_ARCHITECTURE.md` §3.4 already states motif density is a flat per-category Remote Config value, not energy-scaled. *(Bucket A corrects only the "scales with energy" inaccuracy; the Meditate → `motif_density_relax` fallthrough is a design thread deferred to #5, Bucket C.)*
- **R-07** — doc wrong / code right — §3.4 already states the five layer volumes are Remote Config reads (defaults match).
- **R-09** — doc wrong / code right — `TECHNICAL_ARCHITECTURE.md` §3.5 already documents the correct `findBinauralCarrier(..., {beatFrequencyHz})` signature and 80–300 / 200–400-when-beat≥15 range; the stale half was only in the archived v2.4.
- **R-11** — doc wrong / code right — both docs already reflect `bowl_high_g` = G5; **corrected** an incidental sibling error in `CONTENT_PRODUCTION.md` (`bowl_low_g` mislabeled G4/392 Hz → G3/196 Hz, per `motif_meta.dart`).
- **R-12** — doc wrong / code right — both docs already reflect `low_bell_eb` = Eb3 (155.6 Hz).
- **R-13** — doc wrong / code right — `CONTENT_PRODUCTION.md` already lists the code's 1-decimal motif roots (493.9 / 349.2 / 329.6 Hz).
- **R-16** — doc wrong / code right — both docs already state 43 total entries, 35 available (verified: 8 `isAvailable: false`).
- **R-19** — doc wrong / code right — both docs already state there is no "gong C3"; the sixth tonal motif is `triangle_e`.
- **R-20** — doc wrong / code right — canonical docs already document `triangle_e` in E; the false "no motifs in E" claim was dropped in the split.
- **R-21** — doc wrong / code right — both docs already state 9 unique soundscape roots (verified: 10 soundscapes → 9 pitch classes).
- **R-22** — doc wrong / code right — both docs already state 10 frequency entries including 432 Hz (verified in code).
- **R-23** — doc wrong / code right — `CONTENT_PRODUCTION.md` §7 already uses the singular `mood_profile.dart`.

### Bucket B — resolved (2026-07-17)

Code-comment / docstring fixes (code's own comments contradicted the code; comments only, no behavior change). Each verified against the code before rewriting; `flutter analyze` clean afterward.

- **R-24** — code comment stale — corrected to match behavior — `sound_meta.dart` catalog header said "(33 sounds)"; updated to "43 entries — 35 available, 8 coming-soon", verified against `kSoundCatalog` (43 entries, 8 `isAvailable: false`).
- **R-25** — code comment stale — corrected to match behavior — `generateMix` docstring cited hardcoded layer volumes (0.55/0.35/0.30/0.35/0.30); reworded to state the five volumes are read from Remote Config (`soundscape_volume`, `nature_volume`, `noise_volume`, `binaural_volume`, `frequency_volume`) with in-code defaults.
- **R-26** — code comment stale — corrected to match behavior — `findBinauralCarrier` docstring omitted the `beatFrequencyHz` parameter and the 200–400 Hz (beta/gamma, ≥15 Hz) branch; documented both plus the 190/300 Hz fallback midpoints. Docstring only — crown-jewel logic untouched.

### Bucket C — in progress (2026-07-20)

Design-flavored rulings that carry behavioral/product consequences. Ruled with a recorded decision where one is needed; see the referenced `D-###` entry.

- **R-04** — code capability gap — `addLayer` gained an optional `volume:` target (default 0.7); behavior unchanged. `AudioEngine.addLayer` now mirrors `addToneLayer`/`addBinauralLayer` by accepting a `volume:` named parameter, clamped [0.0, 1.0] and routed through the existing 1.5s `_startFade`. The 0.7 default preserves every current call site's behavior; having the journey engine pass real targets was considered and deferred to V2. See D-007.
- **R-27** — code comment stale — corrected to match behavior — paired with #4. The `_loadWaypoint` docstring and inline comment asserted layers preload at volume 0, contradicted by the 0.7 `addLayer` fade for sample/soundscape layers. Rewrote both to describe the real sequence: tone/binaural preload at 0; sample/soundscape begin fading toward 0.7 and are pinned by `_applyInterpolation`'s first `setVolume` tick (which cancels the fade). Preload logic unchanged — comment only.
- **R-14** — doc wrong / code right — the code's broader tag sets (seven motifs whose tags are strict supersets of the doc) are accepted as intended; documentation updated to match. `CONTENT_PRODUCTION.md` §3 gained a per-motif tag table mirroring `motif_meta.dart`; no code tags changed for these seven. See D-009 (taxonomy provisional).
- **R-15** — code wrong / doc right — restored the missing tags to `piano_note_f` (added `meditate`, `sleep`) and `gourd_percussion` (added `meditate`); `piano_note_f` is again selectable for Sleep/Meditate journeys. Additive edit only — the code's existing tags were kept, consistent with R-14. Tags only; selection logic untouched. See D-009 (stopgap, not a design commitment).
- **R-10** — code bug — both defects fixed: motif engine now wired at the sleep-timer call site; `toSource()` preserves soundscape pitch shift. (A) `JourneyScreen` now holds a `MotifEngine` (injected from `main.dart`) and `_startSleepTimer` passes it to both `Journey.sleepTimer` and `journeyEngine.start`, so running motifs fade to silence with the mix instead of firing on after the fade. (B) `toSource()` reconstructs soundscape layers as `SoundscapeSource` with `pitchShiftRatio` read from the live layer, preserving harmonic tuning across the snapshot (`rootFrequency` defaulted — not tracked per-layer, inert on the reload path). Surgical: no timing/curve changes, `harmonic_matcher.dart` untouched. Ruled bug-not-design and reinforced by the emerging LP/Radio product axis — see D-008 and `PRODUCT_DESIGN.md` §3.7.
