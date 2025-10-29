import 'package:fusion_box/core/services/logger_service.dart';

class NoopLogger implements LoggerService {
  @override
  Future<void> log(String message) async {}

  @override
  Future<void> logError(Object error, StackTrace stack, {bool fatal = false}) async {}
}






