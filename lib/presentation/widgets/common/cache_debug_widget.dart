import 'package:flutter/material.dart';
import 'package:fusion_box/core/services/small_icons_service.dart';

class CacheDebugWidget extends StatefulWidget {
  const CacheDebugWidget({super.key});

  @override
  State<CacheDebugWidget> createState() => _CacheDebugWidgetState();
}

class _CacheDebugWidgetState extends State<CacheDebugWidget> {
  Map<String, int> _cacheStats = {};

  @override
  void initState() {
    super.initState();
    _updateCacheStats();
  }

  void _updateCacheStats() {
    setState(() {
      _cacheStats = SmallIconsService().getCacheStats();
    });
  }

  void _clearCache() {
    SmallIconsService().clearCache();
    _updateCacheStats();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.cached, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Small Icons Cache',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: _updateCacheStats,
                  tooltip: 'Refresh stats',
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: _clearCache,
                  tooltip: 'Clear cache',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Pokemon IDs: ${_cacheStats['pokemonIds'] ?? 0}'),
            Text('Icon URLs: ${_cacheStats['iconUrls'] ?? 0}'),
          ],
        ),
      ),
    );
  }
}
