import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/journey.dart';
import '../models/motif_meta.dart';
import 'audio_engine.dart';
import 'motif_engine.dart';

enum JourneyState { stopped, playing, frozen }

class JourneyEngine extends ChangeNotifier {
  static const _tickInterval = Duration(milliseconds: 200);

  /// Volume ramp applied to all layers for the first 2 s after start,
  /// so the initial mix swells in rather than snapping to full volume.
  static const _startupRamp = Duration(seconds: 2);

  Journey? _journey;
  AudioEngine? _engine;
  MotifEngine? _motifEngine;
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
    Duration totalDuration, {
    MotifEngine? motifEngine,
  }) async {
    if (_state != JourneyState.stopped) await stop();

    _journey = journey;
    _engine = engine;
    _motifEngine = motifEngine;
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

  /// Releases journey control without touching the audio engine.
  ///
  /// The tick timer is cancelled and state is set to stopped, but every
  /// currently-playing layer is left exactly as-is. Use this when the user
  /// manually adjusts the mix (slider drag, layer remove) — audio keeps
  /// playing at current volumes while the journey relinquishes ownership.
  void abandon() {
    _timer?.cancel();
    _timer = null;
    _stopwatch
      ..stop()
      ..reset();
    _state = JourneyState.stopped;
    _journey = null;
    _engine = null;
    _motifEngine = null;
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
      final engine = _engine!;
      _engine = null;
      final paths = engine.layers.map((l) => l.assetPath).toList();
      await Future.wait(paths.map(engine.removeLayer));
    }

    await _motifEngine?.stop();
    _motifEngine = null;

    notifyListeners();
  }

  // ── Timer tick ───────────────────────────────

  void _onTick(Timer _) async {
    if (_ticking || _state != JourneyState.playing) return;
    _ticking = true;
    try {
      if (_stopwatch.elapsed >= _totalDuration) {
        await _applyInterpolation();
        await stop();
      } else {
        await _applyInterpolation();
        _engine?.notifyUpdate();
        notifyListeners();
      }
    } finally {
      _ticking = false;
    }
  }

  // ── Waypoint loading ─────────────────────────

  /// Preloads all source layers from [waypoint] into the engine. Tone and
  /// binaural layers start at volume 0 (passed explicitly). Sample and
  /// soundscape layers begin fading toward [AudioEngine.addLayer]'s default
  /// (0.7) the moment they're added — the first [_applyInterpolation] tick then
  /// calls `setVolume`, which cancels that fade and pins the layer to its
  /// interpolated target. Net effect: every layer converges on the
  /// interpolated volume; sample/soundscape layers may show a brief upward
  /// transient (bounded by [_startupRamp]) before the first tick lands.
  Future<void> _loadWaypoint(JourneyWaypoint waypoint) async {
    if (_engine == null) return;
    for (final src in waypoint.layers) {
      if (src is SoundscapeSource) {
        if (src.volume <= 0) continue;
        if (!_engine!.hasLayer(src.assetPath)) {
          await _engine!.addLayer(src.assetPath, _nameFromPath(src.assetPath));
          _engine!.setPitchShift(src.assetPath, src.pitchShiftRatio);
        }
      } else if (src is SampleSource) {
        if (src.volume <= 0) continue;
        if (!_engine!.hasLayer(src.assetPath)) {
          await _engine!.addLayer(src.assetPath, _nameFromPath(src.assetPath));
        }
      } else if (src is ToneSource) {
        if (src.volume <= 0) continue;
        final id = 'tone:${src.frequency.round()}';
        if (!_engine!.hasLayer(id)) {
          await _engine!
              .addToneLayer(id, _nameFromToneId(id), src.frequency, volume: 0.0);
        }
      } else if (src is BinauralSource) {
        if (src.volume <= 0) continue;
        final id = 'binaural:${src.beatFrequency.round()}';
        if (!_engine!.hasLayer(id)) {
          await _engine!.addBinauralLayer(
            id,
            _nameFromBinauralId(id),
            src.centerFrequency,
            src.beatFrequency,
            volume: 0.0,
          );
        }
      } else if (src is MotifSource) {
        if (_motifEngine == null || _motifEngine!.isRunning) continue;
        // Resolve IDs to catalog entries.
        final palette = src.motifIds
            .map(_findMotifById)
            .whereType<MotifMeta>()
            .toList();
        // Align motifs to any solfeggio tone in this waypoint.
        final toneFreq = waypoint.layers
            .whereType<ToneSource>()
            .map((t) => t.frequency)
            .firstOrNull;
        await _motifEngine!.start(
          palette,
          density: src.density,
          masterVolume: src.volume,
          targetFrequency: toneFreq,
        );
      }
      // Tone/binaural layers stay at 0 here; sample/soundscape layers are
      // mid-fade toward 0.7. Either way, _applyInterpolation's first tick
      // (setVolume) takes over and drives each layer to its interpolated value.
    }
  }

  MotifMeta? _findMotifById(String id) {
    for (final m in kMotifCatalog) {
      if (m.id == id) return m;
    }
    return null;
  }

  // ── Interpolation ────────────────────────────

  Future<void> _applyInterpolation() async {
    if (_journey == null || _engine == null) return;
    final waypoints = _journey!.waypoints;
    if (waypoints.length <= 1) return;

    final totalWeight = _journey!.totalWeight;
    if (totalWeight <= 0) {
      await _loadWaypoint(waypoints.last);
      return;
    }

    // ── Find the active segment ──────────────────
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

    // ── Startup ramp ──────────────────────────────
    final rampFactor = _stopwatch.elapsed < _startupRamp
        ? (_stopwatch.elapsed.inMilliseconds / _startupRamp.inMilliseconds)
            .clamp(0.0, 1.0)
        : 1.0;

    // ── Soundscape layer targets ──────────────────
    // Keyed by assetPath; value = (pitchShiftRatio, volume).
    final Map<String, (double pitch, double vol)> soundscapeTargets = {};

    for (final src in fromWp.layers) {
      if (src is! SoundscapeSource) continue;
      final toSrc = toWp.layers
          .whereType<SoundscapeSource>()
          .where((s) => s.assetPath == src.assetPath)
          .firstOrNull;
      final pitch = _lerp(src.pitchShiftRatio,
          toSrc?.pitchShiftRatio ?? src.pitchShiftRatio, easedT);
      final vol = _lerp(src.volume, toSrc?.volume ?? 0.0, easedT);
      soundscapeTargets[src.assetPath] = (pitch, vol);
    }
    for (final src in toWp.layers) {
      if (src is! SoundscapeSource) continue;
      if (!soundscapeTargets.containsKey(src.assetPath)) {
        soundscapeTargets[src.assetPath] =
            (src.pitchShiftRatio, _lerp(0.0, src.volume, easedT));
      }
    }

    // ── Sample layer targets ──────────────────────
    final Map<String, double> targets = {};

    for (final src in fromWp.layers) {
      if (src is! SampleSource) continue;
      final toSrc = toWp.layers
          .whereType<SampleSource>()
          .where((s) => s.assetPath == src.assetPath)
          .firstOrNull;
      targets[src.assetPath] =
          _lerp(src.volume, toSrc?.volume ?? 0.0, easedT);
    }
    for (final src in toWp.layers) {
      if (src is! SampleSource) continue;
      if (!targets.containsKey(src.assetPath)) {
        targets[src.assetPath] = _lerp(0.0, src.volume, easedT);
      }
    }

    // ── Tone layer targets ────────────────────────
    final Map<String, (double freq, double vol)> toneTargets = {};

    for (final src in fromWp.layers) {
      if (src is! ToneSource) continue;
      final id = 'tone:${src.frequency.round()}';
      final toSrc = toWp.layers
          .whereType<ToneSource>()
          .where((s) => 'tone:${s.frequency.round()}' == id)
          .firstOrNull;
      final freq =
          _lerp(src.frequency, toSrc?.frequency ?? src.frequency, easedT);
      final vol = _lerp(src.volume, toSrc?.volume ?? 0.0, easedT);
      toneTargets[id] = (freq, vol);
    }
    for (final src in toWp.layers) {
      if (src is! ToneSource) continue;
      final id = 'tone:${src.frequency.round()}';
      if (!toneTargets.containsKey(id)) {
        toneTargets[id] = (src.frequency, _lerp(0.0, src.volume, easedT));
      }
    }

    // ── Binaural layer targets ────────────────────
    final Map<String, (double center, double beat, double vol)> binTargets = {};

    for (final src in fromWp.layers) {
      if (src is! BinauralSource) continue;
      final id = 'binaural:${src.beatFrequency.round()}';
      final toSrc = toWp.layers
          .whereType<BinauralSource>()
          .where((s) => 'binaural:${s.beatFrequency.round()}' == id)
          .firstOrNull;
      final center = _lerp(src.centerFrequency,
          toSrc?.centerFrequency ?? src.centerFrequency, easedT);
      final beat = _lerp(src.beatFrequency,
          toSrc?.beatFrequency ?? src.beatFrequency, easedT);
      final vol = _lerp(src.volume, toSrc?.volume ?? 0.0, easedT);
      binTargets[id] = (center, beat, vol);
    }
    for (final src in toWp.layers) {
      if (src is! BinauralSource) continue;
      final id = 'binaural:${src.beatFrequency.round()}';
      if (!binTargets.containsKey(id)) {
        binTargets[id] = (
          src.centerFrequency,
          src.beatFrequency,
          _lerp(0.0, src.volume, easedT),
        );
      }
    }

    // ── Apply soundscape layers ───────────────────
    for (final entry in soundscapeTargets.entries) {
      if (_engine == null) return;
      final path = entry.key;
      final (pitch, rawVol) = entry.value;

      if (rawVol < 0.005) {
        if (_engine!.hasLayer(path)) await _engine!.removeLayer(path);
      } else {
        if (!_engine!.hasLayer(path)) {
          await _engine!.addLayer(path, _nameFromPath(path));
          _engine!.setPitchShift(path, pitch);
        }
        _engine!.setVolume(path, (rawVol * rampFactor).clamp(0.0, 1.0));
        _engine!.setPitchShift(path, pitch);
      }
    }

    // ── Apply sample layers ───────────────────────
    for (final entry in targets.entries) {
      if (_engine == null) return;
      final path = entry.key;
      final rawVol = entry.value;

      if (rawVol < 0.005) {
        if (_engine!.hasLayer(path)) await _engine!.removeLayer(path);
      } else {
        if (!_engine!.hasLayer(path)) {
          await _engine!.addLayer(path, _nameFromPath(path));
        }
        _engine!.setVolume(path, (rawVol * rampFactor).clamp(0.0, 1.0));
      }
    }

    // ── Apply tone layers ─────────────────────────
    for (final entry in toneTargets.entries) {
      if (_engine == null) return;
      final id = entry.key;
      final (freq, rawVol) = entry.value;

      if (rawVol < 0.005) {
        if (_engine!.hasLayer(id)) await _engine!.removeLayer(id);
      } else {
        if (!_engine!.hasLayer(id)) {
          await _engine!
              .addToneLayer(id, _nameFromToneId(id), freq, volume: 0.0);
        }
        _engine!.setVolume(id, (rawVol * rampFactor).clamp(0.0, 1.0));
        _engine!.setToneFrequency(id, freq);
      }
    }

    // ── Apply binaural layers ─────────────────────
    for (final entry in binTargets.entries) {
      if (_engine == null) return;
      final id = entry.key;
      final (center, beat, rawVol) = entry.value;

      if (rawVol < 0.005) {
        if (_engine!.hasLayer(id)) await _engine!.removeLayer(id);
      } else {
        if (!_engine!.hasLayer(id)) {
          await _engine!.addBinauralLayer(
              id, _nameFromBinauralId(id), center, beat,
              volume: 0.0);
        }
        _engine!.setVolume(id, (rawVol * rampFactor).clamp(0.0, 1.0));
        _engine!.setBinauralFrequencies(id, center, beat);
      }
    }

    // ── Motif density/volume interpolation ───────────────────────────────
    final fromMotif = fromWp.layers.whereType<MotifSource>().firstOrNull;
    final toMotif = toWp.layers.whereType<MotifSource>().firstOrNull;
    if (_motifEngine != null && (fromMotif != null || toMotif != null)) {
      final d1 = fromMotif?.density ?? 0.0;
      final d2 = toMotif?.density ?? 0.0;
      final v1 = fromMotif?.volume ?? 0.0;
      final v2 = toMotif?.volume ?? 0.0;
      _motifEngine!.setDensity(_lerp(d1, d2, easedT));
      _motifEngine!.setMasterVolume(_lerp(v1, v2, easedT));
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

  /// Derives a display name from a sample asset path.
  /// e.g. "assets/audio/noise/brown_noise.mp3" → "Brown Noise"
  String _nameFromPath(String assetPath) {
    final stem = assetPath.split('/').last.replaceAll('.mp3', '');
    return stem.split('_').map((w) {
      if (w.isEmpty) return '';
      if (w == 'hz') return 'Hz';
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  /// e.g. "tone:528" → "528 Hz"
  String _nameFromToneId(String id) {
    final hz = id.split(':').last;
    return '$hz Hz';
  }

  /// e.g. "binaural:10" → "Alpha Binaural"
  String _nameFromBinauralId(String id) {
    final hz = double.tryParse(id.split(':').last) ?? 10.0;
    return '${_beatBandName(hz)} Binaural';
  }

  String _beatBandName(double hz) {
    if (hz < 4) return 'Delta';
    if (hz < 8) return 'Theta';
    if (hz < 13) return 'Alpha';
    if (hz < 30) return 'Beta';
    return 'Gamma';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
