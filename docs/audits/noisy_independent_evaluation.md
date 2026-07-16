# Noisy — Independent Evaluation

**Scope:** `docs/noisy_design_document.md` (v2.4, March 2026) and the full Flutter codebase (`lib/`, platform folders, `pubspec.yaml`, `test/`).
**Method:** Fresh read with no prior context. Every claim below cites what I observed; where I'm inferring, I say so explicitly.

---

## 1. What's Working Well

### The harmonic system is a real, implemented differentiator — not a slogan

The strongest thing in this project is that the "key-aware" pitch architecture actually exists in code and is musically sound. `harmonic_matcher.dart` is a clean, pure-Dart module with zero Flutter dependencies: correct Hz↔MIDI conversion (`69 + 12·log₂(hz/440)`), octave folding to ±6 semitones so pitch shifts always take the shortest path, and a `findBestMatch` that evaluates seven consonant intervals and picks the one requiring the least shift. The triad-aware refinements are the kind of decisions a musician makes, not a checkbox feature: the binaural carrier is restricted to the root or perfect 5th of the soundscape key, octave-transposed into an 80–300 Hz "felt bass" range, and among valid octaves the code deliberately picks the one *furthest* in real semitones from the solfeggio tone to avoid frequency crowding. The consonance scoring (unison 1.0, P5 0.9, M3 0.8, m3 0.7, everything else 0.3) feeding 40% of soundscape selection in `mood_engine.dart` closes the loop: content selection, tone placement, and carrier placement all reason about the same key. Most competitor apps layer sounds with no tonal relationship at all. This is the thing that merits continued investment, and it's also the part that's hardest for a competitor to copy without genuine music expertise.

### The engine decomposition is appropriate and disciplined

`AudioEngine` (layer lifecycle), `ToneService` (SoLoud synthesis), `JourneyEngine` (timeline interpolation), `MotifEngine` (generative one-shots), `MoodEngine` (selection logic), `HarmonicMatcher` (pure math) — each service has one job, and the boundaries hold up in the code, not just the doc. The `SoundSource` hierarchy in `journey.dart` (Sample / Soundscape / Tone / Binaural / Motif) gives the journey engine a uniform way to interpolate heterogeneous layer types, and the semantic ID conventions (`tone:528`, `binaural:10`) are consistently applied across engine and journey code. Dependencies are wired by plain constructor injection in `MainShell` — no service-locator magic, which is the right call at this scale.

### Audio craft shows up in the details

The equal-power crossfade in `_applyLayerVolumes` is implemented correctly (cos/sin curves with a comment explaining the ~3 dB midpoint dip of linear fades), every layer add/remove is faded (1.5 s in, 1 s out), journeys get a 2 s startup ramp, and the two-player crossfade loop starts 3.5 s before the loop point. The design doc's "Smooth Transitions" principle and the code match each other exactly — the doc isn't aspirational documentation drifting from reality.

### Concurrency handling is unusually careful for a project of this profile

Several places show real defensive thinking about async races: `removeLayer` re-looks-up the layer index after the fade completes with a comment noting parallel removals may have shifted positions; `JourneyEngine` has a `_ticking` re-entrancy guard; UI listeners debounce engine notifications via `addPostFrameCallback` (in both `main.dart` and `mixer_screen.dart`) to avoid mid-frame `setState`; and the `abandon()`/`MotifEngine.start()` race is not only fixed but *documented* — `abandon()` deliberately doesn't stop the motif engine, and the next `start()` awaits `stop()` internally. These are the bugs that usually plague timer-driven audio apps, and they've been found and handled.

### The MotifEngine is elegant

Prime-number cycle lengths (13–43 s), per-cycle probability gating against a density parameter, ±20% random volume variation, random initial offsets to prevent simultaneous first-fire, and harmonic pitch-shifting of tonal motifs toward the active solfeggio tone. It's an Eno-style generative system in ~150 lines, with graceful degradation (atonal motifs simply play unshifted). Good idea, small implementation, correctly kept outside the 5-layer cap.

