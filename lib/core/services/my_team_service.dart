import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Simple persistence layer for "My Team" feature.
/// Stores up to 6 fusions, each defined by head and body pokedex numbers.
class MyTeamService {
  static const String _storageKey = 'my_team_v1';
  static const int maxTeamSize = 6;

  /// Represents the result of trying to add a fusion to the team.
  static const String resultAdded = 'added';
  static const String resultAlreadyExists = 'already_exists';
  static const String resultTeamFull = 'team_full';

  /// Returns a list of fusion entries where each entry is a map with keys
  /// 'head' and 'body' pointing to the pokedex numbers.
  static Future<List<Map<String, int>>> getTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => {
                  'head': (e['head'] as num).toInt(),
                  'body': (e['body'] as num).toInt(),
                })
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveTeam(List<Map<String, int>> team) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(team);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Attempts to add a fusion. Returns one of the result constants.
  static Future<String> addFusion({required int headId, required int bodyId}) async {
    final team = await getTeam();

    if (team.length >= maxTeamSize) {
      return resultTeamFull;
    }

    final exists = team.any((e) => e['head'] == headId && e['body'] == bodyId);
    if (exists) {
      return resultAlreadyExists;
    }

    team.add({'head': headId, 'body': bodyId});
    await _saveTeam(team);
    return resultAdded;
  }

  static Future<void> removeAt(int index) async {
    final team = await getTeam();
    if (index < 0 || index >= team.length) return;
    team.removeAt(index);
    await _saveTeam(team);
  }

  static Future<void> removeFusion({required int headId, required int bodyId}) async {
    final team = await getTeam();
    team.removeWhere((e) => e['head'] == headId && e['body'] == bodyId);
    await _saveTeam(team);
  }

  static Future<void> clearTeam() async {
    await _saveTeam([]);
  }
}


