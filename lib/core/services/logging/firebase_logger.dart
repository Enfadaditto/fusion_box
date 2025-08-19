import 'package:fusion_box/core/services/logger_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class FirebaseLogger implements LoggerService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  @override
  Future<void> log(String message) async {
    logError(Exception('log: $message'), StackTrace.current);
  }

  @override
  Future<void> logError(Object error, StackTrace stack, {bool fatal = false}) async {
    _crashlytics.recordError(error, stack, fatal: fatal);
  }
}