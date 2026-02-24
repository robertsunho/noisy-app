import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../services/audio_engine.dart';
import '../services/journey_engine.dart';

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
// Home screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final JourneyEngine journeyEngine;

  const HomeScreen({
    super.key,
    required this.audioEngine,
    required this.journeyEngine,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Which card is expanded to show the duration selector.
  String? _expandedId;

  /// Per-journey selected duration in minutes. Defaults to each journey's
  /// defaultDuration when not yet overridden by the user.
  final Map<String, double> _durationMinutes = {};

  @override
  void initState() {
    super.initState();
    widget.journeyEngine.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.journeyEngine.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  double _durationFor(Journey j) =>
      _durationMinutes[j.id] ?? j.defaultDuration.inMinutes.toDouble();

  Future<void> _startJourney(Journey journey) async {
    final duration = Duration(minutes: _durationFor(journey).round());
    // Collapse the card before starting so the UI doesn't flash.
    setState(() => _expandedId = null);
    await widget.journeyEngine.start(journey, widget.audioEngine, duration);
  }

  @override
  Widget build(BuildContext context) {
    final je = widget.journeyEngine;
    final activeId =
        je.state != JourneyState.stopped ? je.currentJourney?.id : null;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _kJourneys.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final journey = _kJourneys[index];
        final isActive = activeId == journey.id;
        final isExpanded = _expandedId == journey.id;

        return _JourneyCard(
          journey: journey,
          isActive: isActive,
          isExpanded: isExpanded,
          selectedMinutes: _durationFor(journey),
          // Active cards cannot be expanded — they show a stop button instead.
          onTap: isActive
              ? null
              : () => setState(
                    () => _expandedId = isExpanded ? null : journey.id,
                  ),
          onDurationChanged: (v) =>
              setState(() => _durationMinutes[journey.id] = v),
          onStart: () => _startJourney(journey),
          onStop: () => widget.journeyEngine.stop(),
        );
      },
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

  /// Layer names derived from the first waypoint, shown as chips.
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
                        color:
                            gold.withValues(alpha: isActive ? 0.22 : 0.1),
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
                    // Stop button when active; expand toggle otherwise.
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
                    color:
                        theme.colorScheme.outline.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // Label
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

                  // Quick-pick chips
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

                  const SizedBox(height: 4),

                  // Fine-tune slider
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

                  // Start button
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
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// "30 min", "1 hr", "1 hr 30 min"
String _fmtLabel(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return m == 0 ? '$h hr' : '$h hr $m min';
}

/// "30m", "1h", "1h 30m" — compact form for chips
String _fmtChipLabel(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes.remainder(60);
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// "assets/audio/noise/brown_noise.mp3" → "Brown Noise"
String _nameFromPath(String assetPath) {
  final stem = assetPath.split('/').last.replaceAll('.mp3', '');
  return stem.split('_').map((w) {
    if (w.isEmpty) return '';
    if (w == 'hz') return 'Hz';
    return '${w[0].toUpperCase()}${w.substring(1)}';
  }).join(' ');
}
