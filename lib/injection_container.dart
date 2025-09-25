import 'package:flutter/foundation.dart';
import 'package:fusion_box/core/services/logging/firebase_logger.dart';
import 'package:fusion_box/core/services/logging/noop_logger.dart';
import 'package:fusion_box/core/services/logger_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data sources
import 'package:fusion_box/data/datasources/local/pokemon_local_datasource.dart';
import 'package:fusion_box/data/datasources/local/game_local_datasource.dart';

// Repositories
import 'package:fusion_box/data/repositories/pokemon_repository_impl.dart';
import 'package:fusion_box/data/repositories/sprite_repository_impl.dart';
import 'package:fusion_box/domain/repositories/pokemon_repository.dart';
import 'package:fusion_box/domain/repositories/sprite_repository.dart';

// Use cases
import 'package:fusion_box/domain/usecases/get_fusion.dart';
import 'package:fusion_box/domain/usecases/get_pokemon_list.dart';
import 'package:fusion_box/domain/usecases/setup_game_path.dart';
import 'package:fusion_box/domain/usecases/generate_fusion_grid.dart';

// Parsers
import 'package:fusion_box/data/parsers/sprite_parser.dart';
import 'package:fusion_box/data/parsers/fusion_calculator.dart';

// Services
import 'package:fusion_box/core/services/sprite_download_service.dart';

// Presentation
import 'package:fusion_box/presentation/bloc/pokemon_list/pokemon_list_bloc.dart';
import 'package:fusion_box/presentation/bloc/fusion_grid/fusion_grid_bloc.dart';
import 'package:fusion_box/presentation/bloc/game_setup/game_setup_bloc.dart';
import 'package:fusion_box/presentation/bloc/settings/settings_bloc.dart';

final instance = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  instance.registerLazySingleton(() => sharedPreferences);

  // Data sources
  instance.registerLazySingleton<GameLocalDataSource>(
    () => GameLocalDataSourceImpl(),
  );

  instance.registerLazySingleton<PokemonLocalDataSource>(
    () => PokemonLocalDataSourceImpl(),
  );

  // Services
  if (kIsWeb) {
    instance.registerLazySingleton<LoggerService>(() => NoopLogger());
    instance.registerLazySingleton(() => NoopLogger());
  } else {
    instance.registerLazySingleton<LoggerService>(() => FirebaseLogger());
    instance.registerLazySingleton(() => FirebaseLogger());
  }
  instance.registerLazySingleton(() => SpriteDownloadService(
        preferences: instance(),
        logger: instance<LoggerService>(),
      ));

  // Parsers
  instance.registerLazySingleton(() => SpriteParser());

  instance.registerLazySingleton(
    () => FusionCalculator(
      spriteParser: instance(),
      gameLocalDataSource: instance(),
      spriteDownloadService: instance(),
      logger: instance<LoggerService>(),
    ),
  );

  // Repositories
  instance.registerLazySingleton<PokemonRepository>(
    () => PokemonRepositoryImpl(localDataSource: instance()),
  );

  instance.registerLazySingleton<SpriteRepository>(
    () => SpriteRepositoryImpl(
      fusionCalculator: instance(),
      logger: instance<LoggerService>(),
    ),
  );

  // Use cases
  instance.registerLazySingleton(() => GetPokemonList(repository: instance()));
  instance.registerLazySingleton(() => SetupGamePath(gameLocalDataSource: instance()));
  instance.registerLazySingleton(
    () => GetFusion(spriteRepository: instance(), pokemonRepository: instance()),
  );
  instance.registerLazySingleton(() => GenerateFusionGrid(getFusion: instance()));

  // Blocs
  instance.registerFactory(() => PokemonListBloc(getPokemonList: instance()));
  instance.registerFactory(() => FusionGridBloc(generateFusionGrid: instance()));
  instance.registerFactory(() => GameSetupBloc(setupGamePath: instance()));
  instance.registerFactory(() => SettingsBloc());
}
