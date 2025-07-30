import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_event.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<GameSetupBloc>()..add(CheckGamePath()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: BlocListener<GameSetupBloc, GameSetupState>(
          listener: (context, state) {
            if (state is GameSetupError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }

            // Solo mostrar snackbar cuando realmente se actualiza la ruta
            if (state is GamePathSet) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Game path updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }

            if (state is GamePathCleared) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Game path cleared successfully!'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game Path Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Game Directory (Optional)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Setting up your Pokemon Infinite Fusion game directory is optional but highly recommended for the best experience.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<GameSetupBloc, GameSetupState>(
                          builder: (context, state) {
                            if (state is GameSetupLoading) {
                              return const Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Checking current path...'),
                                ],
                              );
                            }

                            if (state is GamePathSet ||
                                state is GamePathVerified) {
                              final gamePath =
                                  state is GamePathSet
                                      ? state.gamePath
                                      : (state as GamePathVerified).gamePath;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Path:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: SelectableText(
                                      gamePath,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          context.read<GameSetupBloc>().add(
                                            SelectGamePath(),
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Change Path'),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed:
                                            () => _showClearDialog(context),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Clear Path'),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          backgroundColor: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No game path configured',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<GameSetupBloc>().add(
                                      SelectGamePath(),
                                    );
                                  },
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Set Game Path'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // App Info Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'App Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('App Name', 'Pokemon Fusion Box'),
                        _buildInfoRow('Version', '1.1.0'),
                        _buildInfoRow('Developer', 'Enfadaditto'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Clear Game Path'),
            content: const Text(
              'Are you sure you want to clear the current game path? '
              'You will need to configure it again to use the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _clearGamePath(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  void _clearGamePath(BuildContext context) {
    context.read<GameSetupBloc>().add(ClearGamePath());
  }
}
