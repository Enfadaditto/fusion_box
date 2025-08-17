import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_stats_view.dart';

class FusionCompareCardMedium extends StatefulWidget {
  final Fusion fusion;

  const FusionCompareCardMedium({super.key, required this.fusion});

  @override
  State<FusionCompareCardMedium> createState() => _FusionCompareCardMediumState();
}

class _FusionCompareCardMediumState extends State<FusionCompareCardMedium> {
  PokemonStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant FusionCompareCardMedium oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fusion.fusionId != widget.fusion.fusionId) {
      _stats = null;
      _isLoading = true;
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (widget.fusion.stats != null) {
      setState(() {
        _stats = widget.fusion.stats;
        _isLoading = false;
      });
      return;
    }
    try {
      final calculator = FusionStatsCalculator();
      final s = await calculator.getStatsFromFusion(
        widget.fusion.headPokemon,
        widget.fusion.bodyPokemon,
      );
      if (!mounted) return;
      setState(() {
        _stats = s;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: widget.fusion.primarySprite != null
                  ? SpriteFromSheet(
                      spriteData: widget.fusion.primarySprite!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    )
                  : Center(child: Text('${widget.fusion.headPokemon.name} + ${widget.fusion.bodyPokemon.name}')),
            ),
            const SizedBox(height: 10),
            // Stats only (compact)
            if (_isLoading)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_stats != null)
              FusionStatsView(stats: _stats!, dense: false),
          ],
        ),
      ),
    );
  }
}

class FusionCompareCardSmall extends StatefulWidget {
  final Fusion fusion;

  const FusionCompareCardSmall({super.key, required this.fusion});

  @override
  State<FusionCompareCardSmall> createState() => _FusionCompareCardSmallState();
}

class _FusionCompareCardSmallState extends State<FusionCompareCardSmall> {
  PokemonStats? _stats;
  bool _isLoading = true;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant FusionCompareCardSmall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fusion.fusionId != widget.fusion.fusionId) {
      _stats = null;
      _isLoading = true;
      _showStats = false;
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (widget.fusion.stats != null) {
      setState(() {
        _stats = widget.fusion.stats;
        _isLoading = false;
      });
      return;
    }
    try {
      final calculator = FusionStatsCalculator();
      final s = await calculator.getStatsFromFusion(
        widget.fusion.headPokemon,
        widget.fusion.bodyPokemon,
      );
      if (!mounted) return;
      setState(() {
        _stats = s;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_showStats) {
      if (_isLoading) {
        content = const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      } else if (_stats != null) {
        content = FusionStatsView(stats: _stats!, dense: true);
      } else {
        content = const SizedBox.shrink();
      }
    } else {
      content = widget.fusion.primarySprite != null
          ? SpriteFromSheet(
              spriteData: widget.fusion.primarySprite!,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            )
          : Center(child: Text('${widget.fusion.headPokemon.name} + ${widget.fusion.bodyPokemon.name}'));
    }

    return InkWell(
      onTap: () => setState(() => _showStats = !_showStats),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Center(child: content),
      ),
    );
  }
}
