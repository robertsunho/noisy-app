import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioLayer {
  final String assetPath;
  final String name;
  final AudioPlayer _player;
  double volume;

  AudioLayer({
    required this.assetPath,
    required this.name,
    required AudioPlayer player,
    this.volume = 0.7,
  }) : _player = player;
}

class AudioEngine extends ChangeNotifier {
  static const int maxLayers = 5;

  final List<AudioLayer> _layers = [];

  List<AudioLayer> get layers => List.unmodifiable(_layers);

  bool get isFull => _layers.length >= maxLayers;

  bool hasLayer(String assetPath) =>
      _layers.any((l) => l.assetPath == assetPath);

  Future<void> addLayer(String assetPath, String name) async {
    if (isFull || hasLayer(assetPath)) return;

    final player = AudioPlayer();
    await player.setAsset(assetPath);
    await player.setLoopMode(LoopMode.one);
    await player.setVolume(0.7);

    // Add to list and notify before play() so the UI updates
    // even if play() encounters a browser autoplay restriction.
    _layers.add(AudioLayer(
      assetPath: assetPath,
      name: name,
      player: player,
    ));
    notifyListeners();

    await player.play();
  }

  Future<void> removeLayer(String assetPath) async {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;

    final layer = _layers.removeAt(index);
    notifyListeners();

    await layer._player.stop();
    await layer._player.dispose();
  }

  // Synchronous — no notifyListeners so rapid slider drags don't
  // flood the widget tree with rebuilds. _LayerCard manages its
  // own local slider state.
  void setVolume(String assetPath, double volume) {
    final index = _layers.indexWhere((l) => l.assetPath == assetPath);
    if (index == -1) return;
    final layer = _layers[index];
    layer.volume = volume.clamp(0.0, 1.0);
    layer._player.setVolume(layer.volume);
  }

  @override
  void dispose() {
    for (final layer in _layers) {
      layer._player.stop();
      layer._player.dispose();
    }
    _layers.clear();
    super.dispose();
  }
}
