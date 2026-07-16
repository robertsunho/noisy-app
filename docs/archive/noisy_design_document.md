# NOISY — Design & Development Document

**Version:** 2.4 (March 4, 2026)
**Repository:** github.com/robertsunho/noisy-app
**Developer:** Robert (non-technical founder handling implementation with AI assistance)
**Sound Production:** Robert + partner (analog sound design, ambient compositions)
**AI Development Team:** Claude (architecture & design lead), Claude Code (implementation)

---

## 1. PRODUCT OVERVIEW

Noisy is a mobile ambient sound app built for Noisy Records. It differentiates from competitors through handcrafted analog sound design, evolving soundscapes (not static loops), mood-based AI generation, real-time audio synthesis, generative composition with Eno-style overlapping motifs, and key-aware harmonic matching across all sonic layers.

**Brand positioning:** "Algorithmically arranged, humanly crafted." Every sound in the app is produced by human hands; the technology intelligently selects, layers, tunes, and evolves them over time.

**Core experience:** The user opens the app, adjusts three mood sliders ("How do you want to feel?"), and the engine generates a personalized, evolving soundscape blending an ambient soundscape bed, nature/noise textures, a solfeggio frequency tone, a key-aware binaural beat, and generative motifs (chimes, bowls, bells) drifting in on independent prime-number timer cycles — all harmonically matched to the same key and shifting over time.

---

## 2. TECH STACK

