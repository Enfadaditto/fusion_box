import 'package:fusion_box/core/constants/pokemon_type_chart.dart';

class TypeEffectivenessService {
  const TypeEffectivenessService();

  /// Full effectiveness map: attack type -> multiplier (includes 0, 0.25, 0.5, 1, 2, 4).
  Map<String, double> effectivenessMap(List<String> defenderTypes) {
    final List<String> normalized = defenderTypes.toSet().toList();
    final Map<String, double> result = <String, double>{};
    for (final String attack in kAllTypes) {
      result[attack] = defensiveEffectiveness(attack, normalized);
    }
    return result;
  }

  Map<String, double> effectivenessMapSingle(String type) => effectivenessMap(<String>[type]);
  Map<String, double> effectivenessMapDual(String type1, String type2) => effectivenessMap(<String>[type1, type2]);

  /// Grouped buckets of effectiveness: multiplier -> list of attack types.
  /// Buckets: 0.0, 0.25, 0.5, 1.0, 2.0, 4.0
  Map<double, List<String>> groupedEffectiveness(List<String> defenderTypes) {
    final Map<double, List<String>> buckets = <double, List<String>>{
      0.0: <String>[],
      0.25: <String>[],
      0.5: <String>[],
      1.0: <String>[],
      2.0: <String>[],
      4.0: <String>[],
    };

    final Map<String, double> map = effectivenessMap(defenderTypes);
    for (final String attack in kAllTypes) {
      final double mult = map[attack] ?? 1.0;
      buckets[mult]?.add(attack);
    }
    return buckets;
  }

  Map<double, List<String>> groupedEffectivenessSingle(String type) => groupedEffectiveness(<String>[type]);
  Map<double, List<String>> groupedEffectivenessDual(String type1, String type2) => groupedEffectiveness(<String>[type1, type2]);

  /// Returns all weaknesses for a defender that has one or two types.
  /// Output: Map of attack type -> multiplier (>1 only). Sorted descending by multiplier in the returned list of entries.
  Map<String, double> weaknessesFor(List<String> defenderTypes) {
    final Map<String, double> all = effectivenessMap(defenderTypes);
    final Map<String, double> onlyWeak = <String, double>{};
    all.forEach((String attack, double mult) {
      if (mult > 1.0) {
        onlyWeak[attack] = mult;
      }
    });
    return onlyWeak;
  }

  /// Convenience overloads
  Map<String, double> weaknessesForSingle(String type) => weaknessesFor(<String>[type]);
  Map<String, double> weaknessesForDual(String type1, String type2) => weaknessesFor(<String>[type1, type2]);

  /// Returns a sorted list of (type, multiplier) descending by multiplier.
  List<MapEntry<String, double>> sortedWeaknesses(List<String> defenderTypes) {
    final Map<String, double> map = weaknessesFor(defenderTypes);
    final List<MapEntry<String, double>> entries = map.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
