abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => 'Failure: $message';
}

class SpriteFailure extends Failure {
  const SpriteFailure(super.message);
}

class DataFailure extends Failure {
  const DataFailure(super.message);
}
