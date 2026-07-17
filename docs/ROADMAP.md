# ROADMAP

Forward-looking plan for Noisy. Claude Code marks items complete (`[x]`) as work lands, with a Changelog entry for each. Ordered by phase; phases are sequenced but not time-boxed.

**Last updated:** July 17, 2026
**Current phase:** Phase 2 — Infrastructure & Reconciliation

---

## Phase 1 — Documentation Infrastructure *(complete)*

- [x] `DOCMAP.md` — doc set orientation
- [x] `DECISIONS_AND_CHANGELOG.md` — append-only record, seeded with prior decisions
- [x] `ROADMAP.md` — this file
- [x] `TECHNICAL_ARCHITECTURE.md` — split from design doc v2.4, corrected, engine layer
- [x] `PRODUCT_DESIGN.md` — split from design doc v2.4, vision-first, product layer
- [x] `ENGINEERING_PRINCIPLES.md` — Noisy-specific invariants/guardrails
- [x] `CONTENT_PRODUCTION.md` — production spec + asset registry (from existing checklist)

---

## Phase 2 — Codebase / Design-Doc Reconciliation (the 29 discrepancies)

Each discrepancy from `AUDIT_REPORT.md` is triaged into one of three buckets (per Decision D-003). Rule each, record the ruling in `DECISIONS_AND_CHANGELOG.md`, then apply the fix.

### Bucket A — Trivial doc fixes (doc wrong, code right; no judgment needed)
Fast. Correct the design doc / new canonical docs to match the code.

- [x] #1 — Flutter version (doc says 3.41.1; actual 3.44.6)
- [x] #2 — §3 file structure omits `analytics_service.dart`, `firebase_options.dart`
- [x] #3 — §3 noise list says "yellow"; the 5th available noise is "red"
- [x] #9 — §4.5 `findBinauralCarrier` stale signature/range (doc contradicts itself; §4.5 is stale half)
- [x] #11 — `bowl_high_g` documented an octave off (G4 vs actual G5) — doc-only, no behavioral impact
- [x] #12 — `low_bell_eb` documented an octave off (Eb4 vs actual Eb3) — doc-only
- [x] #13 — three motif root freqs rounded differently (inaudible; doc for completeness)
- [x] #16 — "43 available sounds" → 43 total, 35 available
- [x] #19 — §13.2 lists a "gong C3" that doesn't exist (real 6th tonal motif is `triangle_e`)
- [x] #20 — §13.2 says no motifs in E; `triangle_e` is in E
- [x] #21 — §13.2 says 8 unique soundscape roots; there are 9 (doc's own arithmetic confirms 9)
- [x] #22 — §13.3 says 9 solfeggio frequencies; catalog has 10 (432 Hz omitted)
- [x] #23 — §13.9 names `mood_profiles.dart`; actual file is `mood_profile.dart` (singular)
- [x] #7 — §4.4 presents 5 layer volumes as constants; they are Remote Config reads (numbers match defaults)
- [x] #6 — §4.4 "density scales with energy" describes interpolation the code doesn't do (values match RC defaults). *Rule after #5 — same Meditate/Relax density thread.*

### Bucket B — Code-comment / intra-code fixes (code's own comments contradict code)
Fast. Update stale comments/docstrings in the code.

- [x] #24 — `sound_meta.dart` header comment says "33 sounds"; there are 43 (doc is right here)
- [x] #25 — `generateMix` docstring lists hardcoded volumes now read from Remote Config
- [x] #26 — (intra-code, per audit) — confirm and fix

### Bucket C — Design-flavored rulings (behavioral/product consequences; needs Robert)
Slow. These are latent bugs or design decisions. Some may be *promoted* into the Phase 4 V2 plan rather than ruled on in isolation.

