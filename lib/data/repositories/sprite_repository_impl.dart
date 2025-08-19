import 'package:fusion_box/core/errors/exceptions.dart';
import 'package:fusion_box/data/parsers/fusion_calculator.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';
import 'package:image/image.dart' as img;
import 'package:fusion_box/core/services/logger_service.dart';
 

class SpriteRepositoryImpl implements SpriteRepository {
  final FusionCalculator fusionCalculator;
  final LoggerService logger;
  
  // Simple in-memory cache to avoid re-cropping sprites between grid regenerations
  final Map<String, SpriteData> _spriteCache = {};
  // Ephemeral cache of available variants per headId for the current page session
  final Map<int, List<String>> _headIdToVariants = {};

  SpriteRepositoryImpl({required this.fusionCalculator, required this.logger});

  String _cacheKey(int headId, int bodyId, String variant) {
    return '$headId-$bodyId-$variant';
  }

  @override
  Future<String?> getSpritesheetPath(int headId) async {
    try {
      return fusionCalculator.getFullSpritesheetPath(headId);
    } catch (e, s) {
      await logger.logError(
        Exception('getSpritesheetPath failed for headId=$headId error=$e'),
        s,
      );
      return null;
    }
  }

  @override
  Future<List<SpriteData>> getFusionSprites(int headId, int bodyId) async {
    try {
      return await fusionCalculator.getFusion(headId, bodyId);
    } catch (e, s) {
      await logger.logError(
        Exception('getFusionSprites failed for headId=$headId bodyId=$bodyId error=$e'),
        s,
      );
      throw SpriteNotFoundException('Failed to get fusion sprites: $e');
    }
  }

  @override
  Future<List<String>> getAvailableVariants(int headId, int bodyId) async {
    try {
      // Ephemeral memoization during this Fusion Grid session
      final memo = _headIdToVariants[headId];
      if (memo != null && memo.isNotEmpty) {
        return memo;
      }
      // Resolve variants from disk/parse (no persistent cache)
      final diskVariants = await fusionCalculator.listAvailableVariants(headId);
      if (diskVariants.isNotEmpty) {
        _headIdToVariants[headId] = diskVariants;
        return _headIdToVariants[headId]!;
      }

      // If not on disk, parse fully
      final sprites = await fusionCalculator.getFusion(headId, bodyId);
      final variants = sprites.map((s) => s.variant).toSet().toList();
      _headIdToVariants[headId] = variants;
      return _headIdToVariants[headId]!;
    } catch (e, s) {
      await logger.logError(
        Exception('getAvailableVariants failed for headId=$headId bodyId=$bodyId error=$e'),
        s,
      );
      return [];
    }
  }

  @override
  Future<SpriteData?> getSpecificSprite(
    int headId,
    int bodyId, {
    String variant = '',
  }) async {
    final key = _cacheKey(headId, bodyId, variant);
    final cached = _spriteCache[key];
    if (cached != null) {
      return cached;
    }

    final sprite = await fusionCalculator.getSpecificFusionSprite(
      headId,
      bodyId,
      variant: variant,
    );

    if (sprite != null) {
      _spriteCache[key] = sprite;
    }

    return sprite;
  }

  @override
  Future<SpriteData?> getSpecificSpriteFromSpritesheet(
    String spritesheetPath,
    img.Image spritesheet,
    int headId,
    int bodyId, {
    String variant = '',
  }) async {
    final key = _cacheKey(headId, bodyId, variant);
    final cached = _spriteCache[key];
    if (cached != null) {
      return cached;
    }

    final sprite = await fusionCalculator.getSpecificFusionSpriteFromSpritesheet(
      spritesheetPath,
      spritesheet,
      headId,
      bodyId,
      variant: variant,
    );

    if (sprite != null) {
      _spriteCache[key] = sprite;
    }

    return sprite;
  }

  @override
  Future<List<SpriteData>> getAllSpriteVariants(int headId, int bodyId) async {
    final sprites = <SpriteData>[];
    final variants = await getAvailableVariants(headId, bodyId);

    final seenVariants = <String>{};
    for (final variant in variants) {
      if (seenVariants.contains(variant)) {
        continue;
      }
      final sprite = await getSpecificSprite(
        headId,
        bodyId,
        variant: variant,
      );
      if (sprite != null) {
        sprites.add(sprite);
        seenVariants.add(variant);
      }
    }

    // Do not update any persistent variant cache
    return sprites;
  }

  @override
  Future<SpriteData?> getAutogenSprite(int headId, int bodyId) async {
    // For autogen, use a special variant key to avoid clashes
    const String autogenVariant = '__autogen__';
    final key = _cacheKey(headId, bodyId, autogenVariant);
    final cached = _spriteCache[key];
    if (cached != null) {
      return cached;
    }

    final sprite = await fusionCalculator.getAutogenSprite(headId, bodyId);

    if (sprite != null) {
      _spriteCache[key] = sprite;
    }

    return sprite;
  }

  @override
  void clearEphemeralVariantCache() {
    _headIdToVariants.clear();
  }
}
