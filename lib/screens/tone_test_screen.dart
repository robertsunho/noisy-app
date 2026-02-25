import 'package:flutter/material.dart';
import '../services/tone_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brainwave band labels for the beat-frequency slider
// ─────────────────────────────────────────────────────────────────────────────

String _beatBandLabel(double hz) {
  if (hz < 4) return 'Delta (${hz.toStringAsFixed(1)} Hz)';
  if (hz < 8) return 'Theta (${hz.toStringAsFixed(1)} Hz)';
  if (hz < 13) return 'Alpha (${hz.toStringAsFixed(1)} Hz)';
  if (hz < 30) return 'Beta (${hz.toStringAsFixed(1)} Hz)';
  return 'Gamma (${hz.toStringAsFixed(1)} Hz)';
}

// ─────────────────────────────────────────────────────────────────────────────
// ToneTestScreen
// ─────────────────────────────────────────────────────────────────────────────

class ToneTestScreen extends StatefulWidget {
  const ToneTestScreen({super.key});

  @override
  State<ToneTestScreen> createState() => _ToneTestScreenState();
}

class _ToneTestScreenState extends State<ToneTestScreen> {
  final _service = ToneService();

  // ── Tone state ─────────────────────────────────────────────────────────────
  double _toneFreq = 440.0;
  double _toneVol = 0.5;
  String? _toneId;
  bool _toneBusy = false;

  // ── Binaural state ─────────────────────────────────────────────────────────
  double _binCenter = 200.0;
  double _binBeat = 10.0; // Alpha band default
  double _binVol = 0.5;
  String? _binId;
  bool _binBusy = false;

  bool get _toneActive => _toneId != null;
  bool get _binActive => _binId != null;

  @override
  void dispose() {
    _service.stopAll();
    super.dispose();
  }

  // ── Tone controls ──────────────────────────────────────────────────────────

  Future<void> _toggleTone() async {
    if (_toneBusy) return;
    setState(() => _toneBusy = true);
    try {
      if (_toneActive) {
        await _service.stopTone(_toneId!);
        setState(() => _toneId = null);
      } else {
        final id = await _service.playTone(_toneFreq, volume: _toneVol);
        setState(() => _toneId = id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _toneBusy = false);
    }
  }

  void _onToneFreqChanged(double v) {
    setState(() => _toneFreq = v);
    if (_toneActive) _service.setToneFrequency(_toneId!, v);
  }

  void _onToneVolChanged(double v) {
    setState(() => _toneVol = v);
    if (_toneActive) _service.setToneVolume(_toneId!, v);
  }

  // ── Binaural controls ──────────────────────────────────────────────────────

  Future<void> _toggleBinaural() async {
    if (_binBusy) return;
    setState(() => _binBusy = true);
    try {
      if (_binActive) {
        await _service.stopTone(_binId!);
        setState(() => _binId = null);
      } else {
        final id = await _service.playBinaural(_binCenter, _binBeat,
            volume: _binVol);
        setState(() => _binId = id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _binBusy = false);
    }
  }

  void _onBinCenterChanged(double v) {
    setState(() => _binCenter = v);
    if (_binActive) _service.setBinauralFrequencies(_binId!, v, _binBeat);
  }

  void _onBinBeatChanged(double v) {
    setState(() => _binBeat = v);
    if (_binActive) _service.setBinauralFrequencies(_binId!, _binCenter, v);
  }

  void _onBinVolChanged(double v) {
    setState(() => _binVol = v);
    if (_binActive) _service.setBinauralVolume(_binId!, v);
  }

  // ── Stop All ───────────────────────────────────────────────────────────────

  Future<void> _stopAll() async {
    await _service.stopAll();
    setState(() {
      _toneId = null;
      _binId = null;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tone Generator'),
        backgroundColor: const Color(0xFF252525),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Tone section ─────────────────────────────────────────────────
          _SectionCard(
            label: 'TONE',
            children: [
              _SliderRow(
                label: 'Frequency',
                value: _toneFreq,
                valueLabel: '${_toneFreq.round()} Hz',
                min: 100,
                max: 1000,
                divisions: 90,
                gold: gold,
                onChanged: _onToneFreqChanged,
              ),
              const SizedBox(height: 4),
              _SliderRow(
                label: 'Volume',
                value: _toneVol,
                valueLabel: _toneVol.toStringAsFixed(2),
                min: 0,
                max: 1,
                divisions: 20,
                gold: gold,
                onChanged: _onToneVolChanged,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _toneBusy ? null : _toggleTone,
                  icon: _toneBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1C1C1C)),
                        )
                      : Icon(_toneActive
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded),
                  label: Text(_toneActive ? 'Stop Tone' : 'Play Tone'),
                  style: _buttonStyle(gold, _toneActive),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Binaural section ─────────────────────────────────────────────
          _SectionCard(
            label: 'BINAURAL BEAT',
            children: [
              _SliderRow(
                label: 'Center Frequency',
                value: _binCenter,
                valueLabel: '${_binCenter.round()} Hz',
                min: 100,
                max: 500,
                divisions: 80,
                gold: gold,
                onChanged: _onBinCenterChanged,
              ),
              const SizedBox(height: 4),
              _SliderRow(
                label: 'Beat Frequency',
                value: _binBeat,
                valueLabel: _beatBandLabel(_binBeat),
                min: 1,
                max: 40,
                divisions: 39,
                gold: gold,
                onChanged: _onBinBeatChanged,
              ),
              const SizedBox(height: 4),
              _SliderRow(
                label: 'Volume',
                value: _binVol,
                valueLabel: _binVol.toStringAsFixed(2),
                min: 0,
                max: 1,
                divisions: 20,
                gold: gold,
                onChanged: _onBinVolChanged,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _binBusy ? null : _toggleBinaural,
                  icon: _binBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1C1C1C)),
                        )
                      : Icon(_binActive
                          ? Icons.stop_rounded
                          : Icons.headphones_rounded),
                  label: Text(
                      _binActive ? 'Stop Binaural' : 'Play Binaural'),
                  style: _buttonStyle(gold, _binActive),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Stop All ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _service.hasActiveTones ? _stopAll : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Stop All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: gold,
                side: BorderSide(
                  color: _service.hasActiveTones
                      ? gold.withValues(alpha: 0.6)
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle(Color gold, bool active) =>
      FilledButton.styleFrom(
        backgroundColor: active ? gold.withValues(alpha: 0.8) : gold,
        foregroundColor: const Color(0xFF1C1C1C),
        disabledBackgroundColor: gold.withValues(alpha: 0.15),
        disabledForegroundColor: gold.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SectionCard({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color gold;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.gold,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              valueLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: gold,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
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
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
