import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/theme_tags.dart';

/// A parsed mood: slider values plus zero to three vocabulary theme tags.
typedef MoodParse = ({
  double energy,
  double focus,
  double warmth,
  List<String> themes,
});

class LlmService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';
  static final _system =
      'You are a mood interpreter for an ambient sound app. The user will '
      'describe how they want to feel. Respond with ONLY a JSON object '
      'containing three values between 0.0 and 1.0, nothing else — no '
      'markdown, no explanation. The three values are: energy (0.0 = '
      'calm/sleepy, 1.0 = alert/energized), focus (0.0 = diffuse/dreamy, '
      '1.0 = sharp/concentrated), warmth (0.0 = dark/heavy/cool, 1.0 = '
      'bright/light/warm). Also include "themes": a list of zero to three '
      'words chosen ONLY from this list: ${kThemeTags.join(', ')}. Use no '
      'other words. Example response: '
      '{"energy": 0.3, "focus": 0.2, "warmth": 0.7, "themes": ["night", "rain"]}';

  /// Parses the model's text response. Pure: no I/O.
  ///
  /// energy/focus/warmth are parsed exactly as before the themes field existed
  /// (D-017); a missing or malformed `themes` never fails the parse — it
  /// yields an empty list. Returns null if the energy/focus/warmth parse fails.
  static MoodParse? parseResponseText(String text) {
    try {
      // Strip any accidental markdown fences.
      final cleaned = text
          .replaceAll(RegExp(r'```[a-z]*'), '')
          .replaceAll('```', '')
          .trim();

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      return (
        energy: (parsed['energy'] as num).toDouble(),
        focus: (parsed['focus'] as num).toDouble(),
        warmth: (parsed['warmth'] as num).toDouble(),
        themes: filterThemeTags(parsed['themes']),
      );
    } catch (_) {
      return null;
    }
  }

  Future<MoodParse?> parseMood(String userText) async {
    try {
      final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return null;

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 100,
              'system': _system,
              'messages': [
                {'role': 'user', 'content': userText},
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          (body['content'] as List).first['text'] as String;

      return parseResponseText(text);
    } catch (_) {
      return null;
    }
  }
}
