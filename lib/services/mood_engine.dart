import 'dart:math';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/mood_profile.dart';
import '../models/motif_meta.dart';
import '../models/sound_meta.dart';
import 'harmonic_matcher.dart';

class SoundRecommendation {
  final SoundMeta meta;
  final double volume;
  final double distance;

  const SoundRecommendation({
    required this.meta,
    required this.volume,
    required this.distance,
  });
}

class MoodEngine {
  /// Maximum acceptable distance before a category is skipped.
  static const _maxDist = 1.2;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns 3–5 sounds for the given mood:
  ///   • 1 soundscape  (always selected)
  ///   • 1 nature      (always selected)
  ///   • 1 noise color (always selected)
  ///   • 1 binaural    (skipped if best distance > 1.2)
  ///   • 1 frequency   (skipped if best distance > 1.2)
  ///
  /// Per-layer volumes are read from Remote Config (`soundscape_volume`,
  /// `nature_volume`, `noise_volume`, `binaural_volume`, `frequency_volume`)
  /// with in-code defaults — not hardcoded here.
  List<SoundRecommendation> generateMix(
      double energy, double focus, double warmth) {
    return _selectByCategory(energy, focus, warmth);
  }

  /// Maps binaural catalog IDs to (centerFrequency, beatFrequency) parameters.
  static const _binauralParams = <String, (double, double)>{
    'delta': (150.0, 2.0),
    'theta': (150.0, 6.0),
    'alpha': (200.0, 10.0),
    'beta':  (200.0, 20.0),
    'gamma': (200.0, 40.0),
  };

