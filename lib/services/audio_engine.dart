import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'tone_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AudioLayer
// ─────────────────────────────────────────────────────────────────────────────

class AudioLayer {
  final String assetPath;
  final String name;

  /// True when this layer is managed by [ToneService] rather than just_audio.
  final bool isTone;

  /// Internal ToneService ID (e.g. 'tone_0'). Non-null only when [isTone].
  final String? _toneServiceId;

  /// Frequency for pure-tone layers. Null for sample and binaural layers.
  final double? toneFreq;

  /// Center frequency for binaural layers. Null for sample and tone layers.
  final double? binCenterFreq;

  /// Beat frequency for binaural layers. Null for sample and tone layers.
  final double? binBeatFreq;

  AudioPlayer? _player;   // null for tone layers
  AudioPlayer? _xPlayer;  // secondary player during crossfade (sample layers only)
  double volume;

  /// Current playback speed ratio used to approximate pitch shifting.
  /// 1.0 = no shift. Only meaningful for sample-based layers.
  double pitchShiftRatio = 1.0;
  double _xfadeT = 0.0;
  Duration? fileDuration;

  Timer? _fadeTimer;
  Timer? _xfadeTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  /// For sample-based (just_audio) layers.
  AudioLayer({
    required this.assetPath,
    required this.name,
    required AudioPlayer player,
    this.volume = 0.0,
  })  : _player = player,
        isTone = false,
        _toneServiceId = null,
        toneFreq = null,
        binCenterFreq = null,
        binBeatFreq = null;

  /// For pure sine-wave tone layers managed by [ToneService].
  AudioLayer.tone({
    required this.assetPath,
    required this.name,
    required String toneServiceId,
    required double frequency,
    this.volume = 0.0,
  })  : _player = null,
        isTone = true,
        _toneServiceId = toneServiceId,
        toneFreq = frequency,
        binCenterFreq = null,
        binBeatFreq = null;

  /// For binaural-beat layers managed by [ToneService].
  AudioLayer.binaural({
    required this.assetPath,
    required this.name,
    required String toneServiceId,
    required double centerFrequency,
    required double beatFrequency,
    this.volume = 0.0,
  })  : _player = null,
        isTone = true,
        _toneServiceId = toneServiceId,
        toneFreq = null,
        binCenterFreq = centerFrequency,
        binBeatFreq = beatFrequency;
}

// ─────────────────────────────────────────────────────────────────────────────
// AudioEngine
// ─────────────────────────────────────────────────────────────────────────────

class AudioEngine extends ChangeNotifier {
  static const int maxLayers = 5;

  // How long the crossfade blend lasts, and how early to start it.
  static const _xfadeDuration = Duration(seconds: 3);
  static const _xfadeBuffer = Duration(milliseconds: 500);

  final ToneService _toneService;
  AudioEngine(this._toneService);

  final List<AudioLayer> _layers = [];

  List<AudioLayer> get layers => List.unmodifiable(_layers);
  bool get isFull => _layers.length >= maxLayers;
  bool hasLayer(String assetPath) =>
      _layers.any((l) => l.assetPath == assetPath);

  // ── Sample layer commands ─────────────────────────────────────────────────

  /// Adds a sample-based layer starting at volume 0 and fades it in over 1.5s
  /// to [volume] (default 0.7). Mirrors the `volume:` target that
  /// [addToneLayer] and [addBinauralLayer] already accept.
  Future<void> addLayer(String assetPath, String name,
      {double volume = 0.7}) async {
    if (isFull || hasLayer(assetPath)) return;

    final player = AudioPlayer();
    await player.setAsset(assetPath);
    await player.setVolume(0.0);

    final layer = AudioLayer(
      assetPath: assetPath,
      name: name,
      player: player,
      volume: 0.0,
    );
    layer.fileDuration = player.duration;
    _layers.add(layer);
    notifyListeners();

    unawaited(player.play());
    _startFade(layer, volume.clamp(0.0, 1.0), const Duration(milliseconds: 1500));
    _setupLayerLooping(layer);
  }

  // ── Tone layer commands ───────────────────────────────────────────────────

  /// Adds a pure sine-wave tone layer. Use the semantic ID `tone:<hz>`.
  Future<void> addToneLayer(
    String id,
    String displayName,
    double frequency, {
    double volume = 0.5,
  }) async {
    if (isFull || hasLayer(id)) return;
    final sid = await _toneService.playTone(frequency, volume: 0.0);
    final layer = AudioLayer.tone(
      assetPath: id,
      name: displayName,
      toneServiceId: sid,
      frequency: frequency,
      volume: 0.0,
    );
    _layers.add(layer);
    notifyListeners();
    _startFade(layer, volume, const Duration(milliseconds: 1500));
  }

