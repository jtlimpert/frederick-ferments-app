import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'screens/connection_test_screen.dart';

/// Entry point for the Frederick Ferments inventory app.
void main() async {
  await initHiveForFlutter();

  runApp(
    const ProviderScope(
      child: FrederickFermentsApp(),
    ),
  );
}

/// Root widget for the Frederick Ferments application.
class FrederickFermentsApp extends StatelessWidget {
  const FrederickFermentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frederick Ferments',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const ConnectionTestScreen(),
    );
  }
}
