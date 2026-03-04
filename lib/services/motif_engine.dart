import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/motif_meta.dart';
import 'harmonic_matcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Internal state for a single cycling motif
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveMotif {
  final MotifMeta meta;
  final AudioPlayer player;
  final Duration cycleDuration;
  Timer? timer;
  final double volume;
  final double pitchShiftRatio;

  _ActiveMotif({
    required this.meta,
    required this.player,
    required this.cycleDuration,
    required this.volume,
    required this.pitchShiftRatio,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MotifEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Fires short musical fragments on prime-number timer cycles, creating
/// never-repeating organic textures. Runs independently of AudioEngine and
/// does not count toward the 5-layer cap.
class MotifEngine extends ChangeNotifier {
  /// Prime-number cycle lengths in seconds — one per motif slot.
  static const _primeCycles = [13, 17, 19, 23, 29, 31, 37, 41, 43];

  final _random = Random();
  final List<_ActiveMotif> _activeMotifs = [];
  double _density = 0.5;
  double _masterVolume = 0.3;
  bool _isRunning = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isRunning => _isRunning;
  double get density => _density;
  List<String> get activeMotifIds =>
      _activeMotifs.map((m) => m.meta.id).toList();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Starts cycling [palette] motifs.
  ///
  /// [density] is the probability [0, 1] that a motif fires on any given cycle.
  /// [masterVolume] scales all motif volumes.
  /// [targetFrequency] harmonically aligns pitched motifs to a solfeggio tone.
  Future<void> start(
    List<MotifMeta> palette, {
    double density = 0.5,
    double masterVolume = 0.3,
    double? targetFrequency,
  }) async {
    await stop();
    _density = density.clamp(0.0, 1.0);
    _masterVolume = masterVolume.clamp(0.0, 1.0);
    _isRunning = true;

    for (var i = 0; i < palette.length && i < _primeCycles.length; i++) {
      final m = palette[i];
      final player = AudioPlayer();
      await player.setAsset(m.assetPath);

      double pitchShiftRatio = 1.0;
      if (targetFrequency != null && m.rootFrequency != null) {
        pitchShiftRatio = HarmonicMatcher.findBestMatch(
          m.rootFrequency!,
          targetFrequency,
        ).shiftRatio;
        await player.setSpeed(pitchShiftRatio);
      }

      final motif = _ActiveMotif(
        meta: m,
        player: player,
        cycleDuration: Duration(seconds: _primeCycles[i]),
        volume: m.defaultVolume,
        pitchShiftRatio: pitchShiftRatio,
      );
      _activeMotifs.add(motif);

      // Stagger the first fire with a random offset within the first cycle.
      final offsetMs = _random.nextInt(motif.cycleDuration.inMilliseconds);
      Timer(Duration(milliseconds: offsetMs), () => _scheduleCycle(motif));
    }
  }

  /// Updates trigger probability without restarting motifs.
  void setDensity(double density) {
    _density = density.clamp(0.0, 1.0);
  }

  /// Updates master volume without restarting motifs.
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  /// Stops all motifs and releases their audio players.
  Future<void> stop() async {
    _isRunning = false;
    for (final motif in _activeMotifs) {
      motif.timer?.cancel();
      await motif.player.stop();
      await motif.player.dispose();
    }
    _activeMotifs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final motif in _activeMotifs) {
      motif.timer?.cancel();
      motif.player.stop();
      motif.player.dispose();
    }
    _activeMotifs.clear();
    super.dispose();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  /// Fires one cycle: maybe play the motif, then reschedule.
  void _scheduleCycle(_ActiveMotif motif) {
    if (!_isRunning) return;
    if (_random.nextDouble() < _density) {
      final vol =
          motif.volume * _masterVolume * (0.8 + _random.nextDouble() * 0.2);
      motif.player.setVolume(vol);
      motif.player.seek(Duration.zero);
      motif.player.play(); // one-shot; no looping
    }
    // Always reschedule regardless of whether it played this cycle.
    motif.timer = Timer(motif.cycleDuration, () => _scheduleCycle(motif));
  }
}
