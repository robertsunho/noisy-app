import 'dart:math';
import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/mood_profile.dart';
import '../models/sound_meta.dart';

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

  /// Creates a 3-waypoint [Journey] whose mix is tuned to the requested mood.
  Journey generateJourney(
      double energy, double focus, double warmth, Duration duration) {
    final recs = generateMix(energy, focus, warmth);
    final category = _inferCategory(energy, focus, warmth);

    // Waypoint 0 — starting state
    final wp0 = JourneyWaypoint(
      layers: [
        for (final r in recs)
          SampleSource(assetPath: r.meta.assetPath, volume: r.volume)
      ],
    );

    // Waypoint 1 — slight mid-journey variation (alternating layers ±0.05)
    final wp1 = JourneyWaypoint(
      layers: [
        for (var i = 0; i < recs.length; i++)
          SampleSource(
            assetPath: recs[i].meta.assetPath,
            volume: (recs[i].volume + (i.isEven ? 0.05 : -0.05))
                .clamp(0.10, 0.70),
          )
      ],
      weight: 1.0,
      curve: EaseCurve.easeInOut,
    );

    // Waypoint 2 — settle back to original volumes
    final wp2 = JourneyWaypoint(
      layers: [
        for (final r in recs)
          SampleSource(assetPath: r.meta.assetPath, volume: r.volume)
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

  /// Build the balanced mix: 2 textures + up to 1 binaural + up to 1 frequency.
  List<SoundRecommendation> _selectByCategory(
      double energy, double focus, double warmth) {
    // Per-category sorted lists (closest first).
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

    final textures = all
        .where((e) =>
            e.$1.category == 'nature' || e.$1.category == 'noise')
        .toList(); // already sorted by distance

    final binaurals = ofCat('binaural');
    final frequencies = ofCat('frequencies');

    final result = <SoundRecommendation>[];

    // 1st texture — always included (nature/noise are always available)
    if (textures.isNotEmpty) {
      result.add(SoundRecommendation(
          meta: textures[0].$1, volume: 0.50, distance: textures[0].$2));
    }

    // Best binaural — skip if too distant
    if (binaurals.isNotEmpty && binaurals.first.$2 <= _maxDist) {
      result.add(SoundRecommendation(
          meta: binaurals.first.$1,
          volume: 0.45,
          distance: binaurals.first.$2));
    }

    // 2nd texture (if available)
    if (textures.length >= 2) {
      result.add(SoundRecommendation(
          meta: textures[1].$1, volume: 0.30, distance: textures[1].$2));
    }

    // Best frequency — skip if too distant
    if (frequencies.isNotEmpty && frequencies.first.$2 <= _maxDist) {
      result.add(SoundRecommendation(
          meta: frequencies.first.$1,
          volume: 0.40,
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
