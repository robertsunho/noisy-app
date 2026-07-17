# DECISIONS & CHANGELOG

Append-only record of decisions (*why*, including roads not taken) and changes (*what*, to code and docs). Newest entries at the top of each section. Never rewrite history; a decision that reverses an earlier one references it by ID.

**Format:**
- Decisions are prefixed `D-###`
- Changelog entries are prefixed `C-###`
- Discrepancy rulings (from `AUDIT_REPORT.md`) are prefixed `R-##` (matching the audit's discrepancy ID)

---

## DECISIONS

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
