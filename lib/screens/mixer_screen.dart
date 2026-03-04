import 'package:flutter/material.dart';
import '../models/saved_mix.dart';
import '../services/analytics_service.dart';
import '../services/audio_engine.dart';
import '../services/journey_engine.dart';
import '../services/storage_service.dart';

// ── Sound catalog ─────────────────────────────────────────────────────────────

class SoundItem {
  final String name;
  final String assetPath;
  final String category;

  const SoundItem({
    required this.name,
    required this.assetPath,
    required this.category,
  });
}

const List<SoundItem> _kSoundCatalog = [
  // Nature
  SoundItem(name: 'Rain', assetPath: 'assets/audio/nature/rain.mp3', category: 'Nature'),
  SoundItem(name: 'Wind', assetPath: 'assets/audio/nature/wind.mp3', category: 'Nature'),
  SoundItem(name: 'Ocean', assetPath: 'assets/audio/nature/ocean.mp3', category: 'Nature'),
  SoundItem(name: 'Thunder', assetPath: 'assets/audio/nature/thunder.mp3', category: 'Nature'),
  SoundItem(name: 'Crickets', assetPath: 'assets/audio/nature/crickets.mp3', category: 'Nature'),
  // Noise
  SoundItem(name: 'White Noise', assetPath: 'assets/audio/noise/white_noise.mp3', category: 'Noise'),
  SoundItem(name: 'Blue Noise', assetPath: 'assets/audio/noise/blue_noise.mp3', category: 'Noise'),
  SoundItem(name: 'Brown Noise', assetPath: 'assets/audio/noise/brown_noise.mp3', category: 'Noise'),
  SoundItem(name: 'Pink Noise', assetPath: 'assets/audio/noise/pink_noise.mp3', category: 'Noise'),
  SoundItem(name: 'Red Noise', assetPath: 'assets/audio/noise/red_noise.mp3', category: 'Noise'),
  // Binaural
  SoundItem(name: 'Alpha', assetPath: 'assets/audio/binaural/alpha.mp3', category: 'Binaural'),
  SoundItem(name: 'Beta', assetPath: 'assets/audio/binaural/beta.mp3', category: 'Binaural'),
  SoundItem(name: 'Delta', assetPath: 'assets/audio/binaural/delta.mp3', category: 'Binaural'),
  SoundItem(name: 'Gamma', assetPath: 'assets/audio/binaural/gamma.mp3', category: 'Binaural'),
  SoundItem(name: 'Theta', assetPath: 'assets/audio/binaural/theta.mp3', category: 'Binaural'),
  // Frequencies
  SoundItem(name: '174 Hz', assetPath: 'assets/audio/frequencies/174_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '285 Hz', assetPath: 'assets/audio/frequencies/285_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '396 Hz', assetPath: 'assets/audio/frequencies/396_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '417 Hz', assetPath: 'assets/audio/frequencies/417_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '432 Hz', assetPath: 'assets/audio/frequencies/432_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '528 Hz', assetPath: 'assets/audio/frequencies/528_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '639 Hz', assetPath: 'assets/audio/frequencies/639_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '741 Hz', assetPath: 'assets/audio/frequencies/741_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '852 Hz', assetPath: 'assets/audio/frequencies/852_hz.mp3', category: 'Frequencies'),
  SoundItem(name: '963 Hz', assetPath: 'assets/audio/frequencies/963_hz.mp3', category: 'Frequencies'),
];

const _kCategories = ['Nature', 'Noise', 'Binaural', 'Frequencies'];
const _kMixCategories = ['Sleep', 'Focus', 'Meditate', 'Relax', 'Energize'];

// ── Widget ────────────────────────────────────────────────────────────────────

class MixerScreen extends StatefulWidget {
  final AudioEngine engine;
  final JourneyEngine journeyEngine;
  final StorageService storage;
  final AnalyticsService analyticsService;
  final VoidCallback? onMixSaved;

  const MixerScreen({
    super.key,
    required this.engine,
    required this.journeyEngine,
    required this.storage,
    required this.analyticsService,
    this.onMixSaved,
  });

  @override
  State<MixerScreen> createState() => MixerScreenState();
}

class MixerScreenState extends State<MixerScreen> {
  final Set<String> _loading = {};
  bool _engineChangePending = false;

  AudioEngine get _engine => widget.engine;

  @override
  void initState() {
    super.initState();
    _engine.addListener(_onEngineChanged);
  }

  void _onEngineChanged() {
    if (!mounted || _engineChangePending) return;
    _engineChangePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engineChangePending = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    super.dispose();
  }

  // ── Public API (called by MainShell via GlobalKey) ────────────────────────

  void openSaveDialog() => _showSaveDialog();

  // ── Layer removal ─────────────────────────────────────────────────────────

  /// Abandons any active journey (without touching audio), then removes
  /// the layer. Using abandon() instead of stop() means remaining layers
  /// keep playing at their current volumes.
  Future<void> _removeLayer(String assetPath) async {
    final layerName = _engine.layers
        .where((l) => l.assetPath == assetPath)
        .map((l) => l.name)
        .firstOrNull ?? assetPath;
    if (widget.journeyEngine.state != JourneyState.stopped) {
      widget.journeyEngine.abandon();
    }
    await _engine.removeLayer(assetPath);
    widget.analyticsService.logLayerRemove(layerName: layerName);
  }

  // ── Sound tap ─────────────────────────────────────────────────────────────

