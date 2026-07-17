# CONTENT PRODUCTION

The production spec and asset registry for Noisy's audio content. Covers what exists, what to produce, and to what standard. The content pipeline is the business (external eval §4): selection algorithms are replicable; a catalog of well-produced, precisely-tuned sound is not.

**Last updated:** July 16, 2026
**Supersedes:** `content_production_checklist.md` and design doc v2.4 §13 (both archived)

> **⚠ Sequencing caveat — re-derive the target after SoLoud migration.**
> The full production target below (up to 144 soundscapes) is sized by a *technical constraint*: `setSpeed()` pitch-shifting degrades quality beyond a small number of semitones, so dense key coverage is needed. If the SoLoud migration delivers true pitch-shift-without-tempo-change with good quality across ±2–3 semitones, the required catalog may be **substantially smaller** (external eval §2 #2). **Do not commit to producing 144 soundscapes before the SoLoud migration is evaluated.** Produce Wave 1 (below), migrate, then re-derive scope.

---

## 1. Mastering Specifications (all content)

- **Loudness:** −14 LUFS integrated (measure with Youlean Loudness Meter or equivalent)
- **True peak:** −1.0 dBTP maximum
- **Sample rate:** 44100 Hz
- **Bit depth:** 24-bit master (FLAC), export MP3 at 192+ kbps for app assets
- **Tuning:** A = 440 Hz (critical — the harmonic math assumes it)

**Soundscapes additionally:**
- Root frequency precise to within ±5 cents of target
- Seamless loop points
- **No embedded sine waves, binaural beats, or solfeggio tones** — these are added by the app
- Pads/drones/textures, not strong melodic lines that compete with the solfeggio
- Wide but not extreme stereo; leave center space for the mono solfeggio tone

**Motifs additionally:**
- Clean attack, natural decay, silence at tail (one-shots, not loops)
- Tonal motifs: a clear, identifiable pitch (the harmonic matcher needs it)
- Duration ~0.5–4s (shorter for percussion, longer for sustained tones)

---

## 2. Naming Convention

- Soundscapes: `[descriptor]_[key]_[mode].mp3` — e.g. `midnight_bloom_bb_min.mp3`
- Tonal motifs: `[instrument]_[descriptor]_[key].mp3` — e.g. `kalimba_phrase_d.mp3`
- Atonal motifs: `[instrument]_[descriptor].mp3` — e.g. `rain_stick_pass.mp3`

---

## 3. Current Asset Registry (verified against code, July 2026)

*Corrected against `docs/audits/AUDIT_REPORT.md`. This is the ground-truth inventory.*

### Soundscapes (10) — 9 unique roots {F, D, G, Ab, A, C, E, F#, B}
| File | Key | Root Hz |
|---|---|---|
| warm_drift_f_maj | F major | 349.23 |
| deep_current_d_maj | D major | 293.66 |
| open_sky_g_maj | G major | 392.00 |
| soft_veil_ab_maj | Ab major | 415.30 |
| golden_haze_a_maj | A major | 440.00 |
| luminous_calm_c_maj | C major | 261.63 |
| bright_pulse_e_maj | E major | 329.63 |
| shadow_weave_fs_min | F# minor | 369.99 |
| still_waters_a_min | A minor | 440.00 |
| crystal_ascent_b_maj | B major | 493.88 |

**Missing roots:** Db, Eb, Bb. **Major/minor balance:** 8 major, 2 minor (minor underrepresented).

### Motifs (9) — *corrected per audit #19*
- **Tonal (6):** bowl_high_g (**G5**, 784 Hz), bowl_low_g (**G3**, 196 Hz), high_bell_b (B4, 493.9 Hz), low_bell_eb (**Eb3**, 155.6 Hz), piano_note_f (F4, 349.2 Hz), **triangle_e (E4, 329.6 Hz)** — *there is no "gong C3"*
- **Atonal (3):** gourd_percussion, vibe_chimes, wind_chimes
- *Motif tag assignments have open Bucket-C rulings (audit #14/#15) — see `ROADMAP.md`.*

### Nature (5) — not yet normalized
rain, ocean, wind, thunder, crickets

### Noise (5 available + 8 coming-soon)
- **Available:** white, pink, brown, blue, **red** (*not "yellow"* — audit #3)
- **Coming-soon (`isAvailable: false`):** yellow, gray, purple, green, orange, aquamarine, violet, black

### Frequencies (10) — *audit #22*
174, 285, 396, 417, 528, 639, 741, 852, 963 (solfeggio) **+ 432 Hz**

**Total catalog:** 43 entries, 35 available, 8 coming-soon.

---

## 4. Solfeggio-to-Key Compatibility (why key coverage matters)

The harmonic system scores soundscapes on how consonantly the solfeggio sits on the soundscape root (unison/P5/M3/m3 = good). More roots = better matches with less pitch-shifting. The weakest-covered solfeggio frequencies are **174 Hz (F)** and **285 Hz (Db)** — adding **Bb, Eb, Db** roots improves matching for 7 of the 9 solfeggio tones and completes all 12 chromatic pitch classes.

---

## 5. Production Plan

### Phase 1 — Normalize existing content *(do first; zero creative effort, immediate benefit)*
Normalize all **29** existing files (10 soundscapes + 9 motifs + 5 nature + 5 noise) to −14 LUFS / −1.0 dBTP. Makes programmatic volume mixing predictable.

### Wave 1 — Fill harmonic gaps + minor-mode balance
Highest-impact new production. **Produce this, then evaluate SoLoud migration before scaling further.**

| Priority | What | Count | Purpose |
|---|---|---|---|
| 1 | Soundscapes: Bb maj, Bb min, Eb maj, Eb min, Db maj | 5 | Fills gaps for 174/285/639 Hz; completes 12 pitch classes |
| 2 | Minor soundscapes: C min, D min, E min, G min, F min | 5 | Corrects the 8-major/2-minor imbalance; serves low-energy moods |
| 3 | Tonal motifs (kalimba, hang drum, bowed cymbal, vocal, etc.) | 10–15 | Timbre diversity — current 9 are bowl/bell-heavy |
| 4 | Atonal motifs (rain stick, stone click, shell rattle, etc.) | 8–12 | Percussion/texture variety |
| 5 | Remaining noise colors | 8 | Complete the palette |

### Wave 2+ — Scale (RE-DERIVE after SoLoud migration)
The v2.4 vision was 6 major + 6 minor per semitone = 144 soundscapes. **Treat this as provisional.** After the SoLoud migration, re-derive how many soundscapes are actually needed given the tolerable pitch-shift range. The same catalog may buy far more variety, or a much smaller catalog may suffice.

---

## 6. Nature Sound Targets (18 total: 5 existing + 13 new)

Vary along the energy axis within categories so the mood engine can match. Rain (light/moderate/heavy), flowing water (stream/river/waterfall), ocean (calm/waves), wind (breeze/gusts), birds (dawn chorus/single songbird), insects (crickets/cicadas), thunder (1), fire (campfire/fireplace), forest ambience (1).

---

## 7. Integration Workflow

*(Corrected per audit #23 — the file is `mood_profile.dart`, singular.)*

1. Place MP3s in the appropriate `assets/audio/` subdirectory
2. Add entries to `kSoundCatalog` in `sound_meta.dart` (rootFrequency, category, tags, `isAvailable`)
3. Add mood profiles to `kMoodProfiles` in `mood_profile.dart`
4. For motifs: add entries to `kMotifCatalog` in `motif_meta.dart`
5. Test generation across mood slider positions on **Android** (not Chrome)
6. Verify harmonic matching via the Tone Test screen (long-press "Noisy" title)
7. Listen for: clean pitch relationships, no dissonance between layers, balanced volumes

---

## 8. Positioning Note for Content

Per `PRODUCT_DESIGN.md` §2: the solfeggio/binaural framing is a **sonic/aesthetic** choice, not a therapeutic claim. Produce and describe content accordingly — the defensible story is "humanly crafted, harmonically coherent," not wellness numerology.
