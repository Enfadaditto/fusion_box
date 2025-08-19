import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fusion_box/injection_container.dart' as dependency_injection;
import 'package:fusion_box/presentation/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fusion_box/config/firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:fusion_box/core/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  await dependency_injection.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    dependency_injection.instance<LoggerService>().logError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    dependency_injection.instance<LoggerService>().logError(error, stack, fatal: true);
    return true;
  };

  runApp(const FusionBoxApp());
}

class FusionBoxApp extends StatelessWidget {
  const FusionBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokemon Fusion Box',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
