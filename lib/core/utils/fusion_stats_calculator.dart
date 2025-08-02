import 'dart:convert';

import 'package:fusion_box/core/utils/pokemon_name_normalizer.dart';
import 'package:http/http.dart' as http;

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

  Future<PokemonStats> getStatsFromPokemon(Pokemon pokemon) async {
    const String baseUrl = 'https://pokeapi.co/api/v2/pokemon';
    final normalizedName = PokemonNameNormalizer.normalizePokemonName(pokemon.name);
    final response = await http.get(Uri.parse('$baseUrl/$normalizedName'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PokemonStats(
        hp: data['stats'][0]['base_stat'],
        attack: data['stats'][1]['base_stat'],
        defense: data['stats'][2]['base_stat'],
        specialAttack: data['stats'][3]['base_stat'],
        specialDefense: data['stats'][4]['base_stat'],
        speed: data['stats'][5]['base_stat'],
      );
    }

    throw Exception('Failed to load stats for ${pokemon.name}');
  }
}