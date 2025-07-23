import 'package:flutter/material.dart';
import 'package:fusion_box/core/services/permission_service.dart';

class PermissionWrapper extends StatefulWidget {
  final Widget child;

  const PermissionWrapper({super.key, required this.child});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _isCheckingPermissions = true;
  bool _hasPermissions = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    try {
      // Primero verificar si ya tenemos permisos
      final hasPermissions = await PermissionService.hasStoragePermissions();

      if (hasPermissions) {
        setState(() {
          _hasPermissions = true;
          _isCheckingPermissions = false;
        });
        return;
      }

      // Si no tenemos permisos, mostrar explicación y solicitar
      if (mounted) {
        final shouldRequest = await PermissionService.showPermissionRationale(
          context,
        );

        if (shouldRequest) {
          final granted = await PermissionService.requestStoragePermissions();

          setState(() {
            _hasPermissions = granted;
            _isCheckingPermissions = false;
            if (!granted) {
              _errorMessage =
                  'Los permisos de almacenamiento son necesarios para cargar las fusiones.';
            }
          });

          // Si los permisos fueron denegados permanentemente, mostrar diálogo
          if (!granted && mounted) {
            await PermissionService.showPermissionDeniedDialog(context);
          }
        } else {
          setState(() {
            _hasPermissions = false;
            _isCheckingPermissions = false;
            _errorMessage =
                'Los permisos de almacenamiento son necesarios para cargar las fusiones.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _hasPermissions = false;
        _isCheckingPermissions = false;
        _errorMessage = 'Error al verificar permisos: $e';
      });
    }
  }

  Future<void> _retryPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
      _errorMessage = '';
    });

    await _initializePermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return _buildLoadingScreen();
    }

    if (!_hasPermissions) {
      return _buildPermissionDeniedScreen();
    }

    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Verificando permisos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Icono principal
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Título
              Text(
                'Acceso al almacenamiento',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Descripción
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Necesitamos acceso a tus archivos para cargar las fusiones del juego.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Botones principales
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _retryPermissions,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Conceder permiso'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await PermissionService.showPermissionDeniedDialog(
                          context,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Abrir configuración'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Opciones adicionales
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Solo se mostrarán placeholders sin permisos',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _hasPermissions = true;
                            });
                          },
                          child: const Text('Continuar sin permisos'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      await PermissionService.showTroubleshootingDialog(
                        context,
                      );
                    },
                    child: const Text('Ayuda'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
