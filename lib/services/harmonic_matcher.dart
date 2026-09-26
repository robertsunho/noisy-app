import 'dart:developer' as developer;
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// HarmonicMatch result
// ─────────────────────────────────────────────────────────────────────────────

class HarmonicMatch {
  /// Semitones to shift the soundscape (positive = up, negative = down).
  final double shiftSemitones;

  /// Playback speed ratio corresponding to [shiftSemitones].
  /// 1.0 = no shift; pow(2, semitones / 12).
  final double shiftRatio;

  /// Human-readable name of the consonant interval between the shifted
  /// soundscape root and the target frequency.
  final String intervalName;

  /// The soundscape root frequency (Hz) after applying [shiftRatio].
  final double resultingRootHz;

  const HarmonicMatch({
    required this.shiftSemitones,
    required this.shiftRatio,
    required this.intervalName,
    required this.resultingRootHz,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HarmonicMatcher
// ─────────────────────────────────────────────────────────────────────────────

class HarmonicMatcher {
  // Consonant intervals in semitones (interval = semitones from root to target).
  static const _intervals = [0, 3, 4, 5, 7, 9, 12];
  static const _intervalNames = [
    'unison',
    'minor 3rd',
    'major 3rd',
    '4th',
    '5th',
    '6th',
    'octave',
  ];

  /// Carrier returned by [findBinauralCarrier] for invalid input when the
  /// caller supplies no fallback. 200 Hz is the fixed carrier `MoodEngine`
  /// uses for alpha/beta/gamma, and lies inside both carrier windows.
  static const defaultFallbackCarrierHz = 200.0;

  // ── Input guard (D-016) ───────────────────────────────────────────────────

  /// A frequency the pitch math can handle: finite and strictly positive.
  /// A root ≤ 0 would send the octave-reduction loop in [findBinauralCarrier]
  /// into an infinite loop; NaN/infinity throw in `round()`.
  static bool _isValidHz(double hz) => hz.isFinite && hz > 0;

  /// Debug-only, non-throwing: logs invalid input at severe level so it stands
  /// out in the console. Compiled out of release builds. Deliberately not a
  /// throwing assert — see D-016.
  static void _reportInvalid(String method, Map<String, double> args) {
    assert(() {
      final bad = args.entries
          .where((e) => !_isValidHz(e.value))
          .map((e) => '${e.key}=${e.value}')
          .join(', ');
      developer.log(
        'HarmonicMatcher.$method: invalid frequency input ($bad) — '
        'returning neutral result',
        name: 'HarmonicMatcher',
        level: 1000,
      );
      return true;
    }());
  }

  // ── Core pitch math ───────────────────────────────────────────────────────

  /// Converts [hz] to a (fractional) MIDI note number.
  /// Formula: 69 + 12 * log₂(hz / 440).
  static double frequencyToMidi(double hz) {
    return 69.0 + 12.0 * log(hz / 440.0) / log(2.0);
  }

  /// Inverse of [frequencyToMidi]: converts a MIDI note number to Hz.
  /// Formula: 440 * 2^((midi − 69) / 12).
  static double midiToFrequency(double midi) {
    return 440.0 * pow(2.0, (midi - 69.0) / 12.0);
  }

  /// Returns the interval in semitones from [hzA] to [hzB], reduced to the
  /// range [−6, +6] via octave equivalence so we always find the shortest
  /// path around the pitch circle.
  static double semitonesBetween(double hzA, double hzB) {
    double raw = frequencyToMidi(hzB) - frequencyToMidi(hzA);
    raw = raw % 12.0; // fold into [0, 12)
    if (raw > 6.0) raw -= 12.0; // shift to (−6, +6]
    return raw;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Finds which consonant interval between [soundscapeRootHz] and [targetHz]
  /// requires the least pitch shifting, and returns a [HarmonicMatch]
  /// describing the optimal shift.
  ///
  /// For each candidate interval the method calculates the root the soundscape
  /// would need to be shifted to so that [targetHz] falls exactly at that
  /// interval above it, then measures the octave-reduced distance from the
  /// current root.  The interval with the smallest absolute shift wins.
  static HarmonicMatch findBestMatch(
      double soundscapeRootHz, double targetHz) {
    if (!_isValidHz(soundscapeRootHz) || !_isValidHz(targetHz)) {
      _reportInvalid('findBestMatch',
          {'soundscapeRootHz': soundscapeRootHz, 'targetHz': targetHz});
      return HarmonicMatch(
        shiftSemitones: 0.0,
        shiftRatio: 1.0,
        intervalName: 'none',
        resultingRootHz: soundscapeRootHz,
      );
    }

    double bestAbs = double.infinity;
    double bestShift = 0.0;
    int bestIdx = 0;

    for (int i = 0; i < _intervals.length; i++) {
      // Required root if target sits `interval` semitones above it.
      final requiredRootMidi =
          frequencyToMidi(targetHz) - _intervals[i].toDouble();
      final requiredRootHz = midiToFrequency(requiredRootMidi);

      // Octave-reduced shift from current root to required root.
      final shift = semitonesBetween(soundscapeRootHz, requiredRootHz);

      if (shift.abs() < bestAbs) {
        bestAbs = shift.abs();
        bestShift = shift;
        bestIdx = i;
      }
    }

    final ratio = pow(2.0, bestShift / 12.0).toDouble();
    return HarmonicMatch(
      shiftSemitones: bestShift,
      shiftRatio: ratio,
      intervalName: _intervalNames[bestIdx],
      resultingRootHz: soundscapeRootHz * ratio,
    );
  }

  /// Returns the playback speed ratio to shift [soundscapeRootHz] to the
  /// nearest octave of [targetHz] (unison relationship only).
  static double shiftRatioForExactMatch(
      double soundscapeRootHz, double targetHz) {
    if (!_isValidHz(soundscapeRootHz) || !_isValidHz(targetHz)) {
      _reportInvalid('shiftRatioForExactMatch',
          {'soundscapeRootHz': soundscapeRootHz, 'targetHz': targetHz});
      return 1.0;
    }
    final shift = semitonesBetween(soundscapeRootHz, targetHz);
    return pow(2.0, shift / 12.0).toDouble();
  }

  /// Scores how consonant [solfeggioHz] sits relative to [soundscapeRootHz].
  ///
  /// Computes the interval in semitones (octave-folded to 0–11), then maps:
  ///   0  (unison / octave) → 1.0
  ///   7  (perfect 5th)     → 0.9
  ///   4  (major 3rd)       → 0.8
  ///   3  (minor 3rd)       → 0.7
  ///   all other intervals  → 0.3
  ///
  /// Invalid input (≤ 0 or non-finite) scores 0.3 — the same neutral score
  /// `MoodEngine` gives a soundscape with no root frequency.
  static double harmonicCompatibility(
      double soundscapeRootHz, double solfeggioHz) {
    if (!_isValidHz(soundscapeRootHz) || !_isValidHz(solfeggioHz)) {
      _reportInvalid('harmonicCompatibility',
          {'soundscapeRootHz': soundscapeRootHz, 'solfeggioHz': solfeggioHz});
      return 0.3;
    }
    double raw = frequencyToMidi(solfeggioHz) - frequencyToMidi(soundscapeRootHz);
    raw = raw % 12.0;
    if (raw < 0) raw += 12.0;
    final degree = raw.round() % 12;
    switch (degree) {
      case 0: return 1.0;
      case 7: return 0.9;
      case 4: return 0.8;
      case 3: return 0.7;
      default: return 0.3;
    }
  }

  /// Finds a binaural carrier frequency placed on a consonant scale degree of
  /// [soundscapeRootHz] that forms a stable triad voicing with [solfeggioHz],
  /// then octave-transposes the result into a felt-bass range.
  ///
  /// The target range depends on the optional [beatFrequencyHz]: 80–300 Hz by
  /// default, or 200–400 Hz for beta/gamma beats ([beatFrequencyHz] ≥ 15 Hz),
  /// where a higher carrier makes the faster beat read as a single beating tone
  /// rather than two distinct pitches. If no octave lands in range, the carrier
  /// falls back to the octave nearest the range midpoint (190 Hz default,
  /// 300 Hz for beta/gamma).
  ///
  /// Degree selection:
  ///   • solfeggio near root (±1 st)  → carrier = Perfect 5th (degree 7)
  ///   • solfeggio near 5th  (±1 st)  → carrier = Root (degree 0)
  ///   • otherwise                    → carrier = Root (degree 0)
  ///
  /// Among valid octave candidates in range, the one furthest in actual
  /// (non-octave-folded) semitones from the solfeggio is preferred so the
  /// carrier does not crowd the melodic layer.
  ///
  /// Invalid input (≤ 0 or non-finite root or solfeggio) returns
  /// [fallbackCarrierHz] (default [defaultFallbackCarrierHz]) with degree name
  /// `'Fixed'` — the same fixed carrier `MoodEngine` uses when no
  /// soundscape/solfeggio pair exists. See D-016.
  static ({double carrierHz, String degreeName}) findBinauralCarrier(
      double soundscapeRootHz, double solfeggioHz,
      {double? beatFrequencyHz, double? fallbackCarrierHz}) {
    if (!_isValidHz(soundscapeRootHz) || !_isValidHz(solfeggioHz)) {
      _reportInvalid('findBinauralCarrier',
          {'soundscapeRootHz': soundscapeRootHz, 'solfeggioHz': solfeggioHz});
      return (
        carrierHz: fallbackCarrierHz ?? defaultFallbackCarrierHz,
        degreeName: 'Fixed',
      );
    }

    // Solfeggio scale degree relative to root, folded into [0, 12).
    double raw = frequencyToMidi(solfeggioHz) - frequencyToMidi(soundscapeRootHz);
    raw = raw % 12.0;
    if (raw < 0) raw += 12.0;
    final solDegree = raw.round() % 12;

    // Near root = degrees {11, 0, 1}; otherwise → carrier on root.
    final bool nearRoot = solDegree <= 1 || solDegree >= 11;
    final int chosenDegree = nearRoot ? 7 : 0;
    final String degreeName = nearRoot ? 'Perfect 5th' : 'Root';

    // Base carrier frequency from soundscape root at chosen degree.
    final double baseHz = soundscapeRootHz * pow(2.0, chosenDegree / 12.0);

    // Build all octave transpositions of baseHz starting from the [40, 80) band.
    double hz = baseHz;
    while (hz > 80) { hz /= 2; }
    while (hz < 40) { hz *= 2; }
    // hz is now in [40, 80)

    final candidates = <double>[];
    while (hz <= 600) {
      candidates.add(hz);
      hz *= 2;
    }

    // Beta/gamma beats (≥15 Hz) sound better with a higher carrier (200-400 Hz)
    // because a 20-40 Hz beat is a smaller musical interval at higher frequencies,
    // producing a more natural beating tone rather than two distinct pitches.
    final bool highBeat = beatFrequencyHz != null && beatFrequencyHz >= 15.0;
    final double rangeMin = highBeat ? 200.0 : 80.0;
    final double rangeMax = highBeat ? 400.0 : 300.0;
    final double fallbackMid = highBeat ? 300.0 : 190.0;

    final validCandidates = candidates.where((c) => c >= rangeMin && c <= rangeMax).toList();

    final double carrierHz;
    if (validCandidates.isEmpty) {
      // Fall back to octave closest to range midpoint.
      carrierHz = candidates.isEmpty
          ? fallbackMid
          : candidates.reduce((a, b) =>
              (a - fallbackMid).abs() < (b - fallbackMid).abs() ? a : b);
    } else if (validCandidates.length == 1) {
      carrierHz = validCandidates.first;
    } else {
      // Prefer the candidate furthest in actual semitones from solfeggio
      // (non-octave-folded distance) to avoid crowding the melodic layer.
      carrierHz = validCandidates.reduce((a, b) {
        final distA = (frequencyToMidi(a) - frequencyToMidi(solfeggioHz)).abs();
        final distB = (frequencyToMidi(b) - frequencyToMidi(solfeggioHz)).abs();
        return distA >= distB ? a : b;
      });
    }

    return (carrierHz: carrierHz, degreeName: degreeName);
  }
}
