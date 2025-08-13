import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedBoxesService {
  static const String _key = 'saved_boxes_v1';

  /// Returns a list of saved boxes as maps: { 'name': String, 'ids': List<int> }
  static Future<List<Map<String, dynamic>>> getAllBoxes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => {
                  'name': e['name'] as String,
                  'ids': (e['ids'] as List).map((v) => v as int).toList(),
                })
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAllBoxes(List<Map<String, dynamic>> boxes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(boxes);
    await prefs.setString(_key, jsonString);
  }

  static Future<bool> exists(String name) async {
    final boxes = await getAllBoxes();
    return boxes.any((b) => (b['name'] as String).toLowerCase() == name.toLowerCase());
  }

  static Future<void> saveBox(String name, List<int> ids) async {
    final boxes = await getAllBoxes();
    final index = boxes.indexWhere((b) => (b['name'] as String).toLowerCase() == name.toLowerCase());
    final newEntry = {
      'name': name.trim(),
      'ids': ids,
    };
    if (index >= 0) {
      boxes[index] = newEntry;
    } else {
      boxes.add(newEntry);
    }
    await _saveAllBoxes(boxes);
  }

  static Future<void> deleteBox(String name) async {
    final boxes = await getAllBoxes();
    boxes.removeWhere((b) => (b['name'] as String).toLowerCase() == name.toLowerCase());
    await _saveAllBoxes(boxes);
  }
}


