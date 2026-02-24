import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioLayer {
  final String assetPath;
  final String name;
  AudioPlayer _player;     // currently active player
  AudioPlayer? _xPlayer;   // secondary player during crossfade
  double volume;
  double _xfadeT = 0.0;    // 0 = all _player, 1 = all _xPlayer
  Duration? fileDuration;

  Timer? _fadeTimer;        // engine volume fades
  Timer? _xfadeTimer;       // crossfade execution ticks
  StreamSubscription<Duration>? _positionSub;   // crossfade trigger
  StreamSubscription<Duration?>? _durationSub;  // waits for duration on web

  AudioLayer({
    required this.assetPath,
    required this.name,
    required AudioPlayer player,
    this.volume = 0.0,
  }) : _player = player;
}

class AudioEngine extends ChangeNotifier {
  static const int maxLayers = 5;

  // How long the crossfade blend lasts, and how early to start it.
  static const _xfadeDuration = Duration(seconds: 3);
  static const _xfadeBuffer = Duration(milliseconds: 500);

  final List<AudioLayer> _layers = [];

  List<AudioLayer> get layers => List.unmodifiable(_layers);
  bool get isFull => _layers.length >= maxLayers;
  bool hasLayer(String assetPath) =>
      _layers.any((l) => l.assetPath == assetPath);

  // ── Public commands ──────────────────────────────────────────────────────

  /// Adds a new layer starting at volume 0 and fades it up to 0.7 over 1.5 s.
  Future<void> addLayer(String assetPath, String name) async {
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

    // Do NOT await play() — for non-looping players the returned Future only
    // resolves when playback ends, which would block callers.
    unawaited(player.play());

    _startFade(layer, 0.7, const Duration(milliseconds: 1500));
    _setupLayerLooping(layer);
  }

  /// Fades the layer to 0 over ~1 s, then removes and disposes it.
  /// Near-silent layers (≤ 0.02) skip the fade for immediate removal.
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

    await layer._player.stop();
    await layer._player.dispose();
    await layer._xPlayer?.stop();
    await layer._xPlayer?.dispose();
  }

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

  /// Pushes a listener notification without modifying state.
  /// Called by collaborators (e.g. JourneyEngine) to refresh UI listeners.
  void notifyUpdate() => notifyListeners();

  // ── Private ──────────────────────────────────────────────────────────────

  /// Applies [layer.volume] to the correct player(s), accounting for any
  /// crossfade blend in progress.
  void _applyLayerVolumes(AudioLayer layer) {
    final v = layer.volume.clamp(0.0, 1.0);
    if (layer._xPlayer == null) {
      layer._player.setVolume(v);
    } else {
      final t = layer._xfadeT;
      layer._player.setVolume((v * (1.0 - t)).clamp(0.0, 1.0));
      layer._xPlayer!.setVolume((v * t).clamp(0.0, 1.0));
    }
  }

  /// Linearly interpolates [layer.volume] toward [targetVolume] over
  /// [duration] in 50 ms steps, calling [notifyListeners] on each tick so
  /// sliders in the Mixer can follow the fade in real time.
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

  // ── Seamless crossfade loop ───────────────────────────────────────────────

  /// Sets up seamless looping for [layer].
  ///
  /// Immediately applies [LoopMode.one] as a guaranteed fallback — this alone
  /// prevents silence even if the crossfade never fires.  Then:
  /// - If [layer.fileDuration] is already known, starts position monitoring.
  /// - Otherwise, listens on [durationStream] (needed on web/Chrome where
  ///   [AudioPlayer.duration] is null until the file is partially buffered),
  ///   and starts position monitoring once the duration arrives.
  void _setupLayerLooping(AudioLayer layer) {
    // Fallback: LoopMode.one ensures the track loops even without crossfade.
    layer._player.setLoopMode(LoopMode.one);

    if (layer.fileDuration != null) {
      _startPositionMonitor(layer);
    } else {
      // Wait for duration to become available (common on web).
      layer._durationSub?.cancel();
      layer._durationSub = layer._player.durationStream.listen((d) {
        if (d == null) return;
        layer.fileDuration = d;
        layer._durationSub?.cancel();
        layer._durationSub = null;
        _startPositionMonitor(layer);
      });
    }
  }

  /// Subscribes to [layer._player]'s position stream and triggers a crossfade
  /// when the playhead is within ([_xfadeDuration] + [_xfadeBuffer]) of the
  /// end. Works regardless of timer precision and compensates for any drift.
  void _startPositionMonitor(AudioLayer layer) {
    layer._positionSub?.cancel();
    layer._positionSub = null;

    final duration = layer.fileDuration;
    if (duration == null) return;

    final threshold = _xfadeDuration + _xfadeBuffer;

    layer._positionSub = layer._player.positionStream.listen((position) {
      if (layer._xfadeTimer != null) return; // crossfade already running
      if (position < duration - threshold) return; // too early

      // Within the crossfade window — trigger the transition.
      layer._positionSub?.cancel();
      layer._positionSub = null;
      _startCrossfade(layer);
    });
  }

  /// Launches a fresh secondary player and blends from [_player] to [_xPlayer]
  /// over [_xfadeDuration]. Both players carry [LoopMode.one] so either can
  /// survive if the crossfade fires slightly late.
  Future<void> _startCrossfade(AudioLayer layer) async {
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

  /// Swaps in the secondary player as the new primary, disposes the old one,
  /// and begins position monitoring for the next loop crossfade.
  Future<void> _completeCrossfade(AudioLayer layer) async {
    if (!_layers.contains(layer)) {
      await layer._xPlayer?.stop();
      await layer._xPlayer?.dispose();
      layer._xPlayer = null;
      return;
    }

    final oldPlayer = layer._player;
    final newPlayer = layer._xPlayer!;

    layer._player = newPlayer;
    layer._xPlayer = null;
    layer._xfadeT = 0.0;
    // Prefer the new player's duration; keep old value if still unavailable.
    layer.fileDuration = newPlayer.duration ?? layer.fileDuration;
    _applyLayerVolumes(layer);

    await oldPlayer.stop();
    await oldPlayer.dispose();

    // New player already has LoopMode.one; start watching its position.
    _startPositionMonitor(layer);
  }

  @override
  void dispose() {
    for (final layer in _layers) {
      layer._fadeTimer?.cancel();
      layer._xfadeTimer?.cancel();
      layer._positionSub?.cancel();
      layer._durationSub?.cancel();
      layer._player.stop();
      layer._player.dispose();
      layer._xPlayer?.stop();
      layer._xPlayer?.dispose();
    }
    _layers.clear();
    super.dispose();
  }
}
