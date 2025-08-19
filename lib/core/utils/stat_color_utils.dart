import 'package:flutter/material.dart';

/// Utility class for stat-related color operations
class StatColorUtils {
  /// Returns a color based on the stat value
  /// 
  /// Color mapping:
  /// - 200+: Red (excellent)
  /// - 150-199: Orange (very good)
  /// - 100-149: Yellow (good)
  /// - 50-99: Green (average)
  /// - 0-49: Blue (poor)
  static Color getStatColor(int statValue) {
    if (statValue >= 200) return Colors.red;
    if (statValue >= 150) return Colors.orange;
    if (statValue >= 100) return Colors.yellow;
    if (statValue >= 50) return Colors.green;
    return Colors.blue;
  }
} 