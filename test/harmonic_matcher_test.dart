// Table-driven tests for HarmonicMatcher — the crown jewel.
//
// Every expected value below is derived independently from music theory
// (12-tone equal temperament, A4 = 440 Hz = MIDI 69), NOT by running the code
// and copying its output. Hz literals are standard equal-temperament table
// values; values involving 528 Hz were hand-computed from log2(528/440).
//
// If a test here fails, do not "fix" the expectation to match the code —
// treat it as a potential bug in harmonic_matcher.dart and record a ruling.

import 'package:flutter_test/flutter_test.dart';
import 'package:noisy_app/services/harmonic_matcher.dart';

// Equal-temperament reference pitches (Hz).
const c2 = 65.4064;
const e2 = 82.4069;
const a2 = 110.0;
const g2 = 97.9989;
const f2 = 87.3071;
const c3 = 130.8128;
const d3 = 146.8324;
const e3 = 164.8138;
const f3 = 174.6141;
const g3 = 195.9977;
const a3 = 220.0;
const b3 = 246.9417;
const c4 = 261.6256;
const cs4 = 277.1826;
const d4 = 293.6648;
const ds4 = 311.1270;
const e4 = 329.6276;
const f4 = 349.2282;
const fs4 = 369.9944;
const g4 = 391.9954;
const a4 = 440.0;
const as4 = 466.1638;
const b4 = 493.8833;
const c5 = 523.2511;
const d5 = 587.3295;
const e5 = 659.2551;

const hzTol = 0.01;
// Semitones. 0.01 cent — the Hz literals above carry 4 decimals, which alone
// contributes up to ~7e-6 st of input rounding.
const stTol = 1e-4;
const ratioTol = 1e-6;

// 2^(1/12) and its inverse — one equal-tempered semitone.
const semitoneUp = 1.0594631;
const semitoneDown = 0.9438743;

