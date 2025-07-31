abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool useSimpleIcons;
  final bool useAxAFusions;

  SettingsLoaded({required this.useSimpleIcons, required this.useAxAFusions});
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}
