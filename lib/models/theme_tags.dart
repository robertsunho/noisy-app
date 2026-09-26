/// Fixed theme vocabulary the LLM may tag a mood description with (D-017).
///
/// Themes are the only description-derived signal sent to analytics: every
/// tag that leaves the app is one of these constants, never text the user
/// wrote. Provisional — expected to inform Radio station naming.
const kThemeTags = <String>[
  'night', 'dawn', 'dusk', 'rain', 'water', 'ocean', 'forest', 'wind',
  'snow', 'space', 'city', 'warmth', 'cold', 'stillness', 'drift',
  'melancholy', 'joy', 'nostalgia', 'focus', 'rest',
];

/// Maximum number of themes kept from one response.
const kMaxThemeTags = 3;

/// Filters a raw `themes` JSON value down to vocabulary tags.
///
/// Anything that is not a list of strings yields `[]`. Entries are matched
/// case-insensitively; unknown entries are dropped, duplicates removed, and at
/// most [kMaxThemeTags] kept. Returned strings are always the constants from
/// [kThemeTags], so no model- or user-supplied text passes through.
List<String> filterThemeTags(Object? raw) {
  if (raw is! List) return const [];
  final out = <String>[];
  for (final item in raw) {
    if (item is! String) continue;
    final key = item.trim().toLowerCase();
    for (final tag in kThemeTags) {
      if (tag == key && !out.contains(tag)) {
        out.add(tag);
        break;
      }
    }
    if (out.length == kMaxThemeTags) break;
  }
  return out;
}
