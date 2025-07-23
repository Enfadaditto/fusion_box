import 'package:fusion_box/core/errors/exceptions.dart';
import 'package:fusion_box/data/parsers/fusion_calculator.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';

class SpriteRepositoryImpl implements SpriteRepository {
  final FusionCalculator fusionCalculator;

  SpriteRepositoryImpl({required this.fusionCalculator});

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
  Future<SpriteData?> getAutogenSprite(int headId, int bodyId) async {
    return await fusionCalculator.getAutogenSprite(headId, bodyId);
  }
}
