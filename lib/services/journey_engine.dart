import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/journey.dart';
import 'audio_engine.dart';

enum JourneyState { stopped, playing, frozen }

class JourneyEngine extends ChangeNotifier {
  static const _tickInterval = Duration(milliseconds: 200);

  Journey? _journey;
  AudioEngine? _engine;
  JourneyState _state = JourneyState.stopped;
  Duration _totalDuration = const Duration(minutes: 30);

  Timer? _timer;

  /// Tracks real elapsed time. Pauses on freeze, resets on stop.
  final _stopwatch = Stopwatch();

  /// Prevents re-entrant async ticks from overlapping.
  bool _ticking = false;

  // ── Public getters ───────────────────────────

  Journey? get currentJourney => _journey;
  JourneyState get state => _state;
  Duration get totalDuration => _totalDuration;
  Duration get elapsed => _stopwatch.elapsed;

  double get progress {
    final ms = _totalDuration.inMilliseconds;
    if (ms <= 0) return 0.0;
    return (_stopwatch.elapsed.inMilliseconds / ms).clamp(0.0, 1.0);
  }

  // ── Public commands ──────────────────────────

  /// Starts [journey] running against [engine] for [totalDuration].
  /// If a journey is already running it is stopped first.
  Future<void> start(
    Journey journey,
    AudioEngine engine,
    Duration totalDuration,
  ) async {
    if (_state != JourneyState.stopped) await stop();

    _journey = journey;
    _engine = engine;
    _totalDuration = totalDuration;
    _stopwatch.reset();
    _state = JourneyState.playing;

    // Immediately apply waypoint 0 so audio starts without delay.
    await _loadWaypoint(journey.waypoints.first);

    _timer = Timer.periodic(_tickInterval, _onTick);
    _stopwatch.start();
    notifyListeners();
  }

  /// Pauses timeline progression; audio keeps playing at current volumes.
  void freeze() {
    if (_state != JourneyState.playing) return;
    _state = JourneyState.frozen;
    _stopwatch.stop();
    notifyListeners();
  }

  /// Resumes timeline progression after a freeze.
  void unfreeze() {
    if (_state != JourneyState.frozen) return;
    _state = JourneyState.playing;
    _stopwatch.start();
    notifyListeners();
  }

  /// Halts the journey and clears all audio engine layers.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _stopwatch
      ..stop()
      ..reset();
    _state = JourneyState.stopped;
    _journey = null;

    if (_engine != null) {
      final paths = _engine!.layers.map((l) => l.assetPath).toList();
      for (final path in paths) {
        await _engine!.removeLayer(path);
      }
      _engine = null;
    }

    notifyListeners();
  }

  // ── Timer tick ───────────────────────────────

  void _onTick(Timer _) async {
    if (_ticking || _state != JourneyState.playing) return;
    _ticking = true;
    try {
      if (_stopwatch.elapsed >= _totalDuration) {
        // Apply the exact final state before tearing down.
        await _applyInterpolation();
        await stop();
      } else {
        await _applyInterpolation();
        notifyListeners();
      }
    } finally {
      _ticking = false;
    }
  }

  // ── Waypoint loading ─────────────────────────

  /// Loads all SampleSources from [waypoint] into the engine at their
  /// specified volumes. Used for the first waypoint only (instant load).
  Future<void> _loadWaypoint(JourneyWaypoint waypoint) async {
    if (_engine == null) return;
    for (final src in waypoint.layers) {
      if (src is! SampleSource) continue;
      if (src.volume <= 0) continue;
      if (!_engine!.hasLayer(src.assetPath)) {
        await _engine!.addLayer(src.assetPath, _nameFromPath(src.assetPath));
      }
      _engine!.setVolume(src.assetPath, src.volume);
    }
  }

  // ── Interpolation ────────────────────────────

  Future<void> _applyInterpolation() async {
    if (_journey == null || _engine == null) return;
    final waypoints = _journey!.waypoints;
    if (waypoints.length <= 1) return;

    final totalWeight = _journey!.totalWeight;
    if (totalWeight <= 0) {
      // Degenerate: no weights defined — jump to last waypoint.
      await _loadWaypoint(waypoints.last);
      return;
    }

    // ── Find the active segment ──────────────────
    // Segments are defined by cumulative normalised weight boundaries.
    // Segment i goes from waypoints[i-1] to waypoints[i].
    final p = progress;
    int fromIdx = waypoints.length - 2;
    int toIdx = waypoints.length - 1;
    double localT = 1.0;

    double cumulative = 0.0;
    for (int i = 1; i < waypoints.length; i++) {
      final segStart = cumulative / totalWeight;
      cumulative += waypoints[i].weight;
      final segEnd = cumulative / totalWeight;

      if (p <= segEnd + 1e-9 || i == waypoints.length - 1) {
        fromIdx = i - 1;
        toIdx = i;
        final segLen = segEnd - segStart;
        localT = segLen > 0
            ? ((p - segStart) / segLen).clamp(0.0, 1.0)
            : 1.0;
        break;
      }
    }

    final fromWp = waypoints[fromIdx];
    final toWp = waypoints[toIdx];
    final easedT = _applyCurve(localT, toWp.curve);

    // ── Build target volume map ──────────────────
    // Keys are assetPaths; values are the interpolated target volume.
    final Map<String, double> targets = {};

    for (final src in fromWp.layers) {
      if (src is! SampleSource) continue;
      // Find the matching source in the destination waypoint (if any).
      final toSrc = toWp.layers
          .whereType<SampleSource>()
          .where((s) => s.assetPath == src.assetPath)
          .firstOrNull;
      targets[src.assetPath] =
          _lerp(src.volume, toSrc?.volume ?? 0.0, easedT);
    }

    for (final src in toWp.layers) {
      if (src is! SampleSource) continue;
      // Sources only in the destination: fade in from 0.
      if (!targets.containsKey(src.assetPath)) {
        targets[src.assetPath] = _lerp(0.0, src.volume, easedT);
      }
    }

    // ── Apply to audio engine ────────────────────
    for (final entry in targets.entries) {
      if (_engine == null) return; // guard: stop() may have been called
      final path = entry.key;
      final vol = entry.value;

      if (vol < 0.005) {
        // Volume effectively zero — remove layer if present.
        if (_engine!.hasLayer(path)) {
          await _engine!.removeLayer(path);
        }
      } else {
        if (!_engine!.hasLayer(path)) {
          await _engine!.addLayer(path, _nameFromPath(path));
        }
        _engine!.setVolume(path, vol.clamp(0.0, 1.0));
      }
    }
  }

  // ── Helpers ──────────────────────────────────

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _applyCurve(double t, EaseCurve curve) {
    switch (curve) {
      case EaseCurve.linear:
        return t;
      case EaseCurve.easeIn:
        return t * t;
      case EaseCurve.easeOut:
        return 1.0 - (1.0 - t) * (1.0 - t);
      case EaseCurve.easeInOut:
        return t < 0.5
            ? 2.0 * t * t
            : 1.0 - ((-2.0 * t + 2.0) * (-2.0 * t + 2.0)) / 2.0;
    }
  }

  /// Derives a human-readable layer name from an asset path.
  /// e.g. "assets/audio/noise/brown_noise.mp3" → "Brown Noise"
  String _nameFromPath(String assetPath) {
    final stem = assetPath.split('/').last.replaceAll('.mp3', '');
    return stem.split('_').map((w) {
      if (w.isEmpty) return '';
      if (w == 'hz') return 'Hz';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
