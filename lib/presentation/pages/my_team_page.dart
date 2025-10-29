import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';
import 'package:fusion_box/core/services/my_team_service.dart';
import 'package:fusion_box/core/services/type_effectiveness_service.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_bloc.dart';
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_state.dart';
import 'package:fusion_box/presentation/widgets/pokemon/stream_based_pokemon_icon.dart';
import 'package:fusion_box/core/utils/pokemon_enrichment_loader.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/presentation/widgets/fusion/variant_picker_sheet.dart';
import 'package:fusion_box/presentation/widgets/fusion/fusion_compare_cards.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/core/services/my_team_loadout_service.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';
import 'package:fusion_box/core/services/preferred_sprite_service.dart';
 

class MyTeamPage extends StatefulWidget {
  const MyTeamPage({super.key});

  @override
  State<MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<MyTeamPage> {
  late Future<List<Map<String, int>>> _futureTeam;

  @override
  void initState() {
    super.initState();
    _futureTeam = MyTeamService.getTeam();
  }

  

  Future<void> _refresh() async {
    setState(() {
      _futureTeam = MyTeamService.getTeam();
    });
  }

  void _clearAllIfAny(List<Map<String, int>> team) async {
    if (team.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear team?'),
        content: const Text('This will remove all fusions from your team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await MyTeamService.clearTeam();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team cleared')),
        );
      }
    }
  }

  Future<void> _startAddFlow() async {
    final state = context.read<PokemonListBloc>().state;
    if (state is! PokemonListLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista de Pokémon no está lista aún')),
      );
      return;
    }
    final List<Pokemon> all = state.allPokemon;

    final Pokemon? head = await _pickPokemon(all, title: 'Selecciona 2 Pokémon');
    if (head == null) return;
    final Pokemon? body = await _pickPokemon(all, title: 'Selecciona 2 Pokémon');
    if (body == null) return;

    // If both picks are the same Pokémon, add directly (no direction needed)
    if (head.pokedexNumber == body.pokedexNumber) {
      final result = await MyTeamService.addFusion(
        headId: head.pokedexNumber,
        bodyId: body.pokedexNumber,
      );
      if (!context.mounted) return;
      String message;
      switch (result) {
        case MyTeamService.resultAdded:
          message = 'Fusión añadida a tu equipo';
          await _refresh();
          break;
        case MyTeamService.resultAlreadyExists:
          message = 'Esa fusión ya está en tu equipo';
          break;
        case MyTeamService.resultTeamFull:
          message = 'Tu equipo está lleno';
          break;
        default:
          message = 'No se pudo añadir la fusión';
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final selected = await _chooseFusionDirection(head, body);
    if (!context.mounted || selected == null) return;

    final result = await MyTeamService.addFusion(headId: selected['head'] as int, bodyId: selected['body'] as int);
    if (!context.mounted) return;
    if (result == MyTeamService.resultAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fusión añadida a tu equipo')),
      );
      await _refresh();
    } else if (result == MyTeamService.resultAlreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa fusión ya está en tu equipo')),
      );
    } else if (result == MyTeamService.resultTeamFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu equipo está lleno')),
      );
    }
  }

  Future<Map<String, int>?> _chooseFusionDirection(Pokemon head, Pokemon body) async {
    final repo = instance<SpriteRepository>();
    SpriteData? spriteAB;
    SpriteData? spriteBA;

    Future<SpriteData?> loadSprite(int h, int b) async {
      try {
        SpriteData? s = await repo.getSpecificSprite(h, b);
        s ??= await repo.getAutogenSprite(h, b);
        return s;
      } catch (_) {
        return null;
      }
    }

    // Show the sheet immediately; load both directions in the background
    bool isLoading = true;
    bool started = false;

    return showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Kick off async loads only once after the sheet is built
            if (!started) {
              started = true;
              Future<void>(() async {
                final results = await Future.wait<SpriteData?>([
                  loadSprite(head.pokedexNumber, body.pokedexNumber),
                  loadSprite(body.pokedexNumber, head.pokedexNumber),
                ]);
                spriteAB = results[0];
                spriteBA = results[1];
                if (mounted) {
                  setSheetState(() {
                    isLoading = false;
                  });
                }
              });
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16 + MediaQuery.of(context).padding.top,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: isLoading
                  ? SizedBox(
                      height: 220,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                            SizedBox(height: 12),
                            Text('Cargando fusiones...'),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const Text('Elige dirección de fusión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        // Nota: No cerramos esta hoja al añadir; cada tarjeta de FusionDetails ya tiene su botón de añadir.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[600]!),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${head.name} + ${body.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    FusionCompareCardMedium(
                                      fusion: Fusion(
                                        headPokemon: head,
                                        bodyPokemon: body,
                                        availableSprites: const [],
                                        types: _calculateFusionTypes(head, body),
                                        primarySprite: spriteAB,
                                        stats: null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          final result = await MyTeamService.addFusion(
                                            headId: head.pokedexNumber,
                                            bodyId: body.pokedexNumber,
                                          );
                                          if (!this.context.mounted || !context.mounted) return;
                                          String message;
                                          switch (result) {
                                            case MyTeamService.resultAdded:
                                              message = 'Fusión añadida a tu equipo';
                                              await _refresh();
                                              break;
                                            case MyTeamService.resultAlreadyExists:
                                              message = 'Esa fusión ya está en tu equipo';
                                              break;
                                            case MyTeamService.resultTeamFull:
                                              message = 'Tu equipo está lleno';
                                              break;
                                            default:
                                              message = 'No se pudo añadir la fusión';
                                          }
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text('Agregar'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[600]!),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${body.name} + ${head.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    FusionCompareCardMedium(
                                      fusion: Fusion(
                                        headPokemon: body,
                                        bodyPokemon: head,
                                        availableSprites: const [],
                                        types: _calculateFusionTypes(body, head),
                                        primarySprite: spriteBA,
                                        stats: null,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Center(
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          final result = await MyTeamService.addFusion(
                                            headId: body.pokedexNumber,
                                            bodyId: head.pokedexNumber,
                                          );
                                          if (!this.context.mounted || !context.mounted) return;
                                          String message;
                                          switch (result) {
                                            case MyTeamService.resultAdded:
                                              message = 'Fusión añadida a tu equipo';
                                              await _refresh();
                                              break;
                                            case MyTeamService.resultAlreadyExists:
                                              message = 'Esa fusión ya está en tu equipo';
                                              break;
                                            case MyTeamService.resultTeamFull:
                                              message = 'Tu equipo está lleno';
                                              break;
                                            default:
                                              message = 'No se pudo añadir la fusión';
                                          }
                                          ScaffoldMessenger.of(this.context).showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text('Agregar'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
  // ignore: unused_element
  Widget _fusionChoiceCard({
    required String title,
    required SpriteData? sprite,
    required Pokemon fallbackHead,
    required Pokemon fallbackBody,
    required VoidCallback onVariants,
    required VoidCallback onChoose,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            padding: const EdgeInsets.all(6),
            child: (sprite != null)
                ? SpriteFromSheet(spriteData: sprite, width: 80, height: 80, fit: BoxFit.contain)
                : SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: StreamBasedPokemonIcon(pokemon: fallbackHead, size: 36),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: StreamBasedPokemonIcon(pokemon: fallbackBody, size: 36),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onVariants,
                      icon: const Icon(Icons.layers_outlined, size: 16),
                      label: const Text('Variantes'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: onChoose,
                      icon: const Icon(Icons.check),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Pokemon?> _pickPokemon(List<Pokemon> all, {required String title}) async {
    return showModalBottomSheet<Pokemon>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        String query = '';
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final List<Pokemon> filtered = query.isEmpty
                ? all
                : all.where((p) {
                    final q = query.toLowerCase();
                    return p.name.toLowerCase().contains(q) ||
                        p.pokedexNumber.toString().contains(q);
                  }).toList();
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16 + MediaQuery.of(context).padding.top,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o número',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setSheetState(() => query = v.trim()),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return ListTile(
                          leading: StreamBasedPokemonIconSmall(pokemon: p),
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                '#${p.pokedexNumber.toString().padLeft(3, '0')}',
                                style: TextStyle(color: Colors.grey[600], fontFamily: 'monospace'),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p.types.join(', '),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => Navigator.of(context).pop(p),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Team'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Team'),
              Tab(text: 'Def. Coverage')
            ],
          ),
          actions: [
            FutureBuilder<List<Map<String, int>>>(
              future: _futureTeam,
              builder: (context, snapshot) {
                final team = snapshot.data ?? const <Map<String, int>>[];
                if (team.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Clear team',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _clearAllIfAny(team),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<PokemonListBloc, PokemonListState>(
          builder: (context, state) {
            return FutureBuilder<List<Map<String, int>>>(
              future: _futureTeam,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final team = snapshot.data ?? const <Map<String, int>>[];
                final fusions = _buildLightFusions(state, team);
                return TabBarView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildTeamRows(context, fusions),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildDefensiveTable(context, fusions),
                    ),
                  ],
                );
              },
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final controller = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: controller.animation!,
              builder: (context, _) {
                final onTeamTab = controller.index == 0;
                if (!onTeamTab) return const SizedBox.shrink();
                return FutureBuilder<List<Map<String, int>>>(
                  future: _futureTeam,
                  builder: (context, snapshot) {
                    final team = snapshot.data ?? const <Map<String, int>>[];
                    final bool canAddMore = team.length < 6;
                    return canAddMore
    ? FloatingActionButton(
                            onPressed: _startAddFlow,
                            tooltip: 'Añadir fusión',
                            child: const Icon(Icons.add),
                          )
                        : const SizedBox.shrink();
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Fusion> _buildLightFusions(PokemonListState state, List<Map<String, int>> team) {
    if (state is! PokemonListLoaded) return const <Fusion>[];
    final byId = {for (final p in state.allPokemon) p.pokedexNumber: p};
    final List<Fusion> result = [];
    for (final e in team) {
      final head = byId[e['head']];
      final body = byId[e['body']];
      if (head == null || body == null) continue;
      final types = _calculateFusionTypes(head, body);
      result.add(
        Fusion(
          headPokemon: head,
          bodyPokemon: body,
          availableSprites: const [],
          types: types,
          primarySprite: null,
          stats: null,
        ),
      );
    }
    return result;
  }

  List<String> _calculateFusionTypes(Pokemon head, Pokemon body) {
    final types = <String>[];
    if (head.types.isNotEmpty) types.add(head.types.first);
    final bool bodyIsDualType = body.types.length > 1;
    if (bodyIsDualType) {
      if (!types.contains(body.types[1])) {
        types.add(body.types[1]);
      } else {
        types.add(body.types[0]);
      }
    } else {
      if (!types.contains(body.types[0])) {
        types.add(body.types[0]);
      }
    }
    return types;
  }

  Widget _buildTeamRows(BuildContext context, List<Fusion> fusions) {
    if (fusions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_add_outlined,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('Your team is empty'),
            const SizedBox(height: 4),
            Text(
              'Add fusions from the Fusion Grid',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: fusions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fusion = fusions[index];
        return _TeamRow(
          fusion: fusion,
          onDeleted: () => _refresh(),
        );
      },
    );
  }

  Widget _buildDefensiveTable(BuildContext context, List<Fusion> fusions) {
    final effectiveness = const TypeEffectivenessService();
    final List<double> buckets = [0.0, 0.25, 0.5, 1.0, 2.0, 4.0];
    String labelOf(double b) {
      switch (b) {
        case 0.0:
          return 'x0';
        case 0.25:
          return 'x1/4';
        case 0.5:
          return 'x1/2';
        case 1.0:
          return 'x1';
        case 2.0:
          return 'x2';
        case 4.0:
          return 'x4';
      }
      return 'x?';
    }

    Widget cellBox(Widget child, {Color? color, VoidCallback? onTap}) {
      final box = Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color ?? Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: child,
      );
      if (onTap != null) {
        return InkWell(onTap: onTap, child: box);
      }
      return box;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header row
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text('Type', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                  for (final b in buckets)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 64,
                        child: Center(
                          child: Text(labelOf(b), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (final type in PokemonTypeColors.availableTypes) ...[
                Builder(builder: (_) {
                  final Map<double, List<Fusion>> lists = {
                    for (final b in buckets) b: <Fusion>[],
                  };
                  // fill lists per bucket
                  for (final fusion in fusions) {
                    final map = effectiveness.effectivenessMap(fusion.types);
                    final mult = map[type] ?? 1.0;
                    final chosen = buckets.firstWhere((b) => b == mult, orElse: () => 1.0);
                    lists[chosen]!.add(fusion);
                  }

                  final bool highlightRow =
                      (lists[2.0]!.isNotEmpty || lists[4.0]!.isNotEmpty) &&
                      lists[0.0]!.isEmpty &&
                      lists[0.25]!.isEmpty &&
                      lists[0.5]!.isEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: highlightRow
                          ? BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.5),
                              ),
                            )
                          : null,
                      padding: highlightRow
                          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                          : EdgeInsets.zero,
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: PokemonTypeColors.getTypeColor(type),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final b in buckets)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 64,
                              child: cellBox(
                                Text('${lists[b]!.length}'),
                                color: lists[b]!.length >= 3
                                    ? Colors.orange.withValues(alpha: 0.25)
                                    : null,
                                onTap: lists[b]!.isNotEmpty
                                    ? () => _showFusionListForBucket(type, labelOf(b), lists[b]!)
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    ),
                  );
                }),
              ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFusionListForBucket(String type, String label, List<Fusion> fusions) async {
    if (fusions.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: PokemonTypeColors.getTypeColor(type),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$type — $label',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: fusions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final fusion = fusions[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            StreamBasedPokemonIconSmall(pokemon: fusion.headPokemon),
                            const SizedBox(width: 8),
                            const Icon(Icons.add, size: 18),
                            const SizedBox(width: 8),
                            StreamBasedPokemonIconSmall(pokemon: fusion.bodyPokemon),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final t in fusion.types)
                                    _typeChipSmall(t),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _TypeCoverageTile extends StatelessWidget {
  final String type;
  final List<Fusion> resistant;
  final List<Fusion> weak;
  final VoidCallback onTapResistant;
  final VoidCallback onTapWeak;

  const _TypeCoverageTile({
    required this.type,
    required this.resistant,
    required this.weak,
    required this.onTapResistant,
    required this.onTapWeak,
  });

  @override
  Widget build(BuildContext context) {
    final color = PokemonTypeColors.getTypeColor(type);
    final textColor = Colors.black;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: resistant.isNotEmpty ? onTapResistant : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    children: [
                      const Text('Res', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('${resistant.length}')
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: weak.isNotEmpty ? onTapWeak : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    children: [
                      const Text('Weak', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('${weak.length}')
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FusionThumb extends StatelessWidget {
  final Fusion fusion;
  const _FusionThumb({required this.fusion});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: StreamBasedPokemonIcon(pokemon: fusion.headPokemon, size: 36),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: StreamBasedPokemonIcon(pokemon: fusion.bodyPokemon, size: 36),
          ),
        ],
      ),
    );
  }
}

Widget _typeChipSmall(String type) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: PokemonTypeColors.getTypeColor(type),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Text(
      type,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _TeamRow extends StatefulWidget {
  final Fusion fusion;
  final VoidCallback onDeleted;
  const _TeamRow({required this.fusion, required this.onDeleted});

  @override
  State<_TeamRow> createState() => _TeamRowState();
}

class _TeamRowState extends State<_TeamRow> {
  String? _selectedAbility;
  List<String> _allAbilities = const [];
  final List<String?> _selectedMoves = List<String?>.filled(4, null);
  List<String> _allMoves = const [];
  SpriteData? _currentSprite;
  List<SpriteData> _variants = const [];

  Future<void> _confirmRemove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from team?'),
        content: const Text('This will remove this fusion from your team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await MyTeamService.removeFusion(
        headId: widget.fusion.headPokemon.pokedexNumber,
        bodyId: widget.fusion.bodyPokemon.pokedexNumber,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fusion removed')),
      );
      widget.onDeleted();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentSprite = widget.fusion.primarySprite;
    _loadData();
    if (_currentSprite == null) {
      _loadSprite();
    }
  }

  Future<void> _loadData() async {
    final loader = PokemonEnrichmentLoader();
    final abilities = await loader.getCombinedAbilities(
      widget.fusion.headPokemon,
      widget.fusion.bodyPokemon,
    );
    final moves = await loader.getCombinedMoves(
      widget.fusion.headPokemon,
      widget.fusion.bodyPokemon,
    );
    if (!mounted) return;
    final fusionId = widget.fusion.fusionId;
    final savedAbility = await MyTeamLoadoutService.getAbility(fusionId);
    final savedMoves = await MyTeamLoadoutService.getMoves(fusionId);
    if (!mounted) return;
    setState(() {
      _allAbilities = abilities.toList()..sort();
      _allMoves = moves.toList()..sort();
      _selectedAbility = savedAbility ?? (_allAbilities.isNotEmpty ? _allAbilities.first : null);
      for (int i = 0; i < 4; i++) {
        _selectedMoves[i] = i < savedMoves.length ? savedMoves[i] : null;
      }
    });
  }

  Future<void> _loadSprite() async {
    try {
      final repo = instance<SpriteRepository>();
      final headId = widget.fusion.headPokemon.pokedexNumber;
      final bodyId = widget.fusion.bodyPokemon.pokedexNumber;

      // Try preferred variant first to avoid scanning variants
      final preferred = await PreferredSpriteService.getPreferredVariant(headId, bodyId);
      SpriteData? sprite;
      if (preferred != null && preferred.isNotEmpty) {
        sprite = await repo.getSpecificSprite(headId, bodyId, variant: preferred);
      }

      // Fallbacks: default specific sprite, then autogen
      sprite ??= await repo.getSpecificSprite(headId, bodyId);
      sprite ??= await repo.getAutogenSprite(headId, bodyId);

      if (!mounted) return;
      if (sprite != null) {
        setState(() {
          _currentSprite = sprite;
        });
      }
    } catch (_) {
      // Keep overlapped icons as fallback
    }
  }

  // ignore: unused_element
  Future<void> _openVariantPicker() async {
    final headId = widget.fusion.headPokemon.pokedexNumber;
    final bodyId = widget.fusion.bodyPokemon.pokedexNumber;
    final repo = instance<SpriteRepository>();
    try {
      final variants = await repo.getAllSpriteVariants(headId, bodyId);
      variants.sort((a, b) {
        final av = a.variant;
        final bv = b.variant;
        if (av.isEmpty && bv.isNotEmpty) return -1;
        if (bv.isEmpty && av.isNotEmpty) return 1;
        return av.compareTo(bv);
      });
      if (!mounted) return;
      setState(() {
        _variants = variants;
      });
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: 350,
          child: _variants.isEmpty
              ? Center(child: Text('No variants available', style: TextStyle(color: Colors.grey[400])))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _variants.length,
                  itemBuilder: (context, index) {
                    final s = _variants[index];
                    return InkWell(
                      onTap: () async {
                        await PreferredSpriteService.setPreferredVariant(headId, bodyId, s.variant);
                        if (!mounted) return;
                        setState(() => _currentSprite = s);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: SpriteFromSheet(
                          spriteData: s,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          // Left: sprite and fusion types beneath
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  final headId = widget.fusion.headPokemon.pokedexNumber;
                  final bodyId = widget.fusion.bodyPokemon.pokedexNumber;
                  await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.grey[900],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => FusionVariantPickerSheet(
                      headId: headId,
                      bodyId: bodyId,
                      initial: _currentSprite,
                      onSelected: (s) async {
                        setState(() => _currentSprite = s);
                      },
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[600]!),
                      ),
                      child: (_currentSprite ?? widget.fusion.primarySprite) != null
                          ? SpriteFromSheet(
                              spriteData: (_currentSprite ?? widget.fusion.primarySprite)!,
                              width: 88,
                              height: 88,
                              fit: BoxFit.contain,
                            )
                          : SizedBox(
                              width: 88,
                              height: 88,
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: StreamBasedPokemonIcon(
                                      pokemon: widget.fusion.headPokemon,
                                      size: 40,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: StreamBasedPokemonIcon(
                                      pokemon: widget.fusion.bodyPokemon,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final t in widget.fusion.types) _typeChipSmall(t),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Right: ability selector and 2x2 moves grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ability selector
                Row(
                  children: [
                    const Text('Ability:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedAbility,
                      dropdownColor: Colors.grey[900],
                      items: _allAbilities
                          .map((a) => DropdownMenuItem<String>(
                                value: a,
                                child: Text(a, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ))
                          .toList(),
                      onChanged: (v) async {
                        setState(() => _selectedAbility = v);
                        await MyTeamLoadoutService.saveAbility(widget.fusion.fusionId, v);
                      },
                      iconEnabledColor: Colors.white70,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Moves selectors in 2x2 grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double colWidth = (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(4, (i) => SizedBox(width: colWidth, child: _moveSelector(i))),
                    );
                  },
                ),
              ],
            ),
          ),
            ],
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
            onPressed: _confirmRemove,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _moveSelector(int index) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue tev) {
        final q = tev.text.trim().toLowerCase();
        if (q.isEmpty) return _allMoves.take(20);
        return _allMoves.where((m) => m.toLowerCase().contains(q)).take(30);
      },
      displayStringForOption: (opt) => opt,
      onSelected: (value) async {
        setState(() => _selectedMoves[index] = value);
        await MyTeamLoadoutService.saveMoves(widget.fusion.fusionId, _selectedMoves);
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        controller.text = _selectedMoves[index] ?? '';
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            hintText: 'Move',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.grey[900],
            elevation: 4,
            child: SizedBox(
              width: 280,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final opt = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    onTap: () => onSelected(opt),
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