### The LLM integration is proportionate

`llm_service.dart` is a small stateless service: strict JSON-only system prompt, 100-token cap, 10 s timeout, markdown-fence stripping, and null-on-any-failure with a slider fallback in the UI. The LLM is used as an input parser, not a gimmick, and the app degrades cleanly without it. This is the right shape for the feature.

### The design document itself is an asset

Version 2.4 functions as genuine working memory: inventory tables with root frequencies, a solfeggio-to-key compatibility matrix, concrete mastering specs (−14 LUFS, −1.0 dBTP, ±5 cents tuning tolerance, A=440), naming conventions, an integration checklist, and — notably — an honest "Known Issues (Deferred)" section. The content production plan is derived from the harmonic system's actual needs (prioritizing Bb/Eb/Db to fill solfeggio compatibility gaps) rather than arbitrary volume targets. Also good: Remote Config is used with in-code `setDefaults` in `main.dart`, so a failed fetch can't silently zero out all mix volumes.

---

## 2. Greatest Room for Improvement

### #1: Background and lock-screen playback — this is the gap that matters most

Nothing in the project currently addresses audio surviving the screen turning off. There is no `audio_session` or `audio_service` dependency in `pubspec.yaml`, no `UIBackgroundModes`/`audio` key in `ios/Runner/Info.plist`, and `AndroidManifest.xml` declares only `INTERNET` — no foreground service, no wake lock. For an app whose core use cases are *sleep* (45-minute journeys) and *focus* (90-minute journeys), this is existential: on iOS, playback will stop when the app backgrounds; on Android, the process will be killed or throttled soon after. Related and equally unaddressed: audio interruption handling (phone calls, other apps taking the audio session) and lock-screen/notification media controls, which users of this category expect.

This deserves to jump the queue ahead of the content production pass (currently phase 8) for a structural reason, not just priority: the journey and motif engines are driven by Dart `Timer`s, which are suspended or throttled in background execution. The whole timeline/motif timing model needs to be validated (and possibly reworked around a position-or-clock-based approach) under real background conditions. Discovering that after producing 144 soundscapes would be painful. I'd treat "a 45-minute sleep journey completes with the phone locked, on a real Android device and a real iPhone" as the next milestone, full stop.

### #2: Promote the SoLoud migration — it interacts with the content plan

The doc already knows `setSpeed()` pitch-shifting is an approximation (it alters tempo and duration along with pitch) and schedules SoLoud migration as phase 12, *after* content production. I'd argue the ordering is backwards. True pitch-shift-without-tempo-change directly determines how much pitch shifting is tolerable, which determines how dense key coverage needs to be — which is the entire premise of the 144-soundscape target. If post-migration quality is good within, say, ±2–3 semitones, the required catalog may be substantially smaller (or the same catalog buys far more variety). Migrating first could save the two of you months of production work, and it also eliminates the per-loop cost of the current crossfade design, where `_startCrossfade` allocates and decodes a fresh `AudioPlayer` every loop cycle of every sample layer.

### #3: The mood engine is fully deterministic — variety will feel thin fast

`generateMix` is pure argmax: the same slider position always yields the identical mix, so "Generate New Soundscape" with unchanged sliders regenerates the exact same thing (only motif randomness differs). With a 10-soundscape catalog, users will hit perceived repetition almost immediately. A weighted-random draw among the top-k candidates per category (temperature tunable via Remote Config, which is already wired in) is a small change with outsized effect on perceived freshness — and it's cheaper than new content.

### #4: Saved mixes are lossy

`MixLayer` persists only `assetPath`/`name`/`volume` (`mixer_screen.dart` save dialog, confirmed against the SavedMix description in the doc). Pitch-shift ratios, tone/binaural frequency parameters, and motif state are not saved. Saving a mood-generated mix therefore cannot faithfully round-trip: the harmonic tuning is lost, and tone layers whose "asset path" is a semantic ID like `tone:528` will presumably fail if replayed through the sample-based `addLayer` path (`player.setAsset('tone:528')`). *Inference flag:* I did not see the full body of the library's `_playSavedMix`, so it may special-case tone IDs — but the persisted model plainly lacks the fields needed to reconstruct them either way. Given that "save what the engine made for me" is a natural core loop, this is worth fixing before beta.

