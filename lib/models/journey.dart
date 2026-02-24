import 'package:flutter/material.dart';
import '../services/audio_engine.dart';

// ─────────────────────────────────────────────
// Sound source hierarchy
// ─────────────────────────────────────────────

enum SoundSourceType { sample, tone, binaural }

abstract class SoundSource {
  final double volume;
  final SoundSourceType type;

  const SoundSource({required this.volume, required this.type});
}

/// An audio file from the assets folder.
class SampleSource extends SoundSource {
  final String assetPath;

  const SampleSource({required this.assetPath, required super.volume})
      : super(type: SoundSourceType.sample);
}

/// A pure sine-wave tone (placeholder — engine skips this type for now).
class ToneSource extends SoundSource {
  final double frequency;

  const ToneSource({required this.frequency, required super.volume})
      : super(type: SoundSourceType.tone);
}

/// A binaural beat (placeholder — engine skips this type for now).
class BinauralSource extends SoundSource {
  final double centerFrequency;
  final double beatFrequency;

  const BinauralSource({
    required this.centerFrequency,
    required this.beatFrequency,
    required super.volume,
  }) : super(type: SoundSourceType.binaural);
}

// ─────────────────────────────────────────────
// Easing
// ─────────────────────────────────────────────

enum EaseCurve { linear, easeIn, easeOut, easeInOut }

// ─────────────────────────────────────────────
// Waypoint
// ─────────────────────────────────────────────

/// A single target mixer state on the journey timeline.
///
/// [weight] is the proportion of the total journey time used to interpolate
/// FROM the previous waypoint TO this one. The first waypoint must have
/// weight = 0 (it is loaded instantly at the start).
class JourneyWaypoint {
  final List<SoundSource> layers;

  /// Proportion of total journey time to transition INTO this waypoint.
  /// First waypoint must be 0.
  final double weight;

  /// Easing applied to the transition that arrives at this waypoint.
  final EaseCurve curve;

  const JourneyWaypoint({
    required this.layers,
    this.weight = 0.0,
    this.curve = EaseCurve.linear,
  });
}

// ─────────────────────────────────────────────
// Journey
// ─────────────────────────────────────────────

class Journey {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  /// e.g. "Sleep", "Focus", "Meditate", "Relax", "Energize"
  final String category;

  final List<JourneyWaypoint> waypoints;
  final Duration defaultDuration;
  final Duration minDuration;
  final Duration maxDuration;

  const Journey({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.waypoints,
    required this.defaultDuration,
    required this.minDuration,
    required this.maxDuration,
  });

  /// Sum of all waypoint weights (waypoints[1..n]).
  double get totalWeight =>
      waypoints.fold(0.0, (sum, wp) => sum + wp.weight);

  // ── Factories ───────────────────────────────

  /// Wraps a flat list of [SampleSource]s into a single-waypoint journey.
  /// Useful for backward-compatibility with static presets.
  factory Journey.static({
    required String name,
    required String description,
    required IconData icon,
    required String category,
    required List<SampleSource> layers,
  }) {
    return Journey(
      id: name.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
      name: name,
      description: description,
      icon: icon,
      category: category,
      waypoints: [JourneyWaypoint(layers: layers)],
      defaultDuration: const Duration(minutes: 30),
      minDuration: const Duration(minutes: 5),
      maxDuration: const Duration(hours: 2),
    );
  }

  /// Creates a two-waypoint journey that fades the engine's current mix to
  /// silence over [duration]. Snapshots layer volumes at call time.
  factory Journey.sleepTimer(AudioEngine engine, Duration duration) {
    // Snapshot of current mix at current volumes.
    final fromLayers = engine.layers
        .map((l) => SampleSource(assetPath: l.assetPath, volume: l.volume))
        .toList();

    // Same layers, all at 0.0 — the interpolation target.
    final toLayers = engine.layers
        .map((l) => SampleSource(assetPath: l.assetPath, volume: 0.0))
        .toList();

    return Journey(
      id: 'sleep_timer',
      name: 'Sleep Timer',
      description: 'Fading out your mix over ${_fmtLabel(duration)}',
      icon: Icons.bedtime_rounded,
      category: 'Sleep',
      waypoints: [
        JourneyWaypoint(layers: fromLayers, weight: 0.0),
        JourneyWaypoint(
            layers: toLayers, weight: 1.0, curve: EaseCurve.easeOut),
      ],
      defaultDuration: duration,
      minDuration: const Duration(minutes: 1),
      maxDuration: const Duration(hours: 3),
    );
  }

  static String _fmtLabel(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return m == 0 ? '$h hr' : '$h hr $m min';
  }
}