- **Framework:** Flutter 3.41.1, Dart
- **Audio playback (samples):** just_audio (MP3 playback, crossfade looping, volume fading, motif one-shots)
- **Audio synthesis (tones):** flutter_soloud ^3.4.10 (real-time waveform generation, binaural beats via stereo panning)
- **LLM integration:** Anthropic API via http package + flutter_dotenv for key management
- **Persistence:** shared_preferences (local save/load of custom mixes)
- **IDE:** VS Code
- **Version control:** Git/GitHub
- **Testing platform:** Chrome (primary during development — has known audio artifacts with setSpeed/pitch-shifting that don't affect mobile), Android and iOS (future)
- **Implementation workflow:** Design/planning in Claude conversation → implementation prompts to Claude Code in separate PowerShell terminal

**Important technical notes:**
- Chrome web audio: crossfade may not trigger reliably; pitch-shifting via setSpeed() causes audible warbling artifacts; these are Chrome-specific and expected to be absent on mobile
- Slight volume dip at loop points on web; will be seamless on mobile
- Claude Code output token limit: 32000 default; increase via `$env:CLAUDE_CODE_MAX_OUTPUT_TOKENS = "64000"` if needed
- Windows Developer Mode must be enabled for flutter_soloud (symlink requirement)
- flutter_soloud web setup requires two script tags in web/index.html
- Development primarily on Windows; M4 Mac available for iOS builds via Xcode when needed

---

## 3. FILE STRUCTURE

```
lib/
  main.dart                         — App entry, MainShell with all service instances
  models/
    journey.dart                    — Journey, JourneyWaypoint, SoundSource hierarchy
    mood_profile.dart               — MoodProfile class, kMoodProfiles affinity map (43 sounds)
    motif_meta.dart                 — MotifMeta class, kMotifCatalog (9 motifs)
    saved_mix.dart                  — SavedMix class with JSON serialization
    sound_meta.dart                 — SoundMeta class, kSoundCatalog (43 sounds)
  screens/
    home_screen.dart                — "How do you want to feel?" mood generator
    mixer_screen.dart               — Active layers, sound catalog, save dialog
    library_screen.dart             — My Mixes + intention browsing + sound preview
    journey_screen.dart             — Curated journeys + sleep timer
    tone_test_screen.dart           — Developer test screen (long-press app title)
  services/
    audio_engine.dart               — Multi-layer playback + tone layer management
    journey_engine.dart             — Timeline interpolation between waypoints
    mood_engine.dart                — Euclidean distance matching, journey generation
    motif_engine.dart               — Generative motif system with prime-number cycles
    storage_service.dart            — shared_preferences persistence
    tone_service.dart               — flutter_soloud waveform generation wrapper
    harmonic_matcher.dart           — Musical pitch math for soundscape tuning + binaural carrier placement
    llm_service.dart                — Anthropic API integration for natural language mood parsing

assets/audio/
  nature/       — rain, ocean, wind, thunder, crickets (5 MP3s)
  noise/        — white, pink, brown, blue, yellow noise (5 MP3s, 8 more planned)
  binaural/     — delta, theta, alpha, beta, gamma (5 MP3s — replaced by real-time synthesis)
  frequencies/  — 174-963 Hz solfeggio (10 MP3s — replaced by real-time synthesis)
  soundscapes/  — 10 ambient beds in various keys (F, D, G, Ab, A, C, E, F#, A, B)
  motifs/       — 9 short musical fragments (bowls, bells, chimes, percussion, piano)
```

---

## 4. ARCHITECTURE — CORE SYSTEMS

### 4.1 Audio Engine (audio_engine.dart)

Manages all active audio layers — both sample-based (just_audio) and tone-based (flutter_soloud). Extends ChangeNotifier so the UI rebuilds when layers change.

**Key capabilities:**
- Up to 5 simultaneous layers (samples and tones counted together; motifs are separate)
- Independent volume control per layer
- Smooth transitions: addLayer starts at 0, fades to target over 1.5s; removeLayer fades to 0 over 1s before disposal
- Crossfade looping for sample layers: two-player system alternates with 3s crossfade window starting 3.5s before loop point
- Tone layers via ToneService: addToneLayer(), addBinauralLayer(), with real-time frequency and volume control
- setPitchShift(assetPath, ratio) — uses just_audio setSpeed() as approximation (TODO: migrate to SoLoud for true pitch-shift-without-tempo-change)
- notifyUpdate() method for external UI refresh triggers

**AudioLayer fields:** assetPath (or tone ID), name, volume, isTone flag, toneFreq, binCenterFreq, binBeatFreq, pitchShiftRatio

**Layer ID conventions:**
- Sample/soundscape layers: asset path string (e.g., "assets/audio/soundscapes/open_sky_g_maj.mp3")
- Tone layers: "tone:528" (tone: prefix + frequency)
- Binaural layers: "binaural:10" (binaural: prefix + beat frequency)

### 4.2 Tone Service (tone_service.dart)

Wraps flutter_soloud's waveform generation. Manages active tones independently of the audio engine's sample playback.

**Methods:**
- `playTone(frequency, volume)` → returns unique tone ID
- `playBinaural(centerFreq, beatFreq, volume)` → creates two sine waves panned L/R, returns ID
- `setToneFrequency(id, freq)` — real-time frequency change
- `setToneVolume(id, vol)` / `setBinauralVolume(id, vol)`
- `setBinauralFrequencies(id, centerFreq, beatFreq)` — updates both channels
- `stopTone(id)` / `stopAll()`

**Technical detail:** Binaural beats work by playing one sine wave panned fully left at centerFrequency and another panned fully right at (centerFrequency + beatFrequency). The brain perceives the difference as a "beat." Requires headphones.

### 4.3 Journey Engine (journey_engine.dart)

Timeline system that interpolates between mixer states (waypoints) over a duration. States: stopped, playing, frozen.

**Interpolation (every 200ms tick):**
- Calculates current segment from normalized cumulative waypoint weights
- Applies easing curve (linear, easeIn, easeOut, easeInOut)
- Builds target volume/frequency maps for sample, soundscape, tone, binaural, and motif layers
- 2-second startup ramp multiplies all volumes by 0→1 factor
- Layers below volume 0.005 are removed; new layers are added when they appear in waypoints
- Soundscape pitch-shift ratio interpolated and applied each tick
- Motif density and master volume interpolated and applied each tick

**Key methods:**
- `start(journey, audioEngine, duration, {motifEngine})` — clears old, loads waypoint 0, begins tick timer
- `freeze()` / `unfreeze()` — pause/resume timeline without stopping audio
- `abandon()` — releases control without touching audio (used when user manually edits mixer). Does NOT call motifEngine.stop() to avoid race condition; cleanup handled by next start()
- `stop()` — cancels timer, fades out all layers, stops motif engine

**Handles all source types:**
- SampleSource → addLayer/removeLayer/setVolume
- SoundscapeSource → addLayer + setPitchShift, interpolated pitch ratio
- ToneSource → addToneLayer, setToneFrequency, setVolume
- BinauralSource → addBinauralLayer, setBinauralFrequencies, setVolume
- MotifSource → starts/stops MotifEngine, interpolates density and masterVolume

### 4.4 Mood Engine (mood_engine.dart)

Generates soundscape recommendations based on three mood axes (0.0–1.0 each):
- **Energy:** calm/sleepy → alert/energized
- **Focus:** diffuse/dreamy → sharp/concentrated
- **Warmth:** dark/heavy → bright/light

**Algorithm (generateMix) — 5-slot category selection with triad-aware scoring:**

Selection order is critical — the solfeggio frequency is resolved FIRST so it can inform soundscape selection:

1. Best frequency → vol 0.30 (resolved first; skip if distance > 1.2)
2. Best soundscape → vol 0.55 (scored by combined mood fit 60% + harmonic compatibility with solfeggio 40%; falls back to pure mood distance if no solfeggio in mix)
3. Best nature sound → vol 0.35
4. Best noise color → vol 0.30
5. Best binaural → vol 0.35 (skip if distance > 1.2)

**Harmonic compatibility scoring (used in soundscape selection):**
Each candidate soundscape is scored on how consonantly the solfeggio frequency sits relative to its root: unison/octave = 1.0, perfect 5th = 0.9, major 3rd = 0.8, minor 3rd = 0.7, all other intervals (4th, 6th, 7th, etc.) = 0.3. This prevents the system from choosing a soundscape where the solfeggio lands on a dissonant or unstable interval like the 4th or minor 6th.

**Triad-aware binaural carrier placement:**
The binaural carrier is restricted to only two options — the tonic or the perfect 5th of the soundscape root — ensuring it always reinforces the harmonic foundation rather than introducing new tonal color. Selection logic: if solfeggio is near the root (±1 semitone), carrier goes to the 5th; otherwise carrier defaults to the root. The carrier is octave-transposed into an expanded 80-300 Hz range, and among valid octaves, the one furthest in actual (non-folded) semitones from the solfeggio is preferred to avoid frequency crowding. Falls back to fixed carriers (150/200 Hz) when soundscape or solfeggio is absent.

**Design principle:** All three pitched elements (soundscape root, solfeggio frequency, binaural carrier) are treated as a harmonic unit. The soundscape establishes the key, the solfeggio sits on a strong consonant degree within that key, and the binaural reinforces the root or 5th. This produces stable, ambient-appropriate voicings like root + 5th + carrier-on-root rather than stacked chord voicings that introduce tension.

**Motif palette selection:**
Motifs are selected by matching kMotifCatalog tags to the inferred journey category. Up to 5 motifs per journey. Density scales with energy: Sleep 0.20-0.30, Relax/Meditate/Focus 0.30-0.50, Energize 0.60-0.80.

**Journey generation (generateJourney):**
- 3 waypoints with easeInOut curves
- Soundscape sounds → SoundscapeSource (MP3 with pitch-shift ratio from HarmonicMatcher)
- Frequency sounds → ToneSource (real-time synthesis)
- Binaural sounds → BinauralSource (real-time synthesis with key-aware carrier)
- Nature/noise sounds → SampleSource (MP3 playback)
- Motifs → MotifSource (motif IDs, density, master volume)
- Category inferred from input: energy<0.3→Sleep, focus>0.7→Focus, energy<0.5&warmth>0.5→Meditate, energy>0.6→Energize, else→Relax

**Binaural beat frequency mapping (unchanged):**
- delta → beat: 2 Hz
- theta → beat: 6 Hz
- alpha → beat: 10 Hz
- beta → beat: 20 Hz
- gamma → beat: 40 Hz

### 4.5 Harmonic Matcher (harmonic_matcher.dart)

Pure math utility (no Flutter dependencies) for pitch-shifting soundscapes, scoring harmonic compatibility, and placing binaural carriers.

**`findBestMatch(soundscapeRootHz, targetHz)`** — Soundscape pitch-shifting:
- Evaluates 7 consonant intervals: unison, minor 3rd, major 3rd, 4th, 5th, 6th, octave
- For each interval, calculates required soundscape shift
- Uses octave equivalence (folds to ±6 semitones)
- Returns HarmonicMatch with: shiftSemitones, shiftRatio, intervalName, resultingRootHz

**`harmonicCompatibility(soundscapeRootHz, solfeggioHz)`** — Consonance scoring:
- Calculates interval in semitones (octave-folded to 0-11)
- Returns score: unison/octave 1.0, perfect 5th 0.9, major 3rd 0.8, minor 3rd 0.7, all others 0.3
- Used by MoodEngine to weight soundscape selection (40% of combined score)

**`findBinauralCarrier(soundscapeRootHz, solfeggioHz)`** — Binaural carrier placement:
- Determines solfeggio's scale degree relative to soundscape root
- If solfeggio near root (±1 semitone): carrier = perfect 5th (degree 7)
- If solfeggio near 5th (±1 semitone) or anywhere else: carrier = root (degree 0)
- Builds all octave transpositions, filters to 80-300 Hz range
- Among valid octaves, picks the one furthest in actual (non-folded) semitones from solfeggio to avoid frequency crowding
- Falls back to nearest-to-190 Hz if no octave fits the range
- Returns ({double carrierHz, String degreeName})

**Helper methods:**
- `frequencyToMidi(hz)` / `midiToFrequency(midi)` — conversion between Hz and MIDI note numbers
- `semitonesBetween(hzA, hzB)` — interval in semitones with octave equivalence
- `shiftRatioForExactMatch(rootHz, targetHz)` — unison-only matching

### 4.6 Motif Engine (motif_engine.dart)

Independent audio engine for generative composition. Plays short musical fragments on prime-number timer cycles, creating combinations that essentially never repeat. Runs separately from AudioEngine — motifs do NOT count toward the 5-layer limit.

**Prime-number cycle durations (seconds):** 13, 17, 19, 23, 29, 31, 37, 41, 43

**Behavior per cycle:**
- Random check against density (0.0-1.0): if rand < density, play the motif; otherwise skip
- Volume = defaultVolume × masterVolume × random(0.8-1.0) for subtle variation
- One-shot playback (no looping) via just_audio
- Random initial offset (0 to cycleDuration) prevents simultaneous first-fire

**Harmonic pitch-shifting:**
- Tonal motifs (rootFrequency != null) are pitch-shifted via player.setSpeed() to harmonize with the target solfeggio frequency using HarmonicMatcher.findBestMatch()
- Atonal motifs (rootFrequency == null) play unshifted

**Key methods:**
- `start(palette, {density, masterVolume, targetFrequency})` — await stop() first (prevents race condition), then initializes all motif players and timer chains
- `setDensity(double)` / `setMasterVolume(double)` — real-time control from journey engine interpolation
- `stop()` — cancels all timers, disposes all players

**Important race condition fix:** abandon() in JourneyEngine does NOT call motifEngine.stop(). The next motifEngine.start() always calls await stop() internally, ensuring deterministic cleanup without dangling async tasks.

### 4.7 LLM Service (llm_service.dart)

Stateless service for parsing natural language mood descriptions into energy/focus/warmth values via the Anthropic API.

**Method:** `parseMood(String userText)` → returns `({double energy, double focus, double warmth})?`

**Implementation:**
- Reads API key from `.env` file via flutter_dotenv (key is NEVER hardcoded, `.env` is gitignored)
- POST to `https://api.anthropic.com/v1/messages` with model `claude-sonnet-4-20250514`, max_tokens 100
- System prompt instructs the model to return ONLY a JSON object with three 0.0–1.0 values
- 10-second timeout on the HTTP request
- Strips markdown fences before JSON parsing
- Returns null on ANY failure (network, parse, timeout, bad key) — caller shows SnackBar fallback

**User experience:** Text field on Home screen ("Or tell us how you want to feel...") with arrow submit button. On success, slider values are updated internally and generation auto-triggers. On failure, SnackBar suggests using sliders instead. Loading spinner replaces submit button during API call.

---

## 5. DATA MODEL

### 5.1 Sound Source Hierarchy (journey.dart)

```
SoundSource (abstract)
  ├── SampleSource { assetPath, volume }
  ├── SoundscapeSource { assetPath, volume, pitchShiftRatio, rootFrequency }
  ├── ToneSource { frequency, volume }
  ├── BinauralSource { centerFrequency, beatFrequency, volume }
  └── MotifSource { motifIds, density, volume }
```

### 5.2 Journey Model (journey.dart)

```
Journey { id, name, description, icon, category, waypoints,
          defaultDuration, minDuration, maxDuration }
JourneyWaypoint { layers: List<SoundSource>, weight, curve }
```

Factory constructors:
- `Journey.static(layers)` — single-waypoint journey
- `Journey.sleepTimer(audioEngine, duration, {motifEngine})` — snapshots current mix including motifs, fades density to 0

### 5.3 Sound Catalog (sound_meta.dart)

43 entries in kSoundCatalog:
- 10 solfeggio frequencies (174–963 Hz) with benefit descriptions
- 5 binaural beats (delta/theta/alpha/beta/gamma) with brainwave descriptions
- 13 noise colors (5 available, 8 "Coming Soon")
- 5 nature sounds
- 10 soundscapes with rootFrequency metadata

SoundMeta fields: id, name, assetPath, category, description, tags (List<String>), defaultVolume, isAvailable, rootFrequency (double?, for soundscapes)

### 5.4 Motif Catalog (motif_meta.dart)

9 entries in kMotifCatalog:
- bowl_high_g (G4, 392 Hz) — meditate, relax, sleep
- bowl_low_g (G3, 196 Hz) — meditate, sleep
- high_bell_b (B4, 493.88 Hz) — meditate, focus
- low_bell_eb (Eb4, 311.13 Hz) — meditate, relax
- piano_note_f (F4, 349.23 Hz) — relax, meditate, sleep
- triangle_e (E4, 329.63 Hz) — focus, energize
- gourd_percussion (atonal) — relax, meditate
- vibe_chimes (atonal) — relax, meditate, sleep
- wind_chimes (atonal) — relax, sleep

MotifMeta fields: id, name, assetPath, rootFrequency (double?, null for atonal), tags (List<String>), defaultVolume

### 5.5 Mood Profiles (mood_profile.dart)

Hand-tuned (energy, focus, warmth) affinity profiles for all 43 available sounds (33 original + 10 soundscapes). See file for exact values.

### 5.6 Saved Mix (saved_mix.dart)

SavedMix: id (UUID), name, category (optional), layers (assetPath/name/volume), createdAt. Stored via shared_preferences.

---

## 6. SOUNDSCAPE ASSETS

10 ambient beds exported from Ableton at 44100 Hz / 16-bit / MP3:

| Filename | Key | Root Hz | Tags |
|----------|-----|---------|------|
| warm_drift_f_maj.mp3 | F major | 349.23 | sleep, relax, meditate |
| deep_current_d_maj.mp3 | D major | 293.66 | sleep, meditate |
| open_sky_g_maj.mp3 | G major | 392.00 | relax, meditate, energize |
| soft_veil_ab_maj.mp3 | Ab major | 415.30 | sleep, relax |
| golden_haze_a_maj.mp3 | A major | 440.00 | relax, meditate, focus |
| luminous_calm_c_maj.mp3 | C major | 261.63 | relax, meditate, sleep |
| bright_pulse_e_maj.mp3 | E major | 329.63 | focus, energize |
| shadow_weave_fs_min.mp3 | F# minor | 369.99 | sleep, meditate |
| still_waters_a_min.mp3 | A minor | 440.00 | sleep, relax, meditate |
| crystal_ascent_b_maj.mp3 | B major | 493.88 | focus, energize, meditate |

**Naming convention:** `[mood_descriptor]_[key].mp3` where key uses `s` for sharp, `b` for flat, `_maj`/`_min` for mode.

**Content expansion planned:** At least 3 soundscapes per key (major and minor), all normalized to consistent LUFS levels.

---

## 7. UI / NAVIGATION

**Bottom navigation (4 tabs):**
1. **Home** — "How do you want to feel?" mood generator with 3 sliders + duration picker + Generate button + Now Playing section
2. **Mixer** — Active layers with volume sliders + sound catalog organized by category
3. **Library** — My Mixes (most recent first, swipe-to-delete) + intention browsing (Sleep/Focus/Meditate/Relax/Energize)
4. **Journey** — 5 curated journeys with duration selectors + sleep timer

**Design:** Dark theme (charcoal #1C1C1C, amber accent #D4A017). IndexedStack for screen persistence.

**Cross-tab interactions:**
- Save from Mixer → refreshes Library via GlobalKey<LibraryScreenState>
- Generate from Home → starts journey + motif engine, visible in Mixer
- Manual edit in Mixer (slider drag or X button) → calls journeyEngine.abandon() to release autopilot

**Developer access:** Long-press app title → navigates to ToneTestScreen (tone generator + binaural + harmonic matcher + binaural carrier calculator)

---

## 8. CORE DESIGN PRINCIPLES

### Smooth Transitions
Every audio change is gentle, smooth, gradual. Nothing starts or stops abruptly.
- addLayer: starts at 0, fades to target over 1.5s
- removeLayer: fades to 0 over 1s before disposal
- Preset/mix loading: parallel fade-out, then unified 2s swell
- Journey start: 2s startup ramp
- Library preview: 1.5s fade-in, 0.5s fade-out
- Crossfade loop: 3s blend between players

### User Agency
"How do you want to feel?" (aspirational) not "How do you feel?" (diagnostic). Sliders are transparent and invite exploration. User can always manually adjust the mix after generation.

### Decoupled Audio Layers
Five independent sonic dimensions that combine fluidly:
1. **Ambient soundscapes** — atmospheric compositions, pitch-shifted to harmonize with active key
2. **Solfeggio tones** — real-time synthesis at precise frequencies
3. **Binaural beats** — real-time synthesis with carrier placed on consonant scale degree, separated from solfeggio
4. **Nature/noise textures** — atonal atmospheric color
5. **Generative motifs** — short musical fragments on independent prime-number cycles, harmonically matched

---

## 9. CURATED JOURNEYS

Five 4-waypoint journeys with even weight distribution and easeInOut curves:

1. **Country Night** (Sleep, 45min): brown_noise + crickets + delta binaural → delta fades to 0
2. **Study Sound** (Focus, 60min): white_noise + 417 Hz + rain → frequency gradually decreases
3. **Seaside Meditation** (Meditate, 30min): 285 Hz + pink_noise + ocean → ocean fades then returns
4. **Deep Focus** (Focus, 90min): alpha + blue_noise + wind → balanced shifts
5. **Clear Your Mind** (Relax, 20min): 741 Hz + thunder + red_noise → frequency drops, texture builds

**Note:** These journeys use SampleSource references to MP3 files and do not include motifs. They are not modified by the generative systems.

---

## 10. COMPLETED MILESTONES

- **Week 1:** Environment + app skeleton ✓
- **Week 2:** Journey engine + evolving presets ✓
- **Week 3:** Library tab with intention browsing ✓
- **Week 4:** Save/load custom mixes ✓
- **Week 5:** AI mood feature + navigation reorganization ✓
- **Week 6:** Tone generator (flutter_soloud), AudioEngine/JourneyEngine/MoodEngine integration, HarmonicMatcher ✓
- **Week 7:** 10 soundscapes integrated with pitch-shifting, generative motif engine, key-aware binaural carrier placement ✓
- **Week 8 (current):** LLM text input, dedicated noise slot, Android emulator verification, triad-aware harmonic refactor, Firebase integration ✓

---

## 11. ACTIVE DEVELOPMENT — WHERE WE LEFT OFF

### Just Completed (This Session)
- LLM text input integration: natural language mood parsing via Anthropic API
- Dedicated noise slot in mood engine: 5-slot category selection
- Android Studio + emulator setup, full validation (confirmed Chrome artifacts are browser-only)
- Triad-aware harmonic refactor: combined mood + harmonic scoring for soundscape selection; binaural carrier restricted to root/5th; expanded 80-300 Hz range
- Firebase integration: Analytics (with AnalyticsService wrapper), Crashlytics, Remote Config
- Remote Config wired into MoodEngine: all 5 layer volumes + 4 motif densities now remotely tunable
- Save/load bug fixed: debounced engine listener setState via addPostFrameCallback to prevent widget lifecycle assertion error during bulk layer operations
- Equal-power crossfade: replaced linear fade curves with cos/sin curves to eliminate volume dip at loop boundaries
- Beta/gamma binaural carrier range: findBinauralCarrier accepts optional beatFrequencyHz; when >= 15 Hz targets 200-400 Hz instead of 80-300 Hz (not yet wired into call sites)
- Comprehensive content production plan with solfeggio-to-key compatibility matrix and phased checklist

### Known Issues (Deferred)
- Chrome web audio: pitch-shifting via setSpeed() causes audible warbling artifacts — Chrome-specific, absent on mobile
- Beta/gamma carrier range: beatFrequencyHz parameter exists but is not yet passed from mood_engine.dart call site — carriers still default to 80-300 Hz range for all beat types until wired in
- Curated journeys still use old SampleSource MP3 references — need migration to SoundscapeSource + ToneSource + BinauralSource

### Needs Content Work Before Next Code Phase
See Section 13 (Content Production Pass Plan) for the full breakdown.

---

## 12. DEVELOPMENT PHASES (Revised Timeline)

Phases are ordered but not time-boxed — each takes as long as needed for quality.

1. ~~**Android emulator setup and verification**~~ ✓
2. ~~**LLM text input integration**~~ ✓
3. ~~**Triad-aware harmonic refactor**~~ ✓
4. ~~**Firebase integration**~~ ✓
5. ~~**Wire Remote Config into engines**~~ ✓
6. ~~**Save/load bug fix**~~ ✓
7. ~~**Audio polish (crossfade + beta/gamma carrier)**~~ ✓
8. **Content production pass** (see Section 13 for detailed plan)
9. **Content integration** (add to catalogs, mood profiles, test harmonic matching)
10. **Wire beta/gamma beat frequency into binaural carrier call site**
11. **Curated journey migration** (update to SoundscapeSource + ToneSource + BinauralSource + MotifSource)
12. **SoLoud migration** (unified audio engine, proper pitch-shift-without-tempo-change)
13. **UI/UX design pass** (partner collaboration, slider axis naming, visual polish)
14. **Beta testing**
15. **Monetization + store prep** (RevenueCat freemium model)
16. **Marketing + launch** (ASO, social media, wellness/meditation influencer outreach)

**iOS development:** Use M4 Mac with Xcode for iOS builds. Apple Developer account ($99/year) needed for device deployment and App Store submission.

---

## 13. CONTENT PRODUCTION PASS PLAN

### 13.1 Why This Matters

The triad-aware harmonic system selects soundscapes based on both mood fit AND harmonic compatibility with the solfeggio frequency. More soundscapes across more keys = better harmonic matches with less pitch shifting = more natural, musical results. Additionally, all content needs normalization to a consistent loudness level so the programmatic volume mixing produces predictable results.

### 13.2 Current Inventory

**Soundscapes (10):**

| Filename | Key | Root Hz | Tags | Good solfeggio matches |
|----------|-----|---------|------|----------------------|
| warm_drift_f_maj.mp3 | F major | 349.23 | sleep, relax, meditate | 174(uni), 417(m3), 528(P5), 852(m3) |
| deep_current_d_maj.mp3 | D major | 293.66 | sleep, meditate | 174(m3), 741(M3) |
| open_sky_g_maj.mp3 | G major | 392.00 | relax, meditate, energize | 396(uni), 963(M3) |
| soft_veil_ab_maj.mp3 | Ab major | 415.30 | sleep, relax | 417(uni), 528(M3), 639(P5), 852(uni), 963(m3) |
| golden_haze_a_maj.mp3 | A major | 440.00 | relax, meditate, focus | 285(M3), 528(m3) |
| luminous_calm_c_maj.mp3 | C major | 261.63 | relax, meditate, sleep | 396(P5), 528(uni), 639(m3) |
| bright_pulse_e_maj.mp3 | E major | 329.63 | focus, energize | 396(m3), 417(M3), 852(M3), 963(P5) |
| shadow_weave_fs_min.mp3 | F# minor | 369.99 | sleep, meditate | 285(P5), 741(uni) |
| still_waters_a_min.mp3 | A minor | 440.00 | sleep, relax, meditate | 285(M3), 528(m3) |
| crystal_ascent_b_maj.mp3 | B major | 493.88 | focus, energize, meditate | 639(M3), 741(P5), 963(uni) |

**Key coverage:** 8 unique roots across 10 soundscapes (A appears twice — major and minor). Missing entirely: Db/C#, Eb/D#, Bb/A#.

**Motifs (9):** 6 tonal (bowls G3/G4, bells B4/Eb4, piano F4, gong C3) + 3 atonal percussion. No motifs in keys of D, A, E, or any sharp/flat keys besides Eb and B.

**Nature (5):** rain, ocean, wind, thunder, crickets. Not normalized.

**Noise (5 available, 8 planned):** white, pink, brown, blue, yellow. Not normalized.

### 13.3 Solfeggio-to-Key Compatibility Matrix

The 9 solfeggio frequencies land on these pitch classes: F, Db, G, Ab, C, Eb, F#, Ab, B.

For each solfeggio, the "good" soundscape roots (where the solfeggio sits on unison, P5, M3, or m3) are:

| Solfeggio | Pitch | Good root matches (current) | Gaps |
|-----------|-------|-----------------------------|------|
| 174 Hz | F | D, F | Limited — only 2 matches |
| 285 Hz | Db | F#, A | Thin — no Db root available |
| 396 Hz | G | C, E, G | Solid |
| 417 Hz | Ab | E, F, Ab | Solid |
| 528 Hz | C | C, F, Ab, A | Strong |
| 639 Hz | Eb | C, Ab, B | OK but no Eb root |
| 741 Hz | F# | D, F#, B | OK |
| 852 Hz | Ab | E, F, Ab | Solid |
| 963 Hz | B | E, G, Ab, B | Strong |

**Key insight:** 174 Hz (F) and 285 Hz (Db) have the weakest coverage. Adding soundscapes rooted in Bb and Db would significantly improve both.

### 13.4 Priority Soundscapes to Create

**Tier 1 — Fill missing roots (highest impact on harmonic matching):**

| New root | Mode(s) | Solfeggio matches it adds | Mood gap it fills |
|----------|---------|--------------------------|-------------------|
| Bb | major + minor | 174(P5), 285(m3) | Need warm/relaxing options |
| Eb | major + minor | 396(M3), 639(uni), 741(m3) | Need meditative/dreamy options |
| Db | major | 174(M3), 285(uni), 417(P4→weak but Db root helps), 852(P5) | Need sleep/deep options |

Adding these 5 soundscapes (Bb maj, Bb min, Eb maj, Eb min, Db maj) would give coverage across all 12 chromatic pitch classes and dramatically improve matching for the currently weakest solfeggio frequencies.

**Tier 2 — Add minor modes for existing roots (expands mood range per key):**

| New soundscape | Why |
|----------------|-----|
| C minor | C major exists; minor version expands sleep/dark options at this strong root |
| D minor | D major exists; minor fills a melancholic/introspective gap |
| E minor | E major exists; minor adds depth for meditate/sleep at a strong harmonic root |
| G minor | G major exists; minor adds dark/moody option at this key |
| F minor | F major exists; minor complements the strongest 174 Hz match |

**Tier 3 — Second soundscapes for well-covered keys (variety):**

Additional soundscapes in F, C, Ab, E, and B with different moods/textures to give the mood engine more options within harmonically strong keys. These are less urgent — the system can pitch-shift existing soundscapes — but improve the overall variety.

### 13.5 Priority Motifs to Create

The motif engine pitch-shifts tonal motifs to match the solfeggio, so key variety matters less than tonal/atonal variety and timbre diversity. Current gaps:

**Tonal motifs needed (10-15 new):**
- Singing bowls: additional sizes/pitches (crystal bowl high, large brass bowl low)
- Melodic fragments: kalimba phrases, ambient guitar harmonics, hang drum notes
- Sustained tones: bowed cymbal, glass harmonica, wine glass rim
- Vocal: single "om" sustain, breathy vocal pad

**Atonal motifs needed (8-12 new):**
- Percussion: rain stick single pass, ocean drum, tongue drum (can be atonal if played percussively)
- Texture: wood creaks, stone clicks, shell rattle, seed pod shake
- Impacts: soft mallet on wood, finger cymbal ting, water droplet (single)
- Breath/air: exhale, wind gust, cloth rustle

**Design principle for motifs:** Each motif should have a clear, clean attack and a natural decay. They're one-shots, not loops. Tonal motifs should sustain enough for pitch to be perceived (0.5-3 seconds). Atonal motifs can be shorter. All should feel organic and handcrafted — no synthesizers.

### 13.6 Nature & Noise Samples

**Nature — normalize only, no new content needed for MVP:**
Current 5 (rain, ocean, wind, thunder, crickets) are sufficient. Normalize to -14 LUFS. Consider adding 2-3 more post-launch: birdsong, flowing water/stream, campfire crackling.

**Noise — add the 8 planned colors:**
Bring the planned but unavailable noise colors into production. All should be seamless loops normalized to -14 LUFS. Ensure they're true noise (no tonal content) so they don't interfere with harmonic matching.

### 13.7 Mastering & Normalization Specifications

**All content:**
- Loudness: -14 LUFS integrated (measure with Youlean Loudness Meter or similar)
- True peak: -1.0 dBTP maximum
- Sample rate: 44100 Hz
- Bit depth: 16-bit minimum (24-bit for FLAC masters)
- Export formats: FLAC (archival master) + MP3 192+ kbps (app asset)

**Soundscapes specifically:**
- Standard tuning: A = 440 Hz (critical for harmonic matching math)
- Root frequency must be precise — tune to within ±5 cents of target
- Seamless loop points (crossfade at export or mark loop region)
- No embedded sine waves, binaural beats, or solfeggio frequencies — these are added by the app
- Frequency content: avoid strong melodic lines that compete with solfeggio; pads, drones, and textures work best
- Stereo width: wide but not extreme; leave center space for the mono solfeggio tone

**Motifs specifically:**
- Clean attack, natural decay, silence at tail (no loop)
- Tonal motifs: must have a clear, identifiable pitch for the harmonic matcher to work with
- Duration: 0.5-4 seconds (shorter for percussion, longer for sustained tones)
- Name tonal motifs with root key: `bowl_high_g.mp3`, `kalimba_phrase_d.mp3`
- Name atonal motifs descriptively: `rain_stick_pass.mp3`, `stone_click.mp3`

### 13.8 Naming Convention

`[descriptor]_[key]_[mode].mp3`

Examples: `midnight_bloom_bb_min.mp3`, `forest_floor_eb_maj.mp3`, `crystal_cave_db_maj.mp3`

For motifs: `[instrument]_[descriptor]_[key].mp3` or `[instrument]_[descriptor].mp3` (atonal)

### 13.9 Workflow for Integration

After content is created and mastered:
1. Place MP3 files in the appropriate `assets/audio/` subdirectories
2. Add entries to `kSoundCatalog` in `sound_meta.dart` with rootFrequency, category, tags
3. Add mood profiles to `kMoodProfiles` in `mood_profiles.dart`
4. For new motifs: add entries to `kMotifCatalog` in `motif_meta.dart`
5. Run the app and test generation across all mood slider positions
6. Verify harmonic matching with the tone test screen (long-press "Noisy" title)
7. Listen for: clean pitch relationships, no dissonance between layers, balanced volumes

### 13.10 Production Priority Summary

| Priority | What | Count | Purpose |
|----------|------|-------|---------|
| 1 | Normalize all existing content to -14 LUFS | 29 files | Foundation — makes volume mixing predictable |
| 2 | New soundscapes: Bb maj, Bb min, Eb maj, Eb min, Db maj | 5 | Fills harmonic gaps for 174/285/639 Hz |
| 3 | New minor soundscapes: C min, D min, E min, G min, F min | 5 | Expands mood range per key |
| 4 | New tonal motifs | 10-15 | Timbre diversity for generative composition |
| 5 | New atonal motifs | 8-12 | Percussion/texture variety |
| 6 | Remaining noise colors | 8 | Complete the noise palette |
| 7 | Tier 3 soundscapes (second options for strong keys) | 5-10 | Variety within well-covered keys |

---

## 14. TIER 2 FEATURES (Post-Launch)

Features to explore after core product launch. Not on the critical path but architecturally compatible with the existing system.

### Plant Radio (Live Stream Layer)

**Concept:** A plant bioelectricity sensor (e.g. PlantWave or similar MIDI device) translates plant biofeedback into MIDI on a separate device (laptop running Ableton, Raspberry Pi, etc.). That device runs the sound design algorithm and streams the resulting audio. Noisy receives the audio stream and layers it into the existing mix as a "Live" layer.

**Why external processing:** Keeping MIDI interpretation and sound generation on a separate device avoids Bluetooth MIDI complexity, third-party hardware dependencies, and keeps the app focused on its core audio playback architecture. The sound design stays "humanly crafted" under Robert and partner's control rather than being algorithmically generated on-device.

**Architecture:** The app would treat a live stream as a new source type (`StreamSource`) — essentially a URL-based audio layer played via just_audio's network streaming. It would appear in the Mixer alongside local layers and could coexist with mood-generated soundscapes.

**Product angle:** Best suited as a curated live broadcast ("Noisy Plant Radio, live from the studio") rather than a user-facing hardware integration feature. Strong brand potential for events, physical retail spaces, or social media presence without complicating the core app experience.

**Implementation when ready:**
- New `StreamSource` type in journey.dart
- URL input or preset station selector in a new "Live" tab or Mixer category
- just_audio handles network audio streaming natively
- Volume control same as any other Mixer layer

---

## 15. KEY COMMITS

- Latest — Equal-power crossfade + beta/gamma carrier range
- `4ca7132` — Debounce engine listener setState (save/load bug fix)
- Previous — Remote Config wired into MoodEngine + Firebase integration
- Previous — Triad-aware harmonic refactor
- Previous — LLM text input + dedicated noise slot + Android emulator verified
- `e660b16` — Generative motifs + key-aware binaural carrier + soundscape integration
- `c896bfc` — 10 real soundscapes + harmonic pitch-shifting in mood journeys

---

## 16. PROMPT TEMPLATES FOR CLAUDE CODE

When resuming development, provide Claude Code with context about the project before giving task-specific prompts. Key files to reference:
- `lib/services/audio_engine.dart` — the central audio manager
- `lib/services/tone_service.dart` — real-time synthesis
- `lib/services/motif_engine.dart` — generative motif system
- `lib/services/journey_engine.dart` — timeline interpolation
- `lib/services/mood_engine.dart` — soundscape generation logic (triad-aware selection)
- `lib/services/harmonic_matcher.dart` — pitch math, harmonic compatibility scoring, binaural carrier placement
- `lib/services/llm_service.dart` — natural language mood parsing via Anthropic API
- `lib/services/analytics_service.dart` — Firebase Analytics event wrapper
- `lib/models/journey.dart` — SoundSource hierarchy (Sample, Soundscape, Tone, Binaural, Motif)
- `lib/models/sound_meta.dart` — sound catalog
- `lib/models/motif_meta.dart` — motif catalog
- `lib/firebase_options.dart` — Firebase configuration (auto-generated by flutterfire)

Always end prompts with: "Run flutter analyze when done and fix any issues."
