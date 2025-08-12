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
import 'package:fusion_box/presentation/widgets/common/debug_icon.dart';
import 'package:fusion_box/presentation/widgets/pokemon/stream_based_pokemon_icon.dart';
import 'package:fusion_box/core/services/settings_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PokemonSelectionPage extends StatefulWidget {
  const PokemonSelectionPage({super.key});

  @override
  State<PokemonSelectionPage> createState() => _PokemonSelectionPageState();
}

class _PokemonSelectionPageState extends State<PokemonSelectionPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
          create: (context) => sl<PokemonListBloc>()..add(LoadPokemonList()),
        ),
        BlocProvider(create: (context) => sl<FusionGridBloc>()),
        BlocProvider(
          create: (context) => sl<GameSetupBloc>()..add(CheckGamePath()),
        ),
        BlocProvider(
          create: (context) => sl<SettingsBloc>()..add(LoadSettings()),
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
              //TODO: REMOVE FOR RELEASE
              const DebugIcon(),
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
          body: BlocBuilder<PokemonListBloc, PokemonListState>(
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
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search Pokemon...',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon:
                                  _searchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          context.read<PokemonListBloc>().add(
                                            SearchPokemon(''),
                                          );
                                        },
                                      )
                                      : null,
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
                            },
                          ),
                        ),

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
                                            'Selected Pokemon (${state.selectedPokemon.length})',
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
                                                  value: 'clear',
                                                  child: Text('Clear All'),
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
                                                } else if (value == 'clear') {
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
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (state.selectedPokemon.isEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Column(
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
                                         )
                                      else
                                        StreamBuilder<bool>(
                                          stream: SettingsNotificationService().simpleIconsStream,
                                          initialData: SettingsNotificationService().currentValue,
                                          builder: (context, snapshot) {
                                            final useSimpleIcons = snapshot.data ?? true;

                                            return Wrap(
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
                                      // CTA moved to sticky bottom bar
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
                                    leading: StreamBasedPokemonIconSmall(
                                      pokemon: pokemon,
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
          bottomNavigationBar: BlocBuilder<PokemonListBloc, PokemonListState>(
            builder: (context, state) {
              if (state is! PokemonListLoaded || state.selectedPokemon.length < 2) {
                return const SizedBox.shrink();
              }

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final fusionGridBloc = sl<FusionGridBloc>();
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
                ),
              );
            },
          ),
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
