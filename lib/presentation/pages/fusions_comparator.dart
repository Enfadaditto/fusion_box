import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_comparison_card.dart';

class FusionsComparatorPage extends StatelessWidget {
  final List<Fusion> selectedFusions;

  const FusionsComparatorPage({
    super.key,
    required this.selectedFusions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compare Fusions (${selectedFusions.length})'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Header con información
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Center(
              child: Text(
                  'Swipe horizontally to view all fusions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ),
          
          // Lista horizontal de fusiones
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: selectedFusions.length,
              itemBuilder: (context, index) {
                final fusion = selectedFusions[index];
                return FusionComparisonCard(
                  fusion: fusion,
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 