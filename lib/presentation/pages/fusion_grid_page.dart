import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_event.dart';
import 'package:fusion_box/presentation/widgets/pokemon/cached_pokemon_icon.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';

class FusionGridPage extends StatelessWidget {
  const FusionGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fusion Grid'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              context.read<FusionGridBloc>().add(ClearFusionGrid());
              Navigator.of(context).pop();
            },
            tooltip: 'Clear Grid',
          ),
        ],
      ),
      body: BlocBuilder<FusionGridBloc, FusionGridState>(
        builder: (context, state) {
          if (state is FusionGridLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Generating fusion grid...',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take a moment',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (state is FusionGridError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          if (state is FusionGridLoaded) {
            return _buildFusionGrid(context, state);
          }

          return const Center(child: Text('No fusion grid available'));
        },
      ),
    );
  }

  Widget _buildFusionGrid(BuildContext context, FusionGridLoaded state) {
    final gridSize = state.selectedPokemon.length;

    return Column(
      children: [
        // Header con información
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            children: [
              Text(
                '${gridSize}x$gridSize Fusion Grid',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${state.selectedPokemon.length} Pokemon selected',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Grid scrollable simple
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                  defaultColumnWidth: const FixedColumnWidth(100),
                  children: [
                    // Header row con nombres de Pokemon
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[800]),
                      children: [
                        // Celda vacía para la esquina
                        Container(
                          height: 80,
                          padding: const EdgeInsets.all(4),
                          child: const Center(
                            child: Text(
                              'Head \\ Body',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Headers de Pokemon (body)
                        ...state.selectedPokemon.map<Widget>(
                          (pokemon) => Container(
                            height: 80,
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CachedPokemonIcon(pokemon: pokemon, size: 32),
                                const SizedBox(height: 2),
                                Text(
                                  pokemon.name,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Filas de datos
                    ...List.generate(gridSize, (rowIndex) {
                      final headPokemon = state.selectedPokemon[rowIndex];

                      return TableRow(
                        children: [
                          // Header de fila (head Pokemon)
                          Container(
                            height: 100,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.grey[800]),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CachedPokemonIcon(
                                  pokemon: headPokemon,
                                  size: 32,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  headPokemon.name,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // Celdas de fusión
                          ...List.generate(gridSize, (colIndex) {
                            final fusion = state.fusionGrid[rowIndex][colIndex];

                            return _buildFusionCell(
                              context,
                              fusion,
                              rowIndex == colIndex,
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFusionCell(
    BuildContext context,
    Fusion? fusion,
    bool isSamePokemon,
  ) {
    // Determinar si esta celda específica usa sprite autogenerado
    final isAutogenerated = fusion?.primarySprite?.isAutogenerated == true;

    Color? backgroundColor;

    if (fusion != null) {
      if (isAutogenerated) {
        // Celda con sprite autogenerado - fondo gris
        backgroundColor = Colors.grey[700];
      } else {
        // Celda normal
        backgroundColor = Colors.indigo[800];
      }
    } else {
      // Sin datos
      backgroundColor = Colors.red[800];
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border:
            isAutogenerated
                ? Border.all(color: Colors.grey[400]!, width: 1)
                : null,
      ),
      child:
          fusion != null
              ? _buildFusionContent(context, fusion, isAutogenerated)
              : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, color: Colors.red, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'No Data',
                      style: TextStyle(fontSize: 8, color: Colors.red),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildFusionContent(
    BuildContext context,
    Fusion fusion,
    bool isAutogenerated,
  ) {
    return InkWell(
      onTap: () {
        _showFusionDetails(context, fusion);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sprite de la fusión (usar sprite real si está disponible)
          fusion.primarySprite != null
              ? SpriteFromSheet(
                spriteData: fusion.primarySprite!,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              )
              : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.purple[300]!),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
          const SizedBox(height: 2),
          // Nombre de la fusión
          Text(
            '${fusion.headPokemon.name}/${fusion.bodyPokemon.name}',
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.bold,
              color: isAutogenerated ? Colors.grey[300] : Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Tipos
          Text(
            fusion.types.join('/'),
            style: TextStyle(
              fontSize: 7,
              color: isAutogenerated ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFusionDetails(BuildContext context, Fusion fusion) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              '${fusion.headPokemon.name}/${fusion.bodyPokemon.name}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Head: ${fusion.headPokemon.name} (#${fusion.headPokemon.pokedexNumber})',
                ),
                Text(
                  'Body: ${fusion.bodyPokemon.name} (#${fusion.bodyPokemon.pokedexNumber})',
                ),
                const SizedBox(height: 8),
                Text('Types: ${fusion.types.join(', ')}'),
                const SizedBox(height: 8),
                Text('Fusion ID: ${fusion.fusionId}'),
                if (fusion.primarySprite?.isAutogenerated == true) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Using autogenerated sprite',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
