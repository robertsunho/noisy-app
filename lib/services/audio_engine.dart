import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioLayer {
  final String assetPath;
  final String name;
  AudioPlayer _player;     // currently active player
  AudioPlayer? _xPlayer;   // secondary player during crossfade loop
  double volume;
  double _xfadeT = 0.0;    // 0 = all _player, 1 = all _xPlayer
  Duration? fileDuration;

  Timer? _fadeTimer;        // engine volume fades
  Timer? _scheduleTimer;    // when to start next loop crossfade
  Timer? _xfadeTimer;       // crossfade execution ticks

  AudioLayer({
    required this.assetPath,
    required this.name,
    required AudioPlayer player,
    this.volume = 0.0,
  }) : _player = player;
}

class AudioEngine extends ChangeNotifier {
  static const int maxLayers = 5;

  // Crossfade duration and lead-time before the loop point.
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

    // Fade in to default volume and schedule the seamless loop crossfade.
    _startFade(layer, 0.7, const Duration(milliseconds: 1500));
    _scheduleLoop(layer);
  }

  /// Fades the layer to 0 over ~1 s, then removes and disposes it.
  /// If the layer is already near-silent (volume ≤ 0.02) the fade is skipped
  /// so the journey engine's near-zero removals complete immediately.
  Future<void> removeLayer(String assetPath) async {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;

    final layer = _layers[index];
    layer._fadeTimer?.cancel();
    layer._fadeTimer = null;
    layer._scheduleTimer?.cancel();
    layer._scheduleTimer = null;
    layer._xfadeTimer?.cancel();
    layer._xfadeTimer = null;

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
  /// crossfade in progress.
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

  /// Schedules a crossfade to start [_xfadeDuration] + [_xfadeBuffer] before
  /// the current player reaches the end of [layer.fileDuration].
  void _scheduleLoop(AudioLayer layer) {
    layer._scheduleTimer?.cancel();
    layer._scheduleTimer = null;

    final duration = layer.fileDuration;
    if (duration == null) return;

    final delay = duration - _xfadeDuration - _xfadeBuffer;
    if (delay <= Duration.zero) return; // file too short for crossfade

    layer._scheduleTimer = Timer(delay, () => _startCrossfade(layer));
  }

  /// Starts a crossfade: launches a fresh secondary player and blends
  /// from [layer._player] → [layer._xPlayer] over [_xfadeDuration].
  Future<void> _startCrossfade(AudioLayer layer) async {
    if (!_layers.contains(layer)) return;
    if (layer._xfadeTimer != null) return; // already crossfading

    final next = AudioPlayer();
    await next.setAsset(layer.assetPath);
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
  /// and schedules the next crossfade.
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
    layer.fileDuration = newPlayer.duration;
    _applyLayerVolumes(layer);

    await oldPlayer.stop();
    await oldPlayer.dispose();

    _scheduleLoop(layer);
  }

  @override
  void dispose() {
    for (final layer in _layers) {
      layer._fadeTimer?.cancel();
      layer._scheduleTimer?.cancel();
      layer._xfadeTimer?.cancel();
      layer._player.stop();
      layer._player.dispose();
      layer._xPlayer?.stop();
      layer._xPlayer?.dispose();
    }
    _layers.clear();
    super.dispose();
  }
}
