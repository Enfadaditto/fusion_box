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
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Verificando permisos...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Configurando acceso al almacenamiento',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 80, color: Colors.orange[400]),
              const SizedBox(height: 24),
              Text(
                'Permisos de almacenamiento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Para mostrar las fusiones de Pokémon, necesitamos acceso a los archivos del juego en tu dispositivo.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _retryPermissions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Intentar de nuevo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await PermissionService.showPermissionDeniedDialog(context);
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Abrir configuración'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(height: 8),
                    Text(
                      'La aplicación funcionará con limitaciones sin estos permisos. Solo se mostrarán placeholders en lugar de las fusiones reales.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
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
              TextButton.icon(
                onPressed: () async {
                  await PermissionService.showTroubleshootingDialog(context);
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('¿Problemas con placeholders?'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
