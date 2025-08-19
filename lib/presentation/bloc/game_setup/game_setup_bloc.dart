import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fusion_box/domain/usecases/setup_game_path.dart';
import 'package:fusion_box/core/services/permission_service.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_event.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_state.dart';

class GameSetupBloc extends Bloc<GameSetupEvent, GameSetupState> {
  final SetupGamePath setupGamePath;

  GameSetupBloc({required this.setupGamePath}) : super(GameSetupInitial()) {
    on<CheckGamePath>(_onCheckGamePath);
    on<SelectGamePath>(_onSelectGamePath);
    on<RequestStoragePermissions>(_onRequestStoragePermissions);
    on<SetGamePath>(_onSetGamePath);
    on<ValidateGamePath>(_onValidateGamePath);
    on<ClearGamePath>(_onClearGamePath);
  }

  Future<void> _onCheckGamePath(
    CheckGamePath event,
    Emitter<GameSetupState> emit,
  ) async {
    emit(GameSetupLoading());

    try {
      final currentPath = await setupGamePath.getCurrentPath();
      if (currentPath != null && currentPath.isNotEmpty) {
        final isValid = await setupGamePath.validatePath(currentPath);
        if (isValid) {
          emit(GamePathVerified(currentPath));
        } else {
          emit(GamePathNotSet());
        }
      } else {
        emit(GamePathNotSet());
      }
    } catch (e) {
      emit(GameSetupError('Failed to check game path: $e'));
    }
  }

  Future<void> _onSelectGamePath(
    SelectGamePath event,
    Emitter<GameSetupState> emit,
  ) async {
    try {
      // First check if we have permissions
      final hasPermissions = await PermissionService.hasStoragePermissions();

      if (!hasPermissions) {
        // Request permissions first
        add(RequestStoragePermissions());
        return;
      }

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        add(ValidateGamePath(selectedDirectory));
      }
    } catch (e) {
      emit(GameSetupError('Failed to select directory: $e'));
    }
  }

  Future<void> _onRequestStoragePermissions(
    RequestStoragePermissions event,
    Emitter<GameSetupState> emit,
  ) async {
    emit(StoragePermissionRequesting());

    try {
      final granted = await PermissionService.requestStoragePermissions();

      if (granted) {
        emit(StoragePermissionGranted());
        // After permissions are granted, proceed with directory selection
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();

        if (selectedDirectory != null) {
          add(ValidateGamePath(selectedDirectory));
        }
      } else {
        emit(
          StoragePermissionDenied(
            'Storage permissions are required to access game files. Please grant permissions in settings.',
          ),
        );
      }
    } catch (e) {
      emit(StoragePermissionDenied('Failed to request permissions: $e'));
    }
  }

  Future<void> _onSetGamePath(
    SetGamePath event,
    Emitter<GameSetupState> emit,
  ) async {
    emit(GameSetupLoading());

    try {
      final success = await setupGamePath.setGamePath(event.path);
      if (success) {
        emit(GamePathSet(event.path));
      } else {
        emit(
          GamePathInvalid(
            'Invalid game path. Make sure the directory contains the Pokemon Infinite Fusion game files.',
          ),
        );
      }
    } catch (e) {
      emit(GameSetupError('Failed to set game path: $e'));
    }
  }

  Future<void> _onValidateGamePath(
    ValidateGamePath event,
    Emitter<GameSetupState> emit,
  ) async {
    emit(GamePathValidating());

    try {
      final isValid = await setupGamePath.validatePath(event.path);
      if (isValid) {
        // Automáticamente configurar la ruta si es válida
        final success = await setupGamePath.setGamePath(event.path);
        if (success) {
          emit(GamePathSet(event.path));
        } else {
          emit(
            GamePathInvalid('Failed to save the game path. Please try again.'),
          );
        }
      } else {
        emit(
          GamePathInvalid(
            'Invalid game path. Make sure the directory contains the Pokemon Infinite Fusion game files.',
          ),
        );
      }
    } catch (e) {
      emit(GameSetupError('Failed to validate game path: $e'));
    }
  }

  Future<void> _onClearGamePath(
    ClearGamePath event,
    Emitter<GameSetupState> emit,
  ) async {
    emit(GameSetupLoading());

    try {
      final success = await setupGamePath.clearGamePath();
      if (success) {
        emit(GamePathCleared());
        // Después de limpiar, volver al estado inicial
        emit(GamePathNotSet());
      } else {
        emit(GameSetupError('Failed to clear game path'));
      }
    } catch (e) {
      emit(GameSetupError('Failed to clear game path: $e'));
    }
  }
}
