// Defensive type chart (Gen 6+). Static, immutable structure.
// For each DEFENDER type, lists which ATTACKER types deal x2 (weak), x0.5 (resist), or x0 (immune).

const List<String> kAllTypes = <String>[
  'Normal', 'Fire', 'Water', 'Electric', 'Grass', 'Ice',
  'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
  'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy',
];

// Map: Defender -> { 'weak': [...], 'resist': [...], 'immune': [...] }
const Map<String, Map<String, List<String>>> kDefensiveTypeChart = <String, Map<String, List<String>>>{
  'Normal': <String, List<String>>{
    'weak': <String>['Fighting'],
    'resist': <String>[],
    'immune': <String>['Ghost'],
  },
  'Fire': <String, List<String>>{
    'weak': <String>['Water', 'Ground', 'Rock'],
    'resist': <String>['Fire', 'Grass', 'Ice', 'Bug', 'Steel', 'Fairy'],
    'immune': <String>[],
  },
  'Water': <String, List<String>>{
    'weak': <String>['Electric', 'Grass'],
    'resist': <String>['Fire', 'Water', 'Ice', 'Steel'],
    'immune': <String>[],
  },
  'Electric': <String, List<String>>{
    'weak': <String>['Ground'],
    'resist': <String>['Electric', 'Flying', 'Steel'],
    'immune': <String>[],
  },
  'Grass': <String, List<String>>{
    'weak': <String>['Fire', 'Ice', 'Poison', 'Flying', 'Bug'],
    'resist': <String>['Water', 'Electric', 'Grass', 'Ground'],
    'immune': <String>[],
  },
  'Ice': <String, List<String>>{
    'weak': <String>['Fire', 'Fighting', 'Rock', 'Steel'],
    'resist': <String>['Ice'],
    'immune': <String>[],
  },
  'Fighting': <String, List<String>>{
    'weak': <String>['Flying', 'Psychic', 'Fairy'],
    'resist': <String>['Bug', 'Rock', 'Dark'],
    'immune': <String>[],
  },
  'Poison': <String, List<String>>{
    'weak': <String>['Ground', 'Psychic'],
    'resist': <String>['Grass', 'Fighting', 'Poison', 'Bug', 'Fairy'],
    'immune': <String>[],
  },
  'Ground': <String, List<String>>{
    'weak': <String>['Water', 'Grass', 'Ice'],
    'resist': <String>['Poison', 'Rock'],
    'immune': <String>['Electric'],
  },
  'Flying': <String, List<String>>{
    'weak': <String>['Electric', 'Ice', 'Rock'],
    'resist': <String>['Grass', 'Fighting', 'Bug'],
    'immune': <String>['Ground'],
  },
  'Psychic': <String, List<String>>{
    'weak': <String>['Bug', 'Ghost', 'Dark'],
    'resist': <String>['Fighting', 'Psychic'],
    'immune': <String>[],
  },
  'Bug': <String, List<String>>{
    'weak': <String>['Fire', 'Flying', 'Rock'],
    'resist': <String>['Grass', 'Fighting', 'Ground'],
    'immune': <String>[],
  },
  'Rock': <String, List<String>>{
    'weak': <String>['Water', 'Grass', 'Fighting', 'Ground', 'Steel'],
    'resist': <String>['Normal', 'Fire', 'Poison', 'Flying'],
    'immune': <String>[],
  },
  'Ghost': <String, List<String>>{
    'weak': <String>['Ghost', 'Dark'],
    'resist': <String>['Poison', 'Bug'],
    'immune': <String>['Normal', 'Fighting'],
  },
  'Dragon': <String, List<String>>{
    'weak': <String>['Ice', 'Dragon', 'Fairy'],
    'resist': <String>['Fire', 'Water', 'Electric', 'Grass'],
    'immune': <String>[],
  },
  'Dark': <String, List<String>>{
    'weak': <String>['Fighting', 'Bug', 'Fairy'],
    'resist': <String>['Ghost', 'Dark'],
    'immune': <String>['Psychic'],
  },
  'Steel': <String, List<String>>{
    'weak': <String>['Fire', 'Fighting', 'Ground'],
    'resist': <String>['Normal', 'Grass', 'Ice', 'Flying', 'Psychic', 'Bug', 'Rock', 'Dragon', 'Steel', 'Fairy'],
    'immune': <String>['Poison'],
  },
  'Fairy': <String, List<String>>{
    'weak': <String>['Poison', 'Steel'],
    'resist': <String>['Fighting', 'Bug', 'Dark'],
    'immune': <String>['Dragon'],
  },
};

/// Computes the defensive effectiveness multiplier for a given attack type
/// against one or two defender types (order independent).
double defensiveEffectiveness(String attackType, List<String> defenderTypes) {
  double multiplier = 1.0;
  for (final String defender in defenderTypes) {
    final Map<String, List<String>>? profile = kDefensiveTypeChart[defender];
    if (profile == null) {
      multiplier *= 1.0;
      continue;
    }
    if (profile['immune']!.contains(attackType)) {
      multiplier *= 0.0;
    } else if (profile['weak']!.contains(attackType)) {
      multiplier *= 2.0;
    } else if (profile['resist']!.contains(attackType)) {
      multiplier *= 0.5;
    } else {
      multiplier *= 1.0;
    }
  }
  return multiplier;
}
