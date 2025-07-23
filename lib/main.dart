import 'package:flutter/material.dart';
import 'package:fusion_box/injection_container.dart' as di;
import 'package:fusion_box/presentation/pages/home_page.dart';
import 'package:fusion_box/presentation/widgets/common/permission_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.init();

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
      home: const PermissionWrapper(child: HomePage()),
      debugShowCheckedModeBanner: false,
    );
  }
}
