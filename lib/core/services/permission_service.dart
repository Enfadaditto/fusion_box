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
}
