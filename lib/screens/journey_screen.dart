import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../services/audio_engine.dart';
import '../services/journey_engine.dart';

class JourneyScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final JourneyEngine journeyEngine;

  const JourneyScreen({
    super.key,
    required this.audioEngine,
    required this.journeyEngine,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  /// Duration selected by the user for the next sleep timer (in minutes).
  double _durationMinutes = 30.0;

  Duration get _selectedDuration =>
      Duration(minutes: _durationMinutes.round());

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

  Future<void> _startSleepTimer() async {
    if (widget.audioEngine.layers.isEmpty) return;
    // Snapshot BEFORE calling start() so the engine state is captured
    // prior to any stop() cleanup that start() performs internally.
    final journey =
        Journey.sleepTimer(widget.audioEngine, _selectedDuration);
    await widget.journeyEngine.start(
      journey,
      widget.audioEngine,
      _selectedDuration,
    );
  }

  // ── Build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final je = widget.journeyEngine;
    return je.state == JourneyState.stopped
        ? _IdleView(
            audioEngine: widget.audioEngine,
            durationMinutes: _durationMinutes,
            onDurationChanged: (v) => setState(() => _durationMinutes = v),
            onStart: _startSleepTimer,
          )
        : _ActiveView(journeyEngine: je);
  }
}

// ─────────────────────────────────────────────
// Idle view (no active journey)
// ─────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final AudioEngine audioEngine;
  final double durationMinutes;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback onStart;

  const _IdleView({
    required this.audioEngine,
    required this.durationMinutes,
    required this.onDurationChanged,
    required this.onStart,
  });

  Duration get _selected => Duration(minutes: durationMinutes.round());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final hasMix = audioEngine.layers.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        _Card(
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
                    child: Icon(Icons.bedtime_rounded, color: gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep Timer',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Gradually fade your mix to silence',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Duration label ───────────────────
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

              // ── Quick-pick chips ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [15, 30, 45, 60, 90].map((min) {
                  final selected = durationMinutes.round() == min;
                  return GestureDetector(
                    onTap: () => onDurationChanged(min.toDouble()),
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

              const SizedBox(height: 12),

              // ── Fine-tune slider ─────────────────
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: gold,
                  inactiveTrackColor: gold.withValues(alpha: 0.18),
                  thumbColor: gold,
                  overlayColor: gold.withValues(alpha: 0.12),
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: durationMinutes,
                  min: 5,
                  max: 120,
                  // 5-minute increments: (120-5)/5 = 23 intervals
                  divisions: 23,
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

              const SizedBox(height: 20),

              // ── Current mix preview ──────────────
              if (hasMix) ...[
                Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 13,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        audioEngine.layers.map((l) => l.name).join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withValues(alpha: 0.4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // ── Start button ─────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hasMix ? onStart : null,
                  icon: const Icon(Icons.bedtime_rounded, size: 18),
                  label: const Text('Start Sleep Timer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: const Color(0xFF1C1C1C),
                    disabledBackgroundColor: gold.withValues(alpha: 0.15),
                    disabledForegroundColor: gold.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    color: onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Active view (journey playing or frozen)
// ─────────────────────────────────────────────

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

    // Progress bar colour dims when frozen to communicate pause.
    final barColor = isFrozen ? gold.withValues(alpha: 0.45) : gold;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Journey identity ─────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(journey.icon, color: gold, size: 22),
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

              // ── Progress bar ─────────────────────
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

              // ── Time row ─────────────────────────
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

              // ── State badge ──────────────────────
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

              // ── Controls row ─────────────────────
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

// ─────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// Formatters
// ─────────────────────────────────────────────

/// "30 min", "1 hr", "1 hr 30 min"
String _fmtLabel(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return m == 0 ? '$h hr' : '$h hr $m min';
}

/// "MM:SS" or "H:MM:SS" for clock-style display
String _fmtClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
