import 'dart:typed_data';

class SpriteData {
  final String spritePath;
  final Uint8List? spriteBytes;
  final int x;
  final int y;
  final int width;
  final int height;
  final String variant;
  final bool isAutogenerated;

  const SpriteData({
    required this.spritePath,
    this.spriteBytes,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.variant = '',
    this.isAutogenerated = false,
  });
}
