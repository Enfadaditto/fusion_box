import 'dart:convert';

import 'package:http/http.dart' as http;

class SmallIconsService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2/pokemon';
  static const String _pokemonIconUrl =
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/versions/generation-vii/icons';
  // static const String _pokemonHomeIconUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/home';

  // Singleton
  static final SmallIconsService _instance = SmallIconsService._internal();
  factory SmallIconsService() => _instance;
  SmallIconsService._internal();

  // Cache for Pokemon IDs to avoid repeated API calls
  final Map<String, int> _pokemonIdCache = {};
  final Map<String, String> _pokemonIconUrlCache = {};

  /// Normalizes Pokemon names to match PokeAPI format
  String _normalizePokemonName(String pokemonName) {
    String normalized = pokemonName.toLowerCase().trim();

    // Handle special cases
    switch (normalized) {
      case 'nidoran macho':
      case 'nidoran♂':
        return 'nidoran-m';
      case 'nidoran hembra':
      case 'nidoran♀':
        return 'nidoran-f';
      case 'mr. mime':
      case 'mr mime':
        return 'mr-mime';
      case 'mime jr.':
      case 'mime jr':
        return 'mime-jr';
      case 'porygon-z':
      case 'porygon z':
        return 'porygon-z';
      case 'ho-oh':
      case 'ho oh':
        return 'ho-oh';
      case 'jangmo-o':
      case 'jangmo o':
        return 'jangmo-o';
      case 'hakamo-o':
      case 'hakamo o':
        return 'hakamo-o';
      case 'kommo-o':
      case 'kommo o':
        return 'kommo-o';
      case 'deoxys':
        return 'deoxys-normal';
      case 'farfetch\'d':
      case 'farfetchd':
        return 'farfetchd';
      //TODO: Fix giratina
      case 'giratina':
        return 'giratina-origin';
      //TODO: Fix meloetta
      case 'meloetta-aria':
      case 'meloetta aria':
        return 'meloetta-aria';
      case 'meloetta-pirouette':
      case 'meloetta pirouette':
        return 'meloetta-pirouette';
      //TODO: Fix aegislash
      case 'aegislash':
        return 'aegislash-blade';
      case 'pumpkaboo':
        return 'pumpkaboo-average';
      case 'gourgeist':
        return 'gourgeist-average';
      //TODO: Fix the oricorios - only baile is correct
      case 'oricorio-baile':
      case 'oricorio baile':
        return 'oricorio-baile';
      case 'oricorio-pom-pom':
      case 'oricorio pom pom':
        return 'oricorio-pom-pom';
      case 'oricorio-pa-u':
      case 'oricorio pau':
        return 'oricorio-pau';
      case 'oricorio-sensu':
      case 'oricorio sensu':
        return 'oricorio-sensu';
      case 'lycanroc-midday':
      case 'lycanroc midday':
        return 'lycanroc-midday';
      //TODO: Fix the lycanroc midnight
      case 'lycanroc-midnight':
      case 'lycanroc midnight':
        return 'lycanroc-midnight';
      //TODO: Fix the miniors
      case 'minior-core':
        return 'minior-violet-meteor';
      case 'minior':
        return 'minior-violet';
      case 'mimikyu':
        return 'mimikyu-disguised';
      // TODO: Add ultra necrozma, fix shandyghast,
      default:
        // Replace spaces and special characters with hyphens
        return normalized
            .replaceAll(
              RegExp(r'[^\w\s-]'),
              '',
            ) // Remove special characters except hyphens
            .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
            .replaceAll(
              RegExp(r'-+'),
              '-',
            ) // Replace multiple hyphens with single
            .replaceAll(
              RegExp(r'^-|-$'),
              '',
            ); // Remove leading/trailing hyphens
    }
  }

  Future<String> getPokemonIcon(String pokemonName) async {
    final normalizedName = _normalizePokemonName(pokemonName);

    // Check if we already have the URL cached
    if (_pokemonIconUrlCache.containsKey(normalizedName)) {
      return _pokemonIconUrlCache[normalizedName]!;
    }

    try {
      // Check if we already have the ID cached
      int? pokemonId = _pokemonIdCache[normalizedName];

      if (pokemonId == null) {
        final response = await http.get(Uri.parse('$_baseUrl/$normalizedName'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          pokemonId = data['id'] as int;
          _pokemonIdCache[normalizedName] = pokemonId;
        } else {
          throw Exception('Pokemon not found: $pokemonName');
        }
      }

      final iconUrl = '$_pokemonIconUrl/$pokemonId.png';
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
