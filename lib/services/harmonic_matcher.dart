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

  /// Finds a binaural carrier frequency placed on a consonant scale degree of
  /// [soundscapeRootHz] that avoids the degree occupied by [solfeggioHz],
  /// then octave-transposes the result into the 100–250 Hz felt-bass range.
  ///
  /// Returns the carrier frequency in Hz and a human-readable degree name.
  /// Degree selection priority: Perfect 5th → Perfect 4th → Major 3rd →
  /// Tonic → Major 6th → Minor 3rd.
  static ({double carrierHz, String degreeName}) findBinauralCarrier(
      double soundscapeRootHz, double solfeggioHz) {
    const degrees = [0, 3, 4, 5, 7, 9];
    const names = <int, String>{
      0: 'Tonic',
      3: 'Minor 3rd',
      4: 'Major 3rd',
      5: 'Perfect 4th',
      7: 'Perfect 5th',
      9: 'Major 6th',
    };
    const priority = [7, 5, 4, 0, 9, 3];

    // Interval of solfeggio relative to root, folded into [0, 12).
    double raw = frequencyToMidi(solfeggioHz) - frequencyToMidi(soundscapeRootHz);
    raw = raw % 12.0;
    if (raw < 0) raw += 12.0;

    // Round to nearest consonant degree (with wraparound at the octave).
    int solDegree = degrees.reduce((a, b) =>
        _circDist(raw, a.toDouble()) <= _circDist(raw, b.toDouble()) ? a : b);

    // Exclude the solfeggio's degree so the carrier doesn't clash.
    final candidates = degrees.where((d) => d != solDegree).toList();

    // Pick highest-priority available candidate.
    int chosen = candidates.first;
    for (final p in priority) {
      if (candidates.contains(p)) {
        chosen = p;
        break;
      }
    }

    // Frequency of chosen degree from the soundscape root.
    double hz = soundscapeRootHz * pow(2.0, chosen / 12.0);

    // Octave-transpose into 100–250 Hz (felt-bass range).
    var i = 0;
    while (hz > 250.0 && i < 8) { hz /= 2.0; i++; }
    i = 0;
    while (hz < 100.0 && i < 8) { hz *= 2.0; i++; }
    if (hz < 100.0 || hz > 250.0) hz = 150.0; // shouldn't happen

    return (carrierHz: hz, degreeName: '${names[chosen]!} from root');
  }

  // Circular distance between two values on a [0, 12) pitch-class circle.
  static double _circDist(double a, double b) {
    final d = (a - b).abs() % 12.0;
    return d > 6.0 ? 12.0 - d : d;
  }
}
