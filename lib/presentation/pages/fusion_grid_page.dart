import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';
import 'package:fusion_box/presentation/widgets/pokemon/conditional_pokemon_icon.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';

class FusionGridPage extends StatefulWidget {
  const FusionGridPage({super.key});

  @override
  State<FusionGridPage> createState() => _FusionGridPageState();
}

class _FusionGridPageState extends State<FusionGridPage> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;
  static const double _scaleStep = 0.25;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final newScale = (_currentScale + _scaleStep).clamp(_minScale, _maxScale);
    _setScale(newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale - _scaleStep).clamp(_minScale, _maxScale);
    _setScale(newScale);
  }

  void _resetZoom() {
    _setScale(1.0);
  }

  void _setScale(double scale) {
    setState(() {
      _currentScale = scale;
    });

    // Aplicar la transformación al centro de la vista
    final matrix = Matrix4.identity()..scale(scale);
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fusion Grid'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Indicador de zoom actual
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_currentScale * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
      // Botones flotantes de zoom
      floatingActionButton: _buildZoomControls(),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom In
        FloatingActionButton.small(
          heroTag: "zoom_in",
          onPressed: _currentScale < _maxScale ? _zoomIn : null,
          backgroundColor:
              _currentScale < _maxScale
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
          child: const Icon(Icons.zoom_in),
        ),
        const SizedBox(height: 8),

        // Reset Zoom
        FloatingActionButton.small(
          heroTag: "zoom_reset",
          onPressed: _currentScale != 1.0 ? _resetZoom : null,
          backgroundColor:
              _currentScale != 1.0
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.grey,
          child: const Icon(Icons.center_focus_strong),
        ),
        const SizedBox(height: 8),

        // Zoom Out
        FloatingActionButton.small(
          heroTag: "zoom_out",
          onPressed: _currentScale > _minScale ? _zoomOut : null,
          backgroundColor:
              _currentScale > _minScale
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
          child: const Icon(Icons.zoom_out),
        ),
      ],
    );
  }

  Widget _buildFusionGrid(BuildContext context, FusionGridLoaded state) {
    final gridSize = state.selectedPokemon.length;
    final gridData = _buildGridData(state);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Use pinch to zoom or buttons below',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Grid con zoom mejorado
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(80),
            minScale: _minScale,
            maxScale: _maxScale,
            constrained: false,
            onInteractionEnd: (details) {
              setState(() {
                _currentScale =
                    _transformationController.value.getMaxScaleOnAxis();
              });
            },
            child: gridData,
          ),
        ),
      ],
    );
  }

  Widget _buildGridData(FusionGridLoaded state) {
    final gridSize = state.selectedPokemon.length;

    return Container(
      margin: const EdgeInsets.all(16),
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
                      ConditionalPokemonIcon(pokemon: pokemon, size: 32),
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
            // Verificar que selectedPokemon tenga el tamaño correcto
            if (rowIndex >= state.selectedPokemon.length) {
              return TableRow(
                children: [
                  // Header de fila vacío
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey[800]),
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                  // Celdas vacías
                  ...List.generate(gridSize, (colIndex) {
                    return _buildFusionCell(context, null, false);
                  }),
                ],
              );
            }

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
                      ConditionalPokemonIcon(pokemon: headPokemon, size: 32),
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
                  // Verificar que el fusionGrid tenga el tamaño correcto
                  if (rowIndex >= state.fusionGrid.length ||
                      colIndex >= state.fusionGrid[rowIndex].length) {
                    return _buildFusionCell(
                      context,
                      null,
                      rowIndex == colIndex,
                    );
                  }

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
    );
  }

  Widget _buildFusionCell(
    BuildContext context,
    Fusion? fusion,
    bool isSamePokemon,
  ) {
    // Determinar si esta fusión específica usa sprite autogenerado
    final isAutogenerated = fusion?.primarySprite?.isAutogenerated == true;

    Color? backgroundColor;

    if (fusion != null) {
      if (isAutogenerated) {
        // Esta fusión específica usa sprite autogenerado - fondo gris
        backgroundColor = Colors.grey[700];
      } else {
        // Fusión normal con sprite custom
        backgroundColor = Colors.indigo[800];
      }
    } else {
      // Sin datos - usar color gris oscuro para celdas diagonales deshabilitadas
      backgroundColor = Colors.grey[900];
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: backgroundColor),
      child:
          fusion != null
              ? _buildFusionContent(context, fusion, isAutogenerated)
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, color: Colors.grey[600], size: 20),
                    const SizedBox(height: 2),
                    Text(
                      'Disabled',
                      style: TextStyle(fontSize: 8, color: Colors.grey[600]),
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
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: null,
        contentPadding: const EdgeInsets.all(24),
                 content: Column(
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
                       '${fusion.headPokemon.name} (#${fusion.headPokemon.pokedexNumber})',
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
                       '${fusion.bodyPokemon.name} (#${fusion.bodyPokemon.pokedexNumber})',
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
               child: fusion.primarySprite != null
                   ? SpriteFromSheet(
                       spriteData: fusion.primarySprite!,
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
               fusion.types.join(' / '),
               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
               textAlign: TextAlign.center,
             ),
             
             // Autogenerated sprite indicator
             if (fusion.primarySprite?.isAutogenerated == true) ...[
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
           ],
         ),
      ),
    );
  }
}
