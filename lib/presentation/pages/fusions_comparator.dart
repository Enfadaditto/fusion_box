import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_details.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';

enum ComparatorSortKey {
  none,
  total,
  hp,
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

enum ComparatorSortOrder { descending, ascending }

class FusionsComparatorPage extends StatefulWidget {
  final List<Fusion> selectedFusions;

  const FusionsComparatorPage({super.key, required this.selectedFusions});

  @override
  State<FusionsComparatorPage> createState() => _FusionsComparatorPageState();
}

class _FusionsComparatorPageState extends State<FusionsComparatorPage> {
  List<Fusion> _filteredFusions = [];
  late final List<Fusion> _baseOrder;
  final List<String> _selectedTypes = [];
  final List<String> _selectedPokemon = [];
  bool _showFilters = false;
  static const double _filterRowHeight = 40;

  // Sorting
  ComparatorSortKey _sortKey = ComparatorSortKey.none;
  ComparatorSortOrder _sortOrder = ComparatorSortOrder.descending;

  @override
  void initState() {
    super.initState();
    _baseOrder = List<Fusion>.from(widget.selectedFusions);
    _filteredFusions = List<Fusion>.from(widget.selectedFusions);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      // Reiniciar desde el orden base antes de filtrar
      final starting = List<Fusion>.from(_baseOrder);
      _filteredFusions = starting.where((fusion) {
            // Filter by selected Pokemon (fusion must contain ALL selected Pokemon as head or body)
            if (_selectedPokemon.isNotEmpty) {
              final headName = fusion.headPokemon.name;
              final bodyName = fusion.bodyPokemon.name;
              final fusionPokemon = {headName, bodyName};
              final hasAllSelectedPokemon = _selectedPokemon.every(
                (pokemon) => fusionPokemon.contains(pokemon),
              );
              if (!hasAllSelectedPokemon) {
                return false;
              }
            }

            // Filter by selected types (AND logic - both types must be present)
            if (_selectedTypes.isNotEmpty) {
              final fusionTypes =
                  fusion.types.map((type) => type.toLowerCase()).toSet();
              final selectedTypesLower =
                  _selectedTypes.map((type) => type.toLowerCase()).toSet();
              if (!selectedTypesLower.every(
                (type) => fusionTypes.contains(type),
              )) {
                return false;
              }
            }

            return true;
          }).toList();
      _applySortInternal();
    });
  }

  void _applySortInternal() {
    if (_sortKey == ComparatorSortKey.none) {
      // Restaurar orden base al seleccionar none
      // Manteniendo solo los que pasaron los filtros
      final currentSet = _filteredFusions.map((f) => f.fusionId).toSet();
      _filteredFusions = _baseOrder
          .where((f) => currentSet.contains(f.fusionId))
          .toList();
      return;
    }
    int statValueOf(Fusion fusion) {
      final s = fusion.stats;
      if (s == null) return -0x3fffffff; // place missing stats at the end
      switch (_sortKey) {
        case ComparatorSortKey.none:
          return 0;
        case ComparatorSortKey.total:
          return s.hp + s.attack + s.defense + s.specialAttack + s.specialDefense + s.speed;
        case ComparatorSortKey.hp:
          return s.hp;
        case ComparatorSortKey.attack:
          return s.attack;
        case ComparatorSortKey.defense:
          return s.defense;
        case ComparatorSortKey.specialAttack:
          return s.specialAttack;
        case ComparatorSortKey.specialDefense:
          return s.specialDefense;
        case ComparatorSortKey.speed:
          return s.speed;
      }
    }
    _filteredFusions.sort((a, b) {
      final va = statValueOf(a);
      final vb = statValueOf(b);
      final cmp = va.compareTo(vb);
      return _sortOrder == ComparatorSortOrder.ascending ? cmp : -cmp;
    });
  }

  void _onSelectSortKey(ComparatorSortKey key) {
    setState(() {
      if (key == _sortKey) {
        // Toggle order if selecting the same key
        _sortOrder = _sortOrder == ComparatorSortOrder.descending
            ? ComparatorSortOrder.ascending
            : ComparatorSortOrder.descending;
      } else {
        _sortKey = key;
        // default to descending for new key
        _sortOrder = ComparatorSortOrder.descending;
      }
      _applySortInternal();
    });
  }

  String _sortKeyLabel(ComparatorSortKey key) {
    switch (key) {
      case ComparatorSortKey.none:
        return 'None';
      case ComparatorSortKey.total:
        return 'Total';
      case ComparatorSortKey.hp:
        return 'HP';
      case ComparatorSortKey.attack:
        return 'Attack';
      case ComparatorSortKey.defense:
        return 'Defense';
      case ComparatorSortKey.specialAttack:
        return 'Sp. Atk';
      case ComparatorSortKey.specialDefense:
        return 'Sp. Def';
      case ComparatorSortKey.speed:
        return 'Speed';
    }
  }

  void _toggleTypeFilter(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        // Only allow maximum 2 types
        if (_selectedTypes.length < 2) {
          _selectedTypes.add(type);
        } else {
          // Show a snackbar to inform user about the limit
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Maximum 2 types can be selected'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
      _applyFilters();
    });
  }

  Widget _buildPokemonChip(String pokemon, {bool compact = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          pokemon,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12 : 14,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        deleteIcon: Icon(
          Icons.close,
          color: Colors.white,
          size: compact ? 16 : 18,
        ),
        onDeleted: () {
          setState(() {
            _selectedPokemon.remove(pokemon);
            _applyFilters();
          });
        },
        materialTapTargetSize:
            compact
                ? MaterialTapTargetSize.shrinkWrap
                : MaterialTapTargetSize.padded,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
    );
  }

  Widget _buildTypeChip(String type, {bool compact = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          type,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: compact ? 12 : 14,
          ),
        ),
        backgroundColor: PokemonTypeColors.getTypeColor(type),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        deleteIcon: Icon(
          Icons.close,
          color: Colors.white,
          size: compact ? 16 : 18,
        ),
        onDeleted: () => _toggleTypeFilter(type),
        materialTapTargetSize:
            compact
                ? MaterialTapTargetSize.shrinkWrap
                : MaterialTapTargetSize.padded,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compare Fusions',
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Sort menu
          PopupMenuButton<ComparatorSortKey>(
            tooltip: 'Sort by stat',
            icon: Icon(
              Icons.sort,
              color: _sortKey == ComparatorSortKey.none
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
            onSelected: _onSelectSortKey,
            itemBuilder: (context) => [
              for (final key in ComparatorSortKey.values)
                PopupMenuItem<ComparatorSortKey>(
                  value: key,
                  child: Row(
                    children: [
                      Expanded(child: Text(_sortKeyLabel(key))),
                      if (key == _sortKey)
                        Icon(
                          _sortOrder == ComparatorSortOrder.descending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 18,
                        ),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color:
                  (_selectedTypes.isNotEmpty || _selectedPokemon.isNotEmpty)
                      ? Theme.of(context).colorScheme.primary
                      : null,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle filters',
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            // Filters section (collapsible with animation)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _showFilters ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showFilters ? 1.0 : 0.0,
                child: Column(
                  children: [
                    // Pokemon filter with chips
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Column(
                        children: [
                          // Filter dropdown (only show if less than 2 selected)
                          if (_selectedPokemon.length < 2)
                            SizedBox(
                              height: _filterRowHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PopupMenuButton<String>(
                                      itemBuilder: (context) {
                                        // Get unique Pokemon names from all fusions
                                        final allPokemon = <String>{};
                                        for (final fusion
                                            in widget.selectedFusions) {
                                          allPokemon.add(
                                            fusion.headPokemon.name,
                                          );
                                          allPokemon.add(
                                            fusion.bodyPokemon.name,
                                          );
                                        }
                                        final sortedPokemon =
                                            allPokemon.toList()..sort();

                                        return sortedPokemon.map((pokemon) {
                                          final isSelected = _selectedPokemon
                                              .contains(pokemon);
                                          return PopupMenuItem<String>(
                                            value: pokemon,
                                            child: Row(
                                              children: [
                                                Expanded(child: Text(pokemon)),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.check,
                                                    size: 18,
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList();
                                      },
                                      onSelected: (pokemon) {
                                        setState(() {
                                          if (_selectedPokemon.contains(
                                            pokemon,
                                          )) {
                                            _selectedPokemon.remove(pokemon);
                                          } else {
                                            // Only allow maximum 2 Pokemon
                                            if (_selectedPokemon.length < 2) {
                                              _selectedPokemon.add(pokemon);
                                            } else {
                                              // Show a snackbar to inform user about the limit
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Maximum 2 Pokemon can be selected',
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              return;
                                            }
                                          }
                                          _applyFilters();
                                        });
                                      },
                                      child: Container(
                                        height: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _selectedPokemon.isEmpty
                                                  ? 'Select Pokemon (max 2)'
                                                  : '${_selectedPokemon.length} selected',
                                              style: TextStyle(
                                                color:
                                                    _selectedPokemon.isEmpty
                                                        ? Colors.grey[600]
                                                        : null,
                                              ),
                                            ),
                                            const Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Show selected Pokemon as chips to the right of the filter
                                  ...(_selectedPokemon.map(
                                    (pokemon) => _buildPokemonChip(
                                      pokemon,
                                      compact: false,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          // When 2 selected, show clear on the left and chips in the same row (horizontal scroll if needed)
                          if (_selectedPokemon.length >= 2)
                            SizedBox(
                              height: _filterRowHeight,
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedPokemon.clear();
                                        _applyFilters();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(
                                        0,
                                        _filterRowHeight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Clear'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children:
                                            _selectedPokemon
                                                .map(
                                                  (pokemon) =>
                                                      _buildPokemonChip(
                                                        pokemon,
                                                        compact: false,
                                                      ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Type filters with chips
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 8,
                      ),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Column(
                        children: [
                          // Filter dropdown (only show if less than 2 selected)
                          if (_selectedTypes.length < 2)
                            SizedBox(
                              height: _filterRowHeight,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PopupMenuButton<String>(
                                      itemBuilder:
                                          (context) =>
                                              PokemonTypeColors.availableTypes.map((
                                                type,
                                              ) {
                                                final isSelected =
                                                    _selectedTypes.contains(
                                                      type,
                                                    );
                                                return PopupMenuItem<String>(
                                                  value: type,
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 16,
                                                        height: 16,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              PokemonTypeColors.getTypeColor(
                                                                type,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(type),
                                                      ),
                                                      if (isSelected)
                                                        const Icon(
                                                          Icons.check,
                                                          size: 18,
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                      onSelected: _toggleTypeFilter,
                                      child: Container(
                                        height: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _selectedTypes.isEmpty
                                                  ? 'Select types (max 2)'
                                                  : _selectedTypes.join(', '),
                                              style: TextStyle(
                                                color:
                                                    _selectedTypes.isEmpty
                                                        ? Colors.grey[600]
                                                        : null,
                                              ),
                                            ),
                                            const Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Show selected types as chips to the right of the filter
                                  ...(_selectedTypes.map(
                                    (type) =>
                                        _buildTypeChip(type, compact: false),
                                  )),
                                ],
                              ),
                            ),
                          // When 2 selected, show clear on the left and chips in the same row (horizontal scroll if needed)
                          if (_selectedTypes.length >= 2)
                            SizedBox(
                              height: _filterRowHeight,
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedTypes.clear();
                                        _applyFilters();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(
                                        0,
                                        _filterRowHeight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Clear'),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children:
                                            _selectedTypes
                                                .map(
                                                  (type) => _buildTypeChip(
                                                    type,
                                                    compact: false,
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista horizontal de fusiones
            Expanded(
              child:
                  _filteredFusions.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No fusions found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredFusions.length,
                        itemBuilder: (context, index) {
                          final fusion = _filteredFusions[index];
                          return Container(
                            key: ValueKey(fusion.fusionId),
                            width: 350,
                            margin: const EdgeInsets.only(right: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[600]!),
                            ),
                            child: FusionDetailsContent(
                              key: ValueKey('details-${fusion.fusionId}'),
                              fusion: fusion,
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
