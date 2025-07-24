import 'dart:io';

import 'package:fusion_box/core/errors/exceptions.dart';
import 'package:fusion_box/data/parsers/sprite_parser.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/data/datasources/local/game_local_datasource.dart';
import 'package:fusion_box/core/services/sprite_download_service.dart';

class FusionCalculator {
  final SpriteParser spriteParser;
  final GameLocalDataSource gameLocalDataSource;
  final SpriteDownloadService spriteDownloadService;

  FusionCalculator({
    required this.spriteParser,
    required this.gameLocalDataSource,
    required this.spriteDownloadService,
  });

  Future<List<SpriteData>> getFusion(int headId, int bodyId) async {
    final sprites = <SpriteData>[];

    try {
      final gameBasePath = await _getGameBasePath();
      final basePath = _buildSpritePath(gameBasePath, headId);
      final variants = await _getAvailableVariants(basePath);

      for (final variant in variants) {
        final spriteSheetPath = _buildFullSpritePath(basePath, variant);

        // Intentar descargar el spritesheet si no existe
        await _tryDownloadSpritesheet(headId, spriteSheetPath, variant);

        try {
          final variantSprites = await spriteParser.parseSpritesheetToSprites(
            spriteSheetPath,
            variant,
          );

          final relevantSprites = _filterSpritesByBodyId(
            variantSprites,
            bodyId,
          );

          sprites.addAll(relevantSprites);
        } catch (e) {
          continue;
        }
      }

      return sprites;
    } catch (e) {
      throw FusionCalculationException(
        'Failed to calculate fusion: $headId-$bodyId: $e',
      );
    }
  }

  Future<String> _getGameBasePath() async {
    final path = await gameLocalDataSource.getGamePath();
    if (path == null || path.isEmpty) {
      throw GamePathNotSetException('Game path not configured');
    }
    return path;
  }

  String _buildSpritePath(String gameBasePath, int headId) {
    return '$gameBasePath/Graphics/CustomBattlers/spritesheets/spritesheets_custom/$headId';
  }

  String _buildFullSpritePath(String basePath, String variant) {
    final headId = basePath.split('/').last;
    final suffix = variant.isEmpty ? '' : variant;
    return '$basePath/$headId$suffix.png';
  }

