import 'package:flutter/material.dart';
import '../models/preset.dart';
import '../services/audio_engine.dart';

const List<Preset> _kPresets = [
  Preset(
    name: 'Country Night',
    description: 'Drift off under a blanket of stars',
    icon: Icons.nights_stay_rounded,
    layers: [
      PresetLayer(
        assetPath: 'assets/audio/noise/brown_noise.mp3',
        name: 'Brown Noise',
        volume: 0.4,
      ),
      PresetLayer(
        assetPath: 'assets/audio/nature/crickets.mp3',
        name: 'Crickets',
        volume: 0.2,
      ),
      PresetLayer(
        assetPath: 'assets/audio/binaural/delta.mp3',
        name: 'Delta',
        volume: 0.4,
      ),
    ],
  ),
  Preset(
    name: 'Study Sound',
    description: 'Sharpen your focus for deep work',
    icon: Icons.psychology_rounded,
    layers: [
      PresetLayer(
        assetPath: 'assets/audio/noise/white_noise.mp3',
        name: 'White Noise',
        volume: 0.3,
      ),
      PresetLayer(
        assetPath: 'assets/audio/frequencies/417_hz.mp3',
        name: '417 Hz',
        volume: 0.4,
      ),
      PresetLayer(
        assetPath: 'assets/audio/nature/rain.mp3',
        name: 'Rain',
        volume: 0.3,
      ),
    ],
  ),
  Preset(
    name: 'Seaside Meditation',
    description: 'Find your center by the shore',
    icon: Icons.waves_rounded,
    layers: [
      PresetLayer(
        assetPath: 'assets/audio/frequencies/285_hz.mp3',
        name: '285 Hz',
        volume: 0.3,
      ),
      PresetLayer(
        assetPath: 'assets/audio/noise/pink_noise.mp3',
        name: 'Pink Noise',
        volume: 0.35,
      ),
      PresetLayer(
        assetPath: 'assets/audio/nature/ocean.mp3',
        name: 'Ocean',
        volume: 0.35,
      ),
    ],
  ),
  Preset(
    name: 'Deep Focus',
    description: 'Lock in with clarity',
    icon: Icons.center_focus_strong_rounded,
    layers: [
      PresetLayer(
        assetPath: 'assets/audio/binaural/alpha.mp3',
        name: 'Alpha',
        volume: 0.4,
      ),
      PresetLayer(
        assetPath: 'assets/audio/noise/blue_noise.mp3',
        name: 'Blue Noise',
        volume: 0.25,
      ),
      PresetLayer(
        assetPath: 'assets/audio/nature/wind.mp3',
        name: 'Wind',
        volume: 0.35,
      ),
    ],
  ),
  Preset(
    name: 'Clear Your Mind',
    description: 'Release tension and reset',
    icon: Icons.self_improvement_rounded,
    layers: [
      PresetLayer(
        assetPath: 'assets/audio/frequencies/741_hz.mp3',
        name: '741 Hz',
        volume: 0.45,
      ),
      PresetLayer(
        assetPath: 'assets/audio/nature/wind.mp3',
        name: 'Wind',
        volume: 0.3,
      ),
      PresetLayer(
        assetPath: 'assets/audio/noise/red_noise.mp3',
        name: 'Red Noise',
        volume: 0.35,
      ),
    ],
  ),
];

class HomeScreen extends StatefulWidget {
  final AudioEngine engine;

  const HomeScreen({super.key, required this.engine});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _loadingPreset;

  // Derived from engine state — survives tab switches because the engine
  // is long-lived. Returns the name of the preset whose layer set exactly
  // matches what is currently loaded, or null if no preset matches.
  String? get _activePreset {
    final enginePaths =
        widget.engine.layers.map((l) => l.assetPath).toSet();
    if (enginePaths.isEmpty) return null;
    for (final preset in _kPresets) {
      final presetPaths =
          preset.layers.map((l) => l.assetPath).toSet();
      if (enginePaths.length == presetPaths.length &&
          enginePaths.containsAll(presetPaths)) {
        return preset.name;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onEngineChanged);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  // Any engine change (layer added/removed from Home or Mixer) triggers a
  // rebuild so _activePreset is re-derived from the current engine state.
  void _onEngineChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _playPreset(Preset preset) async {
    if (_loadingPreset != null) return;

    // Tapping the active preset stops playback.
    if (_activePreset == preset.name) {
      setState(() => _loadingPreset = preset.name);
      try {
        final paths = widget.engine.layers.map((l) => l.assetPath).toList();
        for (final path in paths) {
          await widget.engine.removeLayer(path);
        }
      } finally {
        if (mounted) setState(() => _loadingPreset = null);
      }
      return;
    }

    setState(() => _loadingPreset = preset.name);
    try {
      // Clear existing layers sequentially before adding new ones.
      final paths = widget.engine.layers.map((l) => l.assetPath).toList();
      for (final path in paths) {
        await widget.engine.removeLayer(path);
      }

      // Add preset layers one at a time; each addLayer must complete before
      // the next begins so the engine never receives concurrent asset loads.
      for (final layer in preset.layers) {
        await widget.engine.addLayer(layer.assetPath, layer.name);
        widget.engine.setVolume(layer.assetPath, layer.volume);
      }
    } finally {
      // Always clear the spinner, even if an error aborted loading.
      // _activePreset will update automatically via _onEngineChanged.
      if (mounted) setState(() => _loadingPreset = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _kPresets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final preset = _kPresets[index];
        return _PresetCard(
          preset: preset,
          isActive: _activePreset == preset.name,
          isLoading: _loadingPreset == preset.name,
          isDisabled:
              _loadingPreset != null && _loadingPreset != preset.name,
          onPlay: () => _playPreset(preset),
        );
      },
    );
  }
}

class _PresetCard extends StatelessWidget {
  final Preset preset;
  final bool isActive;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPlay;

  const _PresetCard({
    required this.preset,
    required this.isActive,
    required this.isLoading,
    required this.isDisabled,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final onSurface = theme.colorScheme.onSurface;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDisabled ? 0.4 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? gold.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled || isLoading ? null : onPlay,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon bubble
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: gold.withValues(
                              alpha: isActive ? 0.22 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(preset.icon, color: gold, size: 22),
                      ),
                      const SizedBox(width: 14),
                      // Name + description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preset.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurface.withValues(alpha: 0.55),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _PlayButton(
                        isActive: isActive,
                        isLoading: isLoading,
                        onTap: onPlay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Layer chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: preset.layers.map((layer) {
                      return _LayerChip(
                        label: layer.name,
                        isActive: isActive,
                        gold: gold,
                      );
                    }).toList(),
                  ),
                  // "Now playing" indicator
                  if (isActive) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 13,
                          color: gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NOW PLAYING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.primary;

    if (isLoading) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(gold),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? gold : gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: isActive ? const Color(0xFF1C1C1C) : gold,
          size: 20,
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color gold;

  const _LayerChip({
    required this.label,
    required this.isActive,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: isActive ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: gold.withValues(alpha: isActive ? 0.35 : 0.12),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isActive ? gold : gold.withValues(alpha: 0.65),
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
