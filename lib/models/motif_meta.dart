class MotifMeta {
  final String id;
  final String name;
  final String assetPath;

  /// Root pitch of this motif in Hz. Null for atonal/percussive sounds.
  final double? rootFrequency;

  /// Mood tags — matches _inferCategory output: 'sleep', 'meditate', 'relax',
  /// 'focus', 'energize'
  final List<String> tags;

  /// Nominal volume for this motif (multiplied by masterVolume at runtime).
  final double defaultVolume;

  const MotifMeta({
    required this.id,
    required this.name,
    required this.assetPath,
    this.rootFrequency,
    required this.tags,
    this.defaultVolume = 1.0,
  });
}

const List<MotifMeta> kMotifCatalog = [
  MotifMeta(
    id: 'bowl_high_g',
    name: 'Bowl High G',
    assetPath: 'assets/audio/motifs/bowl_high_g.mp3',
    rootFrequency: 784.0, // G5
    tags: ['sleep', 'meditate', 'relax', 'focus'],
  ),
  MotifMeta(
    id: 'bowl_low_g',
    name: 'Bowl Low G',
    assetPath: 'assets/audio/motifs/bowl_low_g.mp3',
    rootFrequency: 196.0, // G3
    tags: ['sleep', 'meditate', 'relax'],
  ),
  MotifMeta(
    id: 'high_bell_b',
    name: 'High Bell B',
    assetPath: 'assets/audio/motifs/high_bell_b.mp3',
    rootFrequency: 493.9, // B4
    tags: ['meditate', 'focus', 'relax', 'energize'],
  ),
  MotifMeta(
    id: 'low_bell_eb',
    name: 'Low Bell Eb',
    assetPath: 'assets/audio/motifs/low_bell_eb.mp3',
    rootFrequency: 155.6, // Eb3
    tags: ['sleep', 'meditate', 'relax'],
  ),
  MotifMeta(
    id: 'piano_note_f',
    name: 'Piano Note F',
    assetPath: 'assets/audio/motifs/piano_note_f.mp3',
    rootFrequency: 349.2, // F4
    tags: ['focus', 'relax', 'energize', 'meditate', 'sleep'],
  ),
  MotifMeta(
    id: 'triangle_e',
    name: 'Triangle E',
    assetPath: 'assets/audio/motifs/triangle_e.mp3',
    rootFrequency: 329.6, // E4
    tags: ['focus', 'energize', 'meditate'],
  ),
  MotifMeta(
    id: 'gourd_percussion',
    name: 'Gourd Percussion',
    assetPath: 'assets/audio/motifs/gourd_percussion.mp3',
    rootFrequency: null, // atonal
    tags: ['energize', 'relax', 'meditate'],
  ),
  MotifMeta(
    id: 'vibe_chimes',
    name: 'Vibe Chimes',
    assetPath: 'assets/audio/motifs/vibe_chimes.mp3',
    rootFrequency: null, // complex timbre
    tags: ['relax', 'focus', 'meditate', 'sleep', 'energize'],
  ),
  MotifMeta(
    id: 'wind_chimes',
    name: 'Wind Chimes',
    assetPath: 'assets/audio/motifs/wind_chimes.mp3',
    rootFrequency: null, // atonal
    tags: ['sleep', 'relax', 'meditate'],
  ),
];
