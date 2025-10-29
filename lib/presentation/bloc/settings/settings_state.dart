abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool useSimpleIcons;
  final bool useAxAFusions;
  final bool useAutogenSprites;

  SettingsLoaded({required this.useSimpleIcons, required this.useAxAFusions, required this.useAutogenSprites});
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}
