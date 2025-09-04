import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/injection_container.dart';

class FusionVariantPickerSheet extends StatefulWidget {
  final int headId;
  final int bodyId;
  final SpriteData? initial;
  final ValueChanged<SpriteData> onSelected;

  const FusionVariantPickerSheet({
    super.key,
    required this.headId,
    required this.bodyId,
    required this.initial,
    required this.onSelected,
  });

  @override
  State<FusionVariantPickerSheet> createState() => _FusionVariantPickerSheetState();
}

class _FusionVariantPickerSheetState extends State<FusionVariantPickerSheet> {
  late final PageController _pageController;
  List<SpriteData> _variants = const [];
  SpriteData? _tempSelection;
  bool _isLoading = true;
  bool _hasTried = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    setState(() => _isLoading = true);
    final repo = instance<SpriteRepository>();
    List<SpriteData> variants = [];
    try {
      variants = await repo.getAllSpriteVariants(widget.headId, widget.bodyId);
      variants.sort((a, b) {
        final av = a.variant;
        final bv = b.variant;
        if (av.isEmpty && bv.isNotEmpty) return -1;
        if (bv.isEmpty && av.isNotEmpty) return 1;
        return av.compareTo(bv);
      });
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _variants = variants;
      _isLoading = false;
      _hasTried = true;
      if (_variants.isNotEmpty) {
        int initialIndex = 0;
        if (widget.initial != null) {
          final found = _variants.indexWhere((s) => s.variant == widget.initial!.variant);
          if (found >= 0) initialIndex = found;
        }
        _tempSelection = _variants[initialIndex];
        _currentIndex = initialIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(initialIndex);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(height: 12),
                      Text('Loading variants…'),
                    ],
                  )
                : (_variants.isEmpty
                    ? Center(child: Text('No variants available', style: TextStyle(color: Colors.grey[400])))
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              if (index >= 0 && index < _variants.length) {
                                setState(() {
                                  _currentIndex = index;
                                  _tempSelection = _variants[index];
                                });
                              }
                            },
                            itemCount: _variants.length,
                            itemBuilder: (context, index) {
                              final s = _variants[index];
                              return Center(
                                child: SpriteFromSheet(
                                  spriteData: s,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                          if (_variants.length > 1) ...[
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                                  onPressed: _currentIndex > 0
                                      ? () {
                                          _pageController.previousPage(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                                  onPressed: _currentIndex < _variants.length - 1
                                      ? () {
                                          _pageController.nextPage(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _tempSelection == null
                        ? null
                        : () {
                            final sel = _tempSelection!;
                            widget.onSelected(sel);
                            Navigator.of(context).pop();
                          },
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


