import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_box/injection_container.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_event.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_state.dart';
import 'package:fusion_box/core/services/sprite_download_service.dart';

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
                              'Game Directory',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                                      OutlinedButton.icon(
                                        onPressed:
                                            () => _showClearDialog(context),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Clear Path'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
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

                // Sprite Download Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildSpriteDownloadSection(),
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
                        const SizedBox(height: 12),
                        const Text(
                          'A tool for exploring Pokemon fusions from Pokemon Infinite Fusion.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
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

  Widget _buildSpriteDownloadSection() {
    final downloadService = sl<SpriteDownloadService>();

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Sprite Downloads',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Automatically download missing fusion sprites from the official server.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: downloadService.isDownloadEnabled,
                  onChanged: (value) async {
                    await downloadService.setDownloadEnabled(value);
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Sprite downloads enabled'
                                : 'Sprite downloads disabled',
                          ),
                          backgroundColor: value ? Colors.green : Colors.orange,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  'Enable automatic downloads',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: downloadService.getRateLimitStatus(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final status = snapshot.data!;
                final requests = status['requestsInWindow'] as int;
                final maxRequests = status['maxRequests'] as int;
                final isLimited = status['rateLimitExceeded'] as bool;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isLimited
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isLimited
                              ? Colors.red.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Status',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color:
                              isLimited ? Colors.red[700] : Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requests: $requests / $maxRequests per minute',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (isLimited) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Rate limit reached. Please wait before downloading more sprites.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDownloadStatsDialog(context),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Stats'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showClearDownloadLogsDialog(context),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear Logs'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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

  void _showDownloadStatsDialog(BuildContext context) {
    final downloadService = sl<SpriteDownloadService>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => FutureBuilder<Map<String, dynamic>>(
            future: downloadService.getRateLimitStatus(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const AlertDialog(
                  title: Text('Download Statistics'),
                  content: CircularProgressIndicator(),
                );
              }

              final status = snapshot.data!;
              final downloadedSprites = downloadService.getDownloadedSprites();

              return AlertDialog(
                title: const Text('Download Statistics'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Downloaded Sprites: ${downloadedSprites.length}'),
                    const SizedBox(height: 8),
                    Text(
                      'Current Requests: ${status['requestsInWindow']} / ${status['maxRequests']}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rate Limit Window: ${status['windowSeconds']} seconds',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${status['rateLimitExceeded'] ? 'Rate Limited' : 'Available'}',
                      style: TextStyle(
                        color:
                            status['rateLimitExceeded']
                                ? Colors.red
                                : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showClearDownloadLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Clear Download Logs'),
            content: const Text(
              'Are you sure you want to clear all download logs? '
              'This will reset rate limiting counters and downloaded sprite tracking.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final downloadService = sl<SpriteDownloadService>();
                  await downloadService.clearDownloadLogs();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Download logs cleared successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }
}
