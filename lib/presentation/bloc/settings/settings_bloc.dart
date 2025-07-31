import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String _simpleIconsKey = 'use_simple_icons';

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleSimpleIcons>(_onToggleSimpleIcons);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final useSimpleIcons = prefs.getBool(_simpleIconsKey) ?? false;

      emit(SettingsLoaded(useSimpleIcons: useSimpleIcons));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onToggleSimpleIcons(
    ToggleSimpleIcons event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_simpleIconsKey, event.useSimpleIcons);

      emit(SettingsLoaded(useSimpleIcons: event.useSimpleIcons));
    } catch (e) {
      emit(SettingsError('Failed to save settings: $e'));
    }
  }
}
