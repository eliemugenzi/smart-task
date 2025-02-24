import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarttask/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
        child: MaterialApp.router(
      title: 'Smart Task',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: ThemeMode.system,
      theme: ThemeData(fontFamily: 'Rubik'),
    ));
  }
}
