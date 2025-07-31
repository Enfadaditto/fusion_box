abstract class SettingsEvent {}

class ToggleSimpleIcons extends SettingsEvent {
  final bool useSimpleIcons;

  ToggleSimpleIcons(this.useSimpleIcons);
}

class LoadSettings extends SettingsEvent {}
