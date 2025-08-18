import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_event.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_state.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_bloc.dart';
import 'package:fusion_box/presentation/pages/fusion_grid_page.dart';
import 'package:fusion_box/presentation/widgets/pokemon/cached_pokemon_icon.dart';

class FusionGridLoadingPage extends StatefulWidget {
  final List<Pokemon> selectedPokemon;

  const FusionGridLoadingPage({super.key, required this.selectedPokemon});

  @override
  State<FusionGridLoadingPage> createState() => _FusionGridLoadingPageState();
}

class _FusionGridLoadingPageState extends State<FusionGridLoadingPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar la animación de rotación
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Configurar animación de fade-in para el contenido
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );

    // Iniciar animaciones y generación con delays para mejor fluidez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();

      // Delay antes de iniciar la generación pesada (permite que la UI se establezca)
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          context.read<FusionGridBloc>().add(
            GenerateFusionGridEvent(widget.selectedPokemon),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FusionGridBloc, FusionGridState>(
      listener: (context, state) {
        if (state is FusionGridLoaded) {
          // Navegar al grid cuando esté completamente listo con transición fluida
          final fusionGridBloc = context.read<FusionGridBloc>();
          final settingsBloc = context.read<SettingsBloc>();
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: fusionGridBloc),
                          BlocProvider.value(value: settingsBloc),
                        ],
                        child: const FusionGridPage(),
                      ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                // Transición de slide desde la derecha con fade
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }

        if (state is FusionGridError) {
          // Mostrar error y volver atrás
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<FusionGridBloc, FusionGridState>(
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pokémon seleccionados en círculo
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          children: [
                            // Círculo de fondo
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Pokémon distribuidos en círculo
                            ...List.generate(
                              widget.selectedPokemon.length.clamp(
                                0,
                                8,
                              ), // Máximo 8 para que se vea bien
                              (index) {
                                final angle =
                                    (2 * math.pi * index) /
                                    widget.selectedPokemon.length.clamp(1, 8);
                                final radius = 70.0;
                                final x = 100 + radius * math.cos(angle) - 20;
                                final y = 100 + radius * math.sin(angle) - 20;

                                return Positioned(
                                  left: x,
                                  top: y,
                                  child: TweenAnimationBuilder<double>(
                                    duration: Duration(
                                      milliseconds: 400 + (index * 100),
                                    ),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: CachedPokemonIcon(
                                            pokemon:
                                                widget.selectedPokemon[index],
                                            size: 62,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            // Centro con rueda de carga personalizada
                            Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: RotationTransition(
                                    turns: _rotationController,
                                    child: Icon(
                                      Icons.autorenew,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Título
                      TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 2),
                        tween: Tween(begin: 0.95, end: 1.05),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Text(
                              'Creating Fusion Grid',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                        onEnd: () {
                          // Cuando termine una animación, empezar la siguiente en dirección contraria
                          if (mounted) {
                            setState(
                              () {},
                            ); // Trigger rebuild para reiniciar la animación
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Información del grid
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${widget.selectedPokemon.length}×${widget.selectedPokemon.length} Grid',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${widget.selectedPokemon.length * widget.selectedPokemon.length} fusion combinations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Texto de carga
                      Text(
                        'Generating sprites and calculating types...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'This may take a few moments',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
