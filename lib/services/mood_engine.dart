import 'dart:math';
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

  /// Returns 2–4 sounds for the given mood:
  ///   • exactly 1 frequency (skipped if best distance > 1.2)   → vol 0.40
  ///   • exactly 1 binaural  (skipped if best distance > 1.2)   → vol 0.45
  ///   • 2 nature/noise textures (always selected)              → vol 0.50 / 0.30
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
                      soundscapeRootHz, solfeggioFreq)
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
    final motifDensity = _inferMotifDensity(energy, category);
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

  /// Maps energy + category to a motif trigger density [0, 1].
  static double _inferMotifDensity(double energy, String category) {
    if (category == 'Sleep') return 0.2 + energy * 0.1;    // 0.20–0.30
    if (category == 'Energize') return 0.6 + energy * 0.2; // 0.60–0.80
    return 0.3 + energy * 0.2;                             // 0.30–0.50
  }

  /// Builds the balanced mix with 4 category slots:
  ///   1. Best soundscape   → vol 0.55 (primary atmospheric layer)
  ///   2. Best texture      → vol 0.40 (nature/noise complement)
  ///   3. Best binaural     → vol 0.40 (skip if distance > 1.2)
  ///   4. Best frequency    → vol 0.35 (skip if distance > 1.2)
  List<SoundRecommendation> _selectByCategory(
      double energy, double focus, double warmth) {
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
    final textures = all
        .where((e) => e.$1.category == 'nature' || e.$1.category == 'noise')
        .toList();
    final binaurals = ofCat('binaural');
    final frequencies = ofCat('frequencies');

    final result = <SoundRecommendation>[];

    // Best soundscape — primary atmospheric layer
    if (soundscapes.isNotEmpty) {
      result.add(SoundRecommendation(
          meta: soundscapes.first.$1,
          volume: 0.55,
          distance: soundscapes.first.$2));
    }

    // Best texture (nature/noise)
    if (textures.isNotEmpty) {
      result.add(SoundRecommendation(
          meta: textures.first.$1,
          volume: 0.40,
          distance: textures.first.$2));
    }

    // Best binaural — skip if too distant
    if (binaurals.isNotEmpty && binaurals.first.$2 <= _maxDist) {
      result.add(SoundRecommendation(
          meta: binaurals.first.$1,
          volume: 0.40,
          distance: binaurals.first.$2));
    }

    // Best frequency — skip if too distant
    if (frequencies.isNotEmpty && frequencies.first.$2 <= _maxDist) {
      result.add(SoundRecommendation(
          meta: frequencies.first.$1,
          volume: 0.35,
          distance: frequencies.first.$2));
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
