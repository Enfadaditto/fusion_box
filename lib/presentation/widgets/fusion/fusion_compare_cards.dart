import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_stats_view.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/core/services/logger_service.dart';
import 'package:fusion_box/core/services/my_team_service.dart';

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
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('FusionCompareCardMedium: stats load failed for ${widget.fusion.fusionId}: $e'),
          s,
        );
      } catch (_) {}
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
              child: Stack(
                children: [
                  Center(
                    child: widget.fusion.primarySprite != null
                        ? SpriteFromSheet(
                            spriteData: widget.fusion.primarySprite!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          )
                        : Text('${widget.fusion.headPokemon.name} + ${widget.fusion.bodyPokemon.name}'),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final headId = widget.fusion.headPokemon.pokedexNumber;
                        final bodyId = widget.fusion.bodyPokemon.pokedexNumber;
                        final result = await MyTeamService.addFusion(headId: headId, bodyId: bodyId);
                        if (!mounted) return;
                        String message;
                        switch (result) {
                          case MyTeamService.resultAdded:
                            message = 'Added to My Team';
                            break;
                          case MyTeamService.resultAlreadyExists:
                            message = 'Already in My Team';
                            break;
                          case MyTeamService.resultTeamFull:
                            message = 'Team is full (6)';
                            break;
                          default:
                            message = 'Could not add to team';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.group_add_outlined, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('FusionCompareCardSmall: stats load failed for ${widget.fusion.fusionId}: $e'),
          s,
        );
      } catch (_) {}
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
        child: !_showStats
            ? Stack(
                children: [
                  Center(child: content),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final headId = widget.fusion.headPokemon.pokedexNumber;
                        final bodyId = widget.fusion.bodyPokemon.pokedexNumber;
                        final result = await MyTeamService.addFusion(headId: headId, bodyId: bodyId);
                        if (!mounted) return;
                        String message;
                        switch (result) {
                          case MyTeamService.resultAdded:
                            message = 'Added to My Team';
                            break;
                          case MyTeamService.resultAlreadyExists:
                            message = 'Already in My Team';
                            break;
                          case MyTeamService.resultTeamFull:
                            message = 'Team is full (6)';
                            break;
                          default:
                            message = 'Could not add to team';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.group_add_outlined, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Center(child: content),
      ),
    );
  }
}
