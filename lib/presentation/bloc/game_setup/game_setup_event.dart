import 'package:equatable/equatable.dart';

abstract class GameSetupEvent extends Equatable {
  const GameSetupEvent();

  @override
  List<Object> get props => [];
}

class CheckGamePath extends GameSetupEvent {}

class SelectGamePath extends GameSetupEvent {}

class RequestStoragePermissions extends GameSetupEvent {}

class SetGamePath extends GameSetupEvent {
  final String path;

  const SetGamePath(this.path);

  @override
  List<Object> get props => [path];
}

class ValidateGamePath extends GameSetupEvent {
  final String path;

  const ValidateGamePath(this.path);

  @override
  List<Object> get props => [path];
}

class ClearGamePath extends GameSetupEvent {}
