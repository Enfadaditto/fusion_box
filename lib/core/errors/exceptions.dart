abstract class SpriteException implements Exception {
  final String message;
  const SpriteException(this.message);

  @override
  String toString() => 'SpriteException: $message';
}

class SpriteNotFoundException extends SpriteException {
  SpriteNotFoundException(super.message);
}

class SpriteParseException extends SpriteException {
  SpriteParseException(super.message);
}

class FusionCalculationException extends SpriteException {
  FusionCalculationException(super.message);
}

class GamePathNotSetException extends SpriteException {
  GamePathNotSetException(super.message);
}

class DataSourceException extends SpriteException {
  DataSourceException(super.message);
}
