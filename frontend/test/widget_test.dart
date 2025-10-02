import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads connection test screen', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FrederickFermentsApp(),
      ),
    );

    // Verify that connection test screen loads
    expect(find.text('Test GraphQL Connection'), findsOneWidget);
    expect(find.text('Test Ping'), findsOneWidget);
    expect(find.text('Test Health Check'), findsOneWidget);
    expect(find.text('Fetch Inventory Items'), findsOneWidget);
  });
}
