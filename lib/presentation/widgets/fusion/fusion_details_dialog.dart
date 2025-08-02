import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';

class FusionDetailsDialog extends StatefulWidget {
  final Fusion fusion;

  const FusionDetailsDialog({
    super.key,
    required this.fusion,
  });

  static void show(BuildContext context, Fusion fusion) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FusionDetailsDialog(fusion: fusion),
    );
  }

  @override
  State<FusionDetailsDialog> createState() => _FusionDetailsDialogState();
}

class _FusionDetailsDialogState extends State<FusionDetailsDialog> {
  PokemonStats? _fusionStats;
  bool _isLoadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadFusionStats();
  }

  Future<void> _loadFusionStats() async {
    try {
      final calculator = FusionStatsCalculator();
      final stats = await calculator.getStatsFromFusion(
        widget.fusion.headPokemon,
        widget.fusion.bodyPokemon,
      );
      
      if (mounted) {
        setState(() {
          _fusionStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsError = e.toString();
          _isLoadingStats = false;
        });
      }
    }
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading stats...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_statsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red[300]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load stats',
                style: TextStyle(fontSize: 12, color: Colors.red[300]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_fusionStats == null) {
      return const SizedBox.shrink();
    }

    final totalStats = _fusionStats!.hp + 
                      _fusionStats!.attack + 
                      _fusionStats!.defense + 
                      _fusionStats!.specialAttack + 
                      _fusionStats!.specialDefense + 
                      _fusionStats!.speed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('HP', _fusionStats!.hp),
          _buildStatRow('Attack', _fusionStats!.attack),
          _buildStatRow('Defense', _fusionStats!.defense),
          _buildStatRow('Sp. Atk', _fusionStats!.specialAttack),
          _buildStatRow('Sp. Def', _fusionStats!.specialDefense),
          _buildStatRow('Speed', _fusionStats!.speed),
          const Divider(color: Colors.grey, height: 24),
          _buildStatRow('Total', totalStats, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildStatRow(String statName, int statValue, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              statName,
              style: TextStyle(
                fontSize: isTotal ? 13 : 12,
                color: isTotal ? Colors.white : Colors.grey[400],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (!isTotal) ...[
                  Expanded(
                    child: LinearProgressIndicator(
                      value: statValue / 255,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatColor(statValue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Spacer(),
                ],
                SizedBox(
                  width: isTotal ? 40 : 30,
                  child: Text(
                    statValue.toString(),
                    style: TextStyle(
                      fontSize: isTotal ? 13 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatColor(int statValue) {
    if (statValue >= 200) return Colors.red;
    if (statValue >= 150) return Colors.orange;
    if (statValue >= 100) return Colors.yellow;
    if (statValue >= 50) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: null,
      contentPadding: const EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Head and Body information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Head',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.fusion.headPokemon.name} (#${widget.fusion.headPokemon.pokedexNumber})',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Body',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.fusion.bodyPokemon.name} (#${widget.fusion.bodyPokemon.pokedexNumber})',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Fusion Sprite
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: widget.fusion.primarySprite != null
                  ? SpriteFromSheet(
                      spriteData: widget.fusion.primarySprite!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple[300]!),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.purple,
                        size: 40,
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // Types
            Text(
              widget.fusion.types.join(' / '),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            
            // Autogenerated sprite indicator
            if (widget.fusion.primarySprite?.isAutogenerated == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Autogenerated sprite',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Stats Section
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }
} 