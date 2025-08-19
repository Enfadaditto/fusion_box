import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_details.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_compare_cards.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';
import 'package:fusion_box/core/utils/pokemon_enrichment_loader.dart';

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
  String? _selectedAbility;
  bool _showFilters = false;
  static const double _filterRowHeight = 40;
  int _numLines = 2;
  List<String> _allAbilities = const [];
  final List<String> _selectedMoves = [];
  List<String> _allMoves = const [];

  // Sorting
  ComparatorSortKey _sortKey = ComparatorSortKey.none;
  ComparatorSortOrder _sortOrder = ComparatorSortOrder.descending;

  @override
  void initState() {
    super.initState();
    _baseOrder = List<Fusion>.from(widget.selectedFusions);
    _filteredFusions = List<Fusion>.from(widget.selectedFusions);
    // Load abilities catalog
    PokemonEnrichmentLoader().getAllAbilities().then((abilities) {
      if (!mounted) return;
      setState(() {
        _allAbilities = abilities;
      });
    });
    PokemonEnrichmentLoader().getAllMoves().then((moves) {
      if (!mounted) return;
      setState(() {
        _allMoves = moves;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _applyFilters() async {
    // Reiniciar desde el orden base antes de filtrar
    final starting = List<Fusion>.from(_baseOrder);

    // First, apply Pokemon and Types synchronously
    List<Fusion> pre = starting.where((fusion) {
      if (_selectedPokemon.isNotEmpty) {
        final headName = fusion.headPokemon.name;
        final bodyName = fusion.bodyPokemon.name;
        final fusionPokemon = {headName, bodyName};
        final hasAllSelectedPokemon = _selectedPokemon.every(
          (pokemon) => fusionPokemon.contains(pokemon),
        );
        if (!hasAllSelectedPokemon) return false;
      }

      if (_selectedTypes.isNotEmpty) {
        final fusionTypes = fusion.types.map((type) => type.toLowerCase()).toSet();
        final selectedTypesLower =
            _selectedTypes.map((type) => type.toLowerCase()).toSet();
        if (!selectedTypesLower.every((type) => fusionTypes.contains(type))) {
          return false;
        }
      }
      return true;
    }).toList();

    // Then, apply ability filter asynchronously if needed
    if (_selectedAbility != null) {
      final loader = PokemonEnrichmentLoader();
      final List<Fusion> refined = [];
      final String required = _selectedAbility!.toLowerCase();
      for (final fusion in pre) {
        final combined = await loader.getCombinedAbilities(
          fusion.headPokemon,
          fusion.bodyPokemon,
        );
        final combinedLower = combined.map((e) => e.toLowerCase()).toSet();
        if (combinedLower.contains(required)) refined.add(fusion);
      }
      pre = refined;
    }

    // Apply moves filter (must contain all selected moves)
    if (_selectedMoves.isNotEmpty) {
      final loader = PokemonEnrichmentLoader();
      final List<Fusion> refined = [];
      final required = _selectedMoves.map((m) => m.toLowerCase()).toList(growable: false);
      for (final fusion in pre) {
        final combined = await loader.getCombinedMoves(
          fusion.headPokemon,
          fusion.bodyPokemon,
        );
        final combinedLower = combined.map((e) => e.toLowerCase()).toSet();
        final ok = required.every(combinedLower.contains);
        if (ok) refined.add(fusion);
      }
      pre = refined;
    }

    if (!mounted) return;
    setState(() {
      _filteredFusions = pre;
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

  void _setAbilityFilter(String? ability) {
    setState(() {
      _selectedAbility = ability;
    });
    // Reapply filters including abilities
    // ignore: discarded_futures
    _applyFilters();
  }

  // Removed _applyFiltersWithAbilities; unified into _applyFilters()

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Compare',
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Lines selector
          PopupMenuButton<int>(
            tooltip: 'Lines per column',
            icon: const Icon(Icons.view_comfy),
            onSelected: (value) {
              setState(() {
                _numLines = value;
              });
            },
            itemBuilder: (context) => [
              for (final lines in [1, 2, 3])
                PopupMenuItem<int>(
                  value: lines,
                  child: Row(
                    children: [
                      Expanded(child: Text(lines == 1 ? '1 line' : '$lines lines')),
                      if (lines == _numLines)
                        const Icon(
                          Icons.check,
                          size: 18,
                        ),
                    ],
                  ),
                ),
            ],
          ),
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
                  (_selectedTypes.isNotEmpty || _selectedPokemon.isNotEmpty || _selectedAbility != null || _selectedMoves.isNotEmpty)
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
                          const SizedBox(height: 8),
                          // Ability filter (single selection autocomplete)
                          Builder(builder: (context) {
                                TextEditingController? abilityCtrl;
                                FocusNode? abilityFocus;
                                return Autocomplete<String>(
                                  optionsBuilder: (TextEditingValue tev) {
                                    final q = tev.text.trim().toLowerCase();
                                    if (q.isEmpty) {
                                      return _allAbilities.take(20);
                                    }
                                    return _allAbilities
                                        .where((a) => a.toLowerCase().contains(q))
                                        .take(30);
                                  },
                                  displayStringForOption: (opt) => opt,
                                  onSelected: (value) {
                                    _setAbilityFilter(value);
                                    if (abilityCtrl != null) abilityCtrl!.text = value;
                                    abilityFocus?.unfocus();
                                  },
                                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                    abilityCtrl = controller;
                                    abilityFocus = focusNode;
                                    if (_selectedAbility != null && controller.text != _selectedAbility) {
                                      controller.text = _selectedAbility!;
                                    }
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Filter by ability',
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (controller.text.isNotEmpty || _selectedAbility != null)
                                              IconButton(
                                                tooltip: 'Clear',
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  controller.clear();
                                                  _setAbilityFilter(null);
                                                  focusNode.requestFocus();
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                      onChanged: (_) {
                                        // typing only updates suggestions
                                      },
                                    );
                                  },
                                  optionsViewBuilder: (context, onSelected, options) {
                                    final list = options.toList(growable: false);
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(8),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxHeight: 280, minWidth: 280),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: list.length,
                                            itemBuilder: (context, index) {
                                              final ability = list[index];
                                              final already = _selectedAbility == ability;
                                              return ListTile(
                                                dense: true,
                                                title: Text(ability),
                                                trailing: already ? const Icon(Icons.check, color: Colors.green) : null,
                                                onTap: () => onSelected(ability),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),

                           const SizedBox(height: 8),
                           // Moves filter (multi-select up to 4)
                           Builder(builder: (context) {
                             TextEditingController? movesCtrl;
                             FocusNode? movesFocus;
                             return Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Autocomplete<String>(
                                   optionsBuilder: (TextEditingValue tev) {
                                     final q = tev.text.trim().toLowerCase();
                                     if (q.isEmpty) return _allMoves.take(20);
                                     return _allMoves.where((m) => m.toLowerCase().contains(q)).take(30);
                                   },
                                   displayStringForOption: (opt) => opt,
                                   onSelected: (value) {
                                     setState(() {
                                       if (_selectedMoves.contains(value)) return;
                                       if (_selectedMoves.length >= 4) {
                                         ScaffoldMessenger.of(context).showSnackBar(
                                           const SnackBar(content: Text('Maximum 4 moves can be selected')),
                                         );
                                         return;
                                       }
                                       _selectedMoves.add(value);
                                     });
                                     if (movesCtrl != null) movesCtrl!.clear();
                                     movesFocus?.unfocus();
                                     // ignore: discarded_futures
                                     _applyFilters();
                                   },
                                   fieldViewBuilder: (context, controller, focusNode, _) {
                                     movesCtrl = controller;
                                     movesFocus = focusNode;
                                     return TextField(
                                       controller: controller,
                                       focusNode: focusNode,
                                       decoration: InputDecoration(
                                         hintText: _selectedMoves.isEmpty ? 'Filter by moves (max 4)' : 'Add another move',
                                         border: const OutlineInputBorder(),
                                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                         suffixIcon: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             if (_selectedMoves.isNotEmpty)
                                               IconButton(
                                                 tooltip: 'Clear moves',
                                                 icon: const Icon(Icons.clear),
                                                 onPressed: () {
                                                   setState(() {
                                                     _selectedMoves.clear();
                                                   });
                                                   controller.clear();
                                                   // ignore: discarded_futures
                                                   _applyFilters();
                                                   focusNode.requestFocus();
                                                 },
                                               ),
                                           ],
                                         ),
                                       ),
                                     );
                                   },
                                   optionsViewBuilder: (context, onSelected, options) {
                                     final list = options.toList(growable: false);
                                     return Align(
                                       alignment: Alignment.topLeft,
                                       child: Material(
                                         elevation: 4,
                                         borderRadius: BorderRadius.circular(8),
                                         child: ConstrainedBox(
                                           constraints: const BoxConstraints(maxHeight: 280, minWidth: 280),
                                           child: ListView.builder(
                                             padding: EdgeInsets.zero,
                                             itemCount: list.length,
                                             itemBuilder: (context, index) {
                                               final move = list[index];
                                               final already = _selectedMoves.contains(move);
                                               return ListTile(
                                                 dense: true,
                                                 title: Text(move),
                                                 trailing: already ? const Icon(Icons.check, color: Colors.green) : null,
                                                 onTap: () => onSelected(move),
                                               );
                                             },
                                           ),
                                         ),
                                       ),
                                     );
                                   },
                                 ),
                                 const SizedBox(height: 8),
                                 SingleChildScrollView(
                                   scrollDirection: Axis.horizontal,
                                   child: Row(
                                     children: _selectedMoves
                                         .map((m) => Padding(
                                               padding: const EdgeInsets.only(right: 8),
                                               child: Chip(
                                                 label: Text(m, style: const TextStyle(color: Colors.white)),
                                                 backgroundColor: Theme.of(context).colorScheme.primary,
                                                 deleteIcon: const Icon(Icons.close, color: Colors.white),
                                                 onDeleted: () {
                                                   setState(() {
                                                     _selectedMoves.remove(m);
                                                     // ignore: discarded_futures
                                                     _applyFilters();
                                                   });
                                                 },
                                               ),
                                             ))
                                         .toList(),
                                   ),
                                 ),
                               ],
                             );
                           }),
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
                      : Builder(
                        builder: (context) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          double tileWidth;
                          switch (_numLines) {
                            case 1:
                              tileWidth = 300;
                              break;
                            case 2:
                              tileWidth = screenWidth / 2;
                              break;
                            case 3:
                              tileWidth = screenWidth / 3;
                              break;
                            default:
                              tileWidth = 300;
                          }

                          return GridView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _numLines,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              mainAxisExtent: tileWidth,
                            ),
                            itemCount: _filteredFusions.length,
                            itemBuilder: (context, index) {
                              final fusion = _filteredFusions[index];
                          if (_numLines == 1) {
                            return Container(
                              key: ValueKey(fusion.fusionId),
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
                          } else if (_numLines == 2) {
                            return FusionCompareCardMedium(
                              key: ValueKey('medium-${fusion.fusionId}'),
                              fusion: fusion,
                            );
                          } else {
                            return FusionCompareCardSmall(
                              key: ValueKey('small-${fusion.fusionId}'),
                              fusion: fusion,
                            );
                          }
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
