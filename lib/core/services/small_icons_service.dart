import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/pokemon_name_normalizer.dart';

class SmallIconsService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';
  // static const String _pokemonIconUrl =
  //     'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-vii/icons';
  // static const String _pokemonHomeIconUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home';

  // Singleton
  static final SmallIconsService _instance = SmallIconsService._internal();
  factory SmallIconsService() => _instance;
  SmallIconsService._internal();

  // Cache for Pokemon IDs to avoid repeated API calls
  final Map<String, int> _pokemonIdCache = {};
  final Map<String, String> _pokemonIconUrlCache = {};



  Future<String> getPokemonIcon(String pokemonName) async {
    final normalizedName = PokemonNameNormalizer.normalizePokemonName(pokemonName);

    // Check if we already have the URL cached
    if (_pokemonIconUrlCache.containsKey(normalizedName)) {
      return _pokemonIconUrlCache[normalizedName]!;
    }

    try {
      // Check if we already have the ID cached
      int? pokemonId = _pokemonIdCache[normalizedName];
      String iconUrl = '';

      if (pokemonId == null) {
        final response = await http.get(Uri.parse('$_baseUrl/$normalizedName'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          pokemonId = data['id'] as int;
          _pokemonIdCache[normalizedName] = pokemonId;
          iconUrl =
              data['sprites']['versions']['generation-vii']['icons']['front_default'];
        } else {
          throw Exception('Pokemon not found: $pokemonName');
        }
      } else {
        // If we have the ID cached, we need to construct the URL
        iconUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-vii/icons/$pokemonId.png';
      }

      _pokemonIconUrlCache[normalizedName] = iconUrl;
      return iconUrl;
    } catch (e) {
      throw Exception('Error fetching pokemon: $e');
    }
  }

  /// Clear the cache (useful for testing or memory management)
  void clearCache() {
    _pokemonIdCache.clear();
    _pokemonIconUrlCache.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'pokemonIds': _pokemonIdCache.length,
      'iconUrls': _pokemonIconUrlCache.length,
    };
  }
}
