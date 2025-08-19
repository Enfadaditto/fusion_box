import 'dart:convert';

import 'package:fusion_box/core/utils/pokemon_name_normalizer.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/pokemon.dart';
import '../../domain/entities/pokemon_stats.dart';

class FusionStatsCalculator {
  static final FusionStatsCalculator _instance = FusionStatsCalculator._internal();
  factory FusionStatsCalculator() => _instance;
  FusionStatsCalculator._internal();

  Future<PokemonStats> getStatsFromFusion(Pokemon head, Pokemon body) async {
    final headStats = await getStatsFromPokemon(head);
    final bodyStats = await getStatsFromPokemon(body);
    return calculateFusionStats(headStats, bodyStats);
  }

  PokemonStats calculateFusionStats(PokemonStats head, PokemonStats body) {
    headDominantStats(int headStat, int bodyStat) => (2 * headStat + bodyStat) ~/ 3;
    bodyDominantStats(int headStat, int bodyStat) => ((2 * bodyStat + headStat) / 3).round();

    return PokemonStats(
        attack: bodyDominantStats(head.attack, body.attack),
        defense: bodyDominantStats(head.defense, body.defense),
        speed: bodyDominantStats(head.speed, body.speed),

        hp: headDominantStats(head.hp, body.hp),
        specialAttack: headDominantStats(head.specialAttack, body.specialAttack),
        specialDefense: headDominantStats(head.specialDefense, body.specialDefense),
    );
  }

  Map<int, PokemonStats>? _statsByNumber;
  Map<String, PokemonStats>? _statsByNormalizedName;

  Future<void> _ensureLocalStatsLoaded() async {
    if (_statsByNumber != null && _statsByNormalizedName != null) {
      return;
    }

    final String jsonString = await rootBundle.loadString('assets/pokemon_full_list.json');
    final List<dynamic> items = json.decode(jsonString) as List<dynamic>;

    final Map<int, PokemonStats> byNumber = {};
    final Map<String, PokemonStats> byNormalizedName = {};

    for (final dynamic raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final int? number = raw['number'] as int?;
      final String? name = raw['name'] as String?;
      final Map<String, dynamic>? statsMap = raw['stats'] as Map<String, dynamic>?;
      if (number == null || name == null || statsMap == null) continue;

      final PokemonStats stats = PokemonStats(
        hp: statsMap['hp'] as int,
        attack: statsMap['attack'] as int,
        defense: statsMap['defense'] as int,
        specialAttack: statsMap['specialAttack'] as int,
        specialDefense: statsMap['specialDefense'] as int,
        speed: statsMap['speed'] as int,
      );

      byNumber[number] = stats;
      final String normalizedName = PokemonNameNormalizer.normalizePokemonName(name);
      byNormalizedName[normalizedName] = stats;
    }

    _statsByNumber = byNumber;
    _statsByNormalizedName = byNormalizedName;
  }

  Future<PokemonStats> getStatsFromPokemon(Pokemon pokemon) async {
    await _ensureLocalStatsLoaded();

    final PokemonStats? byNumber = _statsByNumber![pokemon.pokedexNumber];
    if (byNumber != null) return byNumber;

    final String normalizedName = PokemonNameNormalizer.normalizePokemonName(pokemon.name);
    final PokemonStats? byName = _statsByNormalizedName![normalizedName];
    if (byName != null) return byName;

    throw Exception('Base stats not found locally for ${pokemon.name} (#${pokemon.pokedexNumber}). Please generate assets/pokemon_full_list.json');
  }
}