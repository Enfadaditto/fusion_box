import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fusion_box/core/services/settings_notification_service.dart';
import 'package:fusion_box/core/services/settings_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String _simpleIconsKey = 'use_simple_icons';
  static const String _axAFusionsKey = 'use_axa_fusions';
  static const String _autogenSpritesKey = 'use_autogen_sprites';

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleSimpleIcons>(_onToggleSimpleIcons);
    on<ToggleAxAFusions>(_onToggleAxAFusions);
    on<ToggleAutogenSprites>(_onToggleAutogenSprites);
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
      final useAutogenSprites = prefs.getBool(_autogenSpritesKey) ?? true;

      emit(
        SettingsLoaded(
          useSimpleIcons: useSimpleIcons,
          useAxAFusions: useAxAFusions,
          useAutogenSprites: useAutogenSprites,
        ),
      );

      // Notify other parts of the app about the loaded settings
      SettingsNotificationService().notifySimpleIconsChanged(useSimpleIcons);
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
        useAutogenSprites: currentState.useAutogenSprites,
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
          useAutogenSprites: currentState.useAutogenSprites,
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
        useAutogenSprites: currentState.useAutogenSprites,
      );

      emit(newState);

      // Emit SettingsChanged event to notify other parts of the app
      add(
        SettingsChanged(
          useSimpleIcons: currentState.useSimpleIcons,
          useAxAFusions: event.useAxAFusions,
          useAutogenSprites: currentState.useAutogenSprites,
        ),
      );
    } catch (e) {
      emit(SettingsError('Failed to save settings: $e'));
    }
  }

  Future<void> _onToggleAutogenSprites(
    ToggleAutogenSprites event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await SettingsService.setUseAutogenSprites(event.useAutogenSprites);

      final currentState = state as SettingsLoaded;
      final newState = SettingsLoaded(
        useSimpleIcons: currentState.useSimpleIcons,
        useAxAFusions: currentState.useAxAFusions,
        useAutogenSprites: event.useAutogenSprites,
      );

      emit(newState);

      add(
        SettingsChanged(
          useSimpleIcons: currentState.useSimpleIcons,
          useAxAFusions: currentState.useAxAFusions,
          useAutogenSprites: event.useAutogenSprites,
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
