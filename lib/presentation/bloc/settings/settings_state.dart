abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final bool useSimpleIcons;

  SettingsLoaded({required this.useSimpleIcons});
}

class SettingsError extends SettingsState {
  final String message;

  SettingsError(this.message);
}
