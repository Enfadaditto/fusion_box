abstract class SettingsEvent {}

class ToggleSimpleIcons extends SettingsEvent {
  final bool useSimpleIcons;

  ToggleSimpleIcons(this.useSimpleIcons);
}

class ToggleAxAFusions extends SettingsEvent {
  final bool useAxAFusions;

  ToggleAxAFusions(this.useAxAFusions);
}

class LoadSettings extends SettingsEvent {}

class SettingsChanged extends SettingsEvent {
  final bool useSimpleIcons;
  final bool useAxAFusions;

  SettingsChanged({required this.useSimpleIcons, required this.useAxAFusions});
}
