// Tests for the saved-mix format (D-018): v2 round trip for every layer kind,
// pre-v2 fixtures still loading, and bad layers skipped without losing the mix.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noisy_app/models/saved_mix.dart';

/// Serialize → JSON string → deserialize, as StorageService does.
SavedMix roundTrip(SavedMix mix) =>
    SavedMix.fromJson(jsonDecode(jsonEncode(mix.toJson())) as Map<String, dynamic>);

void expectSameLayer(MixLayer a, MixLayer b) {
  expect(a.kind, b.kind);
  expect(a.assetPath, b.assetPath);
  expect(a.name, b.name);
  expect(a.volume, b.volume);
  expect(a.pitchShiftRatio, b.pitchShiftRatio);
  expect(a.frequency, b.frequency);
  expect(a.carrierHz, b.carrierHz);
  expect(a.beatHz, b.beatHz);
}

SavedMix mixOf(List<MixLayer> layers) => SavedMix(
      id: 'id-1',
      name: 'Evening',
      category: 'Relax',
      layers: layers,
      createdAt: DateTime.utc(2026, 9, 25, 20, 30),
    );

// A mix as saved before D-018: no version, no kind, assetPath/name/volume only.
const _v1Fixture = '''
{
  "id": "legacy-1",
  "name": "Old mix",
  "category": "Sleep",
  "createdAt": "2026-07-01T22:00:00.000",
  "layers": [
    {"assetPath": "assets/audio/soundscapes/luminous_calm.mp3", "name": "Luminous Calm", "volume": 0.6},
    {"assetPath": "assets/audio/nature/rain.mp3", "name": "Rain", "volume": 0.4},
    {"assetPath": "tone:528", "name": "528 Hz", "volume": 0.2},
    {"assetPath": "binaural:6", "name": "Theta 6 Hz", "volume": 0.3},
    {"assetPath": "assets/audio/binaural/alpha.mp3", "name": "Alpha", "volume": 0.5}
  ]
}
''';

