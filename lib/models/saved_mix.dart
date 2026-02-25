import 'dart:math';

class MixLayer {
  final String assetPath;
  final String name;
  final double volume;

  const MixLayer({
    required this.assetPath,
    required this.name,
    required this.volume,
  });

  Map<String, dynamic> toJson() => {
        'assetPath': assetPath,
        'name': name,
        'volume': volume,
      };

  factory MixLayer.fromJson(Map<String, dynamic> json) => MixLayer(
        assetPath: json['assetPath'] as String,
        name: json['name'] as String,
        volume: (json['volume'] as num).toDouble(),
      );
}

class SavedMix {
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
            .map((l) => MixLayer.fromJson(l as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
