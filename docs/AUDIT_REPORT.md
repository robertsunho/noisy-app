# Design Doc vs. Codebase — Discrepancy Audit

**Audited document:** `docs/noisy_design_document.md` (v2.4, March 4, 2026)
**Audit date:** July 15, 2026
**Scope:** All of `lib/` (21 Dart files), `assets/`, `pubspec.yaml`, `web/index.html`, `.gitignore`, git history
**Method:** Read-only. No source file, asset, or the design doc was modified.

---

## Summary

**Total discrepancies found: 29**

| Category | Count | What it covers |
|---|---|---|
| catalog | 10 | Sound/motif/soundscape catalog entries, counts, keys, root frequencies, tags |
| numeric | 5 | Volumes, densities, thresholds, versions, counts |
| architecture | 4 | Files, classes, method signatures the doc describes |
| behavior | 4 | How the doc says a system behaves vs. what the code does |
| intra-code | 4 | A code comment/docstring contradicting the code it describes |
| known-issue | 2 | Doc-listed known issues, re-checked against current code |

**The largest single area of drift is the motif catalog** (§5.4 / §13.2): two of six tonal motifs are documented an octave off, all nine have tag lists that disagree with the code, and §13.2 describes a "gong C3" motif that does not exist.

**The most behaviorally significant item is #5** — the `_inferCategory` mood→category thresholds in the doc do not match any rule in the code, and the doc's Meditate rule is the code's *Relax* rule. Anyone reasoning about which journey a slider position produces will get the wrong answer from the doc.

