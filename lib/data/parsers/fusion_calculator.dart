import 'dart:io';
import 'dart:async';

import 'package:fusion_box/core/errors/exceptions.dart';
import 'package:fusion_box/data/parsers/sprite_parser.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/data/datasources/local/game_local_datasource.dart';
import 'package:fusion_box/core/services/sprite_download_service.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:fusion_box/core/services/logger_service.dart';
 

class FusionCalculator {
  final SpriteParser spriteParser;
  final GameLocalDataSource gameLocalDataSource;
  final SpriteDownloadService spriteDownloadService;
  final LoggerService logger;

  FusionCalculator({
    required this.spriteParser,
    required this.gameLocalDataSource,
    required this.spriteDownloadService,
    required this.logger,
  });

  Future<List<SpriteData>> getFusion(int headId, int bodyId) async {
    final sprites = <SpriteData>[];

    try {
      final gameBasePath = await _getGameBasePath();
      final basePath = _buildSpritePath(gameBasePath, headId);
      // Obtener variantes desde el disco cada vez (sin caché de variantes)
      List<String> variants = await _getAvailableVariants(basePath);

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
        } catch (e, s) {
          await logger.logError(
            Exception('parseSpritesheetToSprites failed for headId=$headId bodyId=$bodyId variant=$variant path=$spriteSheetPath error=$e'),
            s,
          );
          continue;
        }
      }

      // No actualizar caché de variantes

      return sprites;
    } catch (e, s) {
      await logger.logError(
        Exception('getFusion failed for headId=$headId bodyId=$bodyId error=$e'),
        s,
      );
      throw FusionCalculationException('Failed to calculate fusion: $headId-$bodyId: $e');
    }
  }

  Future<String> getFullSpritesheetPath(int headId) async {
    final gameBasePath = await _getGameBasePath();
    final basePath = _buildSpritePath(gameBasePath, headId);
    return _buildFullSpritePath(basePath, '');
  }

  Future<String> _getGameBasePath() async {
    final path = await gameLocalDataSource.getGamePath();
    if (path != null && path.isNotEmpty) {
      return path;
    }

    final Directory appDir = await getApplicationSupportDirectory();
    final Directory spritesDir = Directory(
      '${appDir.path}/spritesheets_custom',
    );
    if (!await spritesDir.exists()) {
      await spritesDir.create(recursive: true);
    }
    return spritesDir.path;
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
    final mainFile = File('$basePath/$headId.png');

    // Intentar descargar el sprite principal si no existe
    if (!await mainFile.exists()) {
      await _tryDownloadSpritesheet(headId, '$basePath/$headId.png', '');
    }

    if (await mainFile.exists()) {
      variants.add('');
    }

    final baseDir = Directory(basePath);
    if (await baseDir.exists()) {
      final entities = baseDir.listSync();
      final baseName = basePath.split('/').last;

      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.png')) {
          final fileName = entity.path.split('/').last.replaceAll('.png', '');
          if (fileName.startsWith(baseName)) {
            final suffix = fileName.substring(baseName.length);
            if (suffix.isEmpty) {
              // base already added above
              continue;
            }
            variants.add(suffix);
          }
        }
      }
    }

    // Sort with base first, then lexicographically to keep deterministic order
    variants.sort((a, b) {
      if (a.isEmpty && b.isNotEmpty) return -1;
      if (b.isEmpty && a.isNotEmpty) return 1;
      return a.compareTo(b);
    });

    return variants;
  }

  /// Public method to list available variant suffixes for a given headId by scanning disk.
  Future<List<String>> listAvailableVariants(int headId) async {
    final gameBasePath = await _getGameBasePath();
    final basePath = _buildSpritePath(gameBasePath, headId);
    return _getAvailableVariants(basePath);
  }

  List<SpriteData> _filterSpritesByBodyId(
    List<SpriteData> sprites,
    int bodyId,
  ) {
    if (bodyId < 0 || bodyId >= sprites.length) {
      return [];
    }

    return [sprites[bodyId]];
  }

  /// Obtiene un sprite específico para una fusión
  Future<SpriteData?> getSpecificFusionSprite(
    int headId,
    int bodyId, {
    String variant = '',
  }) async {
    String? debugSpritesheetPath;
    try {
      final gameBasePath = await _getGameBasePath();
      final basePath = _buildSpritePath(gameBasePath, headId);
      final spritesheetPath = _buildFullSpritePath(basePath, variant);
      debugSpritesheetPath = spritesheetPath;

      // Intentar descargar el spritesheet si no existe
      await _tryDownloadSpritesheet(headId, spritesheetPath, variant);

      final sprite = await spriteParser.extractSpriteByIndex(
        spritesheetPath,
        bodyId,
        variant,
      );

      return sprite;
    } catch (e, s) {
      await logger.logError(
        Exception('getSpecificFusionSprite failed for headId=$headId bodyId=$bodyId variant=$variant path=${debugSpritesheetPath ?? "<unknown>"} error=$e'),
        s,
      );
      return null;
    }
  }

  Future<SpriteData?> getSpecificFusionSpriteFromSpritesheet(
    String spritesheetPath,
    img.Image spritesheet,
    int headId,
    int bodyId, {
    String variant = '',
  }) async {
    try {
      final sprite = await spriteParser.extractSpriteByIndexFromSpritesheet(
        spritesheetPath,
        spritesheet,
        bodyId,
        variant,
      );

      return sprite;
    } catch (e, s) {
      await logger.logError(
        Exception('getSpecificFusionSpriteFromSpritesheet failed for headId=$headId bodyId=$bodyId variant=$variant path=${spritesheetPath} error=$e'),
        s,
      );
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
    } catch (e, s) {
      await logger.logError(
        Exception('getAutogenSprite failed for headId=$headId bodyId=$bodyId error=$e'),
        s,
      );
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
          // 1) Desbloquear rápido: asegurar la base solamente
          await spriteDownloadService.downloadSpriteIfNeeded(
            headId: headId,
            localSpritePath: spritesheetPath,
            variant: '',
            type: SpriteType.custom,
          );
          // 2) Prefetch completo en background (no bloquear)
          unawaited(
            spriteDownloadService.downloadAllVariants(
              headId: headId,
              baseLocalPath: spritesheetPath,
              type: SpriteType.custom,
            ),
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
    } catch (e, s) {
      await logger.logError(
        Exception('_tryDownloadSpritesheet failed for headId=$headId variant=$variant path=$spritesheetPath error=$e'),
        s,
      );
    }
  }
}
