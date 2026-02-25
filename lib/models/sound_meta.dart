class SoundMeta {
  final String id;
  final String name;
  final String assetPath;

  /// One of: 'nature' | 'noise' | 'binaural' | 'frequencies' | 'soundscape'
  final String category;

  final String description;

  /// Subset of: 'sleep' | 'focus' | 'meditate' | 'relax' | 'energize'
  final List<String> tags;

  final double defaultVolume;
  final bool isAvailable;

  /// Tonal center of the sound in Hz at standard A=440 tuning.
  /// Null for atonal sounds (nature, noise, binaural).
  final double? rootFrequency;

  const SoundMeta({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.category,
    required this.description,
    required this.tags,
    required this.defaultVolume,
    this.isAvailable = true,
    this.rootFrequency,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Full sound catalog (33 sounds)
// ─────────────────────────────────────────────────────────────────────────────

const List<SoundMeta> kSoundCatalog = [
  // ── Nature ──────────────────────────────────────────────────────────────────
  SoundMeta(
    id: 'rain',
    name: 'Rain',
    assetPath: 'assets/audio/nature/rain.mp3',
    category: 'nature',
    description: 'Steady rainfall on leaves and pavement. Perfect for masking distractions.',
    tags: ['sleep', 'focus', 'relax', 'meditate'],
    defaultVolume: 0.5,
  ),
  SoundMeta(
    id: 'ocean',
    name: 'Ocean',
    assetPath: 'assets/audio/nature/ocean.mp3',
    category: 'nature',
    description: 'Rolling waves on a sandy shore. Evokes calm and spaciousness.',
    tags: ['sleep', 'relax', 'meditate'],
    defaultVolume: 0.5,
  ),
  SoundMeta(
    id: 'wind',
    name: 'Wind',
    assetPath: 'assets/audio/nature/wind.mp3',
    category: 'nature',
    description: 'A gentle breeze through trees and tall grass.',
    tags: ['focus', 'relax', 'meditate'],
    defaultVolume: 0.5,
  ),
  SoundMeta(
    id: 'thunder',
    name: 'Thunder',
    assetPath: 'assets/audio/nature/thunder.mp3',
    category: 'nature',
    description: 'Distant rumbles rolling over a rainy landscape.',
    tags: ['sleep', 'relax'],
    defaultVolume: 0.45,
  ),
  SoundMeta(
    id: 'crickets',
    name: 'Crickets',
    assetPath: 'assets/audio/nature/crickets.mp3',
    category: 'nature',
    description: 'A warm summer night alive with the song of crickets.',
    tags: ['sleep', 'relax'],
    defaultVolume: 0.45,
  ),

  // ── Noise — available ────────────────────────────────────────────────────────
  SoundMeta(
    id: 'white_noise',
    name: 'White Noise',
    assetPath: 'assets/audio/noise/white_noise.mp3',
    category: 'noise',
    description: 'Equal energy across all frequencies. Great for masking any environment.',
    tags: ['sleep', 'focus'],
    defaultVolume: 0.4,
  ),
  SoundMeta(
    id: 'pink_noise',
    name: 'Pink Noise',
    assetPath: 'assets/audio/noise/pink_noise.mp3',
    category: 'noise',
    description: 'Warmer than white noise — deeper and more balanced, like steady rain.',
    tags: ['sleep', 'relax', 'meditate'],
    defaultVolume: 0.4,
  ),
  SoundMeta(
    id: 'brown_noise',
    name: 'Brown Noise',
    assetPath: 'assets/audio/noise/brown_noise.mp3',
    category: 'noise',
    description: 'Deep, rumbling noise similar to a strong river current or thunder.',
    tags: ['sleep', 'focus', 'relax'],
    defaultVolume: 0.4,
  ),
  SoundMeta(
    id: 'blue_noise',
    name: 'Blue Noise',
    assetPath: 'assets/audio/noise/blue_noise.mp3',
    category: 'noise',
    description: 'Bright, airy noise with boosted high frequencies. Crisp and alert.',
    tags: ['focus', 'energize'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: 'red_noise',
    name: 'Red Noise',
    assetPath: 'assets/audio/noise/red_noise.mp3',
    category: 'noise',
    description: 'Even deeper than brown noise — a powerful, grounding bass rumble.',
    tags: ['sleep', 'relax'],
    defaultVolume: 0.4,
  ),

  // ── Noise — coming soon ──────────────────────────────────────────────────────
  SoundMeta(
    id: 'yellow_noise',
    name: 'Yellow Noise',
    assetPath: 'assets/audio/noise/yellow_noise.mp3',
    category: 'noise',
    description: 'Mid-range noise blending warmth and clarity.',
    tags: ['focus', 'relax'],
    defaultVolume: 0.4,
    isAvailable: false,
  ),
  SoundMeta(
    id: 'gray_noise',
    name: 'Gray Noise',
    assetPath: 'assets/audio/noise/gray_noise.mp3',
    category: 'noise',
    description: 'Perceptually flat noise — sounds equally loud at all frequencies.',
    tags: ['sleep', 'focus'],
    defaultVolume: 0.4,
    isAvailable: false,
  ),
  SoundMeta(
    id: 'purple_noise',
    name: 'Purple Noise',
    assetPath: 'assets/audio/noise/purple_noise.mp3',
    category: 'noise',
    description: 'Very high frequency noise, almost a hiss. Sharp and piercing.',
    tags: ['focus', 'energize'],
    defaultVolume: 0.35,
    isAvailable: false,
  ),
  SoundMeta(
    id: 'green_noise',
    name: 'Green Noise',
    assetPath: 'assets/audio/noise/green_noise.mp3',
    category: 'noise',
    description: 'Nature-centered mid-range noise, reminiscent of the outdoors.',
    tags: ['relax', 'meditate'],
    defaultVolume: 0.4,
    isAvailable: false,
  ),
  SoundMeta(
    id: 'orange_noise',
    name: 'Orange Noise',
    assetPath: 'assets/audio/noise/orange_noise.mp3',
    category: 'noise',
    description: 'Warm, dense mid-range noise with a smooth, rounded quality.',
    tags: ['relax', 'sleep'],
    defaultVolume: 0.4,
    isAvailable: false,
  ),
  SoundMeta(
    id: 'aquamarine_noise',
    name: 'Aquamarine Noise',
    assetPath: 'assets/audio/noise/aquamarine_noise.mp3',
    category: 'noise',
    description: 'A cool, flowing noise blend between pink and blue.',
    tags: ['focus', 'relax'],
    defaultVolume: 0.4,
    isAvailable: false,
  ),
  SoundMeta(
    id: 'violet_noise',
    name: 'Violet Noise',
    assetPath: 'assets/audio/noise/violet_noise.mp3',
    category: 'noise',
    description: 'Very high frequency noise with rising intensity. Stimulating.',
    tags: ['focus', 'energize'],
    defaultVolume: 0.35,
    isAvailable: false,
  ),
  SoundMeta(
    id: 'black_noise',
    name: 'Black Noise',
    assetPath: 'assets/audio/noise/black_noise.mp3',
    category: 'noise',
    description: 'Near-silence with occasional subtle texture. Profound quiet.',
    tags: ['sleep', 'meditate'],
    defaultVolume: 0.3,
    isAvailable: false,
  ),

  // ── Binaural beats ───────────────────────────────────────────────────────────
  SoundMeta(
    id: 'delta',
    name: 'Delta',
    assetPath: 'assets/audio/binaural/delta.mp3',
    category: 'binaural',
    description: '0.5–4 Hz — the frequency of deep, dreamless sleep and recovery.',
    tags: ['sleep'],
    defaultVolume: 0.3,
  ),
  SoundMeta(
    id: 'theta',
    name: 'Theta',
    assetPath: 'assets/audio/binaural/theta.mp3',
    category: 'binaural',
    description: '4–8 Hz — deep meditation, creativity, and light sleep.',
    tags: ['sleep', 'meditate', 'relax'],
    defaultVolume: 0.3,
  ),
  SoundMeta(
    id: 'alpha',
    name: 'Alpha',
    assetPath: 'assets/audio/binaural/alpha.mp3',
    category: 'binaural',
    description: '8–14 Hz — calm alertness, relaxed focus, and stress reduction.',
    tags: ['focus', 'relax', 'meditate'],
    defaultVolume: 0.3,
  ),
  SoundMeta(
    id: 'beta',
    name: 'Beta',
    assetPath: 'assets/audio/binaural/beta.mp3',
    category: 'binaural',
    description: '14–30 Hz — active thinking, problem solving, and concentration.',
    tags: ['focus', 'energize'],
    defaultVolume: 0.3,
  ),
  SoundMeta(
    id: 'gamma',
    name: 'Gamma',
    assetPath: 'assets/audio/binaural/gamma.mp3',
    category: 'binaural',
    description: '30–100 Hz — peak cognition, high-level information processing.',
    tags: ['focus', 'energize'],
    defaultVolume: 0.3,
  ),

  // ── Solfeggio frequencies ────────────────────────────────────────────────────
  SoundMeta(
    id: '174_hz',
    name: '174 Hz',
    assetPath: 'assets/audio/frequencies/174_hz.mp3',
    category: 'frequencies',
    description: 'The lowest Solfeggio frequency. Associated with pain relief and grounding.',
    tags: ['relax', 'meditate'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '285_hz',
    name: '285 Hz',
    assetPath: 'assets/audio/frequencies/285_hz.mp3',
    category: 'frequencies',
    description: 'Linked to healing and tissue restoration. Soothing and restorative.',
    tags: ['relax', 'meditate', 'sleep'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '396_hz',
    name: '396 Hz',
    assetPath: 'assets/audio/frequencies/396_hz.mp3',
    category: 'frequencies',
    description: 'Said to release guilt and fear, clearing emotional blockages.',
    tags: ['relax', 'meditate'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '417_hz',
    name: '417 Hz',
    assetPath: 'assets/audio/frequencies/417_hz.mp3',
    category: 'frequencies',
    description: 'Facilitates change and creativity. Helps break old patterns.',
    tags: ['focus', 'meditate'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '432_hz',
    name: '432 Hz',
    assetPath: 'assets/audio/frequencies/432_hz.mp3',
    category: 'frequencies',
    description: 'Natural tuning said to resonate with the universe. Calm and harmonious.',
    tags: ['relax', 'meditate', 'sleep'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '528_hz',
    name: '528 Hz',
    assetPath: 'assets/audio/frequencies/528_hz.mp3',
    category: 'frequencies',
    description: 'The "miracle tone." Associated with transformation and clarity.',
    tags: ['focus', 'meditate', 'energize'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '639_hz',
    name: '639 Hz',
    assetPath: 'assets/audio/frequencies/639_hz.mp3',
    category: 'frequencies',
    description: 'Linked to connection, harmony, and emotional balance.',
    tags: ['relax', 'meditate'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '741_hz',
    name: '741 Hz',
    assetPath: 'assets/audio/frequencies/741_hz.mp3',
    category: 'frequencies',
    description: 'Associated with awakening intuition and mental clarity.',
    tags: ['focus', 'meditate'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '852_hz',
    name: '852 Hz',
    assetPath: 'assets/audio/frequencies/852_hz.mp3',
    category: 'frequencies',
    description: 'Said to return the mind to spiritual order and inner strength.',
    tags: ['meditate', 'relax'],
    defaultVolume: 0.35,
  ),
  SoundMeta(
    id: '963_hz',
    name: '963 Hz',
    assetPath: 'assets/audio/frequencies/963_hz.mp3',
    category: 'frequencies',
    description: 'The highest Solfeggio frequency. Associated with awakening and unity.',
    tags: ['meditate', 'energize'],
    defaultVolume: 0.35,
  ),

  // ── Soundscapes (coming soon) ────────────────────────────────────────────────
  SoundMeta(
    id: 'ambient_calm',
    name: 'Calm Drift',
    assetPath: 'assets/audio/soundscapes/ambient_calm.mp3',
    category: 'soundscape',
    description: 'Gentle ambient atmosphere',
    tags: ['sleep', 'relax', 'meditate'],
    defaultVolume: 0.5,
    isAvailable: false,
    rootFrequency: 261.63, // C4
  ),
  SoundMeta(
    id: 'ambient_focus',
    name: 'Sharp Light',
    assetPath: 'assets/audio/soundscapes/ambient_focus.mp3',
    category: 'soundscape',
    description: 'Bright focused atmosphere',
    tags: ['focus', 'energize'],
    defaultVolume: 0.5,
    isAvailable: false,
    rootFrequency: 349.23, // F4
  ),
  SoundMeta(
    id: 'ambient_deep',
    name: 'Deep Current',
    assetPath: 'assets/audio/soundscapes/ambient_deep.mp3',
    category: 'soundscape',
    description: 'Dark immersive atmosphere',
    tags: ['sleep', 'meditate'],
    defaultVolume: 0.5,
    isAvailable: false,
    rootFrequency: 293.66, // D4
  ),
];