  Future<List<String>> _getAvailableVariants(String basePath) async {
    final variants = <String>[];
    final headId = int.tryParse(basePath.split('/').last) ?? 0;
    final mainFile = File('$basePath.png');

    // Intentar descargar el sprite principal si no existe
    if (!await mainFile.exists()) {
      await _tryDownloadSpritesheet(headId, '$basePath.png', '');
    }

    if (await mainFile.exists()) {
      variants.add('');
    }

    final baseDir = Directory(basePath).parent;
    if (await baseDir.exists()) {
      final entities = baseDir.listSync();
      final baseName = basePath.split('/').last;

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.png')) {
          final fileName = entity.path.split('/').last.replaceAll('.png', '');
          if (fileName.startsWith(baseName) && fileName != baseName) {
            final variant = fileName.substring(baseName.length);
            variants.add(variant);
          }
        }
      }
    }

    return variants;
  }

  List<SpriteData> _filterSpritesByBodyId(
    List<SpriteData> sprites,
    int bodyId,
  ) {
    // El primer espacio del grid está vacío, así que el pokémon 1 está en la posición 1, etc.
    final targetIndex =
        bodyId; // Usar directamente bodyId ya que la posición 0 está vacía

    if (targetIndex < 0 || targetIndex >= sprites.length) {
      return [];
    }

    return [sprites[targetIndex]];
  }

  /// Obtiene un sprite específico para una fusión
  Future<SpriteData?> getSpecificFusionSprite(
    int headId,
    int bodyId, {
    String variant = '',
    int spriteIndex = 0,
  }) async {
    try {
      final gameBasePath = await _getGameBasePath();
      final basePath = _buildSpritePath(gameBasePath, headId);
      final spritesheetPath = _buildFullSpritePath(basePath, variant);

      // Intentar descargar el spritesheet si no existe
      await _tryDownloadSpritesheet(headId, spritesheetPath, variant);

      // El primer espacio del grid está vacío, usar directamente bodyId
      final targetIndex = bodyId;

      final sprite = await spriteParser.extractSpriteByIndex(
        spritesheetPath,
        targetIndex,
        variant,
      );

      return sprite;
    } catch (e) {
      return null;
    }
  }

  /// Obtiene un sprite autogenerado como fallback
  Future<SpriteData?> getAutogenSprite(int headId, int bodyId) async {
    try {
      final gameBasePath = await _getGameBasePath();

      // Para fusiones diagonales (mismo pokémon), no aplicar filtro gris
      final isDiagonalFusion = headId == bodyId;

      // Primero intentar con headId
      String autogenPath =
          '$gameBasePath/Graphics/Battlers/spritesheets_autogen/$headId.png';

      if (await File(autogenPath).exists()) {
        final sprite = await spriteParser.extractSpriteByIndex(
          autogenPath,
          bodyId, // Usar bodyId como índice en el sprite autogenerado
          '',
          isAutogenerated:
              true, // SIEMPRE marcar como autogenerado para cálculo correcto de posición
        );

        if (sprite != null) {
          // Para fusiones diagonales, crear una copia sin el filtro autogenerado
          if (isDiagonalFusion) {
            return SpriteData(
              spritePath: sprite.spritePath,
              spriteBytes: sprite.spriteBytes,
              x: sprite.x,
              y: sprite.y,
              width: sprite.width,
              height: sprite.height,
              variant: sprite.variant,
              isAutogenerated:
                  false, // No aplicar filtro gris para fusiones diagonales
            );
          }
          return sprite;
        }
      }

      // Si no funciona con headId, intentar con un cálculo diferente
      // Algunos juegos usan fusionId o otros cálculos
      final fusionId = headId * 1000 + bodyId; // Ejemplo de cálculo
      autogenPath =
          '$gameBasePath/Graphics/Battlers/spritesheets_autogen/$fusionId.png';

      if (await File(autogenPath).exists()) {
        final sprite = await spriteParser.extractSpriteByIndex(
          autogenPath,
          0, // Si es un archivo específico para la fusión, usar índice 0
          '',
          isAutogenerated:
              true, // SIEMPRE marcar como autogenerado para cálculo correcto de posición
        );

        if (sprite != null) {
          // Para fusiones diagonales, crear una copia sin el filtro autogenerado
          if (isDiagonalFusion) {
            return SpriteData(
              spritePath: sprite.spritePath,
              spriteBytes: sprite.spriteBytes,
              x: sprite.x,
              y: sprite.y,
              width: sprite.width,
              height: sprite.height,
              variant: sprite.variant,
              isAutogenerated:
                  false, // No aplicar filtro gris para fusiones diagonales
            );
          }
          return sprite;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Intenta descargar un spritesheet si no existe localmente
  Future<void> _tryDownloadSpritesheet(
    int headId,
    String spritesheetPath,
    String variant,
  ) async {
    try {
      // Solo intentar descargar si el archivo no existe
      final file = File(spritesheetPath);
      if (!await file.exists()) {
        if (variant.isEmpty) {
          // Para el sprite principal, descargar todas las variantes disponibles
          await spriteDownloadService.downloadAllVariants(
            headId: headId,
            baseLocalPath: spritesheetPath,
            type: SpriteType.custom,
          );
        } else {
          // Para variantes específicas, descargar solo esa variante
          await spriteDownloadService.downloadSpriteIfNeeded(
            headId: headId,
            localSpritePath: spritesheetPath,
            variant: variant,
            type: SpriteType.custom,
          );
        }
      }
    } catch (e) {
      // Fallar silenciosamente en la descarga - no afecta el funcionamiento principal
    }
  }
}
