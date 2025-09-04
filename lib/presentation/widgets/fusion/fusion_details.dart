import 'package:flutter/material.dart';
import 'package:fusion_box/domain/entities/fusion.dart';
import 'package:fusion_box/domain/entities/pokemon_stats.dart';
import 'package:fusion_box/presentation/widgets/fusion/sprite_from_sheet.dart';
import 'package:fusion_box/core/utils/fusion_stats_calculator.dart';
import 'package:fusion_box/core/utils/stat_color_utils.dart';
import 'package:fusion_box/core/utils/pokemon_enrichment_loader.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/presentation/widgets/pokemon/stream_based_pokemon_icon.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';
import 'package:fusion_box/domain/entities/sprite_data.dart';
import 'package:fusion_box/core/services/preferred_sprite_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_event.dart';
import 'package:fusion_box/core/services/logger_service.dart';
import 'package:fusion_box/core/services/type_effectiveness_service.dart';
import 'package:fusion_box/core/constants/pokemon_type_colors.dart';
import 'package:fusion_box/core/services/my_team_service.dart';
import 'package:fusion_box/presentation/widgets/fusion/variant_picker_sheet.dart';

class FusionDetailsContent extends StatefulWidget {
  final Fusion? fusion;
  final Pokemon? pokemon;
  final FusionGridBloc? fusionGridBloc;

  const FusionDetailsContent({
    super.key,
    this.fusion,
    this.pokemon,
    this.fusionGridBloc,
  }) : assert(
          (fusion != null) ^ (pokemon != null),
          'Provide exactly one of fusion or pokemon',
        );

  @override
  State<FusionDetailsContent> createState() => _FusionDetailsContentState();
}

class _FusionDetailsContentState extends State<FusionDetailsContent> {
  PokemonStats? _fusionStats;
  bool _isLoadingStats = true;
  String? _statsError;
  Set<String>? _abilities;
  bool _isLoadingAbilities = true;
  List<String>? _moves;
  bool _isLoadingMoves = true;
  SpriteData? _currentSprite;