  /// Adds a binaural-beat layer. Use the semantic ID `binaural:<beatHz>`.
  Future<void> addBinauralLayer(
    String id,
    String displayName,
    double centerFreq,
    double beatFreq, {
    double volume = 0.5,
  }) async {
    if (isFull || hasLayer(id)) return;
    final sid =
        await _toneService.playBinaural(centerFreq, beatFreq, volume: 0.0);
    final layer = AudioLayer.binaural(
      assetPath: id,
      name: displayName,
      toneServiceId: sid,
      centerFrequency: centerFreq,
      beatFrequency: beatFreq,
      volume: 0.0,
    );
    _layers.add(layer);
    notifyListeners();
    _startFade(layer, volume, const Duration(milliseconds: 1500));
  }

  // ── Tone frequency commands ───────────────────────────────────────────────

  /// Updates the frequency of a pure-tone layer in real-time.
  void setToneFrequency(String id, double frequency) {
    final layer = _layers.where((l) => l.assetPath == id).firstOrNull;
    if (layer == null || !layer.isTone || layer.binBeatFreq != null) return;
    _toneService.setToneFrequency(layer._toneServiceId!, frequency);
  }

  /// Updates the center and beat frequencies of a binaural layer in real-time.
  void setBinauralFrequencies(String id, double centerFreq, double beatFreq) {
    final layer = _layers.where((l) => l.assetPath == id).firstOrNull;
    if (layer == null || !layer.isTone || layer.binBeatFreq == null) return;
    _toneService.setBinauralFrequencies(
        layer._toneServiceId!, centerFreq, beatFreq);
  }

  // ── Volume commands ───────────────────────────────────────────────────────

  /// Smoothly transitions a layer's volume to [targetVolume] over [duration].
  void fadeToVolume(String assetPath, double targetVolume, Duration duration) {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;
    _startFade(_layers[index], targetVolume.clamp(0.0, 1.0), duration);
  }

  /// Instant volume change — used by the journey engine's per-tick
  /// interpolation and by the mixer slider during active drag.
  /// Cancels any fade in progress.
  void setVolume(String assetPath, double volume) {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;
    final layer = _layers[index];
    layer._fadeTimer?.cancel();
    layer._fadeTimer = null;
    layer.volume = volume.clamp(0.0, 1.0);
    _applyLayerVolumes(layer);
  }

  /// Sets the playback speed of a sample-based layer to approximate pitch
  /// shifting. [ratio] comes from [HarmonicMatcher] (e.g. 1.059 ≈ +1 st).
  ///
  /// TODO: Migrate to flutter_soloud setRelativePlaySpeed once soundscape
  /// layers use SoLoud, for true pitch-shift-without-tempo-change.
  void setPitchShift(String assetPath, double ratio) {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;
    final layer = _layers[index];
    if (layer.isTone) return; // Tone layers don't use just_audio speed.
    layer.pitchShiftRatio = ratio;
    layer._player?.setSpeed(ratio);
  }

  /// Fades the layer to 0 over ~1 s, then removes and disposes it.
  Future<void> removeLayer(String assetPath) async {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;

    final layer = _layers[index];
    layer._fadeTimer?.cancel();
    layer._fadeTimer = null;
    layer._xfadeTimer?.cancel();
    layer._xfadeTimer = null;
    layer._positionSub?.cancel();
    layer._positionSub = null;
    layer._durationSub?.cancel();
    layer._durationSub = null;

    if (layer.volume > 0.02) {
      final completer = Completer<void>();
      _startFade(
        layer,
        0.0,
        const Duration(milliseconds: 1000),
        onComplete: completer.complete,
      );
      await completer.future;
    }

    // Re-look up the index: parallel removals may have shifted positions.
    final removeIdx = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (removeIdx != -1) {
      _layers.removeAt(removeIdx);
      notifyListeners();
    }

    if (layer.isTone) {
      await _toneService.stopTone(layer._toneServiceId!);
    } else {
      await layer._player!.stop();
      await layer._player!.dispose();
      await layer._xPlayer?.stop();
      await layer._xPlayer?.dispose();
    }
  }

  /// Pushes a listener notification without modifying state.
  void notifyUpdate() => notifyListeners();

  // ── Private ───────────────────────────────────────────────────────────────

  /// Applies [layer.volume] to the correct backend, accounting for any
  /// crossfade blend in progress (sample layers) or delegating to
  /// [ToneService] (tone / binaural layers).
  void _applyLayerVolumes(AudioLayer layer) {
    final v = layer.volume.clamp(0.0, 1.0);
    if (layer.isTone) {
      final sid = layer._toneServiceId!;
      if (layer.binBeatFreq != null) {
        _toneService.setBinauralVolume(sid, v);
      } else {
        _toneService.setToneVolume(sid, v);
      }
      return;
    }
    if (layer._xPlayer == null) {
      layer._player!.setVolume(v);
    } else {
      // Equal-power crossfade: cos/sin curves keep perceived loudness constant.
      // Linear (1-t)/t fades dip ~3 dB at the midpoint; sin²+cos²=1 avoids this.
      final t = layer._xfadeT;
      final cosT = cos(t * pi / 2.0);
      final sinT = sin(t * pi / 2.0);
      layer._player!.setVolume((v * cosT).clamp(0.0, 1.0));
      layer._xPlayer!.setVolume((v * sinT).clamp(0.0, 1.0));
    }
  }