void main() {
  group('round trip (v2)', () {
    const layers = <MixLayer>[
      MixLayer(
          kind: MixLayerKind.sample,
          assetPath: 'assets/audio/nature/rain.mp3',
          name: 'Rain',
          volume: 0.4),
      MixLayer(
          kind: MixLayerKind.soundscape,
          assetPath: 'assets/audio/soundscapes/luminous_calm.mp3',
          name: 'Luminous Calm',
          volume: 0.65,
          pitchShiftRatio: 1.0090758),
      MixLayer(
          kind: MixLayerKind.tone,
          assetPath: 'tone:528',
          name: '528 Hz',
          volume: 0.2,
          frequency: 528.0),
      MixLayer(
          kind: MixLayerKind.binaural,
          assetPath: 'binaural:20',
          name: 'Beta 20 Hz',
          volume: 0.3,
          carrierHz: 391.9954,
          beatHz: 20.0),
    ];

    for (final layer in layers) {
      test('${layer.kind.name} layer survives serialize → deserialize', () {
        final back = roundTrip(mixOf([layer]));
        expect(back.layers, hasLength(1));
        expectSameLayer(back.layers.single, layer);
      });
    }

    test('whole mix, all kinds together, keeps order and metadata', () {
      final mix = mixOf(layers);
      final back = roundTrip(mix);
      expect(back.id, mix.id);
      expect(back.name, mix.name);
      expect(back.category, mix.category);
      expect(back.createdAt, mix.createdAt);
      expect(back.layers, hasLength(layers.length));
      for (var i = 0; i < layers.length; i++) {
        expectSameLayer(back.layers[i], layers[i]);
      }
    });

    test('saved JSON carries version 2 and per-layer kind', () {
      final json = mixOf(layers).toJson();
      expect(json['version'], 2);
      final kinds = (json['layers'] as List).map((l) => l['kind']).toList();
      expect(kinds, ['sample', 'soundscape', 'tone', 'binaural']);
    });
  });

  group('pre-v2 fixture (no version, no kind)', () {
    late SavedMix mix;
    setUp(() {
      mix = SavedMix.fromJson(jsonDecode(_v1Fixture) as Map<String, dynamic>);
    });

    test('loads every layer with metadata intact', () {
      expect(mix.name, 'Old mix');
      expect(mix.category, 'Sleep');
      expect(mix.layers, hasLength(5));
    });

    test('soundscapes/ folder → soundscape, neutral pitch 1.0', () {
      final l = mix.layers[0];
      expect(l.kind, MixLayerKind.soundscape);
      expect(l.pitchShiftRatio, 1.0);
      expect(l.volume, 0.6);
    });

    test('plain asset → sample', () {
      expect(mix.layers[1].kind, MixLayerKind.sample);
      expect(mix.layers[1].assetPath, 'assets/audio/nature/rain.mp3');
    });

    test('tone: prefix → tone, frequency from the ID', () {
      final l = mix.layers[2];
      expect(l.kind, MixLayerKind.tone);
      expect(l.frequency, 528.0);
    });

    test('binaural: prefix → binaural, beat from the ID, legacy carrier', () {
      final l = mix.layers[3];
      expect(l.kind, MixLayerKind.binaural);
      expect(l.beatHz, 6.0);
      expect(l.carrierHz, MixLayer.legacyBinauralCarrierHz);
    });

    test('binaural MP3 sample (Mixer catalog) stays a sample', () {
      expect(mix.layers[4].kind, MixLayerKind.sample);
    });

    test('re-saving an old mix upgrades it to v2 losslessly', () {
      final back = roundTrip(mix);
      for (var i = 0; i < mix.layers.length; i++) {
        expectSameLayer(back.layers[i], mix.layers[i]);
      }
    });
  });

  group('bad layers are skipped, the rest of the mix survives', () {
    const good =
        '{"kind": "sample", "assetPath": "assets/audio/nature/rain.mp3", "name": "Rain", "volume": 0.4}';
    const bad = <(String, String)>[
      ('unknown kind',
          '{"kind": "motif", "assetPath": "x", "name": "X", "volume": 0.5}'),
      ('non-string kind',
          '{"kind": 3, "assetPath": "x", "name": "X", "volume": 0.5}'),
      ('tone with no frequency and unparsable ID',
          '{"kind": "tone", "assetPath": "tone:abc", "name": "X", "volume": 0.5}'),
      ('legacy tone ID with junk',
          '{"assetPath": "tone:", "name": "X", "volume": 0.5}'),
      ('binaural with no beat',
          '{"kind": "binaural", "assetPath": "b", "name": "X", "volume": 0.5, "carrierHz": 200}'),
      ('tone with zero frequency',
          '{"kind": "tone", "assetPath": "tone:0", "name": "X", "volume": 0.5, "frequency": 0}'),
      ('binaural with NaN-like string carrier',
          '{"kind": "binaural", "assetPath": "binaural:6", "name": "X", "volume": 0.5, "carrierHz": "NaN", "beatHz": 6}'),
      ('missing volume',
          '{"kind": "sample", "assetPath": "a", "name": "X"}'),
      ('missing assetPath', '{"kind": "sample", "name": "X", "volume": 0.5}'),
      ('not an object', '"tone:528"'),
    ];

    for (final (label, layerJson) in bad) {
      test(label, () {
        final json = jsonDecode(
                '{"version": 2, "id": "m", "name": "M", "category": "", '
                '"createdAt": "2026-09-25T00:00:00.000", '
                '"layers": [$good, $layerJson, $good]}')
            as Map<String, dynamic>;
        final mix = SavedMix.fromJson(json);
        expect(mix.layers, hasLength(2));
        expect(mix.layers.every((l) => l.kind == MixLayerKind.sample), isTrue);
      });
    }

    test('non-positive soundscape pitch falls back to neutral 1.0', () {
      final l = MixLayer.tryFromJson(<String, dynamic>{
        'kind': 'soundscape',
        'assetPath': 'assets/audio/soundscapes/a.mp3',
        'name': 'A',
        'volume': 0.5,
        'pitchShiftRatio': 0,
      });
      expect(l!.pitchShiftRatio, 1.0);
    });
  });
}
