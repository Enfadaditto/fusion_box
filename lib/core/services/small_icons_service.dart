import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  final Map<String, String> _pokemonIconFilePathCache = {};



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

  /// Returns a File for the Pokemon's small icon, stored persistently in app storage.
  /// If the file is already cached on disk, it is returned immediately without any network call.
  /// Otherwise the icon is downloaded once and stored for future use.
  Future<File?> getPokemonIconFile(String pokemonName) async {
    final normalizedName = PokemonNameNormalizer.normalizePokemonName(pokemonName);

    // Fast path: memory cache of file path
    final memoPath = _pokemonIconFilePathCache[normalizedName];
    if (memoPath != null) {
      final memoFile = File(memoPath);
      if (await memoFile.exists() && (await memoFile.length()) > 0) {
        return memoFile;
      }
    }

    // Ensure cache directory exists
    final cacheDir = await _getIconsCacheDir();
    final filePath = p.join(cacheDir.path, '$normalizedName.png');
    final file = File(filePath);

    // If present on disk, return it
    if (await file.exists() && (await file.length()) > 0) {
      _pokemonIconFilePathCache[normalizedName] = filePath;
      return file;
    }

    try {
      final iconUrl = await getPokemonIcon(pokemonName);
      if (iconUrl.isEmpty) {
        return null;
      }
      final response = await http.get(Uri.parse(
        kIsWeb && iconUrl.startsWith('https://raw.githubusercontent.com')
            ? 'https://images.weserv.nl/?url=' + iconUrl.replaceFirst('https://', '')
            : iconUrl,
      ));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes, flush: true);
        _pokemonIconFilePathCache[normalizedName] = filePath;
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Directory> _getIconsCacheDir() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'small_icons_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Clear the cache (useful for testing or memory management)
  void clearCache() {
    _pokemonIdCache.clear();
    _pokemonIconUrlCache.clear();
    _pokemonIconFilePathCache.clear();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'pokemonIds': _pokemonIdCache.length,
      'iconUrls': _pokemonIconUrlCache.length,
    };
  }
}