  /// Linearly interpolates [layer.volume] toward [targetVolume] over
  /// [duration] in 50 ms steps, calling [notifyListeners] on each tick.
  void _startFade(
    AudioLayer layer,
    double targetVolume,
    Duration duration, {
    VoidCallback? onComplete,
  }) {
    layer._fadeTimer?.cancel();
    layer._fadeTimer = null;

    if (duration.inMilliseconds <= 0) {
      layer.volume = targetVolume;
      _applyLayerVolumes(layer);
      notifyListeners();
      onComplete?.call();
      return;
    }

    final steps = (duration.inMilliseconds / 50).ceil();
    final startVolume = layer.volume;
    int tick = 0;

    layer._fadeTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      tick++;
      if (tick >= steps) {
        timer.cancel();
        layer._fadeTimer = null;
        layer.volume = targetVolume;
        _applyLayerVolumes(layer);
        notifyListeners();
        onComplete?.call();
      } else {
        final t = tick / steps;
        layer.volume =
            (startVolume + (targetVolume - startVolume) * t).clamp(0.0, 1.0);
        _applyLayerVolumes(layer);
        notifyListeners();
      }
    });
  }

  // ── Seamless crossfade loop (sample layers only) ──────────────────────────

  void _setupLayerLooping(AudioLayer layer) {
    if (layer.isTone) return; // Tone layers loop natively via SoLoud.

    layer._player!.setLoopMode(LoopMode.one);

    if (layer.fileDuration != null) {
      _startPositionMonitor(layer);
    } else {
      layer._durationSub?.cancel();
      layer._durationSub = layer._player!.durationStream.listen((d) {
        if (d == null) return;
        layer.fileDuration = d;
        layer._durationSub?.cancel();
        layer._durationSub = null;
        _startPositionMonitor(layer);
      });
    }
  }

  void _startPositionMonitor(AudioLayer layer) {
    layer._positionSub?.cancel();
    layer._positionSub = null;

    final duration = layer.fileDuration;
    if (duration == null) return;

    final threshold = _xfadeDuration + _xfadeBuffer;

    layer._positionSub = layer._player!.positionStream.listen((position) {
      if (layer._xfadeTimer != null) return;
      if (position < duration - threshold) return;

      layer._positionSub?.cancel();
      layer._positionSub = null;
      _startCrossfade(layer);
    });
  }

  Future<void> _startCrossfade(AudioLayer layer) async {
    if (layer.isTone) return; // Should never be called for tone layers.
    if (!_layers.contains(layer)) return;
    if (layer._xfadeTimer != null) return;

    final next = AudioPlayer();
    await next.setAsset(layer.assetPath);
    await next.setLoopMode(LoopMode.one);
    next.setVolume(0.0);
    unawaited(next.play());

    layer._xPlayer = next;
    layer._xfadeT = 0.0;

    final steps = (_xfadeDuration.inMilliseconds / 50).ceil();
    int tick = 0;

    layer._xfadeTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_layers.contains(layer)) {
        timer.cancel();
        layer._xfadeTimer = null;
        next.stop();
        next.dispose();
        return;
      }
      tick++;
      layer._xfadeT = (tick / steps).clamp(0.0, 1.0);
      _applyLayerVolumes(layer);

      if (tick >= steps) {
        timer.cancel();
        layer._xfadeTimer = null;
        _completeCrossfade(layer);
      }
    });
  }

  Future<void> _completeCrossfade(AudioLayer layer) async {
    if (!_layers.contains(layer)) {
      await layer._xPlayer?.stop();
      await layer._xPlayer?.dispose();
      layer._xPlayer = null;
      return;
    }

    final oldPlayer = layer._player!;
    final newPlayer = layer._xPlayer!;

    layer._player = newPlayer;
    layer._xPlayer = null;
    layer._xfadeT = 0.0;
    layer.fileDuration = newPlayer.duration ?? layer.fileDuration;
    _applyLayerVolumes(layer);

    await oldPlayer.stop();
    await oldPlayer.dispose();

    _startPositionMonitor(layer);
  }

  @override
  void dispose() {
    for (final layer in _layers) {
      layer._fadeTimer?.cancel();
      layer._xfadeTimer?.cancel();
      layer._positionSub?.cancel();
      layer._durationSub?.cancel();
      if (!layer.isTone) {
        layer._player?.stop();
        layer._player?.dispose();
        layer._xPlayer?.stop();
        layer._xPlayer?.dispose();
      }
    }
    unawaited(_toneService.stopAll());
    _layers.clear();
    super.dispose();
  }
}
