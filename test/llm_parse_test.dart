// Tests for LlmService.parseResponseText and the theme vocabulary (D-017).
//
// The invariant under test: nothing but a kThemeTags constant can come out
// of the themes field, and adding themes never breaks an energy/focus/warmth
// parse that succeeded before.

import 'package:flutter_test/flutter_test.dart';
import 'package:noisy_app/models/theme_tags.dart';
import 'package:noisy_app/services/llm_service.dart';

MoodParse? parse(String s) => LlmService.parseResponseText(s);

void main() {
  group('theme vocabulary', () {
    test('has the 20 agreed tags, lowercase and unique', () {
      expect(kThemeTags, hasLength(20));
      expect(kThemeTags.toSet(), hasLength(20));
      for (final t in kThemeTags) {
        expect(t, t.toLowerCase());
      }
    });

    test('any kMaxThemeTags tags joined stay under 100 characters', () {
      final longest = [...kThemeTags]
        ..sort((a, b) => b.length.compareTo(a.length));
      expect(longest.take(kMaxThemeTags).join(',').length, lessThan(100));
    });
  });

  group('parseResponseText — themes', () {
    test('valid tags are kept in order', () {
      final r = parse(
          '{"energy": 0.3, "focus": 0.2, "warmth": 0.7, "themes": ["night", "rain"]}');
      expect(r!.themes, ['night', 'rain']);
    });

    test('empty list → no themes', () {
      final r = parse(
          '{"energy": 0.3, "focus": 0.2, "warmth": 0.7, "themes": []}');
      expect(r!.themes, isEmpty);
    });

    test('unknown tags are dropped, known ones kept', () {
      final r = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7, '
          '"themes": ["night", "my ex", "rain", "grandma\'s kitchen"]}');
      expect(r!.themes, ['night', 'rain']);
    });

    test('case and whitespace are normalized to the vocabulary constant', () {
      final r = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7, '
          '"themes": ["Night", " RAIN "]}');
      expect(r!.themes, ['night', 'rain']);
      expect(identical(r.themes[0], kThemeTags[0]), isTrue);
    });

    test('duplicates removed; capped at kMaxThemeTags', () {
      final r = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7, '
          '"themes": ["rain", "rain", "night", "dusk", "snow", "joy"]}');
      expect(r!.themes, ['rain', 'night', 'dusk']);
    });

    test('missing themes field → empty list', () {
      final r = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7}');
      expect(r, isNotNull);
      expect(r!.themes, isEmpty);
    });

    const malformed = <(String, String)>[
      ('a string', '"night, rain"'),
      ('a number', '3'),
      ('null', 'null'),
      ('an object', '{"night": true}'),
      ('a list of non-strings', '[1, true, null, ["night"]]'),
    ];
    for (final (label, value) in malformed) {
      test('malformed themes ($label) → empty list, parse still succeeds', () {
        final r = parse(
            '{"energy": 0.3, "focus": 0.2, "warmth": 0.7, "themes": $value}');
        expect(r, isNotNull);
        expect(r!.themes, isEmpty);
        expect(r.energy, 0.3);
      });
    }

    test('mixed list keeps only vocabulary strings', () {
      final r = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7, '
          '"themes": [42, "ocean", {"x": 1}, "OCEANS"]}');
      expect(r!.themes, ['ocean']);
    });
  });

  group('parseResponseText — existing fields unaffected', () {
    test('energy/focus/warmth identical with and without themes', () {
      final without = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7}')!;
      final withThemes = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7, '
          '"themes": ["dawn"]}')!;
      final withJunk = parse('{"energy": 0.3, "focus": 0.2, "warmth": 0.7, '
          '"themes": "garbage"}')!;
      for (final r in [withThemes, withJunk]) {
        expect(r.energy, without.energy);
        expect(r.focus, without.focus);
        expect(r.warmth, without.warmth);
      }
    });

    test('integer values parse as doubles', () {
      final r = parse('{"energy": 1, "focus": 0, "warmth": 1}')!;
      expect((r.energy, r.focus, r.warmth), (1.0, 0.0, 1.0));
    });

    test('markdown fences are still stripped', () {
      final r = parse('```json\n{"energy": 0.5, "focus": 0.4, "warmth": 0.6, '
          '"themes": ["forest"]}\n```')!;
      expect(r.energy, 0.5);
      expect(r.themes, ['forest']);
    });

    test('missing energy still fails the parse, as before', () {
      expect(parse('{"focus": 0.2, "warmth": 0.7, "themes": ["rain"]}'),
          isNull);
    });

    test('non-numeric focus still fails the parse, as before', () {
      expect(parse('{"energy": 0.3, "focus": "high", "warmth": 0.7}'), isNull);
    });

    test('non-JSON response still fails the parse, as before', () {
      expect(parse('I feel calm'), isNull);
    });
  });
}
