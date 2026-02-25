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
    final shift = semitonesBetween(soundscapeRootHz, targetHz);
    return pow(2.0, shift / 12.0).toDouble();
  }
}
