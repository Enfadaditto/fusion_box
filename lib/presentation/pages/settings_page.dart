import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_event.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_state.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_bloc.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_event.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_state.dart';
import 'package:fusion_box/domain/entities/pokemon.dart';
import 'package:fusion_box/presentation/widgets/pokemon/cached_pokemon_icon.dart';
import 'package:fusion_box/presentation/widgets/pokemon/pokemon_live_icon.dart';
import 'package:fusion_box/presentation/widgets/common/cache_debug_widget.dart';
import 'package:fusion_box/core/services/permission_service.dart';
import 'package:fusion_box/presentation/widgets/common/portrait_lock.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PortraitLock(
      child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<GameSetupBloc>()..add(CheckGamePath()),
        ),
        BlocProvider(
          create: (context) => sl<SettingsBloc>()..add(LoadSettings()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<GameSetupBloc, GameSetupState>(
              listener: (context, state) {
                if (state is GameSetupError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

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

                if (state is StoragePermissionDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Settings',
                        onPressed: () {
                          PermissionService.showPermissionDeniedDialog(context);
                        },
                      ),
                    ),
                  );
                }
              },
            ),
            BlocListener<SettingsBloc, SettingsState>(
              listener: (context, state) {
                if (state is SettingsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: SafeArea(
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

                              if (state is StoragePermissionRequesting) {
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
                                    Text('Requesting storage permissions...'),
                                  ],
                                );
                              }

                              if (state is StoragePermissionGranted) {
                                return const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Permissions granted! Selecting directory...',
                                    ),
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
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
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
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
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

                  // App Settings Section
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
                                Icons.settings,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'App Settings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          BlocBuilder<SettingsBloc, SettingsState>(
                            builder: (context, state) {
                              if (state is SettingsLoading) {
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
                                    Text('Loading settings...'),
                                  ],
                                );
                              }

                              if (state is SettingsLoaded) {
                                return Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text(
                                        'Use Simple Icons',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Use rounded colors to make the app faster (recommended for slow devices)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      value: state.useSimpleIcons,
                                      onChanged: (value) {
                                        context.read<SettingsBloc>().add(
                                          ToggleSimpleIcons(value),
                                        );
                                      },
                                      contentPadding: const EdgeInsets.only(
                                        left: 0,
                                        right: 0,
                                      ),
                                      secondary:
                                          state.useSimpleIcons
                                              ? CachedPokemonIcon(
                                                pokemon: const Pokemon(
                                                  pokedexNumber: 132,
                                                  name: 'Ditto',
                                                  types: ['Normal'],
                                                ),
                                                size: 32.0,
                                              )
                                              : PokemonLiveIcon(isLive: true),
                                    ),
                                    const SizedBox(height: 16),
                                    SwitchListTile(
                                      title: const Text(
                                        'Same Pokemon Fusions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Include same Pokemon fusions in addition to different Pokemon fusions',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      value: state.useAxAFusions,
                                      onChanged: (value) {
                                        context.read<SettingsBloc>().add(
                                          ToggleAxAFusions(value),
                                        );
                                      },
                                      contentPadding: const EdgeInsets.only(
                                        left: 0,
                                        right: 0,
                                      ),
                                      secondary:
                                          state.useAxAFusions
                                              ? Image.asset(
                                                'assets/images/132.132f.png',
                                                width: 32.0,
                                                height: 32.0,
                                                fit: BoxFit.contain,
                                              )
                                              : Container(
                                                width: 32.0,
                                                height: 32.0,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[900],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.grey[600]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.block,
                                                      color: Colors.grey[600],
                                                      size: 16,
                                                    ),
                                                    const SizedBox(height: 1),
                                                    Text(
                                                      'Disabled',
                                                      style: TextStyle(
                                                        fontSize: 6,
                                                        color: Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                    ),
                                  ],
                                );
                              }

                              if (state is SettingsError) {
                                return Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
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
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cache Debug Section (only in debug mode)
                  if (const bool.fromEnvironment('dart.vm.product') == false)
                    const CacheDebugWidget(),

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
      ),
    ));
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
