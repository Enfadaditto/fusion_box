import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class PermissionService {
  /// Solicita todos los permisos necesarios para la app
  static Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        return await _requestAndroidStoragePermissions();
      } else if (Platform.isIOS) {
        return await _requestIOSStoragePermissions();
      }
      return true; // Para otras plataformas (Windows, macOS, Linux)
    } catch (e) {
      return false;
    }
  }

  /// Verifica si ya tenemos los permisos necesarios
  static Future<bool> hasStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        return await _hasAndroidStoragePermissions();
      } else if (Platform.isIOS) {
        return await _hasIOSStoragePermissions();
      }
      return true; // Para otras plataformas
    } catch (e) {
      return false;
    }
  }

  /// Maneja permisos específicos para Android
  static Future<bool> _requestAndroidStoragePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // Para Android 11+ (API 30+) - Usar MANAGE_EXTERNAL_STORAGE
    if (sdkInt >= 30) {
      final manageStorageStatus = await Permission.manageExternalStorage.status;

      if (manageStorageStatus != PermissionStatus.granted) {
        final newStatus = await Permission.manageExternalStorage.request();
        if (newStatus != PermissionStatus.granted) {
          return false;
        }
      }
    }
    // Para Android 10 y anteriores (API < 30)
    else {
      final storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  /// Verifica permisos para Android
  static Future<bool> _hasAndroidStoragePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 30) {
      final manageStorage = await Permission.manageExternalStorage.status;
      return manageStorage == PermissionStatus.granted;
    } else {
      final storage = await Permission.storage.status;
      return storage == PermissionStatus.granted;
    }
  }

  /// Maneja permisos para iOS
  static Future<bool> _requestIOSStoragePermissions() async {
    final photos = await Permission.photos.request();
    return photos == PermissionStatus.granted;
  }

  /// Verifica permisos para iOS
  static Future<bool> _hasIOSStoragePermissions() async {
    final photos = await Permission.photos.status;
    return photos == PermissionStatus.granted;
  }

  /// Muestra diálogo explicando por qué se necesitan los permisos
  static Future<bool> showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Acceso al almacenamiento',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Para mostrar las fusiones reales necesitamos acceso a los archivos del juego.\n\n'
                'Sin este permiso solo verás placeholders.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Permitir'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Muestra diálogo cuando los permisos fueron denegados permanentemente
  static Future<void> showPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Permiso requerido',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Necesitas habilitar el acceso al almacenamiento en configuración.\n\n'
            'Ve a: Aplicaciones > Fusion Box > Permisos',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Configuración'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra información sobre cómo solucionar problemas de sprites
  static Future<void> showTroubleshootingDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Solución de problemas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Si sigues viendo placeholders:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                _buildTroubleshootStep(
                  context,
                  '1',
                  'Verifica que el juego esté instalado',
                ),
                _buildTroubleshootStep(
                  context,
                  '2',
                  'Configura la ruta del juego en ajustes',
                ),
                _buildTroubleshootStep(context, '3', 'Reinicia la aplicación'),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildTroubleshootStep(
    BuildContext context,
    String number,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