  /// Parses the frequency from a solfeggio ID like "528_hz" → 528.0.
  static double? _parseFrequency(String id) {
    final match = RegExp(r'^(\d+)_hz$').firstMatch(id);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  /// Creates a 3-waypoint [Journey] whose mix is tuned to the requested mood.
  ///
  /// Binaural and frequency sounds are emitted as [BinauralSource] /
  /// [ToneSource] so they are played as real oscillators via SoLoud rather
  /// than as pre-recorded MP3 files.
  Journey generateJourney(
      double energy, double focus, double warmth, Duration duration) {
    final recs = generateMix(energy, focus, warmth);
    final category = _inferCategory(energy, focus, warmth);

    // Solfeggio tone frequency (if present in the mix).
    final solfeggioFreq = recs
        .where((r) => r.meta.category == 'frequencies')
        .map((r) => _parseFrequency(r.meta.id))
        .where((f) => f != null)
        .cast<double>()
        .firstOrNull;

    // Soundscape root frequency (if present — used for key-aware binaural carrier).
    final soundscapeRootHz = recs
        .where((r) => r.meta.category == 'soundscape')
        .map((r) => r.meta.rootFrequency)
        .where((f) => f != null)
        .cast<double>()
        .firstOrNull;

    // Converts a recommendation to the appropriate SoundSource subtype.
    SoundSource toSource(SoundRecommendation r, double vol) {
      if (r.meta.category == 'soundscape') {
        final rootHz = r.meta.rootFrequency;
        double shiftRatio = 1.0;
        if (rootHz != null && solfeggioFreq != null) {
          shiftRatio = HarmonicMatcher.findBestMatch(rootHz, solfeggioFreq)
              .shiftRatio;
        }
        return SoundscapeSource(
          assetPath: r.meta.assetPath,
          volume: vol,
          pitchShiftRatio: shiftRatio,
          rootFrequency: rootHz ?? 440.0,
        );
      }
      if (r.meta.category == 'binaural') {
        final p = _binauralParams[r.meta.id];
        if (p != null) {
          final carrierHz = (soundscapeRootHz != null && solfeggioFreq != null)
              ? HarmonicMatcher.findBinauralCarrier(
                      soundscapeRootHz, solfeggioFreq,
                      beatFrequencyHz: p.$2)
                  .carrierHz
              : p.$1;
          return BinauralSource(
              centerFrequency: carrierHz,
              beatFrequency: p.$2,
              volume: vol);
        }
      }
      if (r.meta.category == 'frequencies') {
        final freq = _parseFrequency(r.meta.id);
        if (freq != null) return ToneSource(frequency: freq, volume: vol);
      }
      return SampleSource(assetPath: r.meta.assetPath, volume: vol);
    }

    final motifIds = _selectMotifPalette(category);
    final motifDensity = _inferMotifDensity(category);
    final wp2Density = category == 'Sleep' ? 0.1 : motifDensity;

    // Waypoint 0 — starting state
    final wp0 = JourneyWaypoint(
      layers: [
        for (final r in recs) toSource(r, r.volume),
        if (motifIds.isNotEmpty)
          MotifSource(motifIds: motifIds, density: motifDensity, volume: 0.3),
      ],
    );

    // Waypoint 1 — slight mid-journey variation (alternating layers ±0.05)
    final wp1 = JourneyWaypoint(
      layers: [
        for (var i = 0; i < recs.length; i++)
          toSource(
            recs[i],
            (recs[i].volume + (i.isEven ? 0.05 : -0.05)).clamp(0.10, 0.70),
          ),
        if (motifIds.isNotEmpty)
          MotifSource(motifIds: motifIds, density: motifDensity, volume: 0.3),
      ],
      weight: 1.0,
      curve: EaseCurve.easeInOut,
    );

    // Waypoint 2 — settle back to original volumes (density reduced for sleep)
    final wp2 = JourneyWaypoint(
      layers: [
        for (final r in recs) toSource(r, r.volume),
        if (motifIds.isNotEmpty)
          MotifSource(motifIds: motifIds, density: wp2Density, volume: 0.3),
      ],
      weight: 1.0,
      curve: EaseCurve.easeInOut,
    );

    return Journey(
      id: 'mood_${DateTime.now().millisecondsSinceEpoch}',
      name: _journeyName(category),
      description: _journeyDescription(energy, focus, warmth),
      icon: _inferIcon(category),
      category: category,
      waypoints: [wp0, wp1, wp2],
      defaultDuration: duration,
      minDuration: const Duration(minutes: 5),
      maxDuration: const Duration(hours: 4),
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Selects up to 5 motifs whose tags match the journey category.
  static List<String> _selectMotifPalette(String category) {
    final tag = category.toLowerCase();
    return kMotifCatalog
        .where((m) => m.tags.contains(tag))
        .take(5)
        .map((m) => m.id)
        .toList();
  }

  /// Returns the motif trigger density [0, 1] for [category] from Remote Config.
  static double _inferMotifDensity(String category) {
    final rc = FirebaseRemoteConfig.instance;
    switch (category) {
      case 'Sleep':    return rc.getDouble('motif_density_sleep');
      case 'Energize': return rc.getDouble('motif_density_energize');
      case 'Focus':    return rc.getDouble('motif_density_focus');
      default:         return rc.getDouble('motif_density_relax');
    }
  }

  /// Builds the balanced mix with 5 category slots (volumes from Remote Config):
  ///   1. Best soundscape   (combined mood + harmonic score)
  ///   2. Best nature       (organic texture)
  ///   3. Best noise color  (dedicated noise slot)
  ///   4. Best binaural     (skip if distance > 1.2)
  ///   5. Best frequency    (skip if distance > 1.2)
  ///
  /// Soundscape selection uses a combined score when a solfeggio frequency is
  /// in the mix: 60% mood fit + 40% harmonic compatibility with the solfeggio.
  /// The solfeggio is resolved first so it can inform the soundscape choice.
  List<SoundRecommendation> _selectByCategory(
      double energy, double focus, double warmth) {
    const maxPossibleDist = 1.732; // sqrt(3) — max Euclidean distance in unit cube
    final rc = FirebaseRemoteConfig.instance;

    final all = kSoundCatalog
        .where((s) => s.isAvailable && kMoodProfiles.containsKey(s.id))
        .map((s) {
          final p = kMoodProfiles[s.id]!;
          return (s, _dist(energy, focus, warmth, p.energy, p.focus, p.warmth));
        })
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));

    List<(SoundMeta, double)> ofCat(String cat) =>
        all.where((e) => e.$1.category == cat).toList();

    final soundscapes = ofCat('soundscape');
    final natures = ofCat('nature');
    final noises = ofCat('noise');
    final binaurals = ofCat('binaural');
    final frequencies = ofCat('frequencies');

    final result = <SoundRecommendation>[];

    // Step 1: Resolve solfeggio frequency BEFORE selecting the soundscape so
    // it can drive harmonic compatibility scoring.
    final bestFreq = frequencies.isNotEmpty ? frequencies.first : null;
    final double? solfeggioHz = (bestFreq != null && bestFreq.$2 <= _maxDist)
        ? _parseFrequency(bestFreq.$1.id)
        : null;

    // Step 2: Soundscape — combined mood + harmonic score when solfeggio known.
    if (soundscapes.isNotEmpty) {
      var best = soundscapes.first; // default: pure mood-distance winner
      if (solfeggioHz != null) {
        double computeScore((SoundMeta, double) e) {
          final moodScore = 1.0 - (e.$2 / maxPossibleDist).clamp(0.0, 1.0);
          final rootHz = e.$1.rootFrequency;
          final harmonicScore = rootHz != null
              ? HarmonicMatcher.harmonicCompatibility(rootHz, solfeggioHz)
              : 0.3;
          return moodScore * 0.6 + harmonicScore * 0.4;
        }
        best = soundscapes.reduce(
            (a, b) => computeScore(b) > computeScore(a) ? b : a);
      }
      result.add(SoundRecommendation(
          meta: best.$1,
          volume: rc.getDouble('soundscape_volume'),
          distance: best.$2));
    }

    // Best nature sound
    if (natures.isNotEmpty) {
      result.add(SoundRecommendation(
          meta: natures.first.$1,
          volume: rc.getDouble('nature_volume'),
          distance: natures.first.$2));
    }

    // Best noise color — dedicated slot so it is never crowded out by nature
    if (noises.isNotEmpty) {
      result.add(SoundRecommendation(
          meta: noises.first.$1,
          volume: rc.getDouble('noise_volume'),
          distance: noises.first.$2));
    }

    // Best binaural — skip if too distant
    if (binaurals.isNotEmpty && binaurals.first.$2 <= _maxDist) {
      result.add(SoundRecommendation(
          meta: binaurals.first.$1,
          volume: rc.getDouble('binaural_volume'),
          distance: binaurals.first.$2));
    }

    // Best frequency — skip if too distant
    if (bestFreq != null && bestFreq.$2 <= _maxDist) {
      result.add(SoundRecommendation(
          meta: bestFreq.$1,
          volume: rc.getDouble('frequency_volume'),
          distance: bestFreq.$2));
    }

    return result;
  }

  static double _dist(
      double e1, double f1, double w1, double e2, double f2, double w2) {
    return sqrt(pow(e1 - e2, 2) + pow(f1 - f2, 2) + pow(w1 - w2, 2));
  }

  static String _inferCategory(double energy, double focus, double warmth) {
    if (energy < 0.25 && focus < 0.30) return 'Sleep';
    if (focus > 0.65) return 'Focus';
    if (energy > 0.65) return 'Energize';
    if (energy < 0.35 && warmth > 0.50) return 'Relax';
    if (focus > 0.45) return 'Meditate';
    return 'Relax';
  }

  static IconData _inferIcon(String category) {
    switch (category) {
      case 'Sleep':
        return Icons.bedtime_rounded;
      case 'Focus':
        return Icons.psychology_rounded;
      case 'Meditate':
        return Icons.self_improvement_rounded;
      case 'Energize':
        return Icons.bolt_rounded;
      default:
        return Icons.spa_rounded;
    }
  }

  static String _journeyName(String category) {
    switch (category) {
      case 'Sleep':
        return 'Sleep Journey';
      case 'Focus':
        return 'Focus Journey';
      case 'Meditate':
        return 'Meditation Journey';
      case 'Energize':
        return 'Energy Journey';
      default:
        return 'Relaxation Journey';
    }
  }

  static String _journeyDescription(
      double energy, double focus, double warmth) {
    final parts = <String>[];
    if (energy < 0.30) {
      parts.add('calm');
    } else if (energy > 0.65) {
      parts.add('energized');
    } else {
      parts.add('balanced');
    }
    if (focus > 0.60) parts.add('focused');
    if (warmth > 0.60) {
      parts.add('warm');
    } else if (warmth < 0.30) {
      parts.add('clear');
    }
    return 'A ${parts.join(', ')} soundscape tailored to you';
  }
}
