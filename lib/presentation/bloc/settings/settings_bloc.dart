import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fusion_box/core/services/settings_notification_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String _simpleIconsKey = 'use_simple_icons';
  static const String _axAFusionsKey = 'use_axa_fusions';

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleSimpleIcons>(_onToggleSimpleIcons);
    on<ToggleAxAFusions>(_onToggleAxAFusions);
    on<SettingsChanged>(_onSettingsChanged);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final useSimpleIcons = prefs.getBool(_simpleIconsKey) ?? true;
      final useAxAFusions = prefs.getBool(_axAFusionsKey) ?? false;

      emit(
        SettingsLoaded(
          useSimpleIcons: useSimpleIcons,
          useAxAFusions: useAxAFusions,
        ),
      );
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

      final currentState = state as SettingsLoaded;
      final newState = SettingsLoaded(
        useSimpleIcons: event.useSimpleIcons,
        useAxAFusions: currentState.useAxAFusions,
      );

      emit(newState);

      // Notify other parts of the app about the settings change
      SettingsNotificationService().notifySimpleIconsChanged(
        event.useSimpleIcons,
      );

      // Emit SettingsChanged event to notify other parts of the app
      add(
        SettingsChanged(
          useSimpleIcons: event.useSimpleIcons,
          useAxAFusions: currentState.useAxAFusions,
        ),
      );
    } catch (e) {
      emit(SettingsError('Failed to save settings: $e'));
    }
  }

  Future<void> _onToggleAxAFusions(
    ToggleAxAFusions event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_axAFusionsKey, event.useAxAFusions);

      final currentState = state as SettingsLoaded;
      final newState = SettingsLoaded(
        useSimpleIcons: currentState.useSimpleIcons,
        useAxAFusions: event.useAxAFusions,
      );

      emit(newState);

      // Emit SettingsChanged event to notify other parts of the app
      add(
        SettingsChanged(
          useSimpleIcons: currentState.useSimpleIcons,
          useAxAFusions: event.useAxAFusions,
        ),
      );
    } catch (e) {
      emit(SettingsError('Failed to save settings: $e'));
    }
  }

  void _onSettingsChanged(SettingsChanged event, Emitter<SettingsState> emit) {
    // This event is used to notify other parts of the app about settings changes
    // We don't need to emit a new state here as it's already been emitted
  }
}
