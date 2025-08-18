import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/core/services/saved_boxes_service.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_bloc.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_event.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';
import 'package:fusion_box/presentation/widgets/pokemon/stream_based_pokemon_icon.dart';

class SavedBoxesPage extends StatefulWidget {
  const SavedBoxesPage({super.key});

  @override
  State<SavedBoxesPage> createState() => _SavedBoxesPageState();
}

class _SavedBoxesPageState extends State<SavedBoxesPage> {
  late Future<List<Map<String, dynamic>>> _futureBoxes;
  final FusionStatsCalculator _stats = FusionStatsCalculator();

  @override
  void initState() {
    super.initState();
    _futureBoxes = SavedBoxesService.getAllBoxes();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureBoxes = SavedBoxesService.getAllBoxes();
    });
  }

  void _useBox(List<int> ids, PokemonListLoaded currentState) {
    final all = currentState.allPokemon;
    final alreadySelected = currentState.selectedPokemon.toSet();
    final byId = {for (final p in all) p.pokedexNumber: p};
    // Append only missing ones, preserving saved order
    for (final id in ids) {
      final p = byId[id];
      if (p != null && !alreadySelected.contains(p)) {
        context.read<PokemonListBloc>().add(TogglePokemonSelection(p));
      }
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved box?'),
        content: Text('"$name" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SavedBoxesService.deleteBox(name);
      if (mounted) _refresh();
    }
  }

  Future<List<_PokemonTotalStats>> _computeTopThree(
    List<int> ids,
    PokemonListLoaded currentState,
  ) async {
    final all = currentState.allPokemon;
    final byId = {for (final p in all) p.pokedexNumber: p};
    final candidates = <_PokemonTotalStats>[];
    for (final id in ids) {
      final pokemon = byId[id];
      if (pokemon == null) continue;
      try {
        final s = await _stats.getStatsFromPokemon(pokemon);
        final total = s.hp + s.attack + s.defense + s.specialAttack + s.specialDefense + s.speed;
        candidates.add(_PokemonTotalStats(pokemon: pokemon, total: total));
      } catch (_) {
        // ignore and continue
      }
    }
    candidates.sort((a, b) => b.total.compareTo(a.total));
    if (candidates.length > 3) {
      return candidates.sublist(0, 3);
    }
    return candidates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Boxes'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
        body: BlocBuilder<PokemonListBloc, PokemonListState>(
        builder: (context, state) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureBoxes,
            builder: (context, snapshot) {
              final boxes = snapshot.data ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (boxes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 56, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      const Text('No saved boxes yet'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: boxes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final box = boxes[index];
                    final name = box['name'] as String;
                    final ids = List<int>.from(box['ids'] as List);
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${ids.length} Pokemon'),
                            const SizedBox(height: 8),
                            if (state is PokemonListLoaded)
                              FutureBuilder<List<_PokemonTotalStats>>(
                                future: _computeTopThree(ids, state),
                                builder: (context, snap) {
                                  final items = snap.data ?? const <_PokemonTotalStats>[];
                                  if (snap.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 24,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                    );
                                  }
                                  if (items.isEmpty) return const SizedBox.shrink();
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: items.map((e) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            StreamBasedPokemonIcon(
                                              pokemon: e.pokemon,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '#${e.pokemon.pokedexNumber} ${e.pokemon.name}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '(${e.total})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: state is PokemonListLoaded
                                      ? () => _useBox(ids, state)
                                      : null,
                                  child: const Text('USE'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _confirmDelete(name),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('DELETE'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        ),
      );
  }
}

class _PokemonTotalStats {
  final Pokemon pokemon;
  final int total;
  const _PokemonTotalStats({required this.pokemon, required this.total});
}


