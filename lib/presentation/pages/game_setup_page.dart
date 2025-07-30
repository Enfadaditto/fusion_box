import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_event.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_state.dart';
import 'package:fusion_box/presentation/pages/pokemon_selection_page.dart';

class GameSetupPage extends StatelessWidget {
  const GameSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fusion Box - Setup'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: BlocListener<GameSetupBloc, GameSetupState>(
        listener: (context, state) {
          if (state is GamePathSet) {
            // La navegación se manejará en HomePage automáticamente
            // No necesitamos navegar aquí manualmente
          }

          if (state is GameSetupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Game Path Setup Card
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Game Directory Setup (Optional)',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Setting up your Pokemon Infinite Fusion game directory is optional but highly recommended for the best experience.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Look for the folder containing "Graphics" and other game files.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 24),

                        BlocBuilder<GameSetupBloc, GameSetupState>(
                          builder: (context, state) {
                            if (state is GameSetupLoading ||
                                state is GamePathValidating) {
                              return const Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Validating game path...'),
                                  ],
                                ),
                              );
                            }

                            if (state is GamePathInvalid) {
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            state.message,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSelectButton(context),
                                  const SizedBox(height: 12),
                                  _buildSkipButton(context),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _buildSelectButton(context),
                                const SizedBox(height: 12),
                                _buildSkipButton(context),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<GameSetupBloc>().add(SelectGamePath());
        },
        icon: const Icon(Icons.folder_open),
        label: const Text(
          'Select Game Directory',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const PokemonSelectionPage(),
            ),
          );
        },
        icon: const Icon(Icons.skip_next),
        label: const Text(
          'Continue without setup',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
