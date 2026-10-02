# SESSION HANDOFF

The living "where we left off" note between design conversations. **Not canon** — the canonical docs are the source of truth; this points into them. Rewritten (not appended) at the end of each design conversation. A new conversation reads DOCMAP, then this file.

**Last updated:** 2026-10-02
**Closes:** V2 direction conversation (D-021) · **Opens:** V2 design threads (Phase 3) — see the thread board

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

## Thread board

| # | Thread | Status | Current question | Next action | Blocked by |
|---|---|---|---|---|---|
| 1 | Experience & rooms | Open | One listener's path from first launch to first pressing | Robert reacts to the draft listener story | — |
| 2 | Sound & form | Open | What a side of an LP and an hour of a station sound like; test the Score model | Written sketch, then a hidden Listening Lab screen | Loosely on 1 |
| 3 | Visual identity | Not started | What visual tradition Noisy belongs to | Robert assembles a reference board | — |
| 4 | Content production | Normalization can start | Role taxonomy and launch counts | Measure current loudness of the 29 files; locate masters | 2 (taxonomy, counts) |
| 5 | Architecture & engineering | Investigations only | Can a score be rendered to audio offline on-device? SoLoud pitch-shift quality? | Scope the render investigation | 1–2 for design |
| 6 | Business & launch | Direction set (Foundation §5) | Entitlement model | Sketch after thread 1's story | 1 |

Every design conversation starts by reading this board and ends by updating it. Cross-thread decisions happen in the hub conversation; deep dives may be separate chats that end with a board update.

## Decisions V2 inherits (don't relitigate without new cause)

- **D-001:** preserve the engine; reimagine the product layer.
- **D-010:** the outcome-named categories are replaced, not retuned.
- **D-014:** Radio-style background playback is platform config alone (Track A). An LP timeline must be built against a clock reference from the start (Track B).
- **D-015:** the Anthropic call moves server-side before *any* distribution. This is a hard launch blocker.
- **D-016:** V2 makes `SoundscapeSource.rootFrequency` nullable.
- **D-017:** no user-written text in analytics. The theme vocabulary can seed Radio station naming.
- **D-018:** saved mixes are snapshots for now. The `version` field lets V2 migrate them either way.
- **D-021:** V2 direction adopted from `design-inputs/noisy_v2_foundation.md` — music-first; three rooms (Radio, LP, Collection), LP and Radio both at launch; Studio hidden; subscription for the service, purchases for owned pressings. The Score model is a working hypothesis, not yet a decision.

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
