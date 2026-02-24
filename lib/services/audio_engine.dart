import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioLayer {
  final String assetPath;
  final String name;
  final AudioPlayer _player;
  double volume;

  /// Tracks any ongoing fade for this layer. Cancelled on setVolume,
  /// new fadeToVolume calls, and dispose.
  Timer? _fadeTimer;

  AudioLayer({
    required this.assetPath,
    required this.name,
    required AudioPlayer player,
    this.volume = 0.0,
  }) : _player = player;
}

class AudioEngine extends ChangeNotifier {
  static const int maxLayers = 5;

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
    await player.setLoopMode(LoopMode.one);
    await player.setVolume(0.0);

    final layer = AudioLayer(
      assetPath: assetPath,
      name: name,
      player: player,
      volume: 0.0,
    );
    _layers.add(layer);
    notifyListeners();

    // Do NOT await play() — for LoopMode.one the returned Future only
    // resolves when stop() is called, which would permanently block any
    // caller that awaits addLayer (e.g. parallel preset loading).
    unawaited(player.play());

    // Fade in to default volume.
    _startFade(layer, 0.7, const Duration(milliseconds: 1500));
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
  }

  /// Smoothly transitions a layer's volume from its current level to
  /// [targetVolume] over [duration]. Cancels any fade already in progress.
  void fadeToVolume(String assetPath, double targetVolume, Duration duration) {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;
    _startFade(_layers[index], targetVolume.clamp(0.0, 1.0), duration);
  }

  /// Instant volume change — used by the journey engine's per-tick
  /// interpolation (which already produces smooth transitions) and by the
  /// mixer slider during active drag. Cancels any fade in progress.
  void setVolume(String assetPath, double volume) {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;
    final layer = _layers[index];
    layer._fadeTimer?.cancel();
    layer._fadeTimer = null;
    layer.volume = volume.clamp(0.0, 1.0);
    layer._player.setVolume(layer.volume);
  }

  // ── Private ──────────────────────────────────────────────────────────────

  /// Linearly interpolates [layer.volume] toward [targetVolume] over
  /// [duration] in 50 ms steps, calling [notifyListeners] on each tick so
  /// sliders in the Mixer can follow the fade in real time.
  /// Fires [onComplete] (if provided) after the final tick.
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
      layer._player.setVolume(targetVolume);
      notifyListeners();
      onComplete?.call();
      return;
    }

    final steps = (duration.inMilliseconds / 50).ceil();
    final startVolume = layer.volume;
    int tick = 0;

    layer._fadeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      tick++;
      if (tick >= steps) {
        timer.cancel();
        layer._fadeTimer = null;
        layer.volume = targetVolume;
        layer._player.setVolume(targetVolume);
        notifyListeners();
        onComplete?.call();
      } else {
        final t = tick / steps;
        layer.volume =
            (startVolume + (targetVolume - startVolume) * t).clamp(0.0, 1.0);
        layer._player.setVolume(layer.volume);
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    for (final layer in _layers) {
      layer._fadeTimer?.cancel();
      layer._player.stop();
      layer._player.dispose();
    }
    _layers.clear();
    super.dispose();
  }
}
