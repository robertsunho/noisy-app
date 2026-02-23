import 'package:flutter/material.dart';

class PresetLayer {
  final String assetPath;
  final String name;
  final double volume; // 0.0 – 1.0

  const PresetLayer({
    required this.assetPath,
    required this.name,
    required this.volume,
  });
}

class Preset {
  final String name;
  final String description;
  final IconData icon;
  final List<PresetLayer> layers;

  const Preset({
    required this.name,
    required this.description,
    required this.icon,
    required this.layers,
  });
}