- [ ] #4 — `addLayer` fades to hardcoded 0.7, not "to target" as doc claims. *Ruling needed: is 0.7 intended, or should sample layers honor a target like tones do?*
- [ ] #27 — `_loadWaypoint` comment asserts layers preload at volume 0; sample/soundscape layers actually fade to 0.7 via `addLayer`. *Paired with #4 — fix is comment-or-code depending on #4's ruling.*
- [ ] #5 — mood→category thresholds in doc match nothing in code; doc's Meditate rule is code's Relax rule. *Ruling needed: are the code's current thresholds the intended design, or did they drift? Affects which journey whole slider regions produce.*
- [ ] #8 — undocumented behaviors: ±0.05 waypoint perturbation; hardcoded Sleep density 0.1 (not RC-driven). *Ruling: document as intended, or reconsider?*
- [ ] #10 — `Journey.sleepTimer` motif support never wired at its only call site; motifs keep firing after sleep-timer fade. Also: `toSource()` drops pitch-shift on snapshot. *Likely a bug to fix; confirm intent.*
- [ ] #15 — `piano_note_f` and `gourd_percussion` lost tags in code; `piano_note_f` can never be selected for Sleep/Meditate despite doc. *Ruling: restore tags, or is the code's tagging intended?*
- [ ] #14 — seven motifs carry more tags in code than doc (code is superset). *Ruling: is the code's broader tagging intended? Update doc if so.*
- [ ] #17 — Mixer has its own separate 25-entry catalog: no soundscape is reachable from the Mixer, binaural/frequency are served as MP3 samples (not synthesis), and it is a second hand-maintained catalog. *Ruling: is the soundscape-less, samples-not-synthesis Mixer intended, or a gap to close?*
- [ ] #18 — Library "Browse All" advertises 43 sounds but renders 33 (`'soundscape'` missing from `_kCategoryOrder`; no label/icon keys either). Code bug. *Ruling: add soundscapes to Browse All, or correct the advertised count to 33?*
- [ ] #28 — beta/gamma carrier range: `beatFrequencyHz` param built but not passed from `mood_engine.dart` call site. *Known issue; wire it, or defer with intent recorded.*
- [ ] #29 — curated journeys still use legacy `SampleSource` MP3s, bypassing the harmonic system. *First-impression issue: "curated" showcase hears the old product. Promote to V2?*

> **Note:** All 29 discrepancies are now bucketed — A = 15, B = 3, C = 11. Triage corrected per Decision **D-006** (see Changelog **C-003**).

---

## Phase 3 — Product Reimagining (design, not yet build)

Vision-first redesign of the product layer, driven by `PRODUCT_DESIGN.md`. Synthesizes: Robert's re-engagement observations, the external evaluation, and promoted Bucket-C rulings.

Known raw material to work into this phase:
- [ ] Landing screen: static/cluttered → reimagine around synchronous externalization
- [ ] Mood input model: sliders feel "technical middle-ground" → rethink the input moment
- [ ] Navigation: 3–4 modes is right; reorganize/re-present
- [ ] Determinism → ephemerality: mood engine is pure argmax; same sliders = identical mix. Weighted top-k draw (temperature via Remote Config) to deliver "never the same twice" (external eval §2 #3). *Directly serves the ephemerality thesis.*
- [ ] Positioning: de-emphasize solfeggio/binaural mysticism; lead with "musical, not medical" / "humanly crafted, harmonically coherent" (external eval §3, §4)
- [ ] "Glue" for the mix: candidate new engine capability (shared reverb / bus processing / master limiting) to make layers cohere (Robert's re-engagement note)
- [ ] MotifEngine density redesign: prime-number system yields clumpy/sparse distribution, not steady organic density with a frequency hierarchy (Robert's re-engagement note)

---

## Phase 4 — V2 Build

Concrete implementation of the reimagined product on the preserved engine. Populated after Phase 3 design work. Will incorporate the external evaluation's prioritized launch blockers where they belong.

Launch-blocker candidates from external evaluation (to be scheduled here or earlier as ruled):
- [ ] **Background/lock-screen audio** + validate journey/motif timing under background execution (external eval §2 #1). *May need to move earlier — see D-004. Structural, affects preserved engine.*
- [ ] SoLoud migration for true pitch-shift-without-tempo-change; may shrink the 144-soundscape target (external eval §2 #2)
- [ ] Move Anthropic API call server-side (Cloud Function); stop bundling `.env` in the app (external eval §3)
- [ ] Stop sending raw user mood-text to Firebase Analytics (external eval §3)
- [ ] Replace `com.example.*` placeholder app IDs; real release signing (external eval §3)
- [ ] Saved mixes are lossy (don't round-trip pitch/tone/binaural params) (external eval §2 #4)
- [ ] Unit tests for `HarmonicMatcher` (the crown jewel, currently one smoke test) (external eval §2 #5)

---

## Phase 5+ — Content, Beta, Launch

- [ ] Content production pass (see `CONTENT_PRODUCTION.md`) — re-derive scope after SoLoud migration
- [ ] Beta testing (real Android + iOS hardware)
- [ ] Monetization + store prep
- [ ] Marketing + launch

---

## Deferred / Tier 2 (post-launch)
- [ ] Plant Radio (live stream layer, `StreamSource`)
