import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_event.dart';
import 'package:fusion_box/presentation/widgets/pokemon/stream_based_pokemon_icon.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_details_dialog.dart';
import 'package:fusion_box/presentation/pages/fusions_comparator.dart';

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
  bool _isToolboxVisible = true;

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

  void _navigateToComparison(BuildContext context, FusionGridLoaded state) {
    final selectedFusions = <Fusion>[];

    for (int row = 0; row < state.fusionGrid.length; row++) {
      for (int col = 0; col < state.fusionGrid[row].length; col++) {
        final fusion = state.fusionGrid[row][col];
        if (fusion != null &&
            state.selectedFusionIds.contains(fusion.fusionId)) {
          selectedFusions.add(fusion);
        }
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                FusionsComparatorPage(selectedFusions: selectedFusions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fusion Grid'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Indicador de fusiones seleccionadas
          BlocBuilder<FusionGridBloc, FusionGridState>(
            builder: (context, state) {
              if (state is FusionGridLoaded &&
                  state.selectedFusionIds.isNotEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[600]!),
                    ),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
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
            return Column(
              children: [
                Expanded(child: _buildFusionGrid(context, state)),
                // Botón COMPARE en la parte inferior
                if (state.selectedFusionIds.length >= 2)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _navigateToComparison(context, state),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'COMPARE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Indicador de notificación
                          Positioned(
                            top: -8,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${state.selectedFusionIds.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          return const Center(child: Text('No fusion grid available'));
        },
      ),
    );
  }

  Widget _buildFusionGrid(BuildContext context, FusionGridLoaded state) {
    final gridData = _buildGridData(state);

    return Column(
      children: [
        // Header con información
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Long press on a fusion to select it',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Toolbox con acordeón y marcador
        Column(
          children: [
            // Contenido de la toolbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isToolboxVisible ? 50 : 0,
              child: Container(
                width: double.infinity,
                height: 50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.grey[800],
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isToolboxVisible ? 1.0 : 0.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botones de zoom
                      IconButton(
                        icon: const Icon(Icons.zoom_out, size: 18),
                        onPressed: _currentScale > _minScale ? _zoomOut : null,
                        tooltip: 'Zoom Out',
                        style: IconButton.styleFrom(
                          foregroundColor:
                              _currentScale > _minScale
                                  ? Colors.white
                                  : Colors.grey[400],
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.center_focus_strong, size: 18),
                        onPressed: _currentScale != 1.0 ? _resetZoom : null,
                        tooltip: 'Reset Zoom',
                        style: IconButton.styleFrom(
                          foregroundColor:
                              _currentScale != 1.0
                                  ? Colors.white
                                  : Colors.grey[400],
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.zoom_in, size: 18),
                        onPressed: _currentScale < _maxScale ? _zoomIn : null,
                        tooltip: 'Zoom In',
                        style: IconButton.styleFrom(
                          foregroundColor:
                              _currentScale < _maxScale
                                  ? Colors.white
                                  : Colors.grey[400],
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón de ordenación por stat (menú)
                      BlocBuilder<FusionGridBloc, FusionGridState>(
                        builder: (context, state) {
                          FusionSortKey sortKey = FusionSortKey.none;
                          FusionSortOrder sortOrder = FusionSortOrder.descending;
                          if (state is FusionGridLoaded) {
                            sortKey = state.sortKey;
                            sortOrder = state.sortOrder;
                          }
                          return PopupMenuButton<FusionSortKey>(
                            tooltip: 'Sort by stat',
                            onSelected: (key) {
                              final current = context.read<FusionGridBloc>().state;
                              FusionSortKey nextKey = key;
                              FusionSortOrder nextOrder = FusionSortOrder.descending;
                              if (current is FusionGridLoaded) {
                                if (current.sortKey == key) {
                                  nextOrder = current.sortOrder == FusionSortOrder.descending
                                      ? FusionSortOrder.ascending
                                      : FusionSortOrder.descending;
                                } else {
                                  nextKey = key;
                                  nextOrder = FusionSortOrder.descending;
                                }
                              }
                              context.read<FusionGridBloc>().add(
                                    UpdateFusionSort(
                                      sortKey: nextKey,
                                      sortOrder: nextOrder,
                                    ),
                                  );
                            },
                            itemBuilder: (context) => [
                              for (final key in FusionSortKey.values)
                                PopupMenuItem<FusionSortKey>(
                                  value: key,
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(_sortKeyLabel(key))),
                                      if (key == sortKey)
                                        Icon(
                                          sortOrder == FusionSortOrder.descending
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                            child: Container(
                              height: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[600]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort,
                                    size: 18,
                                    color: state is FusionGridLoaded && state.sortKey != FusionSortKey.none
                                        ? Colors.blue[300]
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    state is FusionGridLoaded
                                        ? _sortKeyLabel(state.sortKey)
                                        : _sortKeyLabel(FusionSortKey.none),
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Marcador con flecha animada
            SizedBox(
              width: double.infinity,
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isToolboxVisible = !_isToolboxVisible;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 20,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _isToolboxVisible ? 0.5 : 0.0,
                        child: Icon(
                          Icons.keyboard_arrow_up,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  String _sortKeyLabel(FusionSortKey key) {
    switch (key) {
      case FusionSortKey.none:
        return 'None';
      case FusionSortKey.total:
        return 'Total';
      case FusionSortKey.hp:
        return 'HP';
      case FusionSortKey.attack:
        return 'Attack';
      case FusionSortKey.defense:
        return 'Defense';
      case FusionSortKey.specialAttack:
        return 'Sp. Atk';
      case FusionSortKey.specialDefense:
        return 'Sp. Def';
      case FusionSortKey.speed:
        return 'Speed';
    }
  }

  Widget _buildGridData(FusionGridLoaded state) {
    final gridSize = state.selectedPokemon.length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Table(
        border: TableBorder.all(color: Colors.grey[300]!, width: 1),
        defaultColumnWidth: const FixedColumnWidth(100),
        children: [
          // Header row con nombres de Pokemon o ranking si hay orden activo
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
              // Headers de columnas
              ...(state.sortKey == FusionSortKey.none
                  // Sin orden: mostrar Pokemon (body)
                  ? state.selectedPokemon.map<Widget>((pokemon) => Container(
                        height: 80,
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StreamBasedPokemonIcon(pokemon: pokemon, size: 32),
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
                      ))
                  // Con orden: mostrar ranking 1..N (columnas reordenadas por fila)
                  : List.generate(gridSize, (index) {
                      return Container(
                        height: 80,
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[600]!),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pos',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    })),
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
                      StreamBasedPokemonIcon(pokemon: headPokemon, size: 32),
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

    return BlocBuilder<FusionGridBloc, FusionGridState>(
      builder: (context, state) {
        final isSelected =
            state is FusionGridLoaded &&
            fusion != null &&
            state.selectedFusionIds.contains(fusion.fusionId);

        return Stack(
          children: [
            Container(
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
                            Icon(
                              Icons.block,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Disabled',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            // Filtro gris si está seleccionado
            if (isSelected)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    context.read<FusionGridBloc>().add(
                      ToggleFusionSelection(fusion),
                    );
                  },
                  onLongPress: () {
                    // Mostrar detalles de la fusión
                    FusionDetailsDialog.show(context, fusion);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            // Checkbox en la esquina superior izquierda (solo visible si hay fusiones seleccionadas)
            if (fusion != null &&
                state is FusionGridLoaded &&
                state.selectedFusionIds.isNotEmpty)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () {
                    context.read<FusionGridBloc>().add(
                      ToggleFusionSelection(fusion),
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Colors.blue
                              : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                            : null,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFusionContent(
    BuildContext context,
    Fusion fusion,
    bool isAutogenerated,
  ) {
    return BlocBuilder<FusionGridBloc, FusionGridState>(
      builder: (context, state) {
        final hasSelectedFusions =
            state is FusionGridLoaded && state.selectedFusionIds.isNotEmpty;

        return InkWell(
          onTap: () {
            if (hasSelectedFusions) {
              // Si hay fusiones seleccionadas, tap selecciona (solo si no está ya seleccionada)
              if (!state.selectedFusionIds.contains(fusion.fusionId)) {
                context.read<FusionGridBloc>().add(
                  ToggleFusionSelection(fusion),
                );
              }
            } else {
              // Si no hay fusiones seleccionadas, tap muestra info
              FusionDetailsDialog.show(context, fusion);
            }
          },
          onLongPress: () {
            if (hasSelectedFusions) {
              // Si hay fusiones seleccionadas, longPress muestra info
              FusionDetailsDialog.show(context, fusion);
            } else {
              // Si no hay fusiones seleccionadas, longPress selecciona
              context.read<FusionGridBloc>().add(ToggleFusionSelection(fusion));
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sprite de la fusión (usar sprite real si está disponible)
              fusion.primarySprite != null
                  ? SpriteFromSheet(
                    spriteData: fusion.primarySprite!,
                    width: 100,
                    height: 60,
                    fit: BoxFit.contain,
                  )
                  : Container(
                    width: 100,
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
      },
    );
  }
}