void main() {
  group('frequencyToMidi', () {
    const cases = <(double hz, double midi)>[
      (440.0, 69),
      (261.63, 60), // middle C, rounded as commonly quoted
      (220.0, 57),
      (880.0, 81),
      (27.5, 21), // A0, lowest piano key
      (4186.01, 108), // C8, highest piano key
      (g4, 67),
    ];
    for (final (hz, midi) in cases) {
      test('$hz Hz → MIDI $midi', () {
        expect(HarmonicMatcher.frequencyToMidi(hz), closeTo(midi, 0.01));
      });
    }
  });

  group('midiToFrequency', () {
    const cases = <(double midi, double hz)>[
      (69, 440.0),
      (60, c4),
      (57, 220.0),
      (81, 880.0),
      (21, 27.5),
      (67, g4),
      (43, g2),
    ];
    for (final (midi, hz) in cases) {
      test('MIDI $midi → $hz Hz', () {
        expect(HarmonicMatcher.midiToFrequency(midi), closeTo(hz, hzTol));
      });
    }
  });

  group('frequency ↔ MIDI round trip', () {
    const freqs = [
      20.0, 27.5, 55.0, 100.0, 174.0, 261.63, 396.0, 432.0, 528.0, 963.0,
      1000.0, 4186.01, 10000.0, 20000.0,
    ];
    for (final hz in freqs) {
      test('$hz Hz survives Hz → MIDI → Hz', () {
        final back = HarmonicMatcher.midiToFrequency(
            HarmonicMatcher.frequencyToMidi(hz));
        expect(back, closeTo(hz, hz * 1e-9));
      });
    }

    test('every integer MIDI note 0..127 survives MIDI → Hz → MIDI', () {
      for (var m = 0; m <= 127; m++) {
        final back = HarmonicMatcher.frequencyToMidi(
            HarmonicMatcher.midiToFrequency(m.toDouble()));
        expect(back, closeTo(m.toDouble(), 1e-9), reason: 'MIDI $m');
      }
    });
  });

  group('semitonesBetween', () {
    // (from, to, expected shortest signed path around the pitch circle)
    const cases = <(String label, double a, double b, double st)>[
      ('C4 → D4 is +2', c4, d4, 2),
      ('D4 → C4 is −2', d4, c4, -2),
      ('C4 → E4 is +4', c4, e4, 4),
      ('E4 → C4 is −4', e4, c4, -4),
      ('C4 → G4 (up a 5th) folds to −5', c4, g4, -5),
      ('G4 → C4 (down a 5th) folds to +5', g4, c4, 5),
      ('C4 → A4 (up a 6th) folds to −3', c4, a4, -3),
      ('C4 → D5 (a 9th) folds to +2', c4, d5, 2),
      ('C4 → G2 (down 17) folds to −5', c4, g2, -5),
      ('A3 → A4 (octave) is 0', a3, a4, 0),
      ('A4 → A3 (octave down) is 0', a4, a3, 0),
      ('A2 → A4 (two octaves) is 0', a2, a4, 0),
      ('unison is 0', c4, c4, 0),
    ];
    for (final (label, a, b, st) in cases) {
      test(label, () {
        expect(HarmonicMatcher.semitonesBetween(a, b), closeTo(st, stTol));
      });
    }

    test('tritone sits on the ±6 fold boundary', () {
      expect(HarmonicMatcher.semitonesBetween(c4, fs4).abs(), closeTo(6, stTol));
      expect(HarmonicMatcher.semitonesBetween(fs4, c4).abs(), closeTo(6, stTol));
    });

    test('result always lies within [−6, +6]', () {
      for (var m = 0; m < 48; m++) {
        final hz = HarmonicMatcher.midiToFrequency(36.0 + m + 0.37);
        final st = HarmonicMatcher.semitonesBetween(c4, hz);
        expect(st, inInclusiveRange(-6.0, 6.0), reason: 'target $hz Hz');
      }
    });
  });

  group('harmonicCompatibility (root C4)', () {
    const cases = <(String label, double target, double score)>[
      ('unison C4', c4, 1.0),
      ('octave C5', c5, 1.0),
      ('octave below C3', c3, 1.0),
      ('perfect 5th G4', g4, 0.9),
      ('major 3rd E4', e4, 0.8),
      ('minor 3rd D#4/Eb4', ds4, 0.7),
      ('major 2nd D4 → other', d4, 0.3),
      ('tritone F#4 → other', fs4, 0.3),
      ('perfect 4th F4 → other', f4, 0.3),
      ('major 6th A4 → other', a4, 0.3),
      ('major 7th B4 → other', b4, 0.3),
      ('528 Hz is ~C5 + 0.16 st → unison', 528.0, 1.0),
    ];
    for (final (label, target, score) in cases) {
      test(label, () {
        expect(HarmonicMatcher.harmonicCompatibility(c4, target), score);
      });
    }

    test('target below root folds upward (G4 root, C4 target = 4th → 0.3)', () {
      expect(HarmonicMatcher.harmonicCompatibility(g4, c4), 0.3);
    });
    test('target a 5th above a non-C root (A3 → E4 → 0.9)', () {
      expect(HarmonicMatcher.harmonicCompatibility(a3, e4), 0.9);
    });
  });

  group('findBestMatch', () {
    // Least-shift reasoning: let d = pitch class of target above root. For each
    // consonant interval I ∈ {0,3,4,5,7,9,12} the required shift is d − I
    // folded to ±6; the smallest |shift| wins.
    const cases = <(
      String label,
      double root,
      double target,
      String interval,
      double shift,
      double ratio,
      double resultHz,
    )>[
      ('C4 + G4: already a 5th', c4, g4, '5th', 0, 1.0, c4),
      ('C4 + E5: already a major 3rd (octave-folded)', c4, e5, 'major 3rd', 0,
          1.0, c4),
      ('C4 + C#4: d=1 → unison, +1 st', c4, cs4, 'unison', 1, semitoneUp, cs4),
      ('C4 + D4: d=2 → minor 3rd, −1 st (B3–D4)', c4, d4, 'minor 3rd', -1,
          semitoneDown, b3),
      ('C4 + Bb4: d=10 → 6th, +1 st (C#4–Bb4)', c4, as4, '6th', 1, semitoneUp,
          cs4),
      ('C4 + B4: d=11 → unison, −1 st', c4, b4, 'unison', -1, semitoneDown, b3),
      ('D4 + C5: d=10 → 6th, +1 st (D#4–C5)', d4, c5, '6th', 1, semitoneUp,
          ds4),
      ('C5 + C4: target below root → unison, no shift', c5, c4, 'unison', 0,
          1.0, c5),
      // 528 Hz is 15.1564 st above A3 → d = 3.1564. Minor 3rd needs +0.1564 st.
      // Required root = 528 / 2^(3/12) / 2 = 221.9967 Hz; ratio = 221.9967/220.
      ('A3 + 528 Hz: minor 3rd, +0.1564 st', a3, 528.0, 'minor 3rd', 0.156413,
          1.0090758, 221.9967),
    ];
    for (final (label, root, target, interval, shift, ratio, resultHz)
        in cases) {
      test(label, () {
        final m = HarmonicMatcher.findBestMatch(root, target);
        expect(m.intervalName, interval);
        expect(m.shiftSemitones, closeTo(shift, 1e-5));
        expect(m.shiftRatio, closeTo(ratio, 1e-6));
        expect(m.resultingRootHz, closeTo(resultHz, hzTol));
      });
    }

    test('never shifts more than 1.5 st (max gap in the consonant set)', () {
      // Consonant pitch classes {0,3,4,5,7,9}: the widest gap is 3 (0→3,
      // 9→12), so the least shift is at most 1.5 semitones.
      for (var i = 0; i < 120; i++) {
        final target = HarmonicMatcher.midiToFrequency(48.0 + i * 0.2);
        final m = HarmonicMatcher.findBestMatch(c4, target);
        expect(m.shiftSemitones.abs(), lessThanOrEqualTo(1.5 + stTol),
            reason: 'target $target Hz');
        expect(m.shiftRatio, closeTo(m.resultingRootHz / c4, ratioTol));
      }
    });
  });

  group('findBinauralCarrier', () {
    // (label, root, solfeggio, beatHz, expected carrier Hz, degree name)
    const cases = <(
      String label,
      double root,
      double sol,
      double? beat,
      double carrier,
      String degree,
    )>[
      // ── D-012 worked example: C4 + 528 Hz (~C, near root) → carrier on G.
      // Octaves of G: 49 / 98 / 196 / 392 Hz.
      ('D-012: C4 + 528, no beat → 98 Hz (80–300, furthest from 528)', c4,
          528.0, null, g2, 'Perfect 5th'),
      ('D-012: C4 + 528, beta 20 Hz → 392 Hz (196 falls under 200 floor)', c4,
          528.0, 20.0, g4, 'Perfect 5th'),
      ('C4 + 528, gamma 40 Hz → 392 Hz', c4, 528.0, 40.0, g4, 'Perfect 5th'),
      ('C4 + 528, alpha 10 Hz stays in default window → 98 Hz', c4, 528.0,
          10.0, g2, 'Perfect 5th'),
      ('C4 + 528, beat exactly 15 Hz → high window → 392 Hz', c4, 528.0, 15.0,
          g4, 'Perfect 5th'),
      ('C4 + 528, beat 14.99 Hz → default window → 98 Hz', c4, 528.0, 14.99,
          g2, 'Perfect 5th'),

      // ── Near-root boundaries: degrees 1 and 11 also count as "near root".
      ('C4 + C#4 (degree 1) → 5th → 98 Hz', c4, cs4, null, g2, 'Perfect 5th'),
      // 417 Hz is 11.07 st above A3 → degree 11 → carrier on E.
      // Octaves of E: 41.2 / 82.4 / 164.8 / 329.6 Hz.
      ('A3 + 417 (degree 11) → 5th → 82.41 Hz', a3, 417.0, null, e2,
          'Perfect 5th'),
      ('A3 + 417, beta → 329.63 Hz', a3, 417.0, 20.0, e4, 'Perfect 5th'),
      // 174 Hz is 0.06 st below F3 → rounds to degree 0 → carrier on C.
      // In-window octaves 130.8 (−4.9 st from 174) and 261.6 (+7.1 st):
      // the upper one is further, so it wins.
      ('F3 + 174 (just flat of root) → 5th → 261.63 Hz (upper octave wins)',
          f3, 174.0, null, c4, 'Perfect 5th'),

      // ── Otherwise → carrier on the root.
      // 396 Hz is 7.18 st above C4 → degree 7 (near the 5th) → root.
      // Octaves of C: 65.4 / 130.8 / 261.6 / 523.3 Hz.
      ('C4 + 396 (near 5th) → root → 130.81 Hz', c4, 396.0, null, c3, 'Root'),
      ('C4 + 396, beta → 261.63 Hz', c4, 396.0, 20.0, c4, 'Root'),
      ('C4 + E4 (degree 4) → root → 130.81 Hz', c4, e4, null, c3, 'Root'),
      // Catalog roots cited in C-011, each + 528 Hz, re-derived by hand.
      // A4: 528 is degree 3 → root; octaves 55/110/220/440.
      ('A4 + 528 → root → 110 Hz', a4, 528.0, null, a2, 'Root'),
      ('A4 + 528, beta → 220 Hz (440 above 400 ceiling)', a4, 528.0, 20.0, a3,
          'Root'),
      // F4: 528 is degree 7 → root; octaves 43.7/87.3/174.6/349.2.
      ('F4 + 528 → root → 87.31 Hz', f4, 528.0, null, f2, 'Root'),
      ('F4 + 528, beta → 349.23 Hz', f4, 528.0, 20.0, f4, 'Root'),
      // D4: 528 is degree 10 → root; octaves 73.4/146.8/293.7/587.3.
      ('D4 + 528 → root → 146.83 Hz', d4, 528.0, null, d3, 'Root'),
      ('D4 + 528, beta → 293.66 Hz', d4, 528.0, 20.0, d4, 'Root'),
    ];
    for (final (label, root, sol, beat, carrier, degree) in cases) {
      test(label, () {
        final r = HarmonicMatcher.findBinauralCarrier(root, sol,
            beatFrequencyHz: beat);
        expect(r.degreeName, degree);
        expect(r.carrierHz, closeTo(carrier, hzTol));
      });
    }

    test('196 Hz boundary: G3 is just under the 200 Hz beta floor', () {
      expect(g3, lessThan(200.0));
      final r =
          HarmonicMatcher.findBinauralCarrier(c4, 528.0, beatFrequencyHz: 20);
      expect(r.carrierHz, isNot(closeTo(g3, hzTol)));
      expect(r.carrierHz, closeTo(g4, hzTol));
    });

    // The "no octave fits the window" fallback. By construction it cannot
    // trigger for any positive finite root: candidates are x, 2x, 4x, 8x with
    // x ∈ [40, 80]. The default window [80, 300] always contains 2x ∈ [80, 160].
    // The beta window [200, 400] spans a full octave; 4x ∈ [160, 320], and when
    // 4x < 200 then x < 50, so 8x ∈ [320, 400) ≤ 600 is a candidate. Hence the
    // fallback branch is unreachable — this sweep pins the window guarantee it
    // would otherwise provide.
    test('carrier always lands inside its window (fallback unreachable)', () {
      for (var i = 0; i < 480; i++) {
        final root = HarmonicMatcher.midiToFrequency(24.0 + i * 0.1);
        for (final sol in [174.0, 285.0, 396.0, 528.0, 639.0, 852.0]) {
          final lo =
              HarmonicMatcher.findBinauralCarrier(root, sol).carrierHz;
          expect(lo, inInclusiveRange(80.0, 300.0),
              reason: 'root $root, sol $sol, default');
          final hi = HarmonicMatcher.findBinauralCarrier(root, sol,
                  beatFrequencyHz: 20)
              .carrierHz;
          expect(hi, inInclusiveRange(200.0, 400.0),
              reason: 'root $root, sol $sol, beta');
        }
      }
    });

    test('fallbackCarrierHz has no effect on valid input', () {
      final r = HarmonicMatcher.findBinauralCarrier(c4, 528.0,
          beatFrequencyHz: 20, fallbackCarrierHz: 150.0);
      expect(r.carrierHz, closeTo(g4, hzTol));
      expect(r.degreeName, 'Perfect 5th');
    });
  });

  // ── Input guard (D-016) ──────────────────────────────────────────────────
  // Non-positive or non-finite frequencies must return a neutral result
  // promptly. Before the guard, a root ≤ 0 hung findBinauralCarrier forever
  // and NaN/infinity threw; the timeout makes a regression fail, not hang.
  group('input guard', () {
    const bad = <(String, double)>[
      ('0', 0.0),
      ('negative', -220.0),
      ('NaN', double.nan),
      ('+infinity', double.infinity),
      ('−infinity', double.negativeInfinity),
    ];
    const noHang = Timeout(Duration(seconds: 5));

    for (final (name, v) in bad) {
      test('findBestMatch: root $name → shift 0, ratio 1.0', () {
        final m = HarmonicMatcher.findBestMatch(v, 528.0);
        expect(m.shiftSemitones, 0.0);
        expect(m.shiftRatio, 1.0);
        expect(m.intervalName, 'none');
      }, timeout: noHang);

      test('findBestMatch: target $name → shift 0, ratio 1.0', () {
        final m = HarmonicMatcher.findBestMatch(c4, v);
        expect(m.shiftSemitones, 0.0);
        expect(m.shiftRatio, 1.0);
        expect(m.intervalName, 'none');
        expect(m.resultingRootHz, c4);
      }, timeout: noHang);

      test('shiftRatioForExactMatch: root/target $name → 1.0', () {
        expect(HarmonicMatcher.shiftRatioForExactMatch(v, 528.0), 1.0);
        expect(HarmonicMatcher.shiftRatioForExactMatch(c4, v), 1.0);
      }, timeout: noHang);

      test('harmonicCompatibility: root/solfeggio $name → 0.3', () {
        expect(HarmonicMatcher.harmonicCompatibility(v, 528.0), 0.3);
        expect(HarmonicMatcher.harmonicCompatibility(c4, v), 0.3);
      }, timeout: noHang);

      test('findBinauralCarrier: root $name → fixed default carrier', () {
        for (final beat in [null, 2.0, 20.0]) {
          final r = HarmonicMatcher.findBinauralCarrier(v, 528.0,
              beatFrequencyHz: beat);
          expect(r.carrierHz, HarmonicMatcher.defaultFallbackCarrierHz);
          expect(r.degreeName, 'Fixed');
        }
      }, timeout: noHang);

      test('findBinauralCarrier: solfeggio $name → caller fallback', () {
        final r = HarmonicMatcher.findBinauralCarrier(c4, v,
            beatFrequencyHz: 6.0, fallbackCarrierHz: 150.0);
        expect(r.carrierHz, 150.0);
        expect(r.degreeName, 'Fixed');
      }, timeout: noHang);
    }

    test('default fallback carrier (200 Hz) lies inside both windows', () {
      const f = HarmonicMatcher.defaultFallbackCarrierHz;
      expect(f, inInclusiveRange(80.0, 300.0));
      expect(f, inInclusiveRange(200.0, 400.0));
    });
  });
}
