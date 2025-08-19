/// Utility class for normalizing Pokemon names to match PokeAPI format
class PokemonNameNormalizer {
  /// Normalizes Pokemon names to match PokeAPI format
  static String normalizePokemonName(String pokemonName) {
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
      case 'giratina':
        return 'giratina-origin';
      case 'meloetta-aria':
      case 'meloetta aria':
        return 'meloetta-aria';
      case 'meloetta-pirouette':
      case 'meloetta pirouette':
        return 'meloetta-pirouette';
      case 'aegislash':
        return 'aegislash-blade';
      case 'pumpkaboo':
        return 'pumpkaboo-average';
      case 'gourgeist':
        return 'gourgeist-average';
      case 'oricorio-baile':
      case 'oricorio baile':
        return 'oricorio-baile';
      case 'oricorio-pom-pom':
      case 'oricorio pom-pom':
      case 'oricorio pom pom':
        return 'oricorio-pom-pom';
      case 'oricorio-pa-u':
      case 'oricorio pa-u':
      case 'oricorio pa u':
        return 'oricorio-pau';
      case 'oricorio-sensu':
      case 'oricorio sensu':
        return 'oricorio-sensu';
      case 'lycanroc-midday':
      case 'lycanroc midday':
        return 'lycanroc-midday';
      case 'lycanroc-midnight':
      case 'lycanroc midnight':
        return 'lycanroc-midnight';
      case 'minior-core':
      case 'minior core':
        return 'minior-violet-meteor';
      case 'minior':
        return 'minior-violet';
      case 'mimikyu':
        return 'mimikyu-disguised';
      case 'ultra-necrozma':
      case 'ultra necrozma':
        return 'necrozma-ultra';
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
} 