**Both open "Known Issues" in §11 are still genuinely open** (#28, #29) — neither has been silently fixed.

**What checked out clean:** the entire §6 soundscape table (all 10 filenames, keys, root frequencies, and tag lists match `sound_meta.dart` exactly); all 5 curated journeys in §9 (composition, categories, durations, and volume arcs); the whole of §4.7 (LLM service); §5.1 and §5.6 (source hierarchy, SavedMix); §4.2 (ToneService); the crossfade/fade timing constants in §8; the Remote Config defaults in `main.dart`; and the three commit SHAs cited in §15.

---

## Discrepancies

### 1. Flutter version is three minor versions stale
- **Category:** numeric
- **Location:** Doc §2 (Tech Stack) / `pubspec.yaml:22`, local toolchain
- **Doc says:** "Framework: Flutter 3.41.1, Dart"
- **Code says:** `flutter --version` reports **Flutter 3.44.6**, Dart 3.12.2 (stable, framework revision `ee80f08bbf`). `pubspec.yaml` constrains `sdk: ^3.11.0`.
- **Ruling:**

### 2. File structure omits two files that exist and are used
- **Category:** architecture
- **Location:** Doc §3 (File Structure) / `lib/services/analytics_service.dart`, `lib/firebase_options.dart`
- **Doc says:** The `lib/` tree in §3 lists 5 screens, 5 models, and 8 services. Neither `analytics_service.dart` nor `firebase_options.dart` appears.
- **Code says:** Both exist. `analytics_service.dart` defines `AnalyticsService` with 5 event wrappers and is injected into `HomeScreen` and `MixerScreen` (`main.dart:151,160,166`). `firebase_options.dart` is imported by `main.dart:7`. Note §16 *does* list both — so §3 is the stale section, not the doc as a whole.
- **Ruling:**

### 3. Doc lists "yellow" as an available noise; the real 5th noise is "red"
- **Category:** catalog
- **Location:** Doc §3 / `assets/audio/noise/`, `sound_meta.dart:123–143`
- **Doc says:** "noise/ — white, pink, brown, blue, yellow noise (5 MP3s, 8 more planned)"
- **Code says:** The 5 MP3s on disk are `white_noise.mp3`, `pink_noise.mp3`, `brown_noise.mp3`, `blue_noise.mp3`, `red_noise.mp3`. There is **no `yellow_noise.mp3`** — `yellow_noise` is in the catalog with `isAvailable: false` (`sound_meta.dart:134–143`), i.e. it is one of the 8 planned, not one of the 5 available. `red_noise` (`isAvailable` defaults true, line 123–131) is documented nowhere in §3. The "5 available / 8 planned" split is correct; only the naming is wrong. Red noise is also used by the "Clear Your Mind" curated journey (`journey_screen.dart:217`), which §9 documents correctly.
- **Ruling:**

### 4. `addLayer` fades to a hardcoded 0.7, not to a "target"
- **Category:** behavior
- **Location:** Doc §4.1 + §8 (Smooth Transitions) / `audio_engine.dart:112–132`
- **Doc says:** "addLayer starts at 0, fades to target over 1.5s" (stated twice, in §4.1 and §8).
- **Code says:** `addLayer(assetPath, name)` takes no target parameter and always calls `_startFade(layer, 0.7, const Duration(milliseconds: 1500))` (line 130) — a fixed 0.7. The 1.5s duration is correct. `addToneLayer` and `addBinauralLayer` *do* honour a `volume:` target (lines 154, 178), so the doc's wording is right for tones and wrong for samples.
- **Ruling:**

### 5. Mood→category inference rules do not match the code at all
- **Category:** behavior
- **Location:** Doc §4.4 (Journey generation) / `mood_engine.dart:295–302`
- **Doc says:** "Category inferred from input: energy<0.3→Sleep, focus>0.7→Focus, energy<0.5&warmth>0.5→Meditate, energy>0.6→Energize, else→Relax"
- **Code says:**
  ```dart
  if (energy < 0.25 && focus < 0.30) return 'Sleep';
  if (focus > 0.65) return 'Focus';
  if (energy > 0.65) return 'Energize';
  if (energy < 0.35 && warmth > 0.50) return 'Relax';
  if (focus > 0.45) return 'Meditate';
  return 'Relax';
  ```
  Every rule differs:
  - **Sleep** requires energy < 0.25 **and** focus < 0.30 (doc: energy < 0.3 alone).
  - **Focus** threshold is 0.65, not 0.7.
  - **Energize** threshold is 0.65, not 0.6 — and is evaluated *third*, before the warmth rule, not fourth.
  - The doc's **Meditate** rule (`energy<0.5 && warmth>0.5`) is, in the code, a near-identical **Relax** rule (`energy<0.35 && warmth>0.50`). The doc assigns this input region to the wrong category.
  - The code's actual Meditate rule (`focus > 0.45`) appears nowhere in the doc.

  Because category drives motif palette, motif density, journey name, and icon, the doc misdescribes the output for a large part of the slider space.
- **Ruling:**

### 6. Motif density is a Remote Config point value, not an energy-scaled range
- **Category:** numeric
- **Location:** Doc §4.4 (Motif palette selection) / `mood_engine.dart:182–190`, `main.dart:34–37`
- **Doc says:** "Density scales with energy: Sleep 0.20-0.30, Relax/Meditate/Focus 0.30-0.50, Energize 0.60-0.80."
- **Code says:** `_inferMotifDensity(category)` is a flat category switch reading four Remote Config keys — no scaling with energy, and a single value per category, not a range:
  | Category | RC key | Default (`main.dart`) | Doc's range |
  |---|---|---|---|
  | Sleep | `motif_density_sleep` | 0.25 | 0.20–0.30 ✓ within |
  | Focus | `motif_density_focus` | 0.40 | 0.30–0.50 ✓ within |
  | Energize | `motif_density_energize` | 0.70 | 0.60–0.80 ✓ within |
  | Relax **and Meditate** (`default:`) | `motif_density_relax` | 0.40 | 0.30–0.50 ✓ within |

  Every default falls inside the doc's stated range, so the *numbers* are compatible — but "scales with energy" describes an interpolation the code does not perform, and Meditate has no key of its own (it silently falls through to `motif_density_relax`).
- **Ruling:**

### 7. §4.4 presents the five layer volumes as fixed constants; they are Remote Config reads
- **Category:** numeric
- **Location:** Doc §4.4 (Algorithm — 5-slot category selection) / `mood_engine.dart:205, 249–285`
- **Doc says:** "1. Best frequency → vol 0.30 ... 2. Best soundscape → vol 0.55 ... 3. Best nature sound → vol 0.35 ... 4. Best noise color → vol 0.30 ... 5. Best binaural → vol 0.35" — written as literals with no mention of Remote Config.
- **Code says:** All five come from `rc.getDouble(...)` (`soundscape_volume`, `nature_volume`, `noise_volume`, `binaural_volume`, `frequency_volume`). The `main.dart:38–42` defaults are exactly 0.55 / 0.35 / 0.30 / 0.35 / 0.30, so the doc's numbers match the *defaults* — but any remote change silently invalidates §4.4. Doc §11 does record that RC was wired in, so this is §4.4 not having been updated to match. (See also #25 — the same staleness exists in a code docstring.)
- **Ruling:**

### 8. Journey generation has two undocumented volume/density behaviors
- **Category:** behavior
- **Location:** Doc §4.4 (Journey generation) / `mood_engine.dart:119, 133–137, 150`
- **Doc says:** "3 waypoints with easeInOut curves" and then lists only the source-type mapping. Nothing about mid-journey variation or a sleep taper.
- **Code says:** Two behaviors are absent from the doc:
  - **Waypoint 1** perturbs each layer by ±0.05 on alternating indices, clamped to `[0.10, 0.70]` (line 136) — "slight mid-journey variation".
  - **Waypoint 2** drops motif density to a hardcoded `0.1` when the category is Sleep (`final wp2Density = category == 'Sleep' ? 0.1 : motifDensity;`, line 119). This 0.1 is *not* Remote Config-driven, unlike every other density in the system.

  The 3-waypoint / easeInOut claim itself is correct (`waypoints: [wp0, wp1, wp2]`, weights 0/1.0/1.0, curves easeInOut).
- **Ruling:**

### 9. §4.5 documents `findBinauralCarrier` with a stale signature and range
- **Category:** architecture
- **Location:** Doc §4.5 (Harmonic Matcher) / `harmonic_matcher.dart:155–156, 186–189`
- **Doc says:** "**`findBinauralCarrier(soundscapeRootHz, solfeggioHz)`**" and "Builds all octave transpositions, filters to 80-300 Hz range ... Falls back to nearest-to-190 Hz if no octave fits the range".
- **Code says:** The signature is `findBinauralCarrier(double soundscapeRootHz, double solfeggioHz, {double? beatFrequencyHz})`. When `beatFrequencyHz >= 15.0`, the range becomes **200–400 Hz** with a 300 Hz fallback rather than 80–300 / 190 (lines 186–189). Doc §11 records this change under "Just Completed", but §4.5 was never updated to match — so the doc contradicts itself, and §4.5 is the stale half. Everything else in §4.5 (degree selection, furthest-octave preference, the 80–300 / 190 default path) is accurate.
- **Ruling:**

### 10. `Journey.sleepTimer`'s motif support is never exercised by its only call site
- **Category:** behavior
- **Location:** Doc §5.2 (Journey Model) / `journey.dart:175–232`, `journey_screen.dart:305–314`
- **Doc says:** "`Journey.sleepTimer(audioEngine, duration, {motifEngine})` — snapshots current mix **including motifs**, fades density to 0"
- **Code says:** The factory does accept `{MotifEngine? motifEngine}` and does build a `MotifSource` fading density to 0 when it is passed (lines 198–214). But the **only** call site — `_startSleepTimer` in `journey_screen.dart:307–313` — passes neither `motifEngine` to `Journey.sleepTimer(...)` nor to `journeyEngine.start(...)`. So in the shipping app the sleep timer never snapshots or fades motifs; if motifs are running when the sleep timer starts, they keep firing at full density after the mix has faded to silence. This mirrors the beta/gamma situation in #28: parameter built, call site not wired.

  Related, same factory: `toSource()` (lines 181–193) reconstructs every non-tone layer as a plain `SampleSource`, so a soundscape's `pitchShiftRatio` and `rootFrequency` are dropped from the snapshot and the layer reverts to unshifted playback for the duration of the sleep timer.
- **Ruling:**

### 11. `bowl_high_g` is documented an octave below its actual root
- **Category:** catalog
- **Location:** Doc §5.4 (Motif Catalog) / `motif_meta.dart:27–33`
- **Doc says:** "bowl_high_g (G4, 392 Hz)"
- **Code says:** `rootFrequency: 784.0, // G5` — one octave up. The code's own comment agrees with the value (G5 = 783.99 Hz), so the code is internally consistent and the doc is wrong.
- **Note for ruling:** No behavioral impact. `HarmonicMatcher.findBestMatch` octave-folds via `semitonesBetween` (`harmonic_matcher.dart:64–69`), so the shift ratio is identical whether the root is G4 or G5. This is a documentation-only error.
- **Ruling:**

### 12. `low_bell_eb` is documented an octave above its actual root
- **Category:** catalog
- **Location:** Doc §5.4 (Motif Catalog) / `motif_meta.dart:48–54`
- **Doc says:** "low_bell_eb (Eb4, 311.13 Hz)"
- **Code says:** `rootFrequency: 155.6, // Eb3` — one octave down. Again the code comment matches the value (Eb3 = 155.56 Hz). Same octave-folding caveat as #11: no behavioral impact, doc-only error.
- **Ruling:**

### 13. Three motif root frequencies are rounded differently in doc vs. code
- **Category:** catalog
- **Location:** Doc §5.4 / `motif_meta.dart:44, 59, 66`
- **Doc says:** high_bell_b **493.88** Hz; piano_note_f **349.23** Hz; triangle_e **329.63** Hz
- **Code says:** `493.9`, `349.2`, `329.6` respectively — the doc quotes 2-decimal equal-temperament values, the code stores 1-decimal. Largest divergence is 0.03 Hz (~0.15 cents), i.e. inaudible and below the `findBestMatch` rounding floor. Flagged only for completeness.
- **Ruling:**

### 14. Seven motifs carry more tags in code than the doc lists
- **Category:** catalog
- **Location:** Doc §5.4 / `motif_meta.dart:26–90`
- **Doc says / Code says:** In each case below the code is a strict superset of the doc — the doc's tags are all present, plus extras. Tags drive `_selectMotifPalette` (`mood_engine.dart:172–179`), so extra tags mean a motif appears in journey categories the doc says it doesn't.
  | Motif | Doc tags | Code tags | Extra in code |
  |---|---|---|---|
  | bowl_high_g | meditate, relax, sleep | sleep, meditate, relax, **focus** | focus |
  | bowl_low_g | meditate, sleep | sleep, meditate, **relax** | relax |
  | high_bell_b | meditate, focus | meditate, focus, **relax**, **energize** | relax, energize |
  | low_bell_eb | meditate, relax | **sleep**, meditate, relax | sleep |
  | triangle_e | focus, energize | focus, energize, **meditate** | meditate |
  | vibe_chimes | relax, meditate, sleep | relax, **focus**, meditate, sleep, **energize** | focus, energize |
  | wind_chimes | relax, sleep | sleep, relax, **meditate** | meditate |
- **Ruling:**

### 15. Two motifs have doc-listed tags that the code has *removed*
- **Category:** catalog
- **Location:** Doc §5.4 / `motif_meta.dart:55–61, 69–75`
- **Doc says / Code says:** Unlike #14, these two are not additive — the code drops tags the doc claims, changing the motif's documented character:
  | Motif | Doc tags | Code tags | Delta |
  |---|---|---|---|
  | piano_note_f | relax, **meditate**, **sleep** | **focus**, relax, **energize** | −meditate, −sleep, +focus, +energize |
  | gourd_percussion | relax, **meditate** | **energize**, relax | −meditate, +energize |

  `piano_note_f` is the sharpest reversal: the doc presents it as a sleep/meditate motif, the code as a focus/energize one. Per `_selectMotifPalette`, it will **never** be selected for a Sleep or Meditate journey despite §5.4 saying it should be.
- **Ruling:**

### 16. "43 available sounds" — 43 is the total; only 35 are available
- **Category:** numeric
- **Location:** Doc §5.5 (Mood Profiles) / `mood_profile.dart:18–75`, `sound_meta.dart:134–213`
- **Doc says:** "Hand-tuned (energy, focus, warmth) affinity profiles for all 43 **available** sounds (33 original + 10 soundscapes)."
- **Code says:** `kMoodProfiles` has 43 entries, but 8 of them are for noise colors with `isAvailable: false` (yellow, gray, purple, green, orange, aquamarine, violet, black). So it is 43 **total**, of which **35 are available**. The code comment at `mood_profile.dart:18–19` states this correctly: "Affinity map for every sound in the catalog (available and coming-soon). MoodEngine filters to isAvailable == true before use." — and `_selectByCategory` does filter on `s.isAvailable` (`mood_engine.dart:208`). The "(33 original + 10 soundscapes)" arithmetic is right; only the word "available" is wrong.
- **Ruling:**

### 17. The Mixer has its own separate 25-entry catalog that excludes all soundscapes
- **Category:** architecture
- **Location:** Doc §7 (UI/Navigation) + §3 + §5.3 / `mixer_screen.dart:10–54`
- **Doc says:** §3 and §5.3 present `sound_meta.dart` / `kSoundCatalog` (43 entries incl. 10 soundscapes) as *the* sound catalog; §7 describes the Mixer as "Active layers with volume sliders + sound catalog organized by category".
- **Code says:** `mixer_screen.dart` does **not** import `sound_meta.dart`. It declares a private `SoundItem` class and its own `_kSoundCatalog` const list of **25** entries (5 nature, 5 noise, 5 binaural, 10 frequencies), gated by `_kCategories = ['Nature', 'Noise', 'Binaural', 'Frequencies']` (line 54). Consequences a reader of the doc would not predict:
  - **No soundscape is reachable from the Mixer** — the 10 soundscapes can only enter a mix via Home-screen generation.
  - The 8 coming-soon noise colors are absent (reasonable, but it means `isAvailable` is not what filters them here — they're simply not in the list).
  - The binaural and frequency entries are served as **MP3 samples**, not the real-time synthesis §3 says "replaced" them.
  - It is a second hand-maintained catalog that must be kept in sync with `kSoundCatalog` by hand.
- **Ruling:**

### 18. Library's "Browse All" advertises 43 sounds but renders 33
- **Category:** catalog
- **Location:** Doc §7 (Library) + §5.3 / `library_screen.dart:11, 201, 771–789`
- **Doc says:** §5.3 documents a 43-entry catalog including 10 soundscapes; §7 describes Library as offering "intention browsing" over it.
- **Code says:** `_BrowseCard(soundCount: kSoundCatalog.length, ...)` (line 201) renders the label "**43 sounds**". But `_SoundsScreen.build` iterates `_kCategoryOrder = ['nature', 'noise', 'frequencies', 'binaural']` (line 11) — `'soundscape'` is **not in the list**, so the 10 soundscape entries are grouped and then never emitted. The user is told 43 and shown 33. (`_kCategoryLabels` and `_kCategoryIcons` likewise have no `'soundscape'` key, so adding the category to `_kCategoryOrder` alone would render a null icon.) The per-intention counts on the `_IntentionCard`s (line 510–512) *do* count soundscapes, so those tallies include sounds Browse All will not show.
- **Ruling:**

### 19. §13.2 lists a "gong C3" motif that does not exist
- **Category:** catalog
- **Location:** Doc §13.2 (Current Inventory) / `motif_meta.dart:26–90`, `assets/audio/motifs/`
- **Doc says:** "**Motifs (9):** 6 tonal (bowls G3/G4, bells B4/Eb4, piano F4, **gong C3**) + 3 atonal percussion."
- **Code says:** There is no gong motif in `kMotifCatalog` and no gong file in `assets/audio/motifs/` (the 9 files on disk match the 9 catalog entries exactly). The sixth tonal motif is **`triangle_e` (E4, 329.6 Hz)**. Correcting the whole parenthetical against the code: bowls G3/**G5**, bells B4/**Eb3**, piano F4, **triangle E4**. The "9 total / 6 tonal / 3 atonal" split is correct.
- **Ruling:**

### 20. §13.2 says there are no motifs in E; `triangle_e` is in E
- **Category:** catalog
- **Location:** Doc §13.2 / `motif_meta.dart:62–68`
- **Doc says:** "No motifs in keys of D, A, E, or any sharp/flat keys besides Eb and B."
- **Code says:** `triangle_e` has `rootFrequency: 329.6, // E4`. D and A are genuinely absent, so only the "E" part of the claim is false. Follows directly from #19 — the sentence appears to have been written when the sixth tonal motif was believed to be a gong in C.
- **Ruling:**

### 21. §13.2 says 8 unique soundscape roots; there are 9
- **Category:** numeric
- **Location:** Doc §13.2 (Key coverage) / `sound_meta.dart:355–454`
- **Doc says:** "**Key coverage:** 8 unique roots across 10 soundscapes (A appears twice — major and minor). Missing entirely: Db/C#, Eb/D#, Bb/A#."
- **Code says:** The 10 roots are F, D, G, Ab, A, C, E, F#, A, B → **9 unique** pitch classes {F, D, G, Ab, A, C, E, F#, B}, with A appearing twice as the doc says. The doc's own surrounding arithmetic confirms 9, not 8: 12 chromatic − 9 present = the 3 it lists as missing (Db, Eb, Bb), and §13.4 states that adding Bb/Eb/Db "would give coverage across all 12 chromatic pitch classes" — which only works from a base of 9. So "8" is an isolated slip; every conclusion drawn from it is still correct.
- **Ruling:**

### 22. §13.3 says 9 solfeggio frequencies; the catalog has 10
- **Category:** catalog
- **Location:** Doc §13.3 (Solfeggio-to-Key Compatibility Matrix) / `sound_meta.dart:263–352`, `assets/audio/frequencies/`
- **Doc says:** "The **9** solfeggio frequencies land on these pitch classes: F, Db, G, Ab, C, Eb, F#, Ab, B." The matrix table below it then lists 9 rows: 174, 285, 396, 417, 528, 639, 741, 852, 963.
- **Code says:** `kSoundCatalog` has **10** `frequencies` entries — the 9 listed plus **432 Hz** (`sound_meta.dart:299–307`), with `432_hz.mp3` present on disk and `432` offered in the tone test screen's solfeggio chips (`tone_test_screen.dart:41–43`). 432 Hz is a real, selectable frequency that the compatibility matrix silently omits, so §13.3's gap analysis and the "good solfeggio matches" column of §13.2 are both computed over an incomplete set. (Doc §3 and §5.3 both correctly say 10.)
- **Ruling:**

### 23. §13.9 names a file that doesn't exist (`mood_profiles.dart`)
- **Category:** architecture
- **Location:** Doc §13.9 (Workflow for Integration), step 3 / `lib/models/mood_profile.dart`
- **Doc says:** "Add mood profiles to `kMoodProfiles` in `mood_profiles.dart`"
- **Code says:** The file is `lib/models/mood_profile.dart` — singular. §3 and §5.5 both spell it correctly; only the §13.9 checklist step is wrong. Minor, but §13.9 is written as a follow-this-literally integration checklist.
- **Ruling:**

### 24. `sound_meta.dart` header comment says 33 sounds; there are 43
- **Category:** intra-code
- **Location:** `sound_meta.dart:34–36`
- **Comment says:** `// Full sound catalog (33 sounds)`
- **Code says:** `kSoundCatalog` contains **43** entries: 5 nature + 5 available noise + 8 coming-soon noise + 5 binaural + 10 frequencies + 10 soundscapes. 33 is the pre-soundscape count (43 − 10), matching the "(33 original + 10 soundscapes)" phrasing in doc §5.5 — the comment was not updated when soundscapes were added. **The doc is right here and the code comment is wrong**, which is the reverse of most entries in this report.
- **Ruling:**

### 25. `generateMix` docstring lists hardcoded volumes the code now reads from Remote Config
- **Category:** intra-code
- **Location:** `mood_engine.dart:28–33` vs. `mood_engine.dart:205, 249–285`
- **Docstring says:**
  ```
  /// Returns 3–5 sounds for the given mood:
  ///   • 1 soundscape  (always selected)                        → vol 0.55
  ///   • 1 nature      (always selected)                        → vol 0.35
  ///   • 1 noise color (always selected)                        → vol 0.30
  ///   • 1 binaural    (skipped if best distance > 1.2)         → vol 0.35
  ///   • 1 frequency   (skipped if best distance > 1.2)         → vol 0.30
  ```
- **Code says:** Every one of those five volumes is now `rc.getDouble('..._volume')`. The values quoted are only the `main.dart` defaults. Notably, the docstring on `_selectByCategory` 170 lines below (`mood_engine.dart:192–201`) **was** updated and correctly says "volumes from Remote Config" — so the two docstrings in the same file now contradict each other. The "3–5 sounds" and "> 1.2" parts of the docstring are accurate (`_maxDist = 1.2`, line 24).
- **Ruling:**

### 26. `findBinauralCarrier` docstring omits the parameter and range branch the function has
- **Category:** intra-code
- **Location:** `harmonic_matcher.dart:143–154` vs. `harmonic_matcher.dart:156, 183–189`
- **Docstring says:** "...then octave-transposes the result into the **80–300 Hz** felt-bass range" and "Among valid octave candidates (**80–300 Hz**), the one furthest ... is preferred". No mention of `beatFrequencyHz`.
- **Code says:** The signature takes `{double? beatFrequencyHz}`, and lines 186–189 select `rangeMin/rangeMax/fallbackMid` of **200/400/300** instead of 80/300/190 whenever `beatFrequencyHz >= 15.0`. There *is* an explanatory comment for the branch at lines 183–185, so the behavior is documented locally — but the function's own docstring still describes only the pre-change behavior. Same root cause as #9.
- **Ruling:**

### 27. `_loadWaypoint` docstring claims layers are added at volume 0; sample layers are added at 0.7
- **Category:** intra-code
- **Location:** `journey_engine.dart:150–151` and `:204` vs. `audio_engine.dart:130`
- **Comments say:** "/// Preloads all source layers from [waypoint] into the engine **at volume 0**. Actual volumes are ramped up by [_applyInterpolation] via [_startupRamp]." and, at the end of the loop, "// Volume intentionally left at 0; _applyInterpolation handles the ramp."
- **Code says:** True for `ToneSource` and `BinauralSource` — both pass `volume: 0.0` explicitly (lines 171, 182). **Not true for `SoundscapeSource` or `SampleSource`**: both call `_engine!.addLayer(path, name)` (lines 158, 164), which internally kicks off `_startFade(layer, 0.7, 1500ms)` (`audio_engine.dart:130`). So sample and soundscape layers begin fading toward 0.7 immediately, and are only reined in when the first `_applyInterpolation` tick calls `setVolume` (which cancels the fade) up to 200ms later. Audible impact is probably small and bounded by the startup ramp, but the comments describe an invariant the code does not hold.
- **Ruling:**

### 28. Known Issue "beta/gamma carrier range not wired in" — STILL OPEN, confirmed
- **Category:** known-issue
- **Location:** Doc §11 (Known Issues) + §12 phase 10 / `mood_engine.dart:99–102`, `tone_test_screen.dart:52–53`
- **Doc says:** "Beta/gamma carrier range: beatFrequencyHz parameter exists but is not yet passed from mood_engine.dart call site — carriers still default to 80-300 Hz range for all beat types until wired in"
- **Code says:** **Accurate — still open.** `mood_engine.dart:100–102` calls `HarmonicMatcher.findBinauralCarrier(soundscapeRootHz, solfeggioFreq)` with no `beatFrequencyHz`, even though the beat frequency is available two lines away as `p.$2` and is used immediately after at line 106. The `highBeat` branch is therefore dead code in production. The second call site, `tone_test_screen.dart:52`, also omits it — so the developer harmonic-matcher screen cannot exercise the branch either. Phase 10 in §12 still correctly lists this as pending.
- **Ruling:**

### 29. Known Issue "curated journeys still use SampleSource" — STILL OPEN, confirmed
- **Category:** known-issue
- **Location:** Doc §11 (Known Issues) + §9 note + §12 phase 11 / `journey_screen.dart:18–248`
- **Doc says:** "Curated journeys still use old SampleSource MP3 references — need migration to SoundscapeSource + ToneSource + BinauralSource" and, in §9, "These journeys use SampleSource references to MP3 files and do not include motifs."
- **Code says:** **Accurate — still open.** All 5 journeys in `_kJourneys` use `SampleSource` exclusively across all 20 waypoints; there is no `SoundscapeSource`, `ToneSource`, `BinauralSource`, or `MotifSource` anywhere in `journey_screen.dart`. Binaural and solfeggio layers are still MP3 playback (`assets/audio/binaural/delta.mp3`, `assets/audio/frequencies/417_hz.mp3`, etc.). `_JourneyCard._layerNames` (line 827) filters `.whereType<SampleSource>()`, so the UI would silently show no layer chips for any migrated journey — worth noting for whoever does phase 11.
- **Ruling:**

---

## Unverified Claims

Doc claims that could not be checked against source, assets, or repo state. None of these are flagged as discrepancies — they are simply outside what a code audit can settle.

| # | Doc location | Claim | Why unverified |
|---|---|---|---|
| U1 | §2, §11 Known Issues | "Chrome web audio: pitch-shifting via setSpeed() causes audible warbling artifacts — Chrome-specific, absent on mobile" | Runtime browser behavior; requires listening on Chrome vs. a device. **Precondition confirmed:** `setSpeed()` is still the pitch-shift mechanism at `audio_engine.dart:231` and `motif_engine.dart:82`, and the `setPitchShift` TODO to migrate to SoLoud (`audio_engine.dart:223–224`) is still present — so nothing has changed that would have resolved it. |
| U2 | §2 | "Chrome web audio: crossfade may not trigger reliably"; "Slight volume dip at loop points on web" | Runtime behavior. Note the equal-power crossfade landed since (`audio_engine.dart:299–305`), which §11 says was done specifically to address the dip — whether it worked on web is untested here. |
| U3 | §2 | "Claude Code output token limit: 32000 default"; "Windows Developer Mode must be enabled for flutter_soloud"; "M4 Mac available for iOS builds" | Development-environment facts, not repo state. |
| U4 | §6, §13.7 | Soundscapes "exported from Ableton at 44100 Hz / 16-bit / MP3"; all mastering specs (−14 LUFS integrated, −1.0 dBTP, A=440 tuning within ±5 cents, seamless loop points, no embedded sine content) | Requires audio-file analysis of the MP3 binaries; not performed. §13.2's "Not normalized" claims for nature/noise are likewise unverifiable from source. |
| U5 | §11, §12 phase 1 | "Android Studio + emulator setup, full validation (confirmed Chrome artifacts are browser-only)" | Historical activity; no artifact in the repo attests to it. |
| U6 | §1, §10, §12 (phases 8–16), §14 | Product positioning, week-by-week milestone history, future roadmap, Tier 2 "Plant Radio" design | Forward-looking or historical; no implementation to compare against. §14's `StreamSource` correctly does not exist yet. |
| U7 | §13.5, §13.6 | Motif/noise content that is "needed" or "planned" | Describes content not yet created; absence is expected, not a discrepancy. |

---

## Verification notes

Claims checked and found **correct**, recorded here so they aren't re-audited:

- **§4.7 LLM Service** — endpoint, model `claude-sonnet-4-20250514`, `max_tokens: 100`, 10s timeout, markdown-fence stripping, null-on-any-failure, `.env` via dotenv, SnackBar fallback (`home_screen.dart:131–137`). `.env` is gitignored (`.gitignore:14`) and untracked — confirmed via `git ls-files`.
- **§6 soundscape table** — all 10 rows (filename, key, root Hz, tags) match `sound_meta.dart:355–454` exactly. All 10 MP3s present.
- **§9 curated journeys** — all 5 verified against `journey_screen.dart`: names, categories, durations (45/60/30/90/20 min), 4 waypoints each with even weight 1.0 and easeInOut, and each described volume arc (delta→0, 417 Hz descending 0.4→0.1, ocean 0.35→0.15→0.3→0.4, 741 Hz→0).
- **§4.1 / §8 timing constants** — crossfade 3s starting 3.5s before loop point (`_xfadeDuration` 3s + `_xfadeBuffer` 500ms), removeLayer 1s, journey startup ramp 2s, library preview 1.5s in / 0.5s out (30 and 10 × 50ms steps), preset load 2s swell, 200ms tick, 0.005 removal threshold, `maxLayers = 5`.
- **§4.4 harmonic scoring & carrier placement** — 60/40 mood/harmonic blend, 1.0/0.9/0.8/0.7/0.3 consonance scores, `_maxDist = 1.2`, solfeggio-resolved-first ordering, 150/200 Hz fallback carriers, and the delta/theta/alpha/beta/gamma → 2/6/10/20/40 Hz beat map.
- **§4.5 findBestMatch** — 7 intervals `[0,3,4,5,7,9,12]` with matching names, ±6 semitone folding.
- **§4.6 MotifEngine** — prime cycles `[13,17,19,23,29,31,37,41,43]`, volume = defaultVolume × masterVolume × random(0.8–1.0), one-shot playback, random first-fire offset, `await stop()` inside `start()`, and the `abandon()`-doesn't-call-`motifEngine.stop()` race fix (`journey_engine.dart:93–104`).
- **§5.1 / §5.6** — SoundSource hierarchy and SavedMix fields match exactly.
- **§7** — 4 tabs, IndexedStack, #1C1C1C / #D4A017, GlobalKey library refresh, `abandon()` on slider drag (`mixer_screen.dart:497–500`) and on X (`:120–122`), long-press → ToneTestScreen with all 4 documented sections.
- **§11 completed items** — Firebase Analytics/Crashlytics/Remote Config wiring, RC → MoodEngine (5 volumes + 4 densities), debounced `addPostFrameCallback` setState in all 3 listeners, equal-power cos/sin crossfade.
- **§13.10** — "29 files" to normalize = 5 nature + 5 noise + 10 soundscapes + 9 motifs. Correct.
- **§15 key commits** — `e660b16`, `c896bfc`, `4ca7132` all exist with the stated subjects.
- **§2 web setup** — two flutter_soloud script tags present at `web/index.html:36–37`.
