import 'package:flutter/material.dart';
import '../services/audio_engine.dart';
import '../services/journey_engine.dart';
import '../services/mood_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home screen — "How do you want to feel?"
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final AudioEngine audioEngine;
  final JourneyEngine journeyEngine;
  final MoodEngine moodEngine;

  const HomeScreen({
    super.key,
    required this.audioEngine,
    required this.journeyEngine,
    required this.moodEngine,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _energy = 0.5;
  double _focus = 0.5;
  double _warmth = 0.5;
  double _durationMinutes = 30.0;
  bool _isGenerating = false;

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

  bool get _isPlaying =>
      widget.journeyEngine.state != JourneyState.stopped;

  Future<void> _generate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    // Release journey control without fading (we're replacing everything).
    if (widget.journeyEngine.state != JourneyState.stopped) {
      widget.journeyEngine.abandon();
    }

    // Fade out and remove all existing layers before loading the new mix.
    final existing =
        widget.audioEngine.layers.map((l) => l.assetPath).toList();
    await Future.wait(existing.map(widget.audioEngine.removeLayer));

    final journey = widget.moodEngine.generateJourney(
      _energy,
      _focus,
      _warmth,
      Duration(minutes: _durationMinutes.round()),
    );
    await widget.journeyEngine.start(
      journey,
      widget.audioEngine,
      Duration(minutes: _durationMinutes.round()),
    );
    if (mounted) setState(() => _isGenerating = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Now Playing banner ─────────────────────────────────────────────
        if (_isPlaying) ...[
          _NowPlayingCard(
            journeyEngine: widget.journeyEngine,
            onStop: widget.journeyEngine.stop,
          ),
          const SizedBox(height: 24),
        ],

        // ── Hero header ────────────────────────────────────────────────────
        Text(
          'How do you want\nto feel?',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Adjust the sliders and we\'ll craft your soundscape.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.5),
          ),
        ),

        const SizedBox(height: 24),

        // ── Mood sliders ───────────────────────────────────────────────────
        _MoodCard(
          children: [
            _MoodSlider(
              label: 'Energy',
              lowLabel: 'Calm',
              highLabel: 'Alert',
              icon: Icons.bolt_rounded,
              value: _energy,
              onChanged: (v) => setState(() => _energy = v),
              gold: gold,
              onSurface: onSurface,
            ),
            const SizedBox(height: 20),
            _MoodSlider(
              label: 'Focus',
              lowLabel: 'Drifting',
              highLabel: 'Sharp',
              icon: Icons.psychology_rounded,
              value: _focus,
              onChanged: (v) => setState(() => _focus = v),
              gold: gold,
              onSurface: onSurface,
            ),
            const SizedBox(height: 20),
            _MoodSlider(
              label: 'Warmth',
              lowLabel: 'Cool',
              highLabel: 'Warm',
              icon: Icons.thermostat_rounded,
              value: _warmth,
              onChanged: (v) => setState(() => _warmth = v),
              gold: gold,
              onSurface: onSurface,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Duration picker ────────────────────────────────────────────────
        _MoodCard(
          children: [
            Text(
              'DURATION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: gold,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [15, 30, 45, 60, 90].map((min) {
                final selected = _durationMinutes.round() == min;
                return GestureDetector(
                  onTap: () => setState(() => _durationMinutes = min.toDouble()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? gold
                          : gold.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      min >= 60 ? '${min ~/ 60}h' : '${min}m',
                      style: TextStyle(
                        color: selected ? const Color(0xFF1C1C1C) : gold,
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
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _durationMinutes,
                min: 5,
                max: 120,
                divisions: 23,
                onChanged: (v) => setState(() => _durationMinutes = v),
              ),
            ),
            Center(
              child: Text(
                _fmtDuration(Duration(minutes: _durationMinutes.round())),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: gold.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Text input placeholder ─────────────────────────────────────────
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Natural language coming soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: AbsorbPointer(
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Or describe how you want to feel...',
                hintStyle: TextStyle(
                  color: onSurface.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.edit_note_rounded,
                  color: onSurface.withValues(alpha: 0.3),
                ),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: gold.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Generate button ────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isGenerating
                ? null
                : _generate,
            icon: _isGenerating
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFF1C1C1C).withValues(alpha: 0.6),
                    ),
                  )
                : Icon(
                    _isPlaying
                        ? Icons.refresh_rounded
                        : Icons.play_arrow_rounded,
                    size: 20,
                  ),
            label: Text(
              _isGenerating
                  ? 'Generating...'
                  : (_isPlaying
                      ? 'Generate New Soundscape'
                      : 'Generate Soundscape'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: const Color(0xFF1C1C1C),
              disabledBackgroundColor: gold.withValues(alpha: 0.15),
              disabledForegroundColor: gold.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(vertical: 15),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Now Playing banner
// ─────────────────────────────────────────────────────────────────────────────

class _NowPlayingCard extends StatelessWidget {
  final JourneyEngine journeyEngine;
  final VoidCallback onStop;

  const _NowPlayingCard({
    required this.journeyEngine,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final journey = journeyEngine.currentJourney!;
    final isFrozen = journeyEngine.state == JourneyState.frozen;

    final elapsed = journeyEngine.elapsed;
    final remaining = journeyEngine.totalDuration - elapsed;
    final clampedRemaining =
        remaining.isNegative ? Duration.zero : remaining;
    final barColor = isFrozen ? gold.withValues(alpha: 0.45) : gold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gold.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(journey.icon, color: gold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.name,
                      style: theme.textTheme.titleSmall?.copyWith(
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onStop,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.stop_rounded,
                    color: gold,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: journeyEngine.progress,
              minHeight: 4,
              backgroundColor: gold.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFrozen ? 'FROZEN' : 'NOW PLAYING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              Text(
                '−${_fmtClock(clampedRemaining)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.45),
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mood card container
// ─────────────────────────────────────────────────────────────────────────────

class _MoodCard extends StatelessWidget {
  final List<Widget> children;

  const _MoodCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Labelled mood slider
// ─────────────────────────────────────────────────────────────────────────────

class _MoodSlider extends StatelessWidget {
  final String label;
  final String lowLabel;
  final String highLabel;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final Color gold;
  final Color onSurface;

  const _MoodSlider({
    required this.label,
    required this.lowLabel,
    required this.highLabel,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.gold,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: gold),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: gold,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                fontSize: 10,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: gold,
            inactiveTrackColor: gold.withValues(alpha: 0.18),
            thumbColor: gold,
            overlayColor: gold.withValues(alpha: 0.12),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lowLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.35),
                  fontSize: 10,
                ),
              ),
              Text(
                highLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.35),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDuration(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return m == 0 ? '$h hr' : '$h hr $m min';
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
