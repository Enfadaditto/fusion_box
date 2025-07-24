import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_bloc.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_event.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';

import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';
import 'package:fusion_box/presentation/pages/settings_page.dart';
import 'package:fusion_box/presentation/pages/fusion_grid_loading_page.dart';
import 'package:fusion_box/presentation/widgets/common/debug_icon.dart';
import 'package:fusion_box/presentation/widgets/pokemon/cached_pokemon_icon.dart';

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
    // Usar la nueva lógica que considera tanto scroll como cantidad de Pokemon
    // Necesitamos acceder al contexto para obtener el estado actual,
    // pero por simplicidad, mantenemos la lógica original aquí
    // La verificación adicional se hará en el build method
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
    // Ocultar el toast si la lista es muy corta (menos de 5 Pokemon)
    // o si el scroll actual es menor a 200px
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
      ],
      child: BlocListener<FusionGridBloc, FusionGridState>(
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
                          padding: const EdgeInsets.all(16),
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
                              // Selected Pokemon box como sliver
                              SliverToBoxAdapter(
                                child: Container(
                                  margin: const EdgeInsets.all(16),
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
                                          if (state.selectedPokemon.isNotEmpty)
                                            TextButton.icon(
                                              onPressed: () {
                                                context
                                                    .read<PokemonListBloc>()
                                                    .add(
                                                      ClearSelectedPokemon(),
                                                    );
                                              },
                                              icon: const Icon(
                                                Icons.clear_all,
                                                size: 16,
                                              ),
                                              label: const Text('Clear All'),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                              ),
                                            ),
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
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children:
                                              state.selectedPokemon.map((
                                                pokemon,
                                              ) {
                                                return Chip(
                                                  avatar: CachedPokemonIcon(
                                                    pokemon: pokemon,
                                                    size: 24,
                                                  ),
                                                  label: Text(
                                                    '${pokemon.pokedexNumber}. ${pokemon.name}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  onDeleted: () {
                                                    context
                                                        .read<PokemonListBloc>()
                                                        .add(
                                                          RemoveSelectedPokemon(
                                                            pokemon,
                                                          ),
                                                        );
                                                  },
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                );
                                              }).toList(),
                                        ),
                                      if (state.selectedPokemon.length >=
                                          2) ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              // Crear nuevo FusionGridBloc y navegar con transición fluida
                                              final fusionGridBloc =
                                                  sl<FusionGridBloc>();

                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  pageBuilder:
                                                      (
                                                        context,
                                                        animation,
                                                        secondaryAnimation,
                                                      ) => BlocProvider.value(
                                                        value: fusionGridBloc,
                                                        child: FusionGridLoadingPage(
                                                          selectedPokemon:
                                                              state
                                                                  .selectedPokemon,
                                                        ),
                                                      ),
                                                  transitionsBuilder: (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child,
                                                  ) {
                                                    // Transición de fade con scale sutil
                                                    return FadeTransition(
                                                      opacity: animation,
                                                      child: ScaleTransition(
                                                        scale: Tween<double>(
                                                          begin: 0.95,
                                                          end: 1.0,
                                                        ).animate(
                                                          CurvedAnimation(
                                                            parent: animation,
                                                            curve:
                                                                Curves
                                                                    .easeOutCubic,
                                                          ),
                                                        ),
                                                        child: child,
                                                      ),
                                                    );
                                                  },
                                                  transitionDuration:
                                                      const Duration(
                                                        milliseconds: 400,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.grid_view),
                                            label: const Text(
                                              'Generate Fusion Grid',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              // Header para la lista de Pokemon
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

                              // Lista de Pokemon como sliver
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final pokemon = state.filteredPokemon[index];
                                  final isSelected = state.selectedPokemon
                                      .contains(pokemon);

                                  return ListTile(
                                    leading: CachedPokemonIconSmall(
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
        ),
      ),
    );
  }
}
