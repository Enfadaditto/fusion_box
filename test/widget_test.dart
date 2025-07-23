// Basic Flutter widget test for Fusion Box app.

import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_box/main.dart';
import 'package:fusion_box/injection_container.dart' as di;

void main() {
  setUp(() async {
    await di.init();
  });

  testWidgets('App launches and shows correct title', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FusionBoxApp());

    // Verify that the app title is displayed
    expect(find.text('Pokemon Fusion Box'), findsOneWidget);
  });
}
