# ROADMAP

Forward-looking plan for Noisy. Claude Code marks items complete (`[x]`) as work lands, with a Changelog entry for each. Ordered by phase; phases are sequenced but not time-boxed.

**Last updated:** July 24, 2026
**Current phase:** Phase 3 — Product Reimagining (Phase 2 complete)
**Open validation debt:** see [Needs hardware validation](#needs-hardware-validation) — R-28 carrier change and the D-014 background-audio predictions both await one device pass.

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

## Phase 2 — Codebase / Design-Doc Reconciliation (the 29 discrepancies) *(complete)*

Each discrepancy from `AUDIT_REPORT.md` is triaged into one of three buckets (per Decision D-003). Rule each, record the ruling in `DECISIONS_AND_CHANGELOG.md`, then apply the fix.

> **Phase 2 complete — 2026-07-24.** All **29 discrepancies are resolved**: Bucket A 15/15, Bucket B 3/3, Bucket C 11/11. Every item carries a recorded ruling (`R-01`–`R-29`) in `DECISIONS_AND_CHANGELOG.md`, and the design-flavored ones a decision (`D-007`–`D-013`). Outcome split: the majority reconciled **documentation to code** with no behavior change; **five code changes** landed (R-04 `addLayer` volume target, R-10 sleep-timer motif fade + pitch preservation, R-15 restored motif tags, R-18 soundscapes in Browse All, R-28 beta/gamma carrier range); **two items were promoted to V2** (R-17 Mixer catalog, R-29 curated journeys — see Phase 3 and Phase 4 below). Two threads carry forward into the V2 work rather than closing here: R-28 is **unvalidated on hardware** and needs an A/B in the V2 audio pass, and the category taxonomy (R-05/R-06) is documented as-is pending replacement. The correctness pass is concluded; strategic/V2 work now begins (D-002).

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
- [x] #6 — §4.4 "density scales with energy" describes interpolation the code doesn't do (values match RC defaults). *Bucket A half closed in R-06; the deferred Meditate/Relax density thread ruled with #5 — R-06 (D-010): Meditate's fallthrough to `motif_density_relax` documented in `TECHNICAL_ARCHITECTURE.md` §3.4; no `motif_density_meditate` key added.*

### Bucket B — Code-comment / intra-code fixes (code's own comments contradict code)
Fast. Update stale comments/docstrings in the code.

- [x] #24 — `sound_meta.dart` header comment says "33 sounds"; there are 43 (doc is right here)
- [x] #25 — `generateMix` docstring lists hardcoded volumes now read from Remote Config
- [x] #26 — (intra-code, per audit) — confirm and fix

### Bucket C — Design-flavored rulings (behavioral/product consequences; needs Robert)
Slow. These are latent bugs or design decisions. Some may be *promoted* into the Phase 4 V2 plan rather than ruled on in isolation.

- [x] #4 — `addLayer` fades to hardcoded 0.7, not "to target" as doc claims. *Ruled R-04 (D-007): 0.7 retained as default; `addLayer` gained an optional `volume:` target so it can honor a target like tones do. Behavior unchanged — journey-engine passing real targets deferred to V2.*
- [x] #27 — `_loadWaypoint` comment asserts layers preload at volume 0; sample/soundscape layers actually fade to 0.7 via `addLayer`. *Ruled R-27: comment corrected to describe the real preload/interpolation sequence; paired with #4.*
- [x] #5 — mood→category thresholds in doc match nothing in code; doc's Meditate rule is code's Relax rule. *Ruled R-05 (D-010): doc reconciled to code — the code's thresholds are the behavior of record, documented in evaluation order in `TECHNICAL_ARCHITECTURE.md` §3.4. No threshold changed: the outcome-named taxonomy is expected to be replaced, not retuned, in V2 (`PRODUCT_DESIGN.md` §3.8), so tuning now is work the overhaul subsumes.*
- [x] #8 — undocumented behaviors: ±0.05 waypoint perturbation; hardcoded Sleep density 0.1 (not RC-driven). *Ruled R-08 (D-010): both documented as intended current behavior in §3.4. The hardcoded 0.1 is flagged there as a documented exception to `ENGINEERING_PRINCIPLES.md` rule 4 — not a pattern to copy. No code change.*
- [x] #10 — `Journey.sleepTimer` motif support never wired at its only call site; motifs keep firing after sleep-timer fade. Also: `toSource()` drops pitch-shift on snapshot. *Ruled R-10 (D-008): both are bugs, both fixed — call site now passes the live MotifEngine (motifs fade with the mix); `toSource()` reconstructs soundscape layers as `SoundscapeSource`, preserving pitch shift.*
- [x] #15 — `piano_note_f` and `gourd_percussion` lost tags in code; `piano_note_f` can never be selected for Sleep/Meditate despite doc. *Ruled R-15 (D-009): restored the missing tags — piano_note_f regains `meditate`/`sleep`, gourd_percussion regains `meditate`. Provisional stopgap; tag taxonomy expected to be reworked in V2.*
- [x] #14 — seven motifs carry more tags in code than doc (code is superset). *Ruled R-14 (D-009): code's broader tagging accepted as intended; `CONTENT_PRODUCTION.md` §3 updated to match.*
- [x] #17 — Mixer has its own separate 25-entry catalog: no soundscape is reachable from the Mixer, binaural/frequency are served as MP3 samples (not synthesis), and it is a second hand-maintained catalog. *Ruled R-17 (D-013): architectural smell, **→ promoted to V2 (see roadmap Phase 3)** — not fixed now because the Mixer surface is within the scope of the V2 navigation/IA reorganization, and the fix is a rebuild rather than a correction. The MP3-vs-synthesis half is separable and could be pulled forward if audio quality warrants.*
- [x] #18 — Library "Browse All" advertises 43 sounds but renders 33 (`'soundscape'` missing from `_kCategoryOrder`; no label/icon keys either). Code bug. *Ruled R-18 (D-011): Option A — added `'soundscape'` to all three category maps, leading the browse order. All 43 entries now render across five categories; the advertised count is unchanged and correct.*
- [x] #28 — beta/gamma carrier range: `beatFrequencyHz` param built but not passed from `mood_engine.dart` call site. *Ruled R-28 (D-012): wired — the call site now passes `beatFrequencyHz: p.$2`, activating the 200–400 Hz range for beta/gamma. Deliberate audible change to Focus/Energize mixes; **unvalidated on hardware** — A/B it during the V2 audio pass alongside mix-glue and MotifEngine density.*
- [x] #29 — curated journeys still use legacy `SampleSource` MP3s, bypassing the harmonic system. *Ruled R-29 (D-013): legacy surface, **→ promoted to V2 (see roadmap Phase 4)** — not fixed now because curated journeys are expected to be replaced by the LP/Radio restructure (`PRODUCT_DESIGN.md` §3.7), so re-authoring them against the current engine is work the restructure subsumes. Accepted cost: the first-impression problem (§3.6) persists through the V2 design period.*

> **Note:** All 29 discrepancies are now bucketed — A = 15, B = 3, C = 11 — and all 29 are now **ruled and closed**. Triage corrected per Decision **D-006** (see Changelog **C-003**); bucket completion recorded in **C-012**.

---

## Needs hardware validation

Claims accepted into the canonical docs that have **not** been checked on a real device. Emulators and Chrome are not adequate for any of these (`ENGINEERING_PRINCIPLES.md` — audio is judged on Android, never Chrome). These share **one device pass**; do it before the V2 audio work depends on them.

- [ ] **Beta/gamma binaural carrier range** (R-28 / D-012) — the 200–400 Hz carrier is now active for beta/gamma beats, a deliberate audible change to Focus/Energize mixes (e.g. C4 root + 528 Hz: 98 Hz → 392 Hz). **A/B by ear**, alongside the mix-glue and MotifEngine-density work. If wrong, reverting is a one-argument change.
- [ ] **Background-audio behavior** (D-014) — the Track A / Track B decomposition is reasoned from code, plugin manifests, and platform contracts, **not measured**. Specifically unverified: how fast Android freezes or kills the process without a foreground service (and how much worse aggressive OEM power management is); **whether SoLoud `SoundHandle`s survive an iOS audio interruption** — `ToneService` stores handles with no revalidation path, so if they don't, every tone and binaural layer becomes a silent no-op the app still reports as playing; whether a stall partway through `AudioEngine`'s crossfade is reachable in practice (listen for phasey doubling at loop boundaries); and whether `Stopwatch`'s monotonic clock stalls under deep device sleep, which would make a 30-minute sleep timer run long.
- [ ] **iOS generally** — `TECHNICAL_ARCHITECTURE.md` §1 records iOS as unvalidated. Expect background audio to fail there immediately and reproducibly until Track A lands.

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

- [ ] **LP timeline on a clock-based reference** — design the shaped/timed experience so its timeline is driven by **wall-clock / audio-position elapsed time, reconciled on resume**, rather than by accumulated Dart `Timer` ticks (which the OS throttles in background). Per **D-014** this belongs *inside* the LP design rather than as a retrofit — a shaped experience should be authored against a clock reference from the start. Scope is narrower than it sounds: `JourneyEngine` already samples a `Stopwatch`, so position cannot drift; what needs solving is resume behavior (glide rather than snap), layer add/remove events skipped inside a stall, and `AudioEngine`'s tick-accumulated crossfade blend. *(Touches empirically-tuned crossfade timing → needs a recorded decision before the code changes; see `TECHNICAL_ARCHITECTURE.md` §6.)*

Promoted from Phase 2 Bucket C (see D-013):
- [ ] **Unify the Mixer onto `sound_meta.dart`** (retire the separate ~25-entry Mixer catalog); **make soundscapes reachable in the Mixer**; **serve binaural/frequency via real-time synthesis, not MP3** *(ref R-17 / #17)*. Sits in Phase 3 because the Mixer's shape is decided by the navigation/IA reorganization above — design that first, then build the unified surface against it. **Separable sub-issue:** the MP3→synthesis half needs neither the catalog merge nor the Mixer rebuild and can be pulled forward on its own if manual testing shows the sampled binaural/frequency layers are audibly worse (they cannot be pitched to the mix's key).

---

## Phase 4 — V2 Build

Concrete implementation of the reimagined product on the preserved engine. Populated after Phase 3 design work. Will incorporate the external evaluation's prioritized launch blockers where they belong.

Promoted from Phase 2 Bucket C (see D-013):
- [ ] **Rebuild curated journeys on the current engine** — as **LP presets and/or Radio stations per `PRODUCT_DESIGN.md` §3.7** — so they no longer bypass the harmonic system *(ref R-29 / #29)*. Today all five use `SampleSource` MP3s across all 20 waypoints: no `SoundscapeSource`/`ToneSource`/`BinauralSource`/`MotifSource`, nothing pitched into key. **Blocks: first-impression integrity, `PRODUCT_DESIGN.md` §3.6** — until this lands, a first-time user sampling "Journey" hears the old, undifferentiated product. Implementation note: `_JourneyCard._layerNames` filters `.whereType<SampleSource>()`, so the card UI shows no layer chips for any migrated journey and must be updated alongside. Depends on the Phase 3 LP/Radio ruling — build only after it is settled whether these become presets, stations, or are dropped.

Launch-blocker candidates from external evaluation (to be scheduled here or earlier as ruled):
- [ ] **Background/lock-screen audio — platform configuration for continuous playback** *(additive; no engine-logic changes)*. Android foreground service (`FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `mediaPlayback` service, notification); iOS `UIBackgroundModes: audio` + activated `AVAudioSession` playback category; wire `audio_session` (**already in the dependency tree** transitively via `just_audio` — present but never imported or configured) or adopt `audio_service`. Per **D-014** this is sufficient for continuous/Radio-style playback on its own: the native audio layer sustains sound without Dart timers. Also add a lifecycle observer — the app currently has none. *(external eval §2 #1; D-004 scoped by D-014.)*
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
