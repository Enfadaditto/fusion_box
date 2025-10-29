import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedBoxesService {
  static const String _key = 'saved_boxes_v1';
  static const String _defaultsInitializedKey = 'saved_boxes_defaults_initialized_v1';

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

  static Future<void> initializeDefaultsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyInitialized = prefs.getBool(_defaultsInitializedKey) ?? false;
    if (alreadyInitialized) return;

    final boxes = await getAllBoxes();
    final existingNames = boxes
        .map((b) => (b['name'] as String).toLowerCase())
        .toSet();

    final defaultBoxes = <Map<String, dynamic>>[
      {
        'name': 'Grass starters',
        'ids': <int>[3, 154, 278, 318, 481],
      },
      {
        'name': 'Water starters',
        'ids': <int>[9, 160, 284, 324, 487],
      },
      {
        'name': 'Fire starters',
        'ids': <int>[6, 157, 281, 321, 484],
      },
      {
        'name': 'Pseudo-legendary',
        'ids': <int>[149, 248, 293, 299, 336, 377, 446, 473],
      },
    ];

    bool modified = false;
    for (final def in defaultBoxes) {
      final name = def['name'] as String;
      if (!existingNames.contains(name.toLowerCase())) {
        boxes.add({
          'name': name,
          'ids': List<int>.from(def['ids'] as List),
        });
        modified = true;
      }
    }

    if (modified) {
      await _saveAllBoxes(boxes);
    }

    await prefs.setBool(_defaultsInitializedKey, true);
  }
}


