# DECISIONS & CHANGELOG

Append-only record of decisions (*why*, including roads not taken) and changes (*what*, to code and docs). Newest entries at the top of each section. Never rewrite history; a decision that reverses an earlier one references it by ID.

**Format:**
- Decisions are prefixed `D-###`
- Changelog entries are prefixed `C-###`
- Discrepancy rulings (from `AUDIT_REPORT.md`) are prefixed `R-##` (matching the audit's discrepancy ID)

---

## DECISIONS

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

*None recorded yet — pending the correctness pass.*