  Future<void> _onSoundTapped(SoundItem sound) async {
    if (_loading.contains(sound.assetPath)) return;

    if (_engine.hasLayer(sound.assetPath)) {
      await _removeLayer(sound.assetPath);
      return;
    }

    if (_engine.isFull) return;

    setState(() => _loading.add(sound.assetPath));
    try {
      await _engine.addLayer(sound.assetPath, sound.name);
      widget.analyticsService.logLayerAdd(
        layerName: sound.name,
        category: sound.category,
      );
    } catch (e) {
      debugPrint('AudioEngine.addLayer error: $e');
    } finally {
      if (mounted) setState(() => _loading.remove(sound.assetPath));
    }
  }

  // ── Save dialog ───────────────────────────────────────────────────────────

  void _showSaveDialog() {
    final controller = TextEditingController();
    String selectedCategory = '';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final theme = Theme.of(ctx);
          final gold = theme.colorScheme.primary;
          final canSave = controller.text.trim().isNotEmpty &&
              _engine.layers.isNotEmpty;

          return AlertDialog(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            title: Text(
              'Save Mix',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                TextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Mix name',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: gold, width: 2),
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 20),

                // Category chips
                Text(
                  'CATEGORY (OPTIONAL)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kMixCategories.map((cat) {
                    final sel = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setDialogState(
                          () => selectedCategory = sel ? '' : cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? gold
                              : gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color:
                                sel ? const Color(0xFF1C1C1C) : gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style:
                      TextStyle(color: theme.colorScheme.outline),
                ),
              ),
              FilledButton(
                onPressed: canSave
                    ? () async {
                        final mix = SavedMix(
                          id: SavedMix.generateId(),
                          name: controller.text.trim(),
                          category: selectedCategory,
                          layers: _engine.layers
                              .map((l) => MixLayer(
                                    assetPath: l.assetPath,
                                    name: l.name,
                                    volume: l.volume,
                                  ))
                              .toList(),
                          createdAt: DateTime.now(),
                        );
                        await widget.storage.save(mix);
                        widget.analyticsService.logMixSave(mixName: mix.name);
                        widget.onMixSaved?.call();
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: const Color(0xFF1C1C1C),
                  disabledBackgroundColor:
                      gold.withValues(alpha: 0.3),
                  disabledForegroundColor:
                      const Color(0xFF1C1C1C).withValues(alpha: 0.4),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).then((_) => controller.dispose());
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layers = _engine.layers;

    final Map<String, List<SoundItem>> grouped = {};
    for (final sound in _kSoundCatalog) {
      grouped.putIfAbsent(sound.category, () => []).add(sound);
    }

    return CustomScrollView(
      slivers: [
        // ── Active Mix ───────────────────────────────────────────────────
        if (layers.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Active Mix',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${layers.length}/${AudioEngine.maxLayers}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _LayerCard(
                key: ValueKey(layers[i].assetPath),
                layer: layers[i],
                engine: _engine,
                journeyEngine: widget.journeyEngine,
                onRemove: () => _removeLayer(layers[i].assetPath),
              ),
              childCount: layers.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            ),
          ),
        ],

        // ── Sound Library ────────────────────────────────────────────────
        for (final category in _kCategories)
          if (grouped[category]?.isNotEmpty == true) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text(
                  category.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sound in grouped[category]!)
                      _SoundChip(
                        sound: sound,
                        isActive: _engine.hasLayer(sound.assetPath),
                        isLoading: _loading.contains(sound.assetPath),
                        isDisabled: !_engine.hasLayer(sound.assetPath) &&
                            _engine.isFull,
                        onTap: () => _onSoundTapped(sound),
                      ),
                  ],
                ),
              ),
            ),
          ],

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Layer card ────────────────────────────────────────────────────────────────

class _LayerCard extends StatefulWidget {
  final AudioLayer layer;
  final AudioEngine engine;
  final JourneyEngine journeyEngine;
  final VoidCallback onRemove;

  const _LayerCard({
    super.key,
    required this.layer,
    required this.engine,
    required this.journeyEngine,
    required this.onRemove,
  });

  @override
  State<_LayerCard> createState() => _LayerCardState();
}

class _LayerCardState extends State<_LayerCard> {
  late double _volume;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _volume = widget.layer.volume;
  }

  @override
  void didUpdateWidget(_LayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _volume = widget.layer.volume;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.layer.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor:
                          theme.colorScheme.outline.withValues(alpha: 0.3),
                      thumbColor: theme.colorScheme.primary,
                      overlayColor:
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _volume,
                      min: 0.0,
                      max: 1.0,
                      onChangeStart: (_) {
                        // Abandon any active journey on the first drag so the
                        // tick can't overwrite this slider's position.
                        if (widget.journeyEngine.state !=
                            JourneyState.stopped) {
                          widget.journeyEngine.abandon();
                        }
                        setState(() => _isDragging = true);
                      },
                      onChangeEnd: (_) =>
                          setState(() => _isDragging = false),
                      onChanged: (v) {
                        setState(() => _volume = v);
                        widget.engine.setVolume(widget.layer.assetPath, v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: theme.colorScheme.outline,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: widget.onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sound chip ────────────────────────────────────────────────────────────────

class _SoundChip extends StatelessWidget {
  final SoundItem sound;
  final bool isActive;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  const _SoundChip({
    required this.sound,
    required this.isActive,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final borderColor = isActive
        ? theme.colorScheme.primary
        : isDisabled
            ? theme.colorScheme.outline.withValues(alpha: 0.2)
            : theme.colorScheme.outline.withValues(alpha: 0.6);

    final bgColor = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : theme.colorScheme.surfaceContainerHighest;

    final textColor = isActive
        ? theme.colorScheme.primary
        : isDisabled
            ? theme.colorScheme.outline.withValues(alpha: 0.4)
            : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: isDisabled || isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              )
            else if (isActive)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            Text(
              sound.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
