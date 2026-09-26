import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  // ── Soundscape generation ──────────────────────────────────────────────────

  /// Fired whenever the user generates a soundscape via the mood sliders.
  void logGenerate({
    required double energy,
    required double focus,
    required double warmth,
    required String category,
  }) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_generate',
      parameters: {
        'energy': energy,
        'focus': focus,
        'warmth': warmth,
        'category': category,
      },
    ));
  }

  /// Fired when the user generates via the natural language mood input.
  ///
  /// Never receives the user's text (D-017): only its length and word count,
  /// the resulting slider values, and vocabulary theme tags.
  void logLlmGenerate({
    required int textLength,
    required int wordCount,
    required double energy,
    required double focus,
    required double warmth,
    required List<String> themes,
  }) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_llm_generate',
      parameters: {
        'text_length': textLength,
        'word_count': wordCount,
        'energy': energy,
        'focus': focus,
        'warmth': warmth,
        // Firebase parameters can't be arrays. ≤ 3 vocabulary words joined
        // stays well under the 100-character parameter limit.
        'themes': themes.isEmpty ? 'none' : themes.join(','),
      },
    ));
  }

  // ── Journey ────────────────────────────────────────────────────────────────

  /// Fired when a curated journey starts.
  void logJourneyStart({
    required String journeyName,
    required String category,
  }) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_journey_start',
      parameters: {
        'journey_name': journeyName,
        'category': category,
      },
    ));
  }

  // ── Mixer ──────────────────────────────────────────────────────────────────

  /// Fired when the user adds a layer from the sound catalog.
  void logLayerAdd({
    required String layerName,
    required String category,
  }) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_layer_add',
      parameters: {
        'layer_name': layerName,
        'category': category,
      },
    ));
  }

  /// Fired when the user removes a layer.
  void logLayerRemove({required String layerName}) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_layer_remove',
      parameters: {'layer_name': layerName},
    ));
  }

  /// Fired when the user saves the current mix. Logs only the length of the
  /// user-typed name, never the name itself (D-017).
  void logMixSave({required int nameLength}) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_mix_save',
      parameters: {'name_length': nameLength},
    ));
  }
}
