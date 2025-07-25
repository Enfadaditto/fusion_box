class AppConfig {
  static const String appName = 'Pokemon Fusion Box';
  static const String appVersion = '1.0.0';

  // Game related configurations
  static const String defaultGamePathMessage =
      'Please select your Pokemon Infinite Fusion game directory';
  static const String spritesSubPath =
      'Graphics/CustomBattlers/spritesheets/spritesheets_custom';

  // UI configurations
  static const int maxSelectedPokemon = 50;
  static const int minPokemonForFusion = 2;

  // Error messages
  static const String gamePathNotFoundError =
      'Game directory not found or invalid';
  static const String spritesNotFoundError =
      'Sprites directory not found in game folder';
  static const String loadPokemonError = 'Failed to load Pokemon data';
}
