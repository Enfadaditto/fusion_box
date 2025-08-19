import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_bloc.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_event.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_state.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_event.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_bloc.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_event.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_state.dart';

import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';
import 'package:fusion_box/presentation/pages/settings_page.dart';
import 'package:fusion_box/presentation/pages/fusion_grid_loading_page.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_details_dialog.dart';
import 'package:fusion_box/presentation/widgets/pokemon/stream_based_pokemon_icon.dart';
import 'package:fusion_box/core/services/settings_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fusion_box/core/services/saved_boxes_service.dart';
import 'package:fusion_box/presentation/pages/saved_boxes_page.dart';
import 'package:fusion_box/core/utils/pokemon_enrichment_loader.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';
import 'package:fusion_box/core/services/logger_service.dart';

class PokemonSelectionPage extends StatefulWidget {
  const PokemonSelectionPage({super.key});

  @override
  State<PokemonSelectionPage> createState() => _PokemonSelectionPageState();
}

class _PokemonSelectionPageState extends State<PokemonSelectionPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _selectedScrollController = ScrollController();
  bool _showBackToTop = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut, // Curva más dramática
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<bool> _handleSaveBox(BuildContext context, String name, List<int> ids) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name')),
      );
      return false;
    }
    await SavedBoxesService.saveBox(trimmed, ids);
    if (!mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "$trimmed"')), 
    );
    return true;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _selectedScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showBackToTop = _scrollController.offset > 200;
    if (showBackToTop != _showBackToTop) {
      setState(() {
        _showBackToTop = showBackToTop;
      });

      if (_showBackToTop) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _checkBackToTopVisibility(int filteredPokemonCount) {
    final shouldShow =
        _scrollController.offset > 200 && filteredPokemonCount > 4;

    if (shouldShow != _showBackToTop) {
      setState(() {
        _showBackToTop = shouldShow;
      });

      if (_showBackToTop) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => instance<PokemonListBloc>()..add(LoadPokemonList()),
        ),
        BlocProvider(create: (context) => instance<FusionGridBloc>()),
        BlocProvider(
          create: (context) => instance<GameSetupBloc>()..add(CheckGamePath()),
        ),
        BlocProvider(
          create: (context) => instance<SettingsBloc>()..add(LoadSettings()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<FusionGridBloc, FusionGridState>(
            listener: (context, state) {
              if (state is FusionGridError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          BlocListener<SettingsBloc, SettingsState>(
            listener: (context, state) {
              if (state is SettingsLoaded) {
                // Force a rebuild of the entire Pokemon list when settings change
                setState(() {});
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pokemon Fusion Box'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              Builder(
                builder: (innerCtx) => IconButton(
                  tooltip: 'Saved Boxes',
                  icon: const Icon(Icons.inventory_2_outlined),
                  onPressed: () {
                    final pokemonListBloc = innerCtx.read<PokemonListBloc>();
                    Navigator.of(innerCtx).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: pokemonListBloc,
                          child: const SavedBoxesPage(),
          ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: BlocBuilder<PokemonListBloc, PokemonListState>(
            builder: (context, state) {
              if (state is PokemonListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PokemonListError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PokemonListBloc>().add(
                            LoadPokemonList(),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is PokemonListLoaded) {
                // Verificar si el toast debe ocultarse cuando la lista es muy corta
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkBackToTopVisibility(state.filteredPokemon.length);
                });

                final media = MediaQuery.of(context);
                final isLandscape = media.orientation == Orientation.landscape;
                final isPhone = media.size.shortestSide < 600;
                final useLandscapeSplit = isLandscape && isPhone;

                if (useLandscapeSplit) {
                  final leftPad = media.padding.left + 12;
                  final rightPad = media.padding.right + 12;
                  return Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: leftPad, right: rightPad),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left panel: search, filters and selected box
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(top: 12, bottom: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(
                                        top: 16,
                                        left: 12,
                                        right: 12,
                                        bottom: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: _searchController,
                                            decoration: InputDecoration(
                                              hintText: 'Search by name or #Dex',
                                              prefixIcon: const Icon(Icons.search),
                                              suffixIcon: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (_searchController.text.isNotEmpty)
                                                    IconButton(
                                                      tooltip: 'Clear',
                                                      icon: const Icon(Icons.clear),
                                                      onPressed: () {
                                                        _searchController.clear();
                                                        context.read<PokemonListBloc>().add(
                                                              const SearchPokemon(''),
                                                            );
                                                        setState(() {});
                                                      },
                                                    ),
                                                  IconButton(
                                                    tooltip: _showSearchFilters ? 'Hide filters' : 'Show filters',
                                                    icon: AnimatedRotation(
                                                      duration: const Duration(milliseconds: 200),
                                                      turns: _showSearchFilters ? 0.25 : 0.0,
                                                      child: const Icon(Icons.chevron_right),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _showSearchFilters = !_showSearchFilters;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                            onChanged: (query) {
                                              context.read<PokemonListBloc>().add(
                                                    SearchPokemon(query),
                                                  );
                                              setState(() {});
                                            },
                                          ),
                                          AnimatedCrossFade(
                                            firstChild: const SizedBox.shrink(),
                                            secondChild: Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  _TypesFilter(),
                                                  const SizedBox(height: 8),
                                                  _AbilityFilter(
                                                    onSelect: (ability) {
                                                      context.read<PokemonListBloc>().add(
                                                            SearchPokemon(ability ?? ''),
                                                          );
                                                    },
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _MovesFilter(),
                                                ],
                                              ),
                                            ),
                                            crossFadeState: _showSearchFilters
                                                ? CrossFadeState.showSecond
                                                : CrossFadeState.showFirst,
                                            duration: const Duration(milliseconds: 250),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    BlocBuilder<GameSetupBloc, GameSetupState>(
                                      builder: (context, gameState) {
                                        if (!(gameState is GamePathNotSet || gameState is GamePathCleared)) {
                                          return const SizedBox.shrink();
                                        }
                                        return FutureBuilder<bool>(
                                          future: SharedPreferences.getInstance().then(
                                            (prefs) => prefs.getBool('game_setup_info_banner_seen') != true,
                                          ),
                                          builder: (context, snapshot) {
                                            final shouldShow = snapshot.data ?? false;
                                            if (!shouldShow) return const SizedBox.shrink();
                                            return _GameSetupInfoBanner(shouldShow: true);
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Selected Pokemon box (same as portrait)
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.withValues(alpha: 0.3),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Theme.of(context).cardColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.catching_pokemon,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text('Selected Pokemon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const Spacer(),
                                              if (state.selectedPokemon.isNotEmpty) ...[
                                                PopupMenuButton<String>(
                                                  tooltip: 'Actions',
                                                  itemBuilder: (context) => const [
                                                    PopupMenuItem(value: 'sort_name', child: Text('Sort A-Z')),
                                                    PopupMenuItem(value: 'sort_dex', child: Text('Sort #Dex')),
                                                    PopupMenuItem(value: 'reorder', child: Text('Reorder...')),
                                                    PopupMenuDivider(),
                                                    PopupMenuItem(value: 'save', child: Text('Save...')),
                                                  ],
                                                  onSelected: (value) async {
                                                    if (value == 'sort_name') {
                                                      context.read<PokemonListBloc>().add(SortSelectedByName());
                                                    } else if (value == 'sort_dex') {
                                                      context.read<PokemonListBloc>().add(SortSelectedByDex());
                                                    } else if (value == 'reorder') {
                                                      showModalBottomSheet(
                                                        context: context,
                                                        isScrollControlled: true,
                                                        shape: const RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                        ),
                                                        builder: (ctx) {
                                                          final pokemonListBloc = context.read<PokemonListBloc>();
                                                          return BlocProvider.value(
                                                            value: pokemonListBloc,
                                                            child: DraggableScrollableSheet(
                                                              expand: false,
                                                              initialChildSize: 0.6,
                                                              minChildSize: 0.4,
                                                              maxChildSize: 0.9,
                                                              builder: (sheetContext, scrollController) {
                                                                return BlocBuilder<PokemonListBloc, PokemonListState>(
                                                                  builder: (builderContext, sheetState) {
                                                                    if (sheetState is! PokemonListLoaded) {
                                                                      return const SizedBox.shrink();
                                                                    }
                                                                    final current = sheetState.selectedPokemon;
                                                                    return Column(
                                                                      children: [
                                                                        const SizedBox(height: 8),
                                                                        Container(
                                                                          height: 4,
                                                                          width: 36,
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.grey.withValues(alpha: 0.4),
                                                                            borderRadius: BorderRadius.circular(2),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 12),
                                                                        const Text('Reorder selected Pokemon', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                        const SizedBox(height: 8),
                                                                        Expanded(
                                                                          child: PrimaryScrollController(
                                                                            controller: scrollController,
                                                                            child: ReorderableListView.builder(
                                                                              buildDefaultDragHandles: false,
                                                                              physics: const BouncingScrollPhysics(),
                                                                              itemCount: current.length,
                                                                              onReorder: (oldIndex, newIndex) {
                                                                                pokemonListBloc.add(ReorderSelectedPokemon(oldIndex, newIndex));
                                                                              },
                                                                              itemBuilder: (context, index) {
                                                                                final p = current[index];
                                                                                return ListTile(
                                                                                  key: ValueKey('reorder_${p.pokedexNumber}_${p.name}'),
                                                                                  leading: StreamBasedPokemonIcon(pokemon: p, size: 28),
                                                                                  title: Text('${p.pokedexNumber}. ${p.name}'),
                                                                                  trailing: ReorderableDragStartListener(
                                                                                    index: index,
                                                                                    child: const Icon(Icons.drag_handle),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SafeArea(
                                                                          top: false,
                                                                          child: Padding(
                                                                            padding: const EdgeInsets.all(12),
                                                                            child: SizedBox(
                                                                              width: double.infinity,
                                                                              child: OutlinedButton(
                                                                                onPressed: () => Navigator.of(sheetContext).pop(),
                                                                                child: const Text('Done'),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    } else if (value == 'save') {
                                                      final nameController = TextEditingController();
                                                      String? errorText;
                                                      bool submitting = false;
                                                      await showDialog<void>(
                                                        context: context,
                                                        builder: (ctx) {
                                                          return StatefulBuilder(
                                                            builder: (ctx, setLocalState) {
                                                              return AlertDialog(
                                                                title: const Text('Save selection as box'),
                                                                content: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    TextField(
                                                                      controller: nameController,
                                                                      autofocus: true,
                                                                      textInputAction: TextInputAction.done,
                                                                      decoration: InputDecoration(
                                                                        labelText: 'Box name',
                                                                        errorText: errorText,
                                                                      ),
                                                                      onSubmitted: (_) async {
                                                                        if (!submitting) {
                                                                          setLocalState(() => submitting = true);
                                                                          final ok = await _handleSaveBox(context, nameController.text, state.selectedPokemon.map((p) => p.pokedexNumber).toList());
                                                                          if (ok && mounted) Navigator.of(ctx).pop();
                                                                          if (mounted) setLocalState(() => submitting = false);
                                                                        }
                                                                      },
                                                                    ),
                                                                  ],
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.of(ctx).pop(),
                                                                    child: const Text('Cancel'),
                                                                  ),
                                                                  ElevatedButton(
                                                                    onPressed: submitting
                                                                        ? null
                                                                        : () async {
                                                                            setLocalState(() => submitting = true);
                                                                            final name = nameController.text.trim();
                                                                            if (name.isEmpty) {
                                                                              setLocalState(() => errorText = 'Please enter a name');
                                                                              submitting = false;
                                                                              return;
                                                                            }
                                                                            final ok = await _handleSaveBox(context, name, state.selectedPokemon.map((p) => p.pokedexNumber).toList());
                                                                            if (ok && mounted) Navigator.of(ctx).pop();
                                                                            if (mounted) setLocalState(() => submitting = false);
                                                                          },
                                                                    child: const Text('Save'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                      );
                                                    }
                                                  },
                                                  child: const Icon(Icons.tune, size: 18),
                                                ),
                                                IconButton(
                                                  tooltip: 'Clear All',
                                                  icon: const Icon(Icons.delete_outline),
                                                  onPressed: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Clear all selected?'),
                                                        content: const Text('This will remove all selected Pokemon.'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(ctx).pop(false),
                                                            child: const Text('Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () => Navigator.of(ctx).pop(true),
                                                            child: const Text('Clear All'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      context.read<PokemonListBloc>().add(ClearSelectedPokemon());
                                                    }
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          if (state.selectedPokemon.isEmpty)
                                            SizedBox(
                                              height: 100,
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.touch_app, color: Colors.grey[600], size: 32),
                                                    const SizedBox(height: 8),
                                                    Text('No Pokemon selected', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                                    const SizedBox(height: 4),
                                                    Text('Tap Pokemon below to add them', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            StreamBuilder<bool>(
                                              stream: SettingsNotificationService().simpleIconsStream,
                                              initialData: SettingsNotificationService().currentValue,
                                              builder: (context, snapshot) {
                                                final useSimpleIcons = snapshot.data ?? true;
                                            return SizedBox(
                                              height: 100,
                                                  child: Scrollbar(
                                                    controller: _selectedScrollController,
                                                    thumbVisibility: true,
                                                    thickness: 4,
                                                    radius: const Radius.circular(12),
                                                    child: SingleChildScrollView(
                                                      controller: _selectedScrollController,
                                                      physics: const BouncingScrollPhysics(),
                                                      child: Wrap(
                                                        spacing: 8,
                                                        runSpacing: useSimpleIcons ? 0 : 8,
                                                        children: state.selectedPokemon.map((pokemon) {
                                                          if (useSimpleIcons) {
                                                            return Chip(
                                                              avatar: StreamBasedPokemonIcon(
                                                                pokemon: pokemon,
                                                            size: 20,
                                                              ),
                                                              label: Text('${pokemon.pokedexNumber}. ${pokemon.name}', style: const TextStyle(fontSize: 12)),
                                                              onDeleted: () {
                                                                context.read<PokemonListBloc>().add(RemoveSelectedPokemon(pokemon));
                                                              },
                                                              deleteIcon: const Icon(Icons.close, size: 16),
                                                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                            );
                                                          } else {
                                                            return Chip(
                                                              avatar: StreamBasedPokemonIcon(
                                                                pokemon: pokemon,
                                                            size: 20,
                                                              ),
                                                              label: const SizedBox.shrink(),
                                                              labelPadding: EdgeInsets.zero,
                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                              padding: EdgeInsets.zero,
                                                              onDeleted: () {
                                                                context.read<PokemonListBloc>().add(RemoveSelectedPokemon(pokemon));
                                                              },
                                                              deleteIcon: const Icon(Icons.close, size: 16),
                                                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                            );
                                                          }
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          if (state.selectedPokemon.length >= 10) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'This may take a while (~${state.selectedPokemon.length * (state.selectedPokemon.length - 1)} combinations)',
                                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (state.selectedPokemon.length >= 2) ...[
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 48,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  final fusionGridBloc = instance<FusionGridBloc>();
                                                  final settingsBloc = context.read<SettingsBloc>();
                                                  Navigator.of(context).push(
                                                    PageRouteBuilder(
                                                      pageBuilder: (context, animation, secondaryAnimation) => MultiBlocProvider(
                                                        providers: [
                                                          BlocProvider.value(value: fusionGridBloc),
                                                          BlocProvider.value(value: settingsBloc),
                                                        ],
                                                        child: FusionGridLoadingPage(selectedPokemon: state.selectedPokemon),
                                                      ),
                                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                        return FadeTransition(
                                                          opacity: animation,
                                                          child: ScaleTransition(
                                                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                                            child: child,
                                                          ),
                                                        );
                                                      },
                                                      transitionDuration: const Duration(milliseconds: 400),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.grid_view),
                                                label: const Text('Generate Fusion Grid'),
                                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right panel: full list with local back-to-top overlay
                            Expanded(
                              child: Stack(
                                children: [
                                  CustomScrollView(
                                    controller: _scrollController,
                                    slivers: [
                                      SliverToBoxAdapter(
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.list,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'All Pokemon (${state.filteredPokemon.length})',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                              if (state.filteredPokemon.length < state.allPokemon.length) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primaryContainer,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    'filtered',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate((context, index) {
                                          final pokemon = state.filteredPokemon[index];
                                          final isSelected = state.selectedPokemon.contains(pokemon);
                                          return ListTile(
                                            leading: StreamBuilder<bool>(
                                              stream: SettingsNotificationService().simpleIconsStream,
                                              initialData: SettingsNotificationService().currentValue,
                                              builder: (context, snapshot) {
                                                final useSimpleIcons = snapshot.data ?? true;
                                                final shouldBob = !useSimpleIcons && isSelected;
                                                return _Bobbing(
                                                  enabled: shouldBob,
                                                  child: StreamBasedPokemonIconSmall(pokemon: pokemon),
                                                );
                                              },
                                            ),
                                            title: Text(
                                              pokemon.name,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Row(
                                              children: [
                                                Text(
                                                  '#${pokemon.pokedexNumber.toString().padLeft(3, '0')}',
                                                  style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace'),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  pokemon.types.join(', '),
                                                  style: TextStyle(color: Colors.grey[700]),
                                                ),
                                              ],
                                            ),
                                            trailing: isSelected
                                                ? const Icon(Icons.check_circle, color: Colors.green)
                                                : const Icon(Icons.add_circle_outline),
                                            onTap: () {
                                              context.read<PokemonListBloc>().add(TogglePokemonSelection(pokemon));
                                            },
                                            onLongPress: () {
                                              FusionDetailsDialog.showForPokemon(context, pokemon);
                                            },
                                          );
                                        }, childCount: state.filteredPokemon.length),
                                      ),
                                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                                    ],
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 24,
                                    right: 24,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _opacityAnimation,
                                        child: Material(
                                          elevation: 6,
                                          borderRadius: BorderRadius.circular(24),
                                          color: Colors.grey[850]?.withValues(alpha: 0.90),
                                          child: InkWell(
                                            onTap: _scrollToTop,
                                            borderRadius: BorderRadius.circular(24),
                                            child: Container(
                                              height: 36,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                                                  const SizedBox(width: 4),
                                                  const Text('Back to top', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                                  const SizedBox(width: 4),
                                                  Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 16),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // No global back-to-top overlay in landscape; it's inside the right panel
                    ],
                  );
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                            bottom: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by name or #Dex',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchController.text.isNotEmpty)
                                        IconButton(
                                          tooltip: 'Clear',
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            context.read<PokemonListBloc>().add(
                                                  const SearchPokemon(''),
                                                );
                                            setState(() {});
                                          },
                                        ),
                                      IconButton(
                                        tooltip: _showSearchFilters ? 'Hide filters' : 'Show filters',
                                        icon: AnimatedRotation(
                                          duration: const Duration(milliseconds: 200),
                                          turns: _showSearchFilters ? 0.25 : 0.0, // right (>) to down (v)
                                          child: const Icon(Icons.chevron_right),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showSearchFilters = !_showSearchFilters;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                onChanged: (query) {
                                  context.read<PokemonListBloc>().add(
                                        SearchPokemon(query),
                                      );
                                  setState(() {}); // refresh clear button visibility
                                },
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _TypesFilter(),
                                      const SizedBox(height: 8),
                                      _AbilityFilter(
                                        onSelect: (ability) {
                                          context.read<PokemonListBloc>().add(
                                                SearchPokemon(ability ?? ''),
                                              );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      _MovesFilter(),
                                    ],
                                  ),
                                ),
                                crossFadeState: _showSearchFilters
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 250),
                              ),
                            ],
                          ),                        ),

                        Expanded(
                          child: CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              // Game Setup Info Banner
                              SliverToBoxAdapter(
                                child: BlocBuilder<
                                  GameSetupBloc,
                                  GameSetupState
                                >(
                                  builder: (context, gameState) {
                                    if (!(gameState is GamePathNotSet ||
                                        gameState is GamePathCleared)) {
                                      return const SizedBox.shrink();
                                    }
                                    return FutureBuilder<bool>(
                                      future: SharedPreferences.getInstance()
                                          .then(
                                            (prefs) =>
                                                prefs.getBool(
                                                  'game_setup_info_banner_seen',
                                                ) !=
                                                true,
                                          ),
                                      builder: (context, snapshot) {
                                        final shouldShow =
                                            snapshot.data ?? false;
                                        if (!shouldShow) {
                                          return const SizedBox.shrink();
                                        }
                                        return _GameSetupInfoBanner(
                                          shouldShow: true,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              // Selected Pokemon box
                              SliverToBoxAdapter(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(context).cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.catching_pokemon,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Selected Pokemon',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (state.selectedPokemon.isNotEmpty) ...[
                                            PopupMenuButton<String>(
                                              tooltip: 'Actions',
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'sort_name',
                                                  child: Text('Sort A-Z'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'sort_dex',
                                                  child: Text('Sort #Dex'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'reorder',
                                                  child: Text('Reorder...'),
                                                ),
                                                const PopupMenuDivider(),
                                                const PopupMenuItem(
                                                  value: 'save',
                                                  child: Text('Save...'),
                                                ),
                                              ],
                                              onSelected: (value) async {
                                                if (value == 'sort_name') {
                                                  context.read<PokemonListBloc>().add(SortSelectedByName());
                                                } else if (value == 'sort_dex') {
                                                  context.read<PokemonListBloc>().add(SortSelectedByDex());
                                                } else if (value == 'reorder') {
                                                  // Open bottom sheet with ReorderableListView
                                                  // ignore: use_build_context_synchronously
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    shape: const RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                                    ),
                                                    builder: (ctx) {
                                                      final pokemonListBloc = context.read<PokemonListBloc>();
                                                      return BlocProvider.value(
                                                        value: pokemonListBloc,
                                                        child: DraggableScrollableSheet(
                                                          expand: false,
                                                          initialChildSize: 0.6,
                                                          minChildSize: 0.4,
                                                          maxChildSize: 0.9,
                                                          builder: (sheetContext, scrollController) {
                                                            return BlocBuilder<PokemonListBloc, PokemonListState>(
                                                              builder: (builderContext, sheetState) {
                                                                if (sheetState is! PokemonListLoaded) {
                                                                  return const SizedBox.shrink();
                                                                }
                                                                final current = sheetState.selectedPokemon;
                                                                return Column(
                                                                  children: [
                                                                    const SizedBox(height: 8),
                                                                    Container(
                                                                      height: 4,
                                                                      width: 36,
                                                                      decoration: BoxDecoration(
                                                                        color: Colors.grey.withValues(alpha: 0.4),
                                                                        borderRadius: BorderRadius.circular(2),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                    const Text('Reorder selected Pokemon', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                    const SizedBox(height: 8),
                                                                    Expanded(
                                                                      child: PrimaryScrollController(
                                                                        controller: scrollController,
                                                                        child: ReorderableListView.builder(
                                                                          buildDefaultDragHandles: false,
                                                                          physics: const BouncingScrollPhysics(),
                                                                          itemCount: current.length,
                                                                          onReorder: (oldIndex, newIndex) {
                                                                            pokemonListBloc.add(ReorderSelectedPokemon(oldIndex, newIndex));
                                                                          },
                                                                          itemBuilder: (context, index) {
                                                                            final p = current[index];
                                                                            return ListTile(
                                                                              key: ValueKey('reorder_${p.pokedexNumber}_${p.name}'),
                                                                              leading: StreamBasedPokemonIcon(pokemon: p, size: 28),
                                                                              title: Text('${p.pokedexNumber}. ${p.name}'),
                                                                              trailing: ReorderableDragStartListener(
                                                                                index: index,
                                                                                child: const Icon(Icons.drag_handle),
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SafeArea(
                                                                      top: false,
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.all(12),
                                                                        child: SizedBox(
                                                                          width: double.infinity,
                                                                          child: OutlinedButton(
                                                                            onPressed: () => Navigator.of(sheetContext).pop(),
                                                                            child: const Text('Done'),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  );
                                                } else if (value == 'save') {
                                                  final nameController = TextEditingController();
                                                  String? errorText;
                                                  bool submitting = false;
                                                  await showDialog<void>(
                                                    context: context,
                                                    builder: (ctx) {
                                                      return StatefulBuilder(
                                                        builder: (ctx, setLocalState) {
                                                          return AlertDialog(
                                                            title: const Text('Save selection as box'),
                                                            content: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                TextField(
                                                                  controller: nameController,
                                                                  autofocus: true,
                                                                  textInputAction: TextInputAction.done,
                                                                  decoration: InputDecoration(
                                                                    labelText: 'Box name',
                                                                    errorText: errorText,
                                                                  ),
                                                                  onSubmitted: (_) async {
                                                                    // Trigger save on Enter
                                                                    if (!submitting) {
                                                                      setLocalState(() => submitting = true);
                                                                      final ok = await _handleSaveBox(context, nameController.text, state.selectedPokemon.map((p) => p.pokedexNumber).toList());
                                                                      if (ok && mounted) Navigator.of(ctx).pop();
                                                                      if (mounted) setLocalState(() => submitting = false);
                                                                    }
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.of(ctx).pop(),
                                                                child: const Text('Cancel'),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: submitting
                                                                    ? null
                                                                    : () async {
                                                                        setLocalState(() => submitting = true);
                                                                        // Validate name
                                                                        final name = nameController.text.trim();
                                                                        if (name.isEmpty) {
                                                                          setLocalState(() => errorText = 'Please enter a name');
                                                                          submitting = false;
                                                                          return;
                                                                        }
                                                                        final ok = await _handleSaveBox(context, name, state.selectedPokemon.map((p) => p.pokedexNumber).toList());
                                                                        if (ok && mounted) Navigator.of(ctx).pop();
                                                                        if (mounted) setLocalState(() => submitting = false);
                                                                      },
                                                                child: const Text('Save'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.tune, size: 18),
                                                  SizedBox(width: 4),
                                                  Text('Actions'),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Clear All',
                                              icon: const Icon(Icons.delete_outline),
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Clear all selected?'),
                                                    content: const Text('This will remove all selected Pokemon.'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.of(ctx).pop(true),
                                                        child: const Text('Clear All'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  // ignore: use_build_context_synchronously
                                                  context.read<PokemonListBloc>().add(ClearSelectedPokemon());
                                                }
                                              },
                                            ),
                                            
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (state.selectedPokemon.isEmpty)
                                        SizedBox(
                                          height: 120,
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.touch_app,
                                                  color: Colors.grey[600],
                                                  size: 32,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'No Pokemon selected',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Tap Pokemon below to add them',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        StreamBuilder<bool>(
                                          stream: SettingsNotificationService().simpleIconsStream,
                                          initialData: SettingsNotificationService().currentValue,
                                          builder: (context, snapshot) {
                                            final useSimpleIcons = snapshot.data ?? true;

                                            return SizedBox(
                                              height: 120,
                                              child: Scrollbar(
                                                controller: _selectedScrollController,
                                                thumbVisibility: true,
                                                thickness: 4,
                                                radius: const Radius.circular(12),
                                                child: SingleChildScrollView(
                                                  controller: _selectedScrollController,
                                                  physics: const BouncingScrollPhysics(),
                                                  child: Wrap(
                                                    spacing: 8,
                                                    runSpacing: useSimpleIcons ? 0 : 8,
                                                    children: state.selectedPokemon.map((pokemon) {
                                                      if (useSimpleIcons) {
                                                        return Chip(
                                                          avatar: StreamBasedPokemonIcon(
                                                            pokemon: pokemon,
                                                            size: 24,
                                                          ),
                                                          label: Text(
                                                            '${pokemon.pokedexNumber}. ${pokemon.name}',
                                                            style: const TextStyle(fontSize: 12),
                                                          ),
                                                          onDeleted: () {
                                                            context.read<PokemonListBloc>().add(
                                                                  RemoveSelectedPokemon(pokemon),
                                                                );
                                                          },
                                                          deleteIcon: const Icon(Icons.close, size: 16),
                                                          backgroundColor: Theme.of(context)
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                        );
                                                      } else {
                                                        return Chip(
                                                          avatar: StreamBasedPokemonIcon(
                                                            pokemon: pokemon,
                                                            size: 24,
                                                          ),
                                                          label: const SizedBox.shrink(),
                                                          labelPadding: EdgeInsets.zero,
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                                          padding: EdgeInsets.zero,
                                                          onDeleted: () {
                                                            context.read<PokemonListBloc>().add(
                                                                  RemoveSelectedPokemon(pokemon),
                                                                );
                                                          },
                                                          deleteIcon: const Icon(Icons.close, size: 16),
                                                          backgroundColor: Theme.of(context)
                                                              .colorScheme
                                                              .surfaceContainerHighest,
                                                        );
                                                      }
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      if (state.selectedPokemon.length >= 10) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'This may take a while (~${state.selectedPokemon.length * (state.selectedPokemon.length - 1)} combinations)',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (state.selectedPokemon.length >= 2) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              final fusionGridBloc = instance<FusionGridBloc>();
                                              final settingsBloc = context.read<SettingsBloc>();

                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) => MultiBlocProvider(
                                                    providers: [
                                                      BlocProvider.value(value: fusionGridBloc),
                                                      BlocProvider.value(value: settingsBloc),
                                                    ],
                                                    child: FusionGridLoadingPage(
                                                      selectedPokemon: state.selectedPokemon,
                                                    ),
                                                  ),
                                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    return FadeTransition(
                                                      opacity: animation,
                                                      child: ScaleTransition(
                                                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                                                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                                                        ),
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                                  transitionDuration: const Duration(milliseconds: 400),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.grid_view),
                                            label: const Text('Generate Fusion Grid'),
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              // Pokemon list header
                              SliverToBoxAdapter(
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.list,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'All Pokemon (${state.filteredPokemon.length})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                      if (state.filteredPokemon.length <
                                          state.allPokemon.length) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            'filtered',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              // Pokemon list
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final pokemon = state.filteredPokemon[index];
                                  final isSelected = state.selectedPokemon
                                      .contains(pokemon);

                                  return ListTile(
                                    leading: StreamBuilder<bool>(
                                      stream: SettingsNotificationService().simpleIconsStream,
                                      initialData: SettingsNotificationService().currentValue,
                                      builder: (context, snapshot) {
                                        final useSimpleIcons = snapshot.data ?? true;
                                        final shouldBob = !useSimpleIcons && isSelected;
                                        return _Bobbing(
                                          enabled: shouldBob,
                                          child: StreamBasedPokemonIconSmall(
                                            pokemon: pokemon,
                                          ),
                                        );
                                      },
                                    ),
                                    title: Text(
                                      pokemon.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          '#${pokemon.pokedexNumber.toString().padLeft(3, '0')}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          pokemon.types.join(', '),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing:
                                        isSelected
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                            : const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                    onTap: () {
                                      context.read<PokemonListBloc>().add(
                                        TogglePokemonSelection(pokemon),
                                      );
                                    },
                                    onLongPress: () {
                                      // Mostrar detalles del Pokemon individual
                                      FusionDetailsDialog.showForPokemon(context, pokemon);
                                    },
                                  );
                                }, childCount: state.filteredPokemon.length),
                              ),

                              // Padding final
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Toast "Back to top" personalizado con animación controlada
                    Positioned(
                      top: 88,
                      left: MediaQuery.of(context).size.width * 0.32,
                      right: MediaQuery.of(context).size.width * 0.32,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _opacityAnimation,
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.grey[850]?.withValues(alpha: 0.90),
                            child: InkWell(
                              onTap: _scrollToTop,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.keyboard_arrow_up,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Back to top',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_up,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const Center(child: Text('Unknown state'));
            },
          ),
          ),
          bottomNavigationBar: const SizedBox.shrink(),
        ),
      ),
  );
  }
}

class _GameSetupInfoBanner extends StatefulWidget {
  final bool shouldShow;
  const _GameSetupInfoBanner({required this.shouldShow});

  @override
  State<_GameSetupInfoBanner> createState() => _GameSetupInfoBannerState();
}

class _AbilityFilter extends StatefulWidget {
  final void Function(String? ability) onSelect;
  const _AbilityFilter({required this.onSelect});

  @override
  State<_AbilityFilter> createState() => _AbilityFilterState();
}

class _MovesFilter extends StatefulWidget {
  @override
  State<_MovesFilter> createState() => _MovesFilterState();
}

class _TypesFilter extends StatefulWidget {
  @override
  State<_TypesFilter> createState() => _TypesFilterState();
}

class _TypesFilterState extends State<_TypesFilter> {
  final List<String> _selectedTypes = [];

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        if (_selectedTypes.length >= 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 2 types can be selected')),
          );
          return;
        }
        _selectedTypes.add(type);
      }
    });
    context.read<PokemonListBloc>().add(UpdateTypesFilter(List<String>.from(_selectedTypes)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: [
              if (_selectedTypes.length < 2)
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue tev) {
                      final q = tev.text.trim().toLowerCase();
                      final all = PokemonTypeColors.availableTypes;
                      if (q.isEmpty) return all;
                      return all.where((t) => t.toLowerCase().contains(q));
                    },
                    displayStringForOption: (opt) => opt,
                    onSelected: (value) {
                      _toggleType(value);
                    },
                    fieldViewBuilder: (context, controller, focusNode, _) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Filter by types (max 2)',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (controller.text.isNotEmpty)
                                IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    focusNode.requestFocus();
                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
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
                            constraints: const BoxConstraints(maxHeight: 280, minWidth: 320),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final type = list[index];
                                final isSelected = _selectedTypes.contains(type);
                                return ListTile(
                                  dense: true,
                                  leading: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: PokemonTypeColors.getTypeColor(type),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  title: Text(type),
                                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                                  onTap: () => onSelected(type),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                const SizedBox.shrink(),
              ..._selectedTypes.map((t) => Chip(
                    label: Text(t, style: const TextStyle(color: Colors.white)),
                      backgroundColor: PokemonTypeColors.getTypeColor(t),
                      deleteIcon: const Icon(Icons.close, color: Colors.white),
                      onDeleted: () => _toggleType(t),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(horizontal: 4, vertical: 4)
                  )),
            ],
          ),
      ],
    );
  }
}

class _MovesFilterState extends State<_MovesFilter> {
  List<String> _allMoves = const [];
  final List<String> _selected = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final moves = await PokemonEnrichmentLoader().getAllMoves();
      if (!mounted) return;
      setState(() {
        _allMoves = moves;
        _loading = false;
      });
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('PokemonSelectionPage: failed to load all moves: $e'),
          s,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _allMoves = const [];
        _loading = false;
      });
    }
  }

  void _apply() {
    context.read<PokemonListBloc>().add(UpdateMovesFilter(List<String>.from(_selected)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _allMoves.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
                final targetW = maxW.clamp(220.0, 400.0);
                return SizedBox(
                  width: targetW,
                  child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue tev) {
                  final q = tev.text.trim().toLowerCase();
                  if (q.isEmpty) return const Iterable<String>.empty();
                  return _allMoves.where((m) => m.toLowerCase().contains(q)).take(30);
                },
                displayStringForOption: (opt) => opt,
                onSelected: (value) {
                  if (_selected.contains(value)) return;
                  if (_selected.length >= 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maximum 4 moves')),
                    );
                    return;
                  }
                  setState(() {
                    _selected.add(value);
                  });
                  _apply();
                },
                fieldViewBuilder: (context, controller, focusNode, _) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Filter by moves (up to 4)',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                                focusNode.requestFocus();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                    onChanged: (_) {
                      // refresh clear button visibility
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      // rely on onSelected
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
                        constraints: const BoxConstraints(maxHeight: 280, minWidth: 320),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final move = list[index];
                            final already = _selected.contains(move);
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
            );
          },
        ),
            if (_selected.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() => _selected.clear());
                  _apply();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear moves'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selected
              .map(
                (m) => Chip(
                  label: Text(m),
                  onDeleted: () {
                    setState(() => _selected.remove(m));
                    _apply();
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AbilityFilterState extends State<_AbilityFilter> {
  List<String> _abilities = const [];
  String? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final abilities = await PokemonEnrichmentLoader().getAllAbilities();
      if (!mounted) return;
      setState(() {
        _abilities = abilities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _abilities = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _abilities.isEmpty) {
      return const SizedBox.shrink();
    }
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _abilities.where((a) => a.toLowerCase().contains(q)).take(30);
      },
      displayStringForOption: (opt) => opt,
      onSelected: (value) {
        setState(() {
          _selected = value;
        });
        widget.onSelect(value);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (_selected != null && controller.text != _selected) {
          controller.text = _selected!;
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
                if ((controller.text.isNotEmpty) || _selected != null)
                  IconButton(
                    tooltip: 'Clear ability filter',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selected = null;
                      });
                      controller.clear();
                      widget.onSelect(null);
                      focusNode.requestFocus();
                    },
                  ),
              ],
            ),
          ),
          onChanged: (value) {
            if (_selected != null) {
              setState(() => _selected = null);
            }
            // Do not call onSelect here; wait for onSelected or clear
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
              constraints: const BoxConstraints(maxHeight: 300, minWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final ability = list[index];
                  return ListTile(
                    dense: true,
                    title: Text(ability),
                    onTap: () => onSelected(ability),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bobbing extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _Bobbing({required this.enabled, required this.child});

  @override
  State<_Bobbing> createState() => _BobbingState();
}

class _BobbingState extends State<_Bobbing> {
  bool _isUp = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant _Bobbing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _start();
      } else {
        _stop();
      }
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      setState(() {
        _isUp = !_isUp;
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (_isUp) {
      setState(() {
        _isUp = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Transform.translate(
      offset: Offset(0, _isUp ? -3.0 : 0.0),
      child: widget.child,
    );
  }
}

class _GameSetupInfoBannerState extends State<_GameSetupInfoBanner> {
  bool _visible = true;
  bool _timerStarted = false;

  @override
  void initState() {
    super.initState();
    _visible = widget.shouldShow;
    if (_visible && !_timerStarted) {
      _timerStarted = true;
      Future.delayed(const Duration(seconds: 5), _hideBanner);
    }
  }

  void _hideBanner() async {
    if (!_visible) return;
    setState(() => _visible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('game_setup_info_banner_seen', true);
  }

  @override
  void dispose() {
    if (_visible) {
      _hideBanner();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
        _hideBanner();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withAlpha(77)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Game folder setup is optional but recommended for better performance. Configure it in Settings.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
