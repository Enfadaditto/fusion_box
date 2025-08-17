import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';
import 'package:fusion_box/core/utils/stat_color_utils.dart';

class FusionStatsView extends StatelessWidget {
  final PokemonStats stats;
  final bool dense;

  const FusionStatsView({
    super.key,
    required this.stats,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final int total = stats.hp + stats.attack + stats.defense + stats.specialAttack + stats.specialDefense + stats.speed;
    final double barHeight = dense ? 3 : 4;
    final double fontSize = 10;
    final double labelWidth = dense ? 50 : 60;
    final double totalValueWidth = dense ? 36 : 40;
    final double valueWidth = dense ? 20 : 30;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _row('HP', stats.hp, barHeight, fontSize, valueWidth),
          _row('Attack', stats.attack, barHeight, fontSize, valueWidth),
          _row('Defense', stats.defense, barHeight, fontSize, valueWidth),
          _row('Sp. Atk', stats.specialAttack, barHeight, fontSize, valueWidth),
          _row('Sp. Def', stats.specialDefense, barHeight, fontSize, valueWidth),
          _row('Speed', stats.speed, barHeight, fontSize, valueWidth),

          Divider(color: Colors.grey[600], height: dense ? 18 : 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: totalValueWidth,
                  child: Text(
                    total.toString(),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _row(String label, int value, double barHeight, double fontSize, double valueWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              label,
              style: TextStyle(fontSize: fontSize, color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: barHeight,
                    child: LinearProgressIndicator(
                      value: value / 255,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        StatColorUtils.getStatColor(value),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: valueWidth,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: fontSize,
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
}


