// Alternativa usando CustomPainter para máximo control
import 'dart:async';

import 'package:flutter/material.dart';

class PokemonLiveIcon extends StatelessWidget {
  final double size;
  final bool showLeftHalf;
  final bool isLive;

  const PokemonLiveIcon({
    super.key,
    this.size = 32.0,
    this.showLeftHalf = true,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLive) {
      return _AnimatedPokemonLiveIcon(size: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<ImageInfo>(
        future: _getImageInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            );
          }

          return CustomPaint(
            painter: _PokemonIconPainter(
              imageInfo: snapshot.data!,
              showLeftHalf: showLeftHalf,
            ),
          );
        },
      ),
    );
  }

  Future<ImageInfo> _getImageInfo() async {
    final ImageStream stream = AssetImage(
      'assets/images/DITTO.png',
    ).resolve(ImageConfiguration.empty);
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    late ImageStreamListener listener;

    listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
      stream.removeListener(listener);
    });

    stream.addListener(listener);
    return completer.future;
  }
}

class _AnimatedPokemonLiveIcon extends StatefulWidget {
  final double size;

  const _AnimatedPokemonLiveIcon({required this.size});

  @override
  State<_AnimatedPokemonLiveIcon> createState() =>
      _AnimatedPokemonLiveIconState();
}

class _AnimatedPokemonLiveIconState extends State<_AnimatedPokemonLiveIcon> {
  bool _isUp = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _isUp = !_isUp;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, _isUp ? -3.0 : 0.0),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<ImageInfo>(
          future: _getImageInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              );
            }

            return CustomPaint(
              painter: _PokemonIconPainter(
                imageInfo: snapshot.data!,
                showLeftHalf: true, // Siempre mostrar la mitad izquierda
              ),
            );
          },
        ),
      ),
    );
  }

  Future<ImageInfo> _getImageInfo() async {
    final ImageStream stream = AssetImage(
      'assets/images/DITTO.png',
    ).resolve(ImageConfiguration.empty);
    final Completer<ImageInfo> completer = Completer<ImageInfo>();
    late ImageStreamListener listener;

    listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
      stream.removeListener(listener);
    });

    stream.addListener(listener);
    return completer.future;
  }
}

class _PokemonIconPainter extends CustomPainter {
  final ImageInfo imageInfo;
  final bool showLeftHalf;

  _PokemonIconPainter({required this.imageInfo, required this.showLeftHalf});

  @override
  void paint(Canvas canvas, Size size) {
    final image = imageInfo.image;
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // Definir el área de origen (mitad izquierda o derecha de la imagen)
    final srcRect =
        showLeftHalf
            ? Rect.fromLTWH(0, 0, imageWidth / 2, imageHeight)
            : Rect.fromLTWH(imageWidth / 2, 0, imageWidth / 2, imageHeight);

    // Área de destino (todo el widget)
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
