import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_mix.dart';

class StorageService {
  static const _key = 'saved_mixes';

  Future<List<SavedMix>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((item) => SavedMix.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(SavedMix mix) async {
    final mixes = await loadAll();
    final idx = mixes.indexWhere((m) => m.id == mix.id);
    if (idx >= 0) {
      mixes[idx] = mix;
    } else {
      mixes.add(mix);
    }
    await _persist(mixes);
  }

  Future<void> delete(String id) async {
    final mixes = await loadAll();
    mixes.removeWhere((m) => m.id == id);
    await _persist(mixes);
  }

  Future<void> _persist(List<SavedMix> mixes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(mixes.map((m) => m.toJson()).toList()),
    );
  }
}
