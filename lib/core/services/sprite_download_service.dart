import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fusion_box/config/app_config.dart';

enum SpriteType { custom, base }

class SpriteDownloadService {
  static const String _userAgent = 'FusionBox/${AppConfig.appVersion}';

  final SharedPreferences _prefs;

  SpriteDownloadService({required SharedPreferences preferences})
    : _prefs = preferences;

  /// Check if downloads are enabled by user preference
  bool get isDownloadEnabled {
    return _prefs.getBool(AppConfig.downloadEnabledKey) ?? true;
  }

  /// Enable or disable sprite downloads
  Future<void> setDownloadEnabled(bool enabled) async {
    await _prefs.setBool(AppConfig.downloadEnabledKey, enabled);
  }

  /// Download a sprite if it doesn't exist locally and conditions are met
  Future<bool> downloadSpriteIfNeeded({
    required int headId,
    required String localSpritePath,
    String variant = '',
    SpriteType type = SpriteType.custom,
  }) async {
    // Check if downloads are enabled
    if (!isDownloadEnabled) {
      return false;
    }

    // Check if file already exists
    final file = File(localSpritePath);
    if (await file.exists()) {
      return true; // Already exists, no need to download
    }

    // Check rate limiting
    if (await _isRateLimitExceeded()) {
      return false;
    }

    try {
      // Build download URL
      final url = _buildDownloadUrl(headId, variant, type);

      // Download the sprite
      final success = await _downloadSprite(url, localSpritePath);

      // Log the download attempt
      await _logDownloadAttempt();

      // If successful, log the downloaded sprite
      if (success) {
        await _logDownloadedSprite(localSpritePath);
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Download all available variants for a head ID until 404 is found
  Future<List<String>> downloadAllVariants({
    required int headId,
    required String baseLocalPath,
    SpriteType type = SpriteType.custom,
  }) async {
    final downloadedVariants = <String>[];

    // Try main sprite first (no variant)
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

    // Try variants a, b, c, d, e, f, g, h, i, j until 404
    const possibleVariants = [
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
    ];

    for (final variant in possibleVariants) {
      // Check if we've hit rate limit
      if (await _isRateLimitExceeded()) {
        break;
      }

      final variantPath = baseLocalPath.replaceAll('.png', '$variant.png');
      final file = File(variantPath);

      // Skip if already exists
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

        await _logDownloadAttempt();

        if (success) {
          downloadedVariants.add(variant);
          await _logDownloadedSprite(variantPath);
        } else {
          // Assume 404 or error, stop trying more variants
          break;
        }
      } catch (e) {
        // Error downloading, stop trying more variants
        break;
      }
    }

    return downloadedVariants;
  }

  /// Build the download URL based on sprite type and parameters
  String _buildDownloadUrl(int headId, String variant, SpriteType type) {
    switch (type) {
      case SpriteType.custom:
        return '${AppConfig.customSpritesBaseUrl}$headId/$headId$variant.png';
      case SpriteType.base:
        return '${AppConfig.baseSpritesBaseUrl}$headId.png';
    }
  }

  /// Download a sprite from the given URL to the destination path
  Future<bool> _downloadSprite(
    String url,
    String destinationPath, {
    bool checkStatus404 = false,
  }) async {
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
        // Verify it's actually an image
        if (!_isValidImageResponse(response)) {
          return false;
        }

        // Create directory if it doesn't exist
        final file = File(destinationPath);
        await file.parent.create(recursive: true);

        // Write the image data
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }

      // If checking for 404 specifically, return false for any non-200 status
      if (checkStatus404 && response.statusCode == 404) {
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verify that the HTTP response contains valid image data
  bool _isValidImageResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    return contentType.startsWith('image/') && response.bodyBytes.isNotEmpty;
  }

  /// Check if rate limit has been exceeded
  Future<bool> _isRateLimitExceeded() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final windowStart = now - AppConfig.rateLimitWindowSeconds;

    // Get existing request timestamps
    final rateLimitLog = _prefs.getStringList(AppConfig.rateLimitLogKey) ?? [];

    // Filter to only include requests within the time window
    final recentRequests =
        rateLimitLog
            .map((timestamp) => int.tryParse(timestamp) ?? 0)
            .where((timestamp) => timestamp > windowStart)
            .toList();

    return recentRequests.length >= AppConfig.maxDownloadRequestsPerMinute;
  }

  /// Log a download attempt for rate limiting
  Future<void> _logDownloadAttempt() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final windowStart = now - AppConfig.rateLimitWindowSeconds;

    // Get existing request timestamps
    final rateLimitLog = _prefs.getStringList(AppConfig.rateLimitLogKey) ?? [];

    // Filter to only include requests within the time window and add new request
    final updatedLog =
        rateLimitLog
            .map((timestamp) => int.tryParse(timestamp) ?? 0)
            .where((timestamp) => timestamp > windowStart)
            .map((timestamp) => timestamp.toString())
            .toList();

    updatedLog.add(now.toString());

    await _prefs.setStringList(AppConfig.rateLimitLogKey, updatedLog);
  }

  /// Log a successfully downloaded sprite
  Future<void> _logDownloadedSprite(String spritePath) async {
    final downloadedSprites =
        _prefs.getStringList(AppConfig.downloadedSpritesLogKey) ?? [];
    if (!downloadedSprites.contains(spritePath)) {
      downloadedSprites.add(spritePath);
      await _prefs.setStringList(
        AppConfig.downloadedSpritesLogKey,
        downloadedSprites,
      );
    }
  }

  /// Get list of downloaded sprites
  List<String> getDownloadedSprites() {
    return _prefs.getStringList(AppConfig.downloadedSpritesLogKey) ?? [];
  }

  /// Clear download logs (useful for debugging/reset)
  Future<void> clearDownloadLogs() async {
    await _prefs.remove(AppConfig.rateLimitLogKey);
    await _prefs.remove(AppConfig.downloadedSpritesLogKey);
  }

  /// Get current rate limit status
  Future<Map<String, dynamic>> getRateLimitStatus() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final windowStart = now - AppConfig.rateLimitWindowSeconds;

    final rateLimitLog = _prefs.getStringList(AppConfig.rateLimitLogKey) ?? [];
    final recentRequests =
        rateLimitLog
            .map((timestamp) => int.tryParse(timestamp) ?? 0)
            .where((timestamp) => timestamp > windowStart)
            .length;

    return {
      'requestsInWindow': recentRequests,
      'maxRequests': AppConfig.maxDownloadRequestsPerMinute,
      'windowSeconds': AppConfig.rateLimitWindowSeconds,
      'rateLimitExceeded':
          recentRequests >= AppConfig.maxDownloadRequestsPerMinute,
    };
  }
}