### #5: Test coverage is one smoke test

`test/widget_test.dart` pumps the app and checks the title renders. Meanwhile `HarmonicMatcher` is a pure-math, dependency-free class — the single most unit-testable thing in the codebase, and the one where a regression is a *wrong note* that no code review will catch. A table of expected outputs (root × solfeggio → shift, interval, carrier Hz, degree) would take an afternoon and protect the crown jewel. The mood engine's category inference and selection are similarly testable with a faked Remote Config.

---

## 3. Risks and Concerns

**The Anthropic API key ships inside the app binary.** `pubspec.yaml` lists `.env` under `assets:`, which is how `flutter_dotenv` works — the file is bundled into every APK/IPA and is trivially extractable by anyone who unzips the package. The design doc's reassurance ("key is NEVER hardcoded, `.env` is gitignored") protects the *repository*, not the *shipped product*. Before any public distribution, the LLM call needs to move behind a server you control (a Cloud Function is the natural fit given Firebase is already integrated), with the key server-side. Otherwise you're exposed to unbounded API-cost abuse. This is the single most important pre-launch fix outside of background audio.

**Raw user text is sent to analytics.** `AnalyticsService.logLlmGenerate` forwards the user's free-text mood description (`user_text`) to Firebase Analytics. People will type emotionally sensitive things into a "tell us how you want to feel" box ("can't sleep, anxious about…"). That's personal data flowing into an analytics warehouse — a privacy-policy and app-store-disclosure issue, and arguably a trust issue for a wellness-adjacent brand. Log the derived slider values and perhaps text length; drop the text itself (Firebase also truncates param values, so its analytical value is limited anyway).

**Placeholder identifiers and debug signing.** `applicationId = "com.example.noisy_app"` (Android) and `com.example.noisyApp` (iOS), with the Android release build signed with debug keys per the TODO in `build.gradle.kts`. Stores will reject `com.example.*`, and — the sneaky part — the Firebase apps in `firebase_options.dart` are registered against these IDs, so changing them later means re-registering with Firebase. Cheap to fix now, annoying to fix later.

**Blocking startup chain.** `main()` awaits `Firebase.initializeApp` → `fetchAndActivate()` (fetch timeout configured at a full minute) → `dotenv.load()` → `SoLoud.init()` before `runApp`. On a flaky connection, first paint could stall badly, and `dotenv.load()` throws if the asset is missing — an all-or-nothing boot. Kick the Remote Config fetch off without awaiting it (defaults are already set, so this is safe) and tolerate a missing `.env`.

**The solfeggio/binaural framing carries claims risk.** Solfeggio frequencies have no scientific basis, and evidence for binaural-beat entrainment is weak. This isn't a code problem — the *musical* use of these tones (as consonant scale degrees in a voiced drone) is legitimate and, frankly, more honest than the mysticism. But marketing copy that implies therapeutic effects invites app-store review friction and erodes the credibility of the genuinely defensible claim ("humanly crafted, harmonically coherent"). Recommend positioning these as sonic/aesthetic choices, with any wellness language kept carefully non-medical.

**The 144-soundscape commitment is a treadmill risk.** It's a very large production load for two people, and (per §2 above) its size is a function of a technical constraint that phase 12 may relax. Sequence the SoLoud migration first and re-derive the number.

