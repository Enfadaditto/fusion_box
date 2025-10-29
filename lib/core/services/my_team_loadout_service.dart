import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists ability and moves selections for each fusion in "My Team".
/// Stored as a single JSON object map: fusionId -> { ability: String?, moves: List<String?> }
class MyTeamLoadoutService {
  static const String _storageKey = 'my_team_loadout_v1';

  static Future<Map<String, dynamic>> _getAllRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<void> _saveAllRaw(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  static Future<void> saveAbility(String fusionId, String? ability) async {
    final all = await _getAllRaw();
    final entry = Map<String, dynamic>.from(all[fusionId] as Map? ?? <String, dynamic>{});
    entry['ability'] = ability;
    all[fusionId] = entry;
    await _saveAllRaw(all);
  }

  static Future<String?> getAbility(String fusionId) async {
    final all = await _getAllRaw();
    final entry = all[fusionId];
    if (entry is Map && entry['ability'] is String) return entry['ability'] as String;
    return null;
  }

  static Future<void> saveMoves(String fusionId, List<String?> moves) async {
    // Ensure exactly 4 slots
    final fixed = List<String?>.generate(4, (i) => i < moves.length ? moves[i] : null);
    final all = await _getAllRaw();
    final entry = Map<String, dynamic>.from(all[fusionId] as Map? ?? <String, dynamic>{});
    entry['moves'] = fixed;
    all[fusionId] = entry;
    await _saveAllRaw(all);
  }

  static Future<List<String?>> getMoves(String fusionId) async {
    final all = await _getAllRaw();
    final entry = all[fusionId];
    if (entry is Map && entry['moves'] is List) {
      final list = (entry['moves'] as List).map((e) => e == null ? null : e.toString()).toList();
      return List<String?>.generate(4, (i) => i < list.length ? list[i] : null);
    }
    return List<String?>.filled(4, null);
  }
}


