import 'package:equatable/equatable.dart';

abstract class GameSetupState extends Equatable {
  const GameSetupState();

  @override
  List<Object> get props => [];
}

class GameSetupInitial extends GameSetupState {}

class GameSetupLoading extends GameSetupState {}

class GamePathNotSet extends GameSetupState {}

class GamePathSet extends GameSetupState {
  final String gamePath;

  const GamePathSet(this.gamePath);

  @override
  List<Object> get props => [gamePath];
}

class GamePathVerified extends GameSetupState {
  final String gamePath;

  const GamePathVerified(this.gamePath);

  @override
  List<Object> get props => [gamePath];
}

class GamePathValidating extends GameSetupState {}

class GamePathValid extends GameSetupState {
  final String gamePath;

  const GamePathValid(this.gamePath);

  @override
  List<Object> get props => [gamePath];
}

class GamePathInvalid extends GameSetupState {
  final String message;

  const GamePathInvalid(this.message);

  @override
  List<Object> get props => [message];
}

class GameSetupError extends GameSetupState {
  final String message;

  const GameSetupError(this.message);

  @override
  List<Object> get props => [message];
}

class GamePathCleared extends GameSetupState {}
