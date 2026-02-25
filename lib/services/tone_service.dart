import 'package:flutter_soloud/flutter_soloud.dart';

// ── Internal entry types ───────────────────────────────────────────────────

class _ToneEntry {
  final AudioSource source;
  final SoundHandle handle;
  _ToneEntry(this.source, this.handle);
}

class _BinauralEntry {
  final AudioSource leftSource;
  final SoundHandle leftHandle;
  final AudioSource rightSource;
  final SoundHandle rightHandle;

  _BinauralEntry(
    this.leftSource,
    this.leftHandle,
    this.rightSource,
    this.rightHandle,
  );
}

// ── ToneService ───────────────────────────────────────────────────────────────

/// Manages real-time sine-wave tone generation via flutter_soloud.
///
/// Completely independent of the just_audio-based [AudioEngine] — the two
/// audio backends co-exist without interfering.
class ToneService {
  final _tones = <String, _ToneEntry>{};
  final _binaurals = <String, _BinauralEntry>{};
  int _idCounter = 0;

  SoLoud get _soloud => SoLoud.instance;
  String _nextId() => 'tone_${_idCounter++}';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Plays a sine wave at [frequency] Hz indefinitely. Returns a tone ID.
  Future<String> playTone(double frequency, {double volume = 0.5}) async {
    final source = await _soloud.loadWaveform(WaveForm.sin, false, 1.0, 0.0);
    _soloud.setWaveformFreq(source, frequency);
    final handle = await _soloud.play(source, volume: volume, looping: true);
    if (handle.isError) {
      await _soloud.disposeSource(source);
      throw StateError('SoLoud failed to play tone at ${frequency}Hz');
    }
    final id = _nextId();
    _tones[id] = _ToneEntry(source, handle);
    return id;
  }

  /// Creates a binaural beat: left ear at [centerFrequency], right ear at
  /// [centerFrequency] + [beatFrequency]. Returns a binaural ID.
  Future<String> playBinaural(
    double centerFrequency,
    double beatFrequency, {
    double volume = 0.5,
  }) async {
    // Left channel
    final lSrc = await _soloud.loadWaveform(WaveForm.sin, false, 1.0, 0.0);
    _soloud.setWaveformFreq(lSrc, centerFrequency);
    final lHandle = await _soloud.play(lSrc,
        volume: volume, pan: -1.0, looping: true);

    // Right channel
    final rSrc = await _soloud.loadWaveform(WaveForm.sin, false, 1.0, 0.0);
    _soloud.setWaveformFreq(rSrc, centerFrequency + beatFrequency);
    final rHandle = await _soloud.play(rSrc,
        volume: volume, pan: 1.0, looping: true);

    if (lHandle.isError || rHandle.isError) {
      if (!lHandle.isError) await _soloud.stop(lHandle);
      if (!rHandle.isError) await _soloud.stop(rHandle);
      await _soloud.disposeSource(lSrc);
      await _soloud.disposeSource(rSrc);
      throw StateError('SoLoud failed to play binaural beat');
    }

    final id = _nextId();
    _binaurals[id] = _BinauralEntry(lSrc, lHandle, rSrc, rHandle);
    return id;
  }

  /// Changes the frequency of an active mono tone in real-time.
  void setToneFrequency(String toneId, double frequency) {
    final entry = _tones[toneId];
    if (entry != null) _soloud.setWaveformFreq(entry.source, frequency);
  }

  /// Changes the volume of an active mono tone.
  void setToneVolume(String toneId, double volume) {
    final entry = _tones[toneId];
    if (entry != null) _soloud.setVolume(entry.handle, volume);
  }

  /// Updates both oscillators of a binaural beat in real-time.
  void setBinauralFrequencies(
    String binauralId,
    double centerFrequency,
    double beatFrequency,
  ) {
    final entry = _binaurals[binauralId];
    if (entry == null) return;
    _soloud.setWaveformFreq(entry.leftSource, centerFrequency);
    _soloud.setWaveformFreq(entry.rightSource, centerFrequency + beatFrequency);
  }

  /// Changes the volume of both oscillators of a binaural beat.
  void setBinauralVolume(String binauralId, double volume) {
    final entry = _binaurals[binauralId];
    if (entry == null) return;
    _soloud.setVolume(entry.leftHandle, volume);
    _soloud.setVolume(entry.rightHandle, volume);
  }

  /// Stops and disposes a single tone or binaural (looked up by ID).
  Future<void> stopTone(String id) async {
    final tone = _tones.remove(id);
    if (tone != null) {
      await _soloud.stop(tone.handle);
      await _soloud.disposeSource(tone.source);
      return;
    }
    final binaural = _binaurals.remove(id);
    if (binaural != null) {
      await _soloud.stop(binaural.leftHandle);
      await _soloud.disposeSource(binaural.leftSource);
      await _soloud.stop(binaural.rightHandle);
      await _soloud.disposeSource(binaural.rightSource);
    }
  }

  /// Stops and disposes all active tones and binaural beats.
  Future<void> stopAll() async {
    final ids = [..._tones.keys, ..._binaurals.keys];
    for (final id in ids) {
      await stopTone(id);
    }
  }

  /// True if any tones or binaural beats are currently playing.
  bool get hasActiveTones => _tones.isNotEmpty || _binaurals.isNotEmpty;
}
