/// Affinity of a sound along three perceptual axes (all values 0.0–1.0).
///
/// - energy  : 0 = calming / sleep-inducing,  1 = alert / stimulating
/// - focus   : 0 = diffuse / dreamy,           1 = sharp / concentrating
/// - warmth  : 0 = cool / clinical,            1 = warm / cozy
class MoodProfile {
  final double energy;
  final double focus;
  final double warmth;

  const MoodProfile({
    required this.energy,
    required this.focus,
    required this.warmth,
  });
}

/// Affinity map for every sound in the catalog (available and coming-soon).
/// MoodEngine filters to isAvailable == true before use.
const Map<String, MoodProfile> kMoodProfiles = {
  // ── Nature ────────────────────────────────────────────────────────────────
  'rain':     MoodProfile(energy: 0.20, focus: 0.50, warmth: 0.55),
  'ocean':    MoodProfile(energy: 0.15, focus: 0.30, warmth: 0.50),
  'wind':     MoodProfile(energy: 0.35, focus: 0.45, warmth: 0.35),
  'thunder':  MoodProfile(energy: 0.10, focus: 0.20, warmth: 0.45),
  'crickets': MoodProfile(energy: 0.15, focus: 0.20, warmth: 0.65),

  // ── Noise — available ─────────────────────────────────────────────────────
  'white_noise': MoodProfile(energy: 0.45, focus: 0.70, warmth: 0.20),
  'pink_noise':  MoodProfile(energy: 0.25, focus: 0.50, warmth: 0.50),
  'brown_noise': MoodProfile(energy: 0.15, focus: 0.40, warmth: 0.60),
  'blue_noise':  MoodProfile(energy: 0.65, focus: 0.75, warmth: 0.15),
  'red_noise':   MoodProfile(energy: 0.10, focus: 0.25, warmth: 0.55),

  // ── Noise — coming soon ───────────────────────────────────────────────────
  'yellow_noise':    MoodProfile(energy: 0.40, focus: 0.55, warmth: 0.45),
  'gray_noise':      MoodProfile(energy: 0.30, focus: 0.60, warmth: 0.30),
  'purple_noise':    MoodProfile(energy: 0.75, focus: 0.80, warmth: 0.10),
  'green_noise':     MoodProfile(energy: 0.30, focus: 0.40, warmth: 0.55),
  'orange_noise':    MoodProfile(energy: 0.20, focus: 0.30, warmth: 0.65),
  'aquamarine_noise':MoodProfile(energy: 0.35, focus: 0.60, warmth: 0.40),
  'violet_noise':    MoodProfile(energy: 0.80, focus: 0.75, warmth: 0.10),
  'black_noise':     MoodProfile(energy: 0.05, focus: 0.15, warmth: 0.50),

  // ── Binaural beats ────────────────────────────────────────────────────────
  'delta': MoodProfile(energy: 0.05, focus: 0.10, warmth: 0.40),
  'theta': MoodProfile(energy: 0.15, focus: 0.30, warmth: 0.50),
  'alpha': MoodProfile(energy: 0.40, focus: 0.60, warmth: 0.45),
  'beta':  MoodProfile(energy: 0.70, focus: 0.85, warmth: 0.30),
  'gamma': MoodProfile(energy: 0.85, focus: 0.90, warmth: 0.20),

  // ── Soundscapes ───────────────────────────────────────────────────────────
  'warm_drift':    MoodProfile(energy: 0.15, focus: 0.20, warmth: 0.70),
  'deep_current':  MoodProfile(energy: 0.10, focus: 0.25, warmth: 0.15),
  'open_sky':      MoodProfile(energy: 0.50, focus: 0.35, warmth: 0.65),
  'soft_veil':     MoodProfile(energy: 0.10, focus: 0.15, warmth: 0.55),
  'golden_haze':   MoodProfile(energy: 0.35, focus: 0.45, warmth: 0.75),
  'luminous_calm': MoodProfile(energy: 0.20, focus: 0.30, warmth: 0.60),
  'bright_pulse':  MoodProfile(energy: 0.70, focus: 0.75, warmth: 0.65),
  'shadow_weave':  MoodProfile(energy: 0.10, focus: 0.20, warmth: 0.20),
  'still_waters':  MoodProfile(energy: 0.15, focus: 0.25, warmth: 0.40),
  'crystal_ascent':MoodProfile(energy: 0.55, focus: 0.65, warmth: 0.80),

  // ── Solfeggio frequencies ─────────────────────────────────────────────────
  '174_hz': MoodProfile(energy: 0.20, focus: 0.20, warmth: 0.60),
  '285_hz': MoodProfile(energy: 0.20, focus: 0.25, warmth: 0.65),
  '396_hz': MoodProfile(energy: 0.25, focus: 0.30, warmth: 0.60),
  '417_hz': MoodProfile(energy: 0.50, focus: 0.65, warmth: 0.40),
  '432_hz': MoodProfile(energy: 0.20, focus: 0.35, warmth: 0.65),
  '528_hz': MoodProfile(energy: 0.55, focus: 0.60, warmth: 0.50),
  '639_hz': MoodProfile(energy: 0.30, focus: 0.35, warmth: 0.70),
  '741_hz': MoodProfile(energy: 0.45, focus: 0.70, warmth: 0.35),
  '852_hz': MoodProfile(energy: 0.30, focus: 0.40, warmth: 0.55),
  '963_hz': MoodProfile(energy: 0.55, focus: 0.45, warmth: 0.45),
};
