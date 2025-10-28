import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fusion_box/config/app_config.dart';
import 'package:fusion_box/core/services/variants_cache_service.dart';
import 'package:fusion_box/core/services/logger_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum SpriteType { custom, base }

class SpriteDownloadService {
  static const String _userAgent = 'FusionBox/${AppConfig.appVersion}';

  final SharedPreferences _prefs;
  final LoggerService _logger;

  SpriteDownloadService({required SharedPreferences preferences, required LoggerService logger})
    : _prefs = preferences,
      _logger = logger;

  Future<bool> downloadSpriteIfNeeded({
    required int headId,
    required String localSpritePath,
    String variant = '',
    SpriteType type = SpriteType.custom,
  }) async {
    if (kIsWeb) {
      // On web we do not write to local filesystem
      return false;
    }
    final file = File(localSpritePath);
    if (await file.exists()) {
      return true;
    }

    try {
      final url = _buildDownloadUrl(headId, variant, type);

      final success = await _downloadSprite(url, localSpritePath);

      return success;
    } catch (e, s) {
      await _logger.logError(
        Exception('downloadSpriteIfNeeded failed: headId=$headId variant="$variant" type=$type path=$localSpritePath error=$e'),
        s,
      );
      return false;
    }
  }

  Future<List<String>> downloadAllVariants({
    required int headId,
    required String baseLocalPath,
    SpriteType type = SpriteType.custom,
  }) async {
    if (kIsWeb) {
      // No-op on web
      return <String>[];
    }
    final downloadedVariants = <String>[];

    final mainPath = baseLocalPath.replaceAll('.png', '.png');
    final mainSuccess = await downloadSpriteIfNeeded(
      headId: headId,
      localSpritePath: mainPath,
      variant: '',
      type: type,
    );

    if (mainSuccess) {
      downloadedVariants.add('');
    }

    final letters = List<String>.generate(26, (i) => String.fromCharCode('a'.codeUnitAt(0) + i));
    final twoLetters = <String>[];
    for (int i = 0; i < 26; i++) {
      for (int j = 0; j < 26; j++) {
        twoLetters.add('${String.fromCharCode('a'.codeUnitAt(0) + i)}${String.fromCharCode('a'.codeUnitAt(0) + j)}');
      }
    }

    for (final variant in letters) {
      final variantPath = baseLocalPath.replaceAll('.png', '$variant.png');
      final file = File(variantPath);

      if (await file.exists()) {
        downloadedVariants.add(variant);
        continue;
      }

      try {
        final url = _buildDownloadUrl(headId, variant, type);
        final success = await _downloadSprite(
          url,
          variantPath,
          checkStatus404: true,
        );

        if (success) {
          downloadedVariants.add(variant);
        }
      } catch (e, s) {
        await _logger.logError(
          Exception('downloadAllVariants(letter) failed: headId=$headId variant="$variant" path=$variantPath error=$e'),
          s,
        );
      }
    }

    int misses = 0;
    const int maxConsecutiveMisses = 40;
    for (final variant in twoLetters) {
      final variantPath = baseLocalPath.replaceAll('.png', '$variant.png');
      final file = File(variantPath);

      if (await file.exists()) {
        downloadedVariants.add(variant);
        misses = 0;
        continue;
      }

      try {
        final url = _buildDownloadUrl(headId, variant, type);
        final success = await _downloadSprite(
          url,
          variantPath,
          checkStatus404: true,
        );

        if (success) {
          downloadedVariants.add(variant);
          misses = 0;
        }
      } catch (e, s) {
        await _logger.logError(
          Exception('downloadAllVariants(twoLetters) failed: headId=$headId variant="$variant" path=$variantPath error=$e'),
          s,
        );
      }

      if (!downloadedVariants.contains(variant)) {
        misses++;
        if (misses >= maxConsecutiveMisses) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }

    if (downloadedVariants.isNotEmpty) {
      final existing = await VariantsCacheService.getCachedVariants(headId) ?? const <String>[];
      final combined = <String>{...existing, ...downloadedVariants}.toList();
      await VariantsCacheService.setCachedVariants(headId, combined);
    }

    return downloadedVariants;
  }

  String _buildDownloadUrl(int headId, String variant, SpriteType type) {
    switch (type) {
      case SpriteType.custom:
        return '${AppConfig.customSpritesBaseUrl}$headId/$headId$variant.png';
      case SpriteType.base:
        return '${AppConfig.baseSpritesBaseUrl}$headId.png';
    }
  }

  Future<bool> _downloadSprite(
    String url,
    String destinationPath, {
    bool checkStatus404 = false,
  }) async {
    if (kIsWeb) {
      // On web we do not persist to disk
      return false;
    }
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': _userAgent,
              'Accept': 'image/png,image/*,*/*',
            },
          )
          .timeout(const Duration(seconds: AppConfig.downloadTimeoutSeconds));

      if (response.statusCode == 200) {
        if (!_isValidImageResponse(response)) {
          return false;
        }

        final file = File(destinationPath);
        await file.parent.create(recursive: true);

        await file.writeAsBytes(response.bodyBytes);
        return true;
      }

      if (checkStatus404 && response.statusCode == 404) {
        return false;
      }

      return false;
    } catch (e, s) {
      await _logger.logError(
        Exception('download _downloadSprite failed: url=$url dest=$destinationPath error=$e'),
        s,
      );
      return false;
    }
  }

  bool _isValidImageResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.startsWith('image/') && response.bodyBytes.isNotEmpty;
  }

  List<String> getDownloadedSprites() {
    return _prefs.getStringList(AppConfig.downloadedSpritesLogKey) ?? [];
  }
}
