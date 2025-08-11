// Run with:
//   dart run tool/generate_pokemon_stats_json.dart
// This script iterates the embedded local Pokémon list and queries PokeAPI
// to produce assets/pokemon_full_list.json with number, name, types and stats.

import 'dart:convert';
import 'dart:io';

import 'package:fusion_box/core/utils/pokemon_name_normalizer.dart';
import 'package:fusion_box/data/datasources/local/pokemon_local_datasource.dart';
import 'package:fusion_box/data/models/pokemon_model.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final datasource = PokemonLocalDataSourceImpl();
  final List<PokemonModel> pokemonList = datasource.getEmbeddedPokemonListForTools();

  const String baseUrl = 'https://pokeapi.co/api/v2/pokemon';
  final List<Map<String, dynamic>> output = [];

  int processed = 0;
  for (final PokemonModel p in pokemonList) {
    processed += 1;
    final String normalized = PokemonNameNormalizer.normalizePokemonName(p.name);
    stdout.writeln('[${processed}/${pokemonList.length}] Fetching $normalized...');
    final uri = Uri.parse('$baseUrl/$normalized');

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        stderr.writeln('  -> WARNING: ${p.name} (#${p.pokedexNumber}) failed: ${response.statusCode}');
        continue;
      }
      final dynamic data = json.decode(response.body);

      final List<dynamic> stats = data['stats'] as List<dynamic>;
      Map<String, int> statsMap() {
        int readStat(String key) {
          try {
            return (stats.firstWhere((s) => (s['stat']['name'] as String) == key)['base_stat'] as num).toInt();
          } catch (_) {
            return 0;
          }
        }

        return {
          'hp': readStat('hp'),
          'attack': readStat('attack'),
          'defense': readStat('defense'),
          'specialAttack': readStat('special-attack'),
          'specialDefense': readStat('special-defense'),
          'speed': readStat('speed'),
        };
      }

      output.add({
        'number': p.pokedexNumber,
        'name': p.name,
        'types': p.types,
        'stats': statsMap(),
      });
    } catch (e) {
      stderr.writeln('  -> ERROR: ${p.name} (#${p.pokedexNumber}) exception: $e');
    }
  }

  // Stable sort by number
  output.sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));

  final String jsonString = const JsonEncoder.withIndent('  ').convert(output);
  final file = File('assets/pokemon_full_list.json');
  await file.create(recursive: true);
  await file.writeAsString(jsonString);
  stdout.writeln('Written ${output.length} entries to assets/pokemon_full_list.json');
}


