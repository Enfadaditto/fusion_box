abstract class SettingsEvent {}

class ToggleSimpleIcons extends SettingsEvent {
  final bool useSimpleIcons;

  ToggleSimpleIcons(this.useSimpleIcons);
}

class ToggleAxAFusions extends SettingsEvent {
  final bool useAxAFusions;

  ToggleAxAFusions(this.useAxAFusions);
}

class ToggleAutogenSprites extends SettingsEvent {
  final bool useAutogenSprites;

  ToggleAutogenSprites(this.useAutogenSprites);
}

class LoadSettings extends SettingsEvent {}

class SettingsChanged extends SettingsEvent {
  final bool useSimpleIcons;
  final bool useAxAFusions;
  final bool useAutogenSprites;

  SettingsChanged({required this.useSimpleIcons, required this.useAxAFusions, required this.useAutogenSprites});
}