**Smaller items.** (a) `maxLayers = 5` counts tones, and generated mixes typically fill all five slots — in the Mixer, `_onSoundTapped` silently returns when full, so users tapping the catalog get no feedback about *why* nothing happened. (b) The five curated journeys still reference legacy MP3 `SampleSource`s (including the retired binaural/frequency MP3s), so the app's "curated" showcase content currently bypasses the entire harmonic system — the doc knows this (phase 11), but it means first-time users sampling Journeys hear the *old* product. (c) iOS remains entirely unvalidated ("future" per the doc); the dual-engine just_audio + SoLoud combination deserves early device testing there rather than at phase-14 beta.

---

## 4. Honest Assessment of the Concept

**The landscape.** Ambient-sound is a crowded, largely commoditized category: giant incumbents (Calm, BetterSleep), beloved craft products (myNoise), simple mixers by the dozen, and — most relevantly — **Endel**, which owns the "AI-generated adaptive soundscape" positioning with real funding and scientific-advisory marketing. A generic slider-mixer with nature sounds and noise colors has no path to standing out; that part of Noisy is table stakes.

**Where Noisy is genuinely distinctive.** Two things, and they reinforce each other. First, the *harmonic coherence* thesis: every pitched element — soundscape bed, solfeggio tone, binaural carrier, generative motifs — tuned to one key and voiced like a musician would voice a drone stack. No mainstream competitor does this; layered mixers routinely produce tonal mud. It's implemented, not promised. Second, the *provenance* story: "algorithmically arranged, humanly crafted," backed by an actual record label identity, analog sound design, and eventually things like Plant Radio as brand theater. Endel's positioning is technological; Noisy's natural positioning is *musical* — closer to "a generative Brian Eno record that responds to you" than to a wellness utility. That's a real, ownable lane, and the Eno-adjacent/ambient-music audience is underserved by apps that sound like laboratories.

**The honest concerns.** The differentiator is subtle: users won't consciously perceive "triad-aware carrier placement" — they'll perceive "this sounds nicer than the others," which is real but hard to communicate in an App Store screenshot. The marketing challenge is translating inaudible craft into perceivable claims (A/B demo clips of coherent-vs-incoherent layering could do this well). Second, the moat is content + taste, not code — the selection algorithms are replicable in a week by anyone; what isn't replicable is a growing catalog of well-produced, precisely tuned soundscapes and the judgment behind the voicing rules. That means the content pipeline *is* the business, which makes the two-person production capacity the binding constraint. Third, the least distinctive elements (solfeggio numerology, brainwave-band binaural presets) are the most prominent in the current sound catalog UI — they make the product look *more* generic, not less, and I'd de-emphasize them in favor of the musical framing.

**Verdict.** The core idea is compelling — not as a mass-market Calm competitor, but as a craft-led, musically literate niche product with a defensible identity. The concept's biggest risk is distribution, not validity. The implementation's biggest risks are the four launch blockers (background audio, shipped API key, analytics privacy, placeholder IDs), all of which are fixable and none of which undermine the architecture.

---

## What I Could Not Judge

I can't hear the audio assets, so the most important quality dimension — whether the ten soundscapes and nine motifs are actually beautiful — is outside my reach; the whole thesis rests on that. There's no usage or retention data (pre-beta), so the deterministic-variety concern in §2 is a prediction, not an observation. Monetization exists only as a phase-15 line item ("RevenueCat freemium"), so I can't evaluate pricing or paywall design. And as flagged, I did not see the full `_playSavedMix` implementation or `storage_service.dart` internals, so the saved-mix round-trip issue is a strong inference from the persisted data model rather than a traced bug.

## If I Had to Pick Five Actions

1. Background/lock-screen audio (audio_session/audio_service, `UIBackgroundModes`, Android foreground service) and validate journey timing under it — before the content pass.
2. Move the Anthropic call behind a Cloud Function; remove `.env` from bundled assets.
3. Do the SoLoud migration next, then re-derive the soundscape count from measured pitch-shift quality.
4. Stop logging raw mood text; fix `com.example.*` IDs and release signing now, while Firebase re-registration is cheap.
5. Unit-test `HarmonicMatcher` and add top-k randomized selection to `MoodEngine` — small efforts, protecting and amplifying the differentiator respectively.
