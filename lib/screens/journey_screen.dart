import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../services/audio_engine.dart';
import '../services/journey_engine.dart';
import '../services/motif_engine.dart';

// ─── Duration quick-pick helpers ─────────────────────────────────────────────

const _kNiceMinutes = <int>[10, 15, 20, 30, 40, 45, 60, 90, 120, 180];

List<int> _quickPicks(Journey j) {
  final min = j.minDuration.inMinutes;
  final max = j.maxDuration.inMinutes;
  return _kNiceMinutes.where((m) => m >= min && m <= max).toList();
}

// ─── Journey catalog ──────────────────────────────────────────────────────────

const List<Journey> _kJourneys = [
  // ── Country Night ────────────────────────────────────────────────────────
  Journey(
    id: 'country_night',
    name: 'Country Night',
    description: 'Drift off under a blanket of stars',
    icon: Icons.nights_stay_rounded,
    category: 'Sleep',
    defaultDuration: Duration(minutes: 45),
    minDuration: Duration(minutes: 20),
    maxDuration: Duration(minutes: 90),
    waypoints: [
      JourneyWaypoint(layers: [
        SampleSource(assetPath: 'assets/audio/noise/brown_noise.mp3', volume: 0.4),
        SampleSource(assetPath: 'assets/audio/nature/crickets.mp3', volume: 0.2),
        SampleSource(assetPath: 'assets/audio/binaural/delta.mp3', volume: 0.4),
      ]),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/noise/brown_noise.mp3', volume: 0.2),
          SampleSource(assetPath: 'assets/audio/nature/crickets.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/binaural/delta.mp3', volume: 0.5),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/noise/brown_noise.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/nature/crickets.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/binaural/delta.mp3', volume: 0.3),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/noise/brown_noise.mp3', volume: 0.5),
          SampleSource(assetPath: 'assets/audio/nature/crickets.mp3', volume: 0.5),
          SampleSource(assetPath: 'assets/audio/binaural/delta.mp3', volume: 0.0),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
    ],
  ),

  // ── Study Sound ──────────────────────────────────────────────────────────
  Journey(
    id: 'study_sound',
    name: 'Study Sound',
    description: 'Sharpen your focus for deep work',
    icon: Icons.menu_book_rounded,
    category: 'Focus',
    defaultDuration: Duration(minutes: 60),
    minDuration: Duration(minutes: 30),
    maxDuration: Duration(minutes: 120),
    waypoints: [
      JourneyWaypoint(layers: [
        SampleSource(assetPath: 'assets/audio/noise/white_noise.mp3', volume: 0.3),
        SampleSource(assetPath: 'assets/audio/frequencies/417_hz.mp3', volume: 0.4),
        SampleSource(assetPath: 'assets/audio/nature/rain.mp3', volume: 0.3),
      ]),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/noise/white_noise.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/frequencies/417_hz.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/nature/rain.mp3', volume: 0.3),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/noise/white_noise.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/frequencies/417_hz.mp3', volume: 0.2),
          SampleSource(assetPath: 'assets/audio/nature/rain.mp3', volume: 0.4),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/noise/white_noise.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/frequencies/417_hz.mp3', volume: 0.1),
          SampleSource(assetPath: 'assets/audio/nature/rain.mp3', volume: 0.5),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
    ],
  ),

  // ── Seaside Meditation ───────────────────────────────────────────────────
  Journey(
    id: 'seaside_meditation',
    name: 'Seaside Meditation',
    description: 'Find your center by the shore',
    icon: Icons.self_improvement_rounded,
    category: 'Meditate',
    defaultDuration: Duration(minutes: 30),
    minDuration: Duration(minutes: 15),
    maxDuration: Duration(minutes: 60),
    waypoints: [
      JourneyWaypoint(layers: [
        SampleSource(assetPath: 'assets/audio/frequencies/285_hz.mp3', volume: 0.3),
        SampleSource(assetPath: 'assets/audio/noise/pink_noise.mp3', volume: 0.35),
        SampleSource(assetPath: 'assets/audio/nature/ocean.mp3', volume: 0.35),
      ]),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/frequencies/285_hz.mp3', volume: 0.45),
          SampleSource(assetPath: 'assets/audio/noise/pink_noise.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/nature/ocean.mp3', volume: 0.15),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/frequencies/285_hz.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/noise/pink_noise.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/nature/ocean.mp3', volume: 0.3),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/frequencies/285_hz.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/noise/pink_noise.mp3', volume: 0.2),
          SampleSource(assetPath: 'assets/audio/nature/ocean.mp3', volume: 0.4),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
    ],
  ),

  // ── Deep Focus ───────────────────────────────────────────────────────────
  Journey(
    id: 'deep_focus',
    name: 'Deep Focus',
    description: 'Lock in with clarity',
    icon: Icons.psychology_rounded,
    category: 'Focus',
    defaultDuration: Duration(minutes: 90),
    minDuration: Duration(minutes: 45),
    maxDuration: Duration(minutes: 180),
    waypoints: [
      JourneyWaypoint(layers: [
        SampleSource(assetPath: 'assets/audio/binaural/alpha.mp3', volume: 0.4),
        SampleSource(assetPath: 'assets/audio/noise/blue_noise.mp3', volume: 0.25),
        SampleSource(assetPath: 'assets/audio/nature/wind.mp3', volume: 0.35),
      ]),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/binaural/alpha.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/noise/blue_noise.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/nature/wind.mp3', volume: 0.2),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/binaural/alpha.mp3', volume: 0.5),
          SampleSource(assetPath: 'assets/audio/noise/blue_noise.mp3', volume: 0.25),
          SampleSource(assetPath: 'assets/audio/nature/wind.mp3', volume: 0.25),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/binaural/alpha.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/noise/blue_noise.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/nature/wind.mp3', volume: 0.4),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
    ],
  ),

  // ── Clear Your Mind ──────────────────────────────────────────────────────
  Journey(
    id: 'clear_your_mind',
    name: 'Clear Your Mind',
    description: 'Release tension and reset',
    icon: Icons.spa_rounded,
    category: 'Relax',
    defaultDuration: Duration(minutes: 20),
    minDuration: Duration(minutes: 10),
    maxDuration: Duration(minutes: 40),
    waypoints: [
      JourneyWaypoint(layers: [
        SampleSource(assetPath: 'assets/audio/frequencies/741_hz.mp3', volume: 0.45),
        SampleSource(assetPath: 'assets/audio/nature/thunder.mp3', volume: 0.3),
        SampleSource(assetPath: 'assets/audio/noise/red_noise.mp3', volume: 0.35),
      ]),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/frequencies/741_hz.mp3', volume: 0.55),
          SampleSource(assetPath: 'assets/audio/nature/thunder.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/noise/red_noise.mp3', volume: 0.25),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/frequencies/741_hz.mp3', volume: 0.3),
          SampleSource(assetPath: 'assets/audio/nature/thunder.mp3', volume: 0.4),
          SampleSource(assetPath: 'assets/audio/noise/red_noise.mp3', volume: 0.3),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
      JourneyWaypoint(
        layers: [
          SampleSource(assetPath: 'assets/audio/frequencies/741_hz.mp3', volume: 0.0),
          SampleSource(assetPath: 'assets/audio/nature/thunder.mp3', volume: 0.5),
          SampleSource(assetPath: 'assets/audio/noise/red_noise.mp3', volume: 0.5),
        ],
        weight: 1.0,
        curve: EaseCurve.easeInOut,
      ),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Journey screen
// ─────────────────────────────────────────────────────────────────────────────

class JourneyScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final JourneyEngine journeyEngine;
  final MotifEngine motifEngine;

  const JourneyScreen({
    super.key,
    required this.audioEngine,
    required this.journeyEngine,
    required this.motifEngine,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  String? _expandedId;
  final Map<String, double> _durationMinutes = {};

  /// Sleep timer duration (separate from journey duration picker).
  double _sleepTimerMinutes = 30.0;

  Duration get _sleepTimerDuration =>
      Duration(minutes: _sleepTimerMinutes.round());

  @override
  void initState() {
    super.initState();
    widget.journeyEngine.addListener(_onChanged);
    widget.audioEngine.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.journeyEngine.removeListener(_onChanged);
    widget.audioEngine.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  double _durationFor(Journey j) =>
      _durationMinutes[j.id] ?? j.defaultDuration.inMinutes.toDouble();

  Future<void> _startJourney(Journey journey) async {
    final duration = Duration(minutes: _durationFor(journey).round());
    setState(() => _expandedId = null);
    await widget.journeyEngine.start(journey, widget.audioEngine, duration);
  }

  Future<void> _startSleepTimer() async {
    if (widget.audioEngine.layers.isEmpty) return;
    // Pass the live MotifEngine so any running motifs are snapshotted into the
    // sleep-timer journey and faded to silence with the rest of the mix. It
    // goes to both Journey.sleepTimer (which builds the fading MotifSource) and
    // journeyEngine.start (which drives the density interpolation).
    final journey = Journey.sleepTimer(
      widget.audioEngine,
      _sleepTimerDuration,
      motifEngine: widget.motifEngine,
    );
    await widget.journeyEngine.start(
      journey,
      widget.audioEngine,
      _sleepTimerDuration,
      motifEngine: widget.motifEngine,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final je = widget.journeyEngine;
    return je.state == JourneyState.stopped
        ? _IdleView(
            audioEngine: widget.audioEngine,
            journeyEngine: je,
            expandedId: _expandedId,
            durationMinutes: _durationMinutes,
            sleepTimerMinutes: _sleepTimerMinutes,
            onExpand: (id) => setState(() => _expandedId = id),
            onDurationChanged: (id, v) =>
                setState(() => _durationMinutes[id] = v),
            onStartJourney: _startJourney,
            onSleepTimerChanged: (v) =>
                setState(() => _sleepTimerMinutes = v),
            onStartSleepTimer: _startSleepTimer,
          )
        : _ActiveView(journeyEngine: je);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle view
// ─────────────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final AudioEngine audioEngine;
  final JourneyEngine journeyEngine;
  final String? expandedId;
  final Map<String, double> durationMinutes;
  final double sleepTimerMinutes;
  final ValueChanged<String?> onExpand;
  final void Function(String id, double v) onDurationChanged;
  final ValueChanged<Journey> onStartJourney;
  final ValueChanged<double> onSleepTimerChanged;
  final VoidCallback onStartSleepTimer;

  const _IdleView({
    required this.audioEngine,
    required this.journeyEngine,
    required this.expandedId,
    required this.durationMinutes,
    required this.sleepTimerMinutes,
    required this.onExpand,
    required this.onDurationChanged,
    required this.onStartJourney,
    required this.onSleepTimerChanged,
    required this.onStartSleepTimer,
  });

  double _durationFor(Journey j) =>
      durationMinutes[j.id] ?? j.defaultDuration.inMinutes.toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final activeId = journeyEngine.state != JourneyState.stopped
        ? journeyEngine.currentJourney?.id
        : null;
    final hasMix = audioEngine.layers.isNotEmpty;
    final sleepSelected =
        Duration(minutes: sleepTimerMinutes.round());

    return CustomScrollView(
      slivers: [
        // ── CURATED JOURNEYS section ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'CURATED JOURNEYS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 1.4,
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
                if (index.isOdd) return const SizedBox(height: 12);
                final journey = _kJourneys[index ~/ 2];
                final isActive = activeId == journey.id;
                final isExpanded = expandedId == journey.id;
                return _JourneyCard(
                  journey: journey,
                  isActive: isActive,
                  isExpanded: isExpanded,
                  selectedMinutes: _durationFor(journey),
                  onTap: isActive
                      ? null
                      : () => onExpand(isExpanded ? null : journey.id),
                  onDurationChanged: (v) =>
                      onDurationChanged(journey.id, v),
                  onStart: () => onStartJourney(journey),
                  onStop: () => journeyEngine.stop(),
                );
              },
              childCount: _kJourneys.length * 2 - 1,
            ),
          ),
        ),

        // ── SLEEP TIMER section ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Text(
              'SLEEP TIMER',
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
            child: _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.bedtime_rounded,
                            color: gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sleep Timer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Gradually fade your mix to silence',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'DURATION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [15, 30, 45, 60, 90].map((min) {
                      final selected = sleepTimerMinutes.round() == min;
                      return GestureDetector(
                        onTap: () => onSleepTimerChanged(min.toDouble()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? gold
                                : gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            min >= 60 ? '${min ~/ 60}h' : '${min}m',
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF1C1C1C)
                                  : gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: gold,
                      inactiveTrackColor: gold.withValues(alpha: 0.18),
                      thumbColor: gold,
                      overlayColor: gold.withValues(alpha: 0.12),
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: sleepTimerMinutes,
                      min: 5,
                      max: 120,
                      divisions: 23,
                      onChanged: onSleepTimerChanged,
                    ),
                  ),
                  Center(
                    child: Text(
                      _fmtLabel(sleepSelected),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: gold.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (hasMix) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            audioEngine.layers
                                .map((l) => l.name)
                                .join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: hasMix ? onStartSleepTimer : null,
                      icon: const Icon(Icons.bedtime_rounded, size: 18),
                      label: const Text('Start Sleep Timer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF1C1C1C),
                        disabledBackgroundColor:
                            gold.withValues(alpha: 0.15),
                        disabledForegroundColor:
                            gold.withValues(alpha: 0.35),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  if (!hasMix) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Go to the Mixer tab and start a mix first.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active view (journey playing or frozen)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  final JourneyEngine journeyEngine;

  const _ActiveView({required this.journeyEngine});

  @override
  Widget build(BuildContext context) {
    final je = journeyEngine;
    final journey = je.currentJourney!;
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final isFrozen = je.state == JourneyState.frozen;

    final elapsed = je.elapsed;
    final remaining = je.totalDuration - elapsed;
    final clampedRemaining =
        remaining.isNegative ? Duration.zero : remaining;
    final barColor = isFrozen ? gold.withValues(alpha: 0.45) : gold;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(journey.icon, color: gold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          journey.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: je.progress,
                  minHeight: 6,
                  backgroundColor: gold.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmtClock(elapsed),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '−${_fmtClock(clampedRemaining)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.5),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFrozen ? 'FROZEN' : 'PLAYING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _ControlButton(
                      icon: isFrozen
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: isFrozen ? 'Resume' : 'Freeze',
                      color: gold,
                      onTap: isFrozen
                          ? journeyEngine.unfreeze
                          : journeyEngine.freeze,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ControlButton(
                      icon: Icons.stop_rounded,
                      label: 'Stop',
                      color: onSurface.withValues(alpha: 0.6),
                      borderColor:
                          theme.colorScheme.outline.withValues(alpha: 0.35),
                      onTap: () => journeyEngine.stop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Journey card
// ─────────────────────────────────────────────────────────────────────────────

class _JourneyCard extends StatelessWidget {
  final Journey journey;
  final bool isActive;
  final bool isExpanded;
  final double selectedMinutes;
  final VoidCallback? onTap;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _JourneyCard({
    required this.journey,
    required this.isActive,
    required this.isExpanded,
    required this.selectedMinutes,
    required this.onTap,
    required this.onDurationChanged,
    required this.onStart,
    required this.onStop,
  });

  Duration get _selected => Duration(minutes: selectedMinutes.round());
  List<int> get _picks => _quickPicks(journey);
  int get _sliderDivisions =>
      ((journey.maxDuration.inMinutes - journey.minDuration.inMinutes) / 5)
          .round();
  List<String> get _layerNames => journey.waypoints.first.layers
      .whereType<SampleSource>()
      .map((s) => _nameFromPath(s.assetPath))
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final surface = theme.colorScheme.surfaceContainerHighest;
    final onSurface = theme.colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? gold.withValues(alpha: 0.5) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ─────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: gold.withValues(
                            alpha: isActive ? 0.22 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(journey.icon, color: gold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journey.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            journey.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurface.withValues(alpha: 0.55),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isActive)
                      _ActionButton(
                        icon: Icons.stop_rounded,
                        filled: true,
                        gold: gold,
                        onTap: onStop,
                      )
                    else
                      _ActionButton(
                        icon: isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.play_arrow_rounded,
                        filled: false,
                        gold: gold,
                        onTap: onTap ?? () {},
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Layer chips ────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _layerNames
                      .map((name) => _LayerChip(
                            label: name,
                            isActive: isActive,
                            gold: gold,
                          ))
                      .toList(),
                ),

                // ── NOW PLAYING indicator ──────────────────────────────
                if (isActive) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded,
                          size: 13, color: gold),
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

                // ── Duration selector (expanded, not active) ───────────
                if (isExpanded && !isActive) ...[
                  const SizedBox(height: 16),
                  Divider(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DURATION',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _picks.map((min) {
                      final sel = selectedMinutes.round() == min;
                      return GestureDetector(
                        onTap: () => onDurationChanged(min.toDouble()),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? gold
                                : gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _fmtChipLabel(min),
                            style: TextStyle(
                              color: sel
                                  ? const Color(0xFF1C1C1C)
                                  : gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: gold,
                      inactiveTrackColor: gold.withValues(alpha: 0.18),
                      thumbColor: gold,
                      overlayColor: gold.withValues(alpha: 0.12),
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: selectedMinutes,
                      min: journey.minDuration.inMinutes.toDouble(),
                      max: journey.maxDuration.inMinutes.toDouble(),
                      divisions: _sliderDivisions,
                      onChanged: onDurationChanged,
                    ),
                  ),
                  Center(
                    child: Text(
                      _fmtLabel(_selected),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: gold.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(
                          'Start Journey · ${_fmtLabel(_selected)}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF1C1C1C),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBorder = borderColor ?? color.withValues(alpha: 0.4);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: resolvedBorder),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final Color gold;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.filled,
    required this.gold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? gold : gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: filled ? const Color(0xFF1C1C1C) : gold,
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

// ─────────────────────────────────────────────────────────────────────────────
// Formatters
// ─────────────────────────────────────────────────────────────────────────────

String _fmtLabel(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return m == 0 ? '$h hr' : '$h hr $m min';
}

String _fmtChipLabel(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes.remainder(60);
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String _fmtClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _nameFromPath(String assetPath) {
  final stem = assetPath.split('/').last.replaceAll('.mp3', '');
  return stem.split('_').map((w) {
    if (w.isEmpty) return '';
    if (w == 'hz') return 'Hz';
    return '${w[0].toUpperCase()}${w.substring(1)}';
  }).join(' ');
}
