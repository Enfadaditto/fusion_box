// Run with:
//   dart run tool/generate_pokemon_stats_json.dart
// This script iterates the embedded local Pokémon list and queries PokeAPI
// to produce assets/pokemon_full_list.json with number, name, types, stats and abilities.

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
    stdout.writeln('[$processed/${pokemonList.length}] Fetching $normalized...');
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

      // Extract abilities (unique, Title Case for readability)
      List<String> toTitleCase(List<String> items) {
        String titleOf(String s) {
          if (s.isEmpty) return s;
          final parts = s.replaceAll('-', ' ').split(' ');
          return parts
              .where((e) => e.trim().isNotEmpty)
              .map((part) => part[0].toUpperCase() + part.substring(1))
              .join(' ');
        }
        final seen = <String>{};
        final List<String> out = [];
        for (final raw in items) {
          final titled = titleOf(raw.trim());
          if (seen.add(titled)) out.add(titled);
        }
        return out;
      }

      final List<dynamic> rawAbilities = (data['abilities'] as List<dynamic>? ?? []);
      final List<String> abilityNames = rawAbilities
          .map((a) => (a['ability']?['name'] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();

      // Extract moves and level learned (from PokeAPI per version group)
      final List<dynamic> rawMoves = (data['moves'] as List<dynamic>? ?? []);
      final Set<String> moveNames = {};
      final List<Map<String, dynamic>> movesByLevel = [];
      String titleOf(String s) {
        if (s.isEmpty) return s;
        final parts = s.replaceAll('-', ' ').split(' ');
        return parts
            .where((e) => e.trim().isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
      }

      for (final dynamic m in rawMoves) {
        if (m is! Map<String, dynamic>) continue;
        final String rawName = (m['move']?['name'] ?? '').toString();
        if (rawName.isEmpty) continue;
        final String moveName = titleOf(rawName);
        moveNames.add(moveName);
        int? minLevel;
        final List<dynamic> vgd = (m['version_group_details'] as List<dynamic>? ?? []);
        for (final dynamic d in vgd) {
          if (d is! Map<String, dynamic>) continue;
          final String method = (d['move_learn_method']?['name'] ?? '').toString();
          if (method != 'level-up') continue;
          final int lvl = ((d['level_learned_at'] ?? 0) as num).toInt();
          if (lvl <= 0) continue;
          if (minLevel == null || lvl < minLevel) minLevel = lvl;
        }
        movesByLevel.add({'name': moveName, 'level': minLevel});
      }

      output.add({
        'number': p.pokedexNumber,
        'name': p.name,
        'types': p.types,
        'stats': statsMap(),
        'abilities': toTitleCase(abilityNames),
        // keep both for compatibility and enriched UI
        'moves': moveNames.toList()..sort(),
        'movesByLevel': movesByLevel,
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


