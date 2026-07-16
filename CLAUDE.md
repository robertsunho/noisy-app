# CLAUDE.md — Standing Orders for Noisy

This file is always in context. It orients you and encodes the non-negotiables. It does **not** duplicate the documentation — it points to it. The canonical docs in `/docs` are the library; this file is the standing orders.

---

## What Noisy is

A mobile ambient-sound app (Flutter/Dart) that externalizes a person's internal state, synchronously, as sound — the anti-streaming inverse of fixed tracks. Its differentiator is a real, implemented **harmonic system**: every pitched layer (soundscape, solfeggio tone, binaural carrier, generative motifs) tuned to one key. See `docs/PRODUCT_DESIGN.md` for the thesis, `docs/TECHNICAL_ARCHITECTURE.md` for how it works.

## Prime directive

**Preserve the engine; reimagine the product layer.** (Decision D-001.)
- **Engine** (`audio_engine`, `tone_service`, `journey_engine`, `motif_engine`, `mood_engine`, `harmonic_matcher`, `llm_service`): the asset. Default to caution. Small, surgical, reviewable diffs.
- **Product/UX layer** (`screens/`, navigation, interaction model): under active reinvention. Bolder change is expected here.

## The documentation set

All canonical docs live in `/docs` (root = canonical only; `docs/audits/` = investigation artifacts; `docs/archive/` = superseded). **Consult `docs/DOCMAP.md` first** — it has a routing table telling you which doc governs which task. In brief:
- Engine work → `docs/TECHNICAL_ARCHITECTURE.md` (+ Engineering Principles first)
- Product/UX work → `docs/PRODUCT_DESIGN.md`
- Any code change → `docs/ENGINEERING_PRINCIPLES.md` **first**
- Content/assets → `docs/CONTENT_PRODUCTION.md`
- Priorities/sequencing → `docs/ROADMAP.md`
- Recording anything → `docs/DECISIONS_AND_CHANGELOG.md`

## Non-negotiables (active every session)

1. **Read `docs/ENGINEERING_PRINCIPLES.md` before any code change.** It contains the hard guardrails; don't rely on memory of them.
2. **Do not modify empirically-tuned audio behavior** (crossfade curves/timing, binaural carrier ranges, consonance scores, `_maxDist`, prime-cycle set, mastering targets — `TECHNICAL_ARCHITECTURE.md` §6) without a recorded decision first.
3. **`harmonic_matcher.dart` stays pure** (no Flutter imports, no side effects) and **gets tests** when changed. It's the crown jewel.
4. **Engine services never import from `screens/`.** One-way dependency: screens → services, never the reverse.
5. **Drift-resolution protocol:** when a canonical doc and the code disagree, do not silently fix either side. Rule it (doc wrong / code wrong / latent design question), record the ruling in `docs/DECISIONS_AND_CHANGELOG.md`, then fix.
6. **Test audio on Android, never Chrome.** Chrome's `setSpeed` warble is a known browser artifact, not a bug — never "fix" phantom issues based on it.
7. **Record what you do.** Substantive change → `C-###` Changelog entry. Decision → `D-###`. Discrepancy ruling → `R-##`.

## Working defaults

- **Commit discipline:** stage only what the task asks for. Leave unrelated working-tree churn (`pubspec.lock`, `gradle.properties`, generated plugin files) untouched unless told otherwise.
- **Git identity** is set repo-locally and globally as Robert Sunho <robertsunho@gmail.com>. If a commit fails on missing identity, that's the thing to check.
- **Commit + push** after completing a discrete task, with a clear message. Reference doc IDs (D-/C-/R-) where relevant.
- **When in doubt near the engine, stop and ask** rather than proceeding. A recorded five-minute discussion beats silently re-breaking hard-won audio behavior.

## Current phase

Phase 2 — reconciliation. The immediate work is ruling on the 29 catalogued discrepancies in `docs/audits/AUDIT_REPORT.md`, triaged into buckets in `docs/ROADMAP.md`. See the roadmap for what's next.
