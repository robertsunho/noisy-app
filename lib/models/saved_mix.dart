import 'dart:math';

import '../services/audio_engine.dart';

/// Which engine method rebuilds a saved layer (D-018).
enum MixLayerKind { sample, soundscape, tone, binaural }

/// One layer of a [SavedMix]: a faithful snapshot of an engine layer, with the
/// parameters needed to rebuild it (D-018).
class MixLayer {
  /// Carrier assumed for a pre-v2 binaural save, which never stored one.
  /// Matches `HarmonicMatcher.defaultFallbackCarrierHz` (D-016).
  static const legacyBinauralCarrierHz = 200.0;

  final MixLayerKind kind;
  final String assetPath;
  final String name;
  final double volume;

  /// Playback-speed pitch shift. Meaningful for [MixLayerKind.soundscape].
  final double pitchShiftRatio;

  /// Tone frequency (Hz). Non-null for [MixLayerKind.tone].
  final double? frequency;

  /// Binaural carrier and beat (Hz). Non-null for [MixLayerKind.binaural].
  final double? carrierHz;
  final double? beatHz;

  const MixLayer({
    required this.assetPath,
    required this.name,
    required this.volume,
    this.kind = MixLayerKind.sample,
    this.pitchShiftRatio = 1.0,
    this.frequency,
    this.carrierHz,
    this.beatHz,
  });

  /// Snapshots a live engine layer. Kind detection mirrors
  /// `Journey.sleepTimer`'s reconstruction of engine layers.
  factory MixLayer.fromEngineLayer(AudioLayer l) {
    if (l.binBeatFreq != null && l.binCenterFreq != null) {
      return MixLayer(
        kind: MixLayerKind.binaural,
        assetPath: l.assetPath,
        name: l.name,
        volume: l.volume,
        carrierHz: l.binCenterFreq,
        beatHz: l.binBeatFreq,
      );
    }
    if (l.isTone && l.toneFreq != null) {
      return MixLayer(
        kind: MixLayerKind.tone,
        assetPath: l.assetPath,
        name: l.name,
        volume: l.volume,
        frequency: l.toneFreq,
      );
    }
    if (l.assetPath.contains('soundscapes/')) {
      return MixLayer(
        kind: MixLayerKind.soundscape,
        assetPath: l.assetPath,
        name: l.name,
        volume: l.volume,
        pitchShiftRatio: l.pitchShiftRatio,
      );
    }
    return MixLayer(assetPath: l.assetPath, name: l.name, volume: l.volume);
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'assetPath': assetPath,
        'name': name,
        'volume': volume,
        if (kind == MixLayerKind.soundscape) 'pitchShiftRatio': pitchShiftRatio,
        if (kind == MixLayerKind.tone) 'frequency': frequency,
        if (kind == MixLayerKind.binaural) ...{
          'carrierHz': carrierHz,
          'beatHz': beatHz,
        },
      };

  /// Parses a saved layer, v2 or pre-v2. Returns null — the layer is skipped —
  /// for an unknown kind or anything malformed, so one bad layer never
  /// discards the whole mix.
  ///
  /// Pre-v2 layers have no `kind`: it is inferred from the ID prefix
  /// (`tone:`, `binaural:`) or the `soundscapes/` folder, and missing
  /// parameters get neutral defaults — pitch ratio 1.0, the frequency encoded
  /// in a `tone:<hz>` / `binaural:<beatHz>` ID, and [legacyBinauralCarrierHz].
  static MixLayer? tryFromJson(Object? json) {
    try {
      if (json is! Map<String, dynamic>) return null;
      final assetPath = json['assetPath'] as String;
      final name = json['name'] as String;
      final volume = (json['volume'] as num).toDouble();

      // Defaults are for *absent* parameters (pre-v2 saves). A parameter that
      // is present but not a number is malformed: skip the layer.
      for (final key in const [
        'pitchShiftRatio', 'frequency', 'carrierHz', 'beatHz',
      ]) {
        final v = json[key];
        if (v != null && v is! num) return null;
      }

      final kindName = json['kind'];
      final MixLayerKind kind;
      if (kindName == null) {
        kind = _inferKind(assetPath);
      } else {
        final k = MixLayerKind.values.asNameMap()[kindName];
        if (k == null) return null;
        kind = k;
      }

      switch (kind) {
        case MixLayerKind.sample:
          return MixLayer(assetPath: assetPath, name: name, volume: volume);
        case MixLayerKind.soundscape:
          final ratio = _num(json['pitchShiftRatio']);
          return MixLayer(
            kind: kind,
            assetPath: assetPath,
            name: name,
            volume: volume,
            pitchShiftRatio: _isPositiveFinite(ratio) ? ratio! : 1.0,
          );
        case MixLayerKind.tone:
          final freq = _num(json['frequency']) ?? _idHz(assetPath, 'tone:');
          if (!_isPositiveFinite(freq)) return null;
          return MixLayer(
            kind: kind,
            assetPath: assetPath,
            name: name,
            volume: volume,
            frequency: freq,
          );
        case MixLayerKind.binaural:
          final beat = _num(json['beatHz']) ?? _idHz(assetPath, 'binaural:');
          final carrier = _num(json['carrierHz']) ?? legacyBinauralCarrierHz;
          if (!_isPositiveFinite(beat) || !_isPositiveFinite(carrier)) return null;
          return MixLayer(
            kind: kind,
            assetPath: assetPath,
            name: name,
            volume: volume,
            carrierHz: carrier,
            beatHz: beat,
          );
      }
    } catch (_) {
      return null;
    }
  }

  static MixLayerKind _inferKind(String assetPath) {
    if (assetPath.startsWith('tone:')) return MixLayerKind.tone;
    if (assetPath.startsWith('binaural:')) return MixLayerKind.binaural;
    if (assetPath.contains('soundscapes/')) return MixLayerKind.soundscape;
    return MixLayerKind.sample;
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  static double? _idHz(String id, String prefix) => id.startsWith(prefix)
      ? double.tryParse(id.substring(prefix.length))
      : null;

  static bool _isPositiveFinite(double? v) => v != null && v.isFinite && v > 0;
}

class SavedMix {
  /// Saved-format schema version. Pre-v2 saves have no version field (and no
  /// per-layer kind); they still load via [MixLayer.tryFromJson] inference.
  /// Exists so V2 can migrate saved data (D-018).
  static const currentVersion = 2;

  final String id;
  final String name;

  /// One of 'Sleep', 'Focus', 'Meditate', 'Relax', 'Energize', or '' (none).
  final String category;
  final List<MixLayer> layers;
  final DateTime createdAt;

  const SavedMix({
    required this.id,
    required this.name,
    required this.category,
    required this.layers,
    required this.createdAt,
  });

  /// Generates a random UUID v4.
  static String generateId() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-'
        '${h.substring(20)}';
  }

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'id': id,
        'name': name,
        'category': category,
        'layers': layers.map((l) => l.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedMix.fromJson(Map<String, dynamic> json) => SavedMix(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        layers: (json['layers'] as List)
            .map(MixLayer.tryFromJson)
            .whereType<MixLayer>()
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
