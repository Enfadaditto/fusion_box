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

final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Data sources
  sl.registerLazySingleton<GameLocalDataSource>(
    () => GameLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<PokemonLocalDataSource>(
    () => PokemonLocalDataSourceImpl(),
  );

  // Services
  sl.registerLazySingleton(() => SpriteDownloadService(preferences: sl()));

  // Parsers
  sl.registerLazySingleton(() => SpriteParser());

  sl.registerLazySingleton(
    () => FusionCalculator(
      spriteParser: sl(),
      gameLocalDataSource: sl(),
      spriteDownloadService: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<PokemonRepository>(
    () => PokemonRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<SpriteRepository>(
    () => SpriteRepositoryImpl(fusionCalculator: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPokemonList(repository: sl()));
  sl.registerLazySingleton(() => SetupGamePath(gameLocalDataSource: sl()));
  sl.registerLazySingleton(
    () => GetFusion(spriteRepository: sl(), pokemonRepository: sl()),
  );
  sl.registerLazySingleton(() => GenerateFusionGrid(getFusion: sl()));

  // Blocs
  sl.registerFactory(() => PokemonListBloc(getPokemonList: sl()));
  sl.registerFactory(() => FusionGridBloc(generateFusionGrid: sl()));
  sl.registerFactory(() => GameSetupBloc(setupGamePath: sl()));
  sl.registerFactory(() => SettingsBloc());
}
