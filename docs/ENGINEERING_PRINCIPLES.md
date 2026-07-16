# ENGINEERING PRINCIPLES

Noisy-specific invariants and guardrails. **Not** a general style guide — this document exists only to protect the things that are specifically easy to break in *this* project. Consult before every code change (per `DOCMAP.md`).

**Last updated:** July 16, 2026

---

## The prime directive

**Preserve the engine; reimagine the product layer.** (Decision D-001.) The engine — `audio_engine`, `tone_service`, `journey_engine`, `motif_engine`, `mood_engine`, `harmonic_matcher`, `llm_service` — is the asset. The product/UX layer is where change is expected. When a task touches the engine, default to caution; when it touches the product layer, default to boldness.

---

## Guardrails (hard rules)

### 1. Do not modify empirically-tuned audio behavior without a ruling.
The behavior in `TECHNICAL_ARCHITECTURE.md` §6 (crossfade curves and timing, binaural carrier placement, pitch-shift approach, mastering targets) was arrived at through real listening tests, not derivation. Numbers that look arbitrary often are not. Changing any of it requires an explicit decision recorded in `DECISIONS_AND_CHANGELOG.md` first. This includes: crossfade window/curves, the 80–300 / 200–400 Hz carrier ranges, the consonance scores, the `_maxDist = 1.2` threshold, and the prime-cycle set.

### 2. `harmonic_matcher.dart` stays pure.
No Flutter imports, no side effects, no I/O. It is pure math and must remain unit-testable in isolation. It is the crown jewel and the one place a regression is an *inaudible-to-code-review wrong note*. Changes here should come with tests (see rule 8).

### 3. Engine services must not import from `screens/`.
Dependency direction is one-way: screens depend on services, never the reverse. Services receive what they need via constructor injection in `MainShell`. Preserving this boundary is what makes the product-layer reinvention safe — you can rebuild the screens without touching the engine.

### 4. Layer volumes and motif densities route through Remote Config.
The five layer volumes (`soundscape_volume`, `nature_volume`, `noise_volume`, `binaural_volume`, `frequency_volume`) and four motif densities (`motif_density_*`) are Remote Config values with in-code `setDefaults`. Do not reintroduce hardcoded values for these. Exception currently in the code: the Sleep waypoint-2 density of 0.1 is hardcoded (audit #8) — that's a flagged inconsistency, not a pattern to copy.

### 5. Do not change `applicationId` / bundle IDs casually.
The Firebase apps in `firebase_options.dart` are registered against the current IDs. Changing `com.example.noisy_app` (Android) / `com.example.noisyApp` (iOS) means re-registering with Firebase. When these are fixed for release (they must be, before store submission), it is a deliberate, recorded change — not an incidental edit.

### 6. The API key must never reach the shipped binary in plaintext.
Currently `.env` is bundled as an asset — a known pre-launch blocker tracked in the roadmap. Until it's moved server-side: do not add further secrets to bundled assets, and treat the existing arrangement as debt, not precedent.

### 7. Respect the drift-resolution protocol.
When you find a mismatch between a canonical doc and the code, do **not** silently "fix" either side. Rule it (doc wrong / code wrong / latent design question), record the ruling in `DECISIONS_AND_CHANGELOG.md`, then apply the fix. This is the whole mechanism that keeps docs and code from re-diverging.

### 8. The crown jewel gets tests.
`HarmonicMatcher` (and, where practical, `MoodEngine` category inference and selection) should have unit tests. A table of `root × solfeggio → (shift, interval, carrier Hz, degree)` protects against silent regressions. Current coverage is a single smoke test; this is a known gap (external eval §2 #5). New harmonic-matcher work should not land without corresponding tests.

---

## Working conventions (softer guidance)

- **Read before writing.** For any repo task, consult the governing doc(s) per the `DOCMAP.md` routing table. For engine work, read `TECHNICAL_ARCHITECTURE.md`; for product work, `PRODUCT_DESIGN.md`.
- **Record what you change.** Every substantive change gets a `C-###` Changelog entry. Every decision gets a `D-###` entry.
- **Prefer surgical diffs.** Especially in the engine — small, reviewable changes over sweeping refactors. The product layer tolerates bigger moves.
- **Match existing patterns.** Constructor injection over service locators; `ChangeNotifier` + debounced `addPostFrameCallback` for UI updates; semantic ID conventions (`tone:528`, `binaural:10`) applied consistently.
- **Test on Android, not Chrome, for audio.** Chrome's `setSpeed` artifacts are not real bugs; never judge audio quality or "fix" phantom issues based on Chrome behavior.
- **Guard async lifecycles.** This codebase is timer-driven; the existing `_ticking` re-entrancy guard, `if (mounted)` checks, and index re-lookup after fades exist for real reasons. Preserve that discipline in new async code.

---

## When in doubt

If a change would touch anything in §6 of `TECHNICAL_ARCHITECTURE.md`, or blur the services↔screens boundary, or alter a Remote Config-driven value — stop and raise it for a decision rather than proceeding. The cost of a recorded five-minute discussion is far below the cost of silently re-breaking hard-won audio behavior.
