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
  void logLlmGenerate({
    required String userText,
    required double energy,
    required double focus,
    required double warmth,
  }) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_llm_generate',
      parameters: {
        'user_text': userText,
        'energy': energy,
        'focus': focus,
        'warmth': warmth,
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

  /// Fired when the user saves the current mix.
  void logMixSave({required String mixName}) {
    unawaited(FirebaseAnalytics.instance.logEvent(
      name: 'noisy_mix_save',
      parameters: {'mix_name': mixName},
    ));
  }
}