  void _showDefensiveSchemeForTypes(List<String> types) {
    final TypeEffectivenessService svc = const TypeEffectivenessService();
    final Map<double, List<String>> buckets = svc.groupedEffectiveness(types);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final double width = MediaQuery.of(context).size.width;
        final double horizontalPadding = 16;
        const int columns = 3; // fixed columns for consistent chip width
        final double chipWidth = (width - horizontalPadding * 2 - (columns - 1) * 6) / columns;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Defensive effectiveness',
                  style: TextStyle(color: Colors.grey[200], fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Types: ${types.join(' / ')}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 12),
                ..._buildEffectivenessSection('x0', buckets[0.0] ?? const <String>[], chipWidth),
                ..._buildEffectivenessSection('x1/4', buckets[0.25] ?? const <String>[], chipWidth),
                ..._buildEffectivenessSection('x1/2', buckets[0.5] ?? const <String>[], chipWidth),
                ..._buildEffectivenessSection('x1', buckets[1.0] ?? const <String>[], chipWidth),
                ..._buildEffectivenessSection('x2', buckets[2.0] ?? const <String>[], chipWidth),
                ..._buildEffectivenessSection('x4', buckets[4.0] ?? const <String>[], chipWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildEffectivenessSection(String label, List<String> types, double chipWidth) {
    if (types.isEmpty) return const <Widget>[];
    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: types
            .map(
              (t) => SizedBox(
                width: chipWidth,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: PokemonTypeColors.getTypeColor(t),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    t,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ];
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PokemonTypeColors.getTypeColor(type),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(
        type,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.fusion != null) {
      _loadFusionStats();
      _loadAbilities();
      _currentSprite = widget.fusion!.primarySprite;
    } else {
      _isLoadingStats = true;
      _loadPokemonStats();
      _loadPokemonAbilities();
      _loadPokemonMoves();
    }
  }

  @override
  void didUpdateWidget(covariant FusionDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fusion?.fusionId != widget.fusion?.fusionId ||
        oldWidget.pokemon?.pokedexNumber != widget.pokemon?.pokedexNumber) {
      // Reset state and reload stats when the fusion changes
      _fusionStats = null;
      _statsError = null;
      _isLoadingStats = widget.fusion != null;
      if (widget.fusion != null) {
        _loadFusionStats();
        _abilities = null;
        _isLoadingAbilities = true;
        _loadAbilities();
        _currentSprite = widget.fusion!.primarySprite;
      } else {
        _isLoadingStats = true;
        _abilities = null;
        _isLoadingAbilities = true;
        _fusionStats = null;
        _loadPokemonStats();
        _loadPokemonAbilities();
        _moves = null;
        _isLoadingMoves = true;
        _loadPokemonMoves();
        _currentSprite = null;
      }
    }
  }

  Future<void> _openSpriteCarousel() async {
    if (widget.fusion == null) return;
    final headId = widget.fusion!.headPokemon.pokedexNumber;
    final bodyId = widget.fusion!.bodyPokemon.pokedexNumber;
    // Capture bloc if available (may not exist in comparator route)
    FusionGridBloc? capturedGridBloc = widget.fusionGridBloc;
    if (capturedGridBloc == null) {
      try {
        capturedGridBloc = context.read<FusionGridBloc>();
      } catch (_) {
        capturedGridBloc = null;
      }
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FusionVariantPickerSheet(
        headId: headId,
        bodyId: bodyId,
        initial: _currentSprite ?? widget.fusion!.primarySprite,
        onSelected: (sel) async {
          await PreferredSpriteService.setPreferredVariant(headId, bodyId, sel.variant);
          if (!mounted) return;
          setState(() {
            _currentSprite = sel;
          });
        },
      ),
    );
  }

  Future<void> _loadFusionStats() async {
    // Si la fusión ya tiene estadísticas calculadas, usarlas directamente
    if (widget.fusion!.stats != null) {
      setState(() {
        _fusionStats = widget.fusion!.stats;
        _isLoadingStats = false;
      });
      return;
    }

    // Si no tiene stats, calcularlas (fallback para compatibilidad)
    try {
      final calculator = FusionStatsCalculator();
      final stats = await calculator.getStatsFromFusion(
        widget.fusion!.headPokemon,
        widget.fusion!.bodyPokemon,
      );
      
      if (mounted) {
        setState(() {
          _fusionStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('FusionDetails: failed to compute stats for ${widget.fusion?.fusionId}: $e'),
          s,
        );
      } catch (_) {}
      if (mounted) {
        setState(() {
          _statsError = e.toString();
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadAbilities() async {
    try {
      final loader = PokemonEnrichmentLoader();
      final combined = await loader.getCombinedAbilities(
        widget.fusion!.headPokemon,
        widget.fusion!.bodyPokemon,
      );
      if (!mounted) return;
      setState(() {
        _abilities = combined;
        _isLoadingAbilities = false;
      });
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('FusionDetails: failed to load abilities for fusion ${widget.fusion?.fusionId}: $e'),
          s,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _abilities = const {};
        _isLoadingAbilities = false;
      });
    }
  }

  Future<void> _loadPokemonAbilities() async {
    try {
      final loader = PokemonEnrichmentLoader();
      final list = await loader.getAbilitiesOfPokemon(widget.pokemon!);
      if (!mounted) return;
      setState(() {
        _abilities = list.toSet();
        _isLoadingAbilities = false;
      });
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('FusionDetails: failed to load abilities for pokemon ${widget.pokemon?.pokedexNumber}: $e'),
          s,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _abilities = const {};
        _isLoadingAbilities = false;
      });
    }
  }

  Future<void> _loadPokemonMoves() async {
    try {
      final loader = PokemonEnrichmentLoader();
      final list = await loader.getMovesOfPokemon(widget.pokemon!);
      if (!mounted) return;
      setState(() {
        _moves = list;
        _isLoadingMoves = false;
      });
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('FusionDetails: failed to load moves for pokemon ${widget.pokemon?.pokedexNumber}: $e'),
          s,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _moves = const [];
        _isLoadingMoves = false;
      });
    }
  }

  Future<void> _loadPokemonStats() async {
    try {
      final calculator = FusionStatsCalculator();
      final stats = await calculator.getStatsFromPokemon(widget.pokemon!);
      if (!mounted) return;
      setState(() {
        _fusionStats = stats;
        _isLoadingStats = false;
      });
    } catch (e, s) {
      try {
        instance.get<LoggerService>().logError(
          Exception('FusionDetails: failed to load pokemon stats for ${widget.pokemon?.pokedexNumber}: $e'),
          s,
        );
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _statsError = e.toString();
        _isLoadingStats = false;
      });
    }
  }

  Widget _buildAbilitiesSection() {
    if (_isLoadingAbilities) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading abilities...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final list = _abilities?.toList();
    list?.sort();
    if (list == null || list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 2,
            runSpacing: 2,
            children: [
              for (final ability in list)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    ability,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Loading stats...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_statsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red[300]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load stats',
                style: TextStyle(fontSize: 12, color: Colors.red[300]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_fusionStats == null) {
      return const SizedBox.shrink();
    }

    final totalStats = _fusionStats!.hp + 
                      _fusionStats!.attack + 
                      _fusionStats!.defense + 
                      _fusionStats!.specialAttack + 
                      _fusionStats!.specialDefense + 
                      _fusionStats!.speed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('HP', _fusionStats!.hp),
          _buildStatRow('Attack', _fusionStats!.attack),
          _buildStatRow('Defense', _fusionStats!.defense),
          _buildStatRow('Sp. Atk', _fusionStats!.specialAttack),
          _buildStatRow('Sp. Def', _fusionStats!.specialDefense),
          _buildStatRow('Speed', _fusionStats!.speed),
          const Divider(color: Colors.grey, height: 24),
          _buildStatRow('Total', totalStats, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildStatRow(String statName, int statValue, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              statName,
              style: TextStyle(
                fontSize: isTotal ? 13 : 12,
                color: isTotal ? Colors.white : Colors.grey[400],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (!isTotal) ...[
                  Expanded(
                    child: LinearProgressIndicator(
                      value: statValue / 255,
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        StatColorUtils.getStatColor(statValue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Spacer(),
                ],
                SizedBox(
                  width: isTotal ? 40 : 30,
                  child: Text(
                    statValue.toString(),
                    style: TextStyle(
                      fontSize: isTotal ? 13 : 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.fusion != null) ...[
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
                      widget.fusion!.headPokemon.name,
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
                      widget.fusion!.bodyPokemon.name,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Single Pokemon info
            Column(
              children: [
                Text(
                  widget.pokemon!.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.pokemon!.types.join(' / '),
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, size: 18, color: Colors.white70),
                      tooltip: 'Show defensive effectiveness',
                      onPressed: () => _showDefensiveSchemeForTypes(widget.pokemon!.types),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Big Pokemon icon (respects simple/live setting)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: StreamBasedPokemonIcon(
                pokemon: widget.pokemon!,
                size: 120,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (widget.fusion != null) ...[
            // Fusion Sprite with integrated small action button
            Stack(
              children: [
                GestureDetector(
                  onTap: _openSpriteCarousel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[600]!),
                    ),
                    child: (_currentSprite ?? widget.fusion!.primarySprite) != null
                        ? SpriteFromSheet(
                            spriteData: (_currentSprite ?? widget.fusion!.primarySprite)!,
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
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final headId = widget.fusion!.headPokemon.pokedexNumber;
                      final bodyId = widget.fusion!.bodyPokemon.pokedexNumber;
                      final result = await MyTeamService.addFusion(headId: headId, bodyId: bodyId);
                      if (!mounted) return;
                      String message;
                      switch (result) {
                        case MyTeamService.resultAdded:
                          message = 'Added to My Team';
                          break;
                        case MyTeamService.resultAlreadyExists:
                          message = 'Already in My Team';
                          break;
                        case MyTeamService.resultTeamFull:
                          message = 'Team is full (6)';
                          break;
                        default:
                          message = 'Could not add to team';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.group_add_outlined, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          if (widget.fusion != null) ...[
            // Types
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.fusion!.types
                          .map((t) => _buildTypeChip(t))
                          .toList(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 18, color: Colors.white70),
                  tooltip: 'Show defensive effectiveness',
                  onPressed: () => _showDefensiveSchemeForTypes(widget.fusion!.types),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          _buildAbilitiesSection(),

          // Autogenerated sprite indicator
          if (widget.fusion?.primarySprite?.isAutogenerated == true) ...[
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
          
          const SizedBox(height: 16),
          
          // Stats Section
          _buildStatsSection(),

          // Compact action removed from here; now integrated into the sprite area

          // Moves section (only for single Pokemon)
          if (widget.fusion == null) ...[
            const SizedBox(height: 24),
            if (_isLoadingMoves)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading moves...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if ((_moves ?? const []).isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moves',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _moves!
                          .take(30)
                          .map((m) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
} 

class _SpriteVariantPickerSheet extends StatefulWidget {
  final int headId;
  final int bodyId;
  final SpriteData? initial;
  final FusionGridBloc? fusionGridBloc;
  final ValueChanged<SpriteData> onSelected;

  const _SpriteVariantPickerSheet({
    required this.headId,
    required this.bodyId,
    required this.initial,
    required this.fusionGridBloc,
    required this.onSelected,
  });

  @override
  State<_SpriteVariantPickerSheet> createState() => _SpriteVariantPickerSheetState();
}

class _SpriteVariantPickerSheetState extends State<_SpriteVariantPickerSheet> {
  late final PageController _pageController;
  List<SpriteData> _variants = const [];
  SpriteData? _tempSelection;
  bool _isLoading = true;
  bool _hasTried = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    setState(() {
      _isLoading = true;
    });
    final repo = instance<SpriteRepository>();
    List<SpriteData> variants = [];
    try {
      variants = await repo.getAllSpriteVariants(widget.headId, widget.bodyId);
      // Orden estable: base primero ('') y luego variantes por nombre
      variants.sort((a, b) {
        final av = a.variant;
        final bv = b.variant;
        if (av.isEmpty && bv.isNotEmpty) return -1;
        if (bv.isEmpty && av.isNotEmpty) return 1;
        return av.compareTo(bv);
      });
      int attempts = 0;
      while (variants.isEmpty && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 350));
        variants = await repo.getAllSpriteVariants(widget.headId, widget.bodyId);
        attempts++;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _variants = variants;
      _isLoading = false;
      _hasTried = true;
      if (_variants.isNotEmpty) {
        int initialIndex = 0;
        if (widget.initial != null) {
          final found = _variants.indexWhere((s) => s.variant == widget.initial!.variant);
          if (found >= 0) initialIndex = found;
        }
        _tempSelection = _variants[initialIndex];
        _currentIndex = initialIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(initialIndex);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Downloading variants…',
                        style: TextStyle(color: Colors.grey[300]),
                      ),
                      if (_hasTried) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadVariants,
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  )
                : (_variants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_empty, color: Colors.grey[500]),
                            const SizedBox(height: 8),
                            Text('No variants available yet', style: TextStyle(color: Colors.grey[400])),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _loadVariants, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              if (index >= 0 && index < _variants.length) {
                                setState(() {
                                  _currentIndex = index;
                                  _tempSelection = _variants[index];
                                });
                              }
                            },
                            itemCount: _variants.length,
                            itemBuilder: (context, index) {
                              final s = _variants[index];
                              return Center(
                                child: SpriteFromSheet(
                                  spriteData: s,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                          if (_variants.length > 1) ...[
                            Positioned(
                              left: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                                  onPressed: _currentIndex > 0
                                      ? () {
                                          _pageController.previousPage(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                                  onPressed: _currentIndex < _variants.length - 1
                                      ? () {
                                          _pageController.nextPage(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOut,
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ],
                      )),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _tempSelection == null
                        ? null
                        : () async {
                            final sel = _tempSelection!;
                            await PreferredSpriteService.setPreferredVariant(
                              widget.headId,
                              widget.bodyId,
                              sel.variant,
                            );
                            if (widget.fusionGridBloc != null) {
                              widget.fusionGridBloc!.add(
                                UpdateFusionSpriteVariant(
                                  headId: widget.headId,
                                  bodyId: widget.bodyId,
                                  sprite: sel,
                                ),
                              );
                            }
                            widget.onSelected(sel);
                            if (mounted) Navigator.of(context).pop();
                          },
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}