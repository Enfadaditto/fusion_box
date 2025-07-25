import 'package:fusion_box/core/errors/exceptions.dart';
import 'package:fusion_box/data/parsers/fusion_calculator.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';
import 'package:image/image.dart' as img;

class SpriteRepositoryImpl implements SpriteRepository {
  final FusionCalculator fusionCalculator;

  SpriteRepositoryImpl({required this.fusionCalculator});

  @override
  Future<String?> getSpritesheetPath(int headId) async {
    try {
      return fusionCalculator.getFullSpritesheetPath(headId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<SpriteData>> getFusionSprites(int headId, int bodyId) async {
    try {
      return await fusionCalculator.getFusion(headId, bodyId);
    } catch (e) {
      throw SpriteNotFoundException('Failed to get fusion sprites: $e');
    }
  }

  @override
  Future<List<String>> getAvailableVariants(int headId, int bodyId) async {
    try {
      final sprites = await fusionCalculator.getFusion(headId, bodyId);
      return sprites.map((s) => s.variant).toSet().toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<SpriteData?> getSpecificSprite(
    int headId,
    int bodyId, {
    String variant = '',
  }) async {
    return await fusionCalculator.getSpecificFusionSprite(
      headId,
      bodyId,
      variant: variant,
    );
  }

  @override
  Future<SpriteData?> getSpecificSpriteFromSpritesheet(
    String spritesheetPath,
    img.Image spritesheet,
    int headId,
    int bodyId, {
    String variant = '',
  }) async {
    return await fusionCalculator.getSpecificFusionSpriteFromSpritesheet(
      spritesheetPath,
      spritesheet,
      headId,
      bodyId,
      variant: variant,
    );
  }

  @override
  Future<List<SpriteData>> getAllSpriteVariants(int headId, int bodyId) async {
    final sprites = <SpriteData>[];
    final variants = await getAvailableVariants(headId, bodyId);

    for (String variant in variants) {
      SpriteData? sprite = await getSpecificSprite(
        headId,
        bodyId,
        variant: variant,
      );
      if (sprite != null) {
        sprites.add(sprite);
      }
    }

    return sprites;
  }

  @override
  Future<SpriteData?> getAutogenSprite(int headId, int bodyId) async {
    return await fusionCalculator.getAutogenSprite(headId, bodyId);
  }
}
