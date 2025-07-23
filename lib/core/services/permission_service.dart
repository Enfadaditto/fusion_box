import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static const String _tag = 'PermissionService';

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
      debugPrint('$_tag: Error requesting permissions: $e');
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
      debugPrint('$_tag: Error checking permissions: $e');
      return false;
    }
  }

  /// Maneja permisos específicos para Android
  static Future<bool> _requestAndroidStoragePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    debugPrint('$_tag: Android SDK: $sdkInt');

    // Para Android 11+ (API 30+) - Usar MANAGE_EXTERNAL_STORAGE
    if (sdkInt >= 30) {
      final manageStorageStatus = await Permission.manageExternalStorage.status;

      if (manageStorageStatus != PermissionStatus.granted) {
        final newStatus = await Permission.manageExternalStorage.request();
        if (newStatus != PermissionStatus.granted) {
          debugPrint('$_tag: MANAGE_EXTERNAL_STORAGE permission denied');
          return false;
        }
      }
    }
    // Para Android 10 y anteriores (API < 30)
    else {
      final storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        debugPrint('$_tag: Storage permission denied');
        return false;
      }
    }

    debugPrint('$_tag: All Android permissions granted');
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
              title: const Text('Permisos de almacenamiento'),
              content: const Text(
                'Esta aplicación necesita acceso completo al almacenamiento para leer los archivos de sprites del juego Pokemon Infinite Fusion.\n\n'
                'Específicamente necesitamos el permiso "Administrar todo el almacenamiento" para acceder a las carpetas del juego.\n\n'
                'Sin estos permisos, solo se mostrarán placeholders en lugar de las fusiones reales.\n\n'
                'Los archivos se buscan típicamente en rutas como:\n'
                '• /storage/emulated/0/Pokemon Infinite Fusion/\n'
                '• /sdcard/Pokemon Infinite Fusion/',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Conceder permisos'),
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
          title: const Text('Permisos requeridos'),
          content: const Text(
            'Los permisos de almacenamiento son necesarios para que la aplicación funcione correctamente.\n\n'
            'Por favor, ve a:\n'
            'Configuración > Aplicaciones > Fusion Box > Permisos\n\n'
            'Y habilita:\n'
            '• Almacenamiento\n'
            '• Administrar todo el almacenamiento (Android 11+)\n\n'
            'Después regresa a la app y toca "Intentar de nuevo".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Abrir configuración'),
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
          title: const Text('¿Sigues viendo placeholders?'),
          content: const SingleChildScrollView(
            child: Text(
              'Si sigues viendo placeholders después de conceder permisos:\n\n'
              '1. Verifica que el juego esté instalado correctamente\n'
              '2. Ve a Configuración y selecciona la carpeta del juego\n'
              '3. Asegúrate de que la ruta contenga:\n'
              '   • Graphics/CustomBattlers/spritesheets/\n'
              '   • Graphics/Battlers/spritesheets_autogen/\n\n'
              '4. Reinicia la aplicación después de cambios\n\n'
              'Rutas típicas del juego:\n'
              '• /storage/emulated/0/Pokemon Infinite Fusion/\n'
              '• /sdcard/Pokemon Infinite Fusion/\n'
              '• /Android/data/com.game.pokemoninfinitefusion/',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
}
