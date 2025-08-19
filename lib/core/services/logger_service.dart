abstract class LoggerService {
  Future<void> log(String message);
  Future<void> logError(Object error, StackTrace stack, {bool fatal = false});
}
