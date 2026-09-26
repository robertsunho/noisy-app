# SESSION HANDOFF

The living "where we left off" note between design conversations. **Not canon** — the canonical docs are the source of truth; this points into them. Rewritten (not appended) at the end of each design conversation. A new conversation reads DOCMAP, then this file.

**Last updated:** 2026-09-25
**Closes:** pre-V2 hardening conversation · **Opens:** V2 design (Phase 3)

---

## Start-of-conversation routine (for Claude in chat)

1. Robert presses **Sync** on the Project's GitHub source once, before the conversation starts, so the Project copy is current.
2. Claude clones the public repo into its session (read-only) and pulls before every review (D-020):
   `GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://github.com/robertsunho/noisy-app`
   This replaces re-syncing the Project after every commit.
3. Read, in order: `DOCMAP.md` → this file → `PRODUCT_DESIGN.md` §1–3 → `ROADMAP.md` Phase 3.

## Working model

- **Claude in chat** is architect and design lead: it reasons, drafts thinking-heavy docs, and writes prompts. **Claude Code** implements, commits and pushes (D-005). Robert pastes the terminal output back for review.
- Robert is a non-technical founder. Make executive calls on technical questions and explain them plainly; bring genuine product, taste and brand decisions to him.
- Drift protocol: rule it, record it, then fix. Prefer changes that add optionality without changing behavior.

## State at handoff

- 166 tests pass; `flutter analyze` clean.
- Phases 1 and 2 are complete (29/29 discrepancies ruled).
- Pre-V2 hardening is complete:
  - HarmonicMatcher test suite (C-014) and input guard (D-016)
  - background-audio scoping (D-014)
  - API-key deferral (D-015)
  - analytics privacy and theme tags (D-017)
  - faithful saved mixes (D-018)
- The engine is preserved. The product layer is unchanged since July, so V2 starts from the shipped UX in `PRODUCT_DESIGN.md` §5.

## What the V2 conversation is for

Phase 3 is **design, not build**. The open questions, in a suggested order (a suggestion, not a prescription):

1. **Commit to the LP / Radio axis or not** (`PRODUCT_DESIGN.md` §3.7). Most downstream questions hang on it:
   - the category taxonomy (§3.8, D-010)
   - the fate of the curated journeys (R-29)
   - the sleep timer
   - whether a saved mix is a snapshot or a recipe (D-018)
   - where the clock-based timeline work lives (D-014 Track B)
   - what shape of LLM input the server-side contract serves (D-015)
2. **The input moment** (§3.1) and **the output moment** (§3.2).
3. **Navigation / IA** (§3.4). The Mixer unification (R-17) follows from it.
4. **Ephemerality**: a weighted top-k draw instead of argmax (§3.3). This interacts with saved mixes: once generation stops being deterministic, a recipe no longer reproduces what the user heard.
5. **Sonic glue** (§3.5) and the **MotifEngine density redesign**. Both are engine-capability candidates and are listening work.

## Decisions V2 inherits (don't relitigate without new cause)

- **D-001:** preserve the engine; reimagine the product layer.
- **D-010:** the outcome-named categories are replaced, not retuned.
- **D-014:** Radio-style background playback is platform config alone (Track A). An LP timeline must be built against a clock reference from the start (Track B).
- **D-015:** the Anthropic call moves server-side before *any* distribution. This is a hard launch blocker.
- **D-016:** V2 makes `SoundscapeSource.rootFrequency` nullable.
- **D-017:** no user-written text in analytics. The theme vocabulary can seed Radio station naming.
- **D-018:** saved mixes are snapshots for now. The `version` field lets V2 migrate them either way.

## Known gaps carried into V2

- Motifs are not saved; a reloaded mood mix has no motifs.
- Tone and binaural layers record their starting frequency, not later live changes.
- The pinned model `claude-sonnet-4-20250514` may be retired. The text feature would then fail silently, falling back to the sliders.
- The curated journeys bypass the harmonic system, which is the first-impression problem (§3.6).
- Audio lives in git. Consider LFS before the library scales.

## Deferred: hardware validation (D-019)

This is a pre-beta gate waiting on devices; it does not block design. It is split by where each check can run (see `ROADMAP.md`):
- **Android emulator:** now, on Robert's PC.
- **Pixel:** expected from the week of 2026-09-28.
- **iOS:** needs a Mac, or a cloud build (e.g. Codemagic + TestFlight), before the iPhone can be used.
