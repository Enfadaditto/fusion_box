import 'dart:async';

class SettingsNotificationService {
  static final SettingsNotificationService _instance =
      SettingsNotificationService._internal();
  factory SettingsNotificationService() => _instance;
  SettingsNotificationService._internal();

  final StreamController<bool> _simpleIconsController =
      StreamController<bool>.broadcast();
  bool _currentValue = true; // Default to simple icons

  Stream<bool> get simpleIconsStream => _simpleIconsController.stream;
  bool get currentValue => _currentValue;

  void notifySimpleIconsChanged(bool useSimpleIcons) {
    _currentValue = useSimpleIcons;
    _simpleIconsController.add(useSimpleIcons);
  }

  void dispose() {
    _simpleIconsController.close();
  }
}
