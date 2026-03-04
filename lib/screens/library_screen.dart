import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/saved_mix.dart';
import '../models/sound_meta.dart';
import '../services/audio_engine.dart';
import '../services/storage_service.dart';

// ─── Category constants ───────────────────────────────────────────────────────

const _kCategoryOrder = ['nature', 'noise', 'frequencies', 'binaural'];

const _kCategoryLabels = {
  'nature': 'Nature',
  'noise': 'Noise',
  'frequencies': 'Frequencies',
  'binaural': 'Binaural',
};

const _kCategoryIcons = <String, IconData>{
  'nature': Icons.park_rounded,
  'noise': Icons.waves_rounded,
  'frequencies': Icons.graphic_eq_rounded,
  'binaural': Icons.headphones_rounded,
};

// ─── Intention data ───────────────────────────────────────────────────────────

class _Intention {
  final String id;
  final String label;
  final IconData icon;

  const _Intention(this.id, this.label, this.icon);
}

const _kIntentions = [
  _Intention('sleep', 'Sleep', Icons.bedtime_rounded),
  _Intention('focus', 'Focus', Icons.psychology_rounded),
  _Intention('meditate', 'Meditate', Icons.self_improvement_rounded),
  _Intention('relax', 'Relax', Icons.spa_rounded),
  _Intention('energize', 'Energize', Icons.bolt_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
// Library screen — top-level tab content
// ─────────────────────────────────────────────────────────────────────────────

class LibraryScreen extends StatefulWidget {
  final AudioEngine engine;
  final StorageService storage;

  const LibraryScreen({
    super.key,
    required this.engine,
    required this.storage,
  });

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  List<SavedMix> _savedMixes = [];

  @override
  void initState() {
    super.initState();
    loadMixes();
  }

  // ── Public API (called by MainShell via GlobalKey) ────────────────────────

  Future<void> loadMixes() async {
    final mixes = await widget.storage.loadAll();
    mixes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (mounted) setState(() => _savedMixes = mixes);
  }

  // ── Mix actions ───────────────────────────────────────────────────────────

  Future<void> _playSavedMix(SavedMix mix) async {
    final existing =
        widget.engine.layers.map((l) => l.assetPath).toList();
    await Future.wait(existing.map(widget.engine.removeLayer));
    if (!mounted) return;

    for (final layer in mix.layers) {
      if (widget.engine.isFull) break;
      await widget.engine.addLayer(layer.assetPath, layer.name);
      if (!mounted) return;
    }

    for (final layer in mix.layers) {
      widget.engine.fadeToVolume(
        layer.assetPath,
        layer.volume,
        const Duration(seconds: 2),
      );
    }
  }

  Future<void> _deleteMix(SavedMix mix) async {
    setState(() => _savedMixes.removeWhere((m) => m.id == mix.id));
    await widget.storage.delete(mix.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${mix.name}" deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await widget.storage.save(mix);
            await loadMixes();
          },
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openSounds(
    BuildContext context, {
    String? tag,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SoundsScreen(
            engine: widget.engine, filterTag: tag, title: title),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // ── My Mixes ──────────────────────────────────────────────────────
        if (_savedMixes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                'MY MIXES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isOdd) return const SizedBox(height: 10);
                  final mix = _savedMixes[index ~/ 2];
                  return Dismissible(
                    key: ValueKey(mix.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteMix(mix),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.white),
                    ),
                    child: _MixCard(
                      mix: mix,
                      onPlay: () => _playSavedMix(mix),
                    ),
                  );
                },
                childCount: _savedMixes.length * 2 - 1,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],

        // ── Browse All ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, _savedMixes.isEmpty ? 20 : 0, 16, 0),
            child: _BrowseCard(
              soundCount: kSoundCatalog.length,
              onTap: () => _openSounds(context, title: 'All Sounds'),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── By Intention ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'BY INTENTION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 12) / 2;
                return Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _IntentionCard(
                            intention: _kIntentions[0],
                            onTap: () => _openSounds(
                              context,
                              tag: _kIntentions[0].id,
                              title: _kIntentions[0].label,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: cardWidth,
                          child: _IntentionCard(
                            intention: _kIntentions[1],
                            onTap: () => _openSounds(
                              context,
                              tag: _kIntentions[1].id,
                              title: _kIntentions[1].label,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _IntentionCard(
                            intention: _kIntentions[2],
                            onTap: () => _openSounds(
                              context,
                              tag: _kIntentions[2].id,
                              title: _kIntentions[2].label,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: cardWidth,
                          child: _IntentionCard(
                            intention: _kIntentions[3],
                            onTap: () => _openSounds(
                              context,
                              tag: _kIntentions[3].id,
                              title: _kIntentions[3].label,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _IntentionCard(
                            intention: _kIntentions[4],
                            onTap: () => _openSounds(
                              context,
                              tag: _kIntentions[4].id,
                              title: _kIntentions[4].label,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mix card
// ─────────────────────────────────────────────────────────────────────────────

class _MixCard extends StatelessWidget {
  final SavedMix mix;
  final VoidCallback onPlay;

  const _MixCard({required this.mix, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPlay,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              mix.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (mix.category.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: gold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: gold.withValues(alpha: 0.25),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                mix.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: gold,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: mix.layers
                            .map((l) => _LayerChip(label: l.name, gold: gold))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IgnorePointer(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: gold,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Browse All card
// ─────────────────────────────────────────────────────────────────────────────

class _BrowseCard extends StatelessWidget {
  final int soundCount;
  final VoidCallback onTap;

  const _BrowseCard({required this.soundCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.library_music_rounded, color: gold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse All',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$soundCount sounds',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Intention card
// ─────────────────────────────────────────────────────────────────────────────

class _IntentionCard extends StatelessWidget {
  final _Intention intention;
  final VoidCallback onTap;

  const _IntentionCard({required this.intention, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    final count = kSoundCatalog
        .where((s) => s.tags.contains(intention.id) && s.isAvailable)
        .length;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(intention.icon, color: gold, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                intention.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count sounds',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sounds screen — pushed route with expandable sound cards
// ─────────────────────────────────────────────────────────────────────────────

class _SoundsScreen extends StatefulWidget {
  final AudioEngine engine;
  final String? filterTag;
  final String title;

  const _SoundsScreen({
    required this.engine,
    required this.title,
    this.filterTag,
  });

  @override
  State<_SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<_SoundsScreen> {
  AudioPlayer? _previewPlayer;
  double _previewVolume = 0.0;
  Timer? _previewFadeTimer;
  String? _previewingPath;
  bool _previewLoading = false;
  StreamSubscription<ProcessingState>? _previewSub;
  bool _engineChangePending = false;

  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_onEngineChanged);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_onEngineChanged);
    _cleanupPreview();
    super.dispose();
  }

  void _onEngineChanged() {
    if (!mounted || _engineChangePending) return;
    _engineChangePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _engineChangePending = false;
      if (mounted) setState(() {});
    });
  }

  void _cleanupPreview() {
    _previewFadeTimer?.cancel();
    _previewFadeTimer = null;
    _previewSub?.cancel();
    _previewSub = null;
    _previewPlayer?.stop();
    _previewPlayer?.dispose();
    _previewPlayer = null;
    _previewVolume = 0.0;
  }

  Future<void> _stopPreviewWithFade() async {
    final player = _previewPlayer;
    if (player == null) return;

    _previewFadeTimer?.cancel();
    _previewFadeTimer = null;
    _previewSub?.cancel();
    _previewSub = null;
    _previewPlayer = null;

    final startVol = _previewVolume;
    _previewVolume = 0.0;

    if (startVol > 0.01) {
      const steps = 10;
      int tick = 0;
      final completer = Completer<void>();

      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        tick++;
        if (tick >= steps) {
          timer.cancel();
          player.setVolume(0);
          if (!completer.isCompleted) completer.complete();
        } else {
          player.setVolume(startVol * (1.0 - tick / steps));
        }
      });

      await completer.future;
    }

    await player.stop();
    await player.dispose();
  }

  Future<void> _togglePreview(SoundMeta meta) async {
    if (_previewingPath == meta.assetPath) {
      if (mounted) setState(() => _previewingPath = null);
      await _stopPreviewWithFade();
      return;
    }

    _cleanupPreview();
    if (!mounted) return;

    setState(() {
      _previewLoading = true;
      _previewingPath = meta.assetPath;
      _previewVolume = 0.0;
    });

    final player = AudioPlayer();
    _previewPlayer = player;

    try {
      await player.setAsset(meta.assetPath);
      await player.setVolume(0.0);

      _previewSub = player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _previewFadeTimer?.cancel();
          _previewFadeTimer = null;
          if (_previewPlayer == player) {
            _previewPlayer?.dispose();
            _previewPlayer = null;
            _previewVolume = 0.0;
          }
          if (mounted) {
            setState(() {
              _previewingPath = null;
              _previewLoading = false;
            });
          }
        }
      });

      unawaited(player.play());
      if (mounted) setState(() => _previewLoading = false);

      const targetVol = 0.7;
      const steps = 30;
      int tick = 0;

      _previewFadeTimer =
          Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (_previewPlayer != player) {
          timer.cancel();
          return;
        }
        tick++;
        if (tick >= steps) {
          timer.cancel();
          _previewFadeTimer = null;
          _previewVolume = targetVol;
          player.setVolume(targetVol);
        } else {
          _previewVolume = targetVol * tick / steps;
          player.setVolume(_previewVolume);
        }
      });
    } catch (_) {
      _cleanupPreview();
      if (mounted) {
        setState(() {
          _previewingPath = null;
          _previewLoading = false;
          _previewVolume = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not preview ${meta.name}')),
        );
      }
    }
  }

  Future<void> _addToMix(SoundMeta meta) async {
    try {
      await widget.engine.addLayer(meta.assetPath, meta.name);
      widget.engine.fadeToVolume(
        meta.assetPath,
        meta.defaultVolume,
        const Duration(milliseconds: 1500),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add ${meta.name} to mix')),
        );
      }
    }
  }

  List<SoundMeta> get _filteredSounds {
    if (widget.filterTag == null) return kSoundCatalog;
    return kSoundCatalog
        .where((s) => s.tags.contains(widget.filterTag))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sounds = _filteredSounds;
    final Map<String, List<SoundMeta>> grouped = {};
    for (final s in sounds) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          for (final category in _kCategoryOrder)
            if (grouped[category]?.isNotEmpty == true) ...[
              _SectionHeader(category: category),
              for (final meta in grouped[category]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SoundCard(
                    key: ValueKey(meta.id),
                    meta: meta,
                    engine: widget.engine,
                    isPreviewLoading:
                        _previewLoading && _previewingPath == meta.assetPath,
                    isPreviewing:
                        !_previewLoading && _previewingPath == meta.assetPath,
                    onPreview: () => _togglePreview(meta),
                    onAddToMix: () => _addToMix(meta),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expandable sound card
// ─────────────────────────────────────────────────────────────────────────────

class _SoundCard extends StatefulWidget {
  final SoundMeta meta;
  final AudioEngine engine;
  final bool isPreviewLoading;
  final bool isPreviewing;
  final VoidCallback onPreview;
  final VoidCallback onAddToMix;

  const _SoundCard({
    super.key,
    required this.meta,
    required this.engine,
    required this.isPreviewLoading,
    required this.isPreviewing,
    required this.onPreview,
    required this.onAddToMix,
  });

  @override
  State<_SoundCard> createState() => _SoundCardState();
}

class _SoundCardState extends State<_SoundCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    final isInMix = widget.engine.hasLayer(widget.meta.assetPath);
    final isSoon = !widget.meta.isAvailable;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInMix
              ? gold.withValues(alpha: 0.45)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            gold.withValues(alpha: isInMix ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        _kCategoryIcons[widget.meta.category],
                        color: gold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.meta.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isInMix) ...[
                      _Badge(
                        label: 'In Mix',
                        color: gold,
                        bgColor: gold.withValues(alpha: 0.12),
                      ),
                      const SizedBox(width: 8),
                    ] else if (isSoon) ...[
                      _Badge(
                        label: 'Soon',
                        color: theme.colorScheme.outline,
                        bgColor: theme.colorScheme.outline
                            .withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 8),
                    ],
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _expanded ? 0.25 : 0.0,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.outline,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  sizeCurve: Curves.easeInOut,
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: isSoon
                        ? _buildComingSoon(context)
                        : _buildAvailableContent(context, isInMix, gold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableContent(
      BuildContext context, bool isInMix, Color gold) {
    final theme = Theme.of(context);
    final isFull = widget.engine.isFull && !isInMix;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.meta.description.isNotEmpty) ...[
          Text(
            widget.meta.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.onPreview,
              icon: widget.isPreviewLoading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: gold,
                      ),
                    )
                  : Icon(
                      widget.isPreviewing
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 16,
                    ),
              label: Text(widget.isPreviewing ? 'Stop' : 'Preview'),
              style: OutlinedButton.styleFrom(
                foregroundColor: widget.isPreviewing
                    ? gold
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                side: BorderSide(
                  color: widget.isPreviewing
                      ? gold.withValues(alpha: 0.6)
                      : theme.colorScheme.outline.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: isInMix || isFull ? null : widget.onAddToMix,
              icon: Icon(
                isInMix ? Icons.check_rounded : Icons.add_rounded,
                size: 16,
              ),
              label: Text(
                isInMix
                    ? 'In Mix'
                    : (isFull ? 'Mixer Full' : 'Add to Mix'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: const Color(0xFF1C1C1C),
                disabledBackgroundColor: gold.withValues(alpha: 0.12),
                disabledForegroundColor: gold.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComingSoon(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.meta.description.isNotEmpty) ...[
          Text(
            widget.meta.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 13,
              color: theme.colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Audio file coming soon',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String category;

  const _SectionHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
      child: Row(
        children: [
          Icon(
            _kCategoryIcons[category],
            size: 13,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            _kCategoryLabels[category]!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final String label;
  final Color gold;

  const _LayerChip({required this.label, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: gold.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: gold.withValues(alpha: 0.65),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
