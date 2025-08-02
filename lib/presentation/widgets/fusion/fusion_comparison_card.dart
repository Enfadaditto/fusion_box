import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';
import 'package:fusion_box/core/utils/stat_color_utils.dart';

class FusionComparisonCard extends StatefulWidget {
  final Fusion fusion;
  final int index;

  const FusionComparisonCard({
    super.key,
    required this.fusion,
    required this.index,
  });

  @override
  State<FusionComparisonCard> createState() => _FusionComparisonCardState();
}

class _FusionComparisonCardState extends State<FusionComparisonCard> {
  PokemonStats? _fusionStats;
  bool _isLoadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadFusionStats();
  }

  Future<void> _loadFusionStats() async {
    // Si la fusión ya tiene estadísticas calculadas, usarlas directamente
    if (widget.fusion.stats != null) {
      setState(() {
        _fusionStats = widget.fusion.stats;
        _isLoadingStats = false;
      });
      return;
    }

    // Si no tiene stats, calcularlas (fallback para compatibilidad)
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
          // Total stats at the top
          _buildStatRow('Total', totalStats, isTotal: true),
          const Divider(color: Colors.grey, height: 16),
          // Individual stats
          _buildStatRow('HP', _fusionStats!.hp),
          _buildStatRow('Attack', _fusionStats!.attack),
          _buildStatRow('Defense', _fusionStats!.defense),
          _buildStatRow('Sp. Atk', _fusionStats!.specialAttack),
          _buildStatRow('Sp. Def', _fusionStats!.specialDefense),
          _buildStatRow('Speed', _fusionStats!.speed),
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
                        StatColorUtils.getStatColor(statValue),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16, bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la fusión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              '${widget.fusion.headPokemon.name}/${widget.fusion.bodyPokemon.name}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Sprite de la fusión
          Container(
            padding: const EdgeInsets.all(16),
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
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[300]!),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.purple,
                      size: 40,
                    ),
                  ),
          ),
          
          // Tipos con chips estandarizados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.fusion.types.map((type) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 80, // Tamaño fijo para todos los chips
                  height: 28, // Altura fija para todos los chips
                  child: Container(
                    decoration: BoxDecoration(
                      color: PokemonTypeColors.getTypeColor(type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Estadísticas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStatsSection(),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 