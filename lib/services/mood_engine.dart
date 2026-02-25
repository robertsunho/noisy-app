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
  static const _volumes = [0.55, 0.45, 0.35, 0.25];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns 3–4 recommended sounds closest to (energy, focus, warmth) with
  /// a diversity constraint: the result must span at least 2 categories.
  List<SoundRecommendation> generateMix(
      double energy, double focus, double warmth) {
    final ranked = _rankSounds(energy, focus, warmth);
    final selected = _selectWithDiversity(ranked, 4);

    return [
      for (var i = 0; i < selected.length; i++)
        SoundRecommendation(
          meta: selected[i].$1,
          volume: _volumes[i],
          distance: selected[i].$2,
        )
    ];
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

  /// Rank all available sounds by Euclidean distance to the target mood.
  List<(SoundMeta, double)> _rankSounds(
      double energy, double focus, double warmth) {
    return kSoundCatalog
        .where((s) => s.isAvailable && kMoodProfiles.containsKey(s.id))
        .map((s) {
          final p = kMoodProfiles[s.id]!;
          final d = _dist(energy, focus, warmth, p.energy, p.focus, p.warmth);
          return (s, d);
        })
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
  }

  /// Select up to [max] sounds, ensuring at least 2 different categories.
  List<(SoundMeta, double)> _selectWithDiversity(
      List<(SoundMeta, double)> ranked, int max) {
    final result = <(SoundMeta, double)>[];
    final seenCategories = <String>{};

    for (final entry in ranked) {
      if (result.length >= max) break;
      final newCategory = !seenCategories.contains(entry.$1.category);
      // Always add the best match; for subsequent ones prefer new categories
      // until we have diversity, then accept any.
      if (result.isEmpty || newCategory || seenCategories.length >= 2) {
        result.add(entry);
        seenCategories.add(entry.$1.category);
      }
    }

    // Pad to at least 3 if diversity checks left us short.
    for (final entry in ranked) {
      if (result.length >= 3) break;
      if (!result.any((r) => r.$1.id == entry.$1.id)) {
        result.add(entry);
      }
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
