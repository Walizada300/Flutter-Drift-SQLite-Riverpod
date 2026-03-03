import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/db_list/db_list_page.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi DB Drift',
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const DbListPage(),
    );
  }
}
