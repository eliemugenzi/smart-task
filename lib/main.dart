import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarttask/firebase_options.dart';
import 'package:smarttask/routes.dart';
import 'package:smarttask/services/notification_service.dart';
import 'package:go_router/go_router.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize the notification service
  await NotificationService.instance.initialize();
  
  // Store the router for notification navigation
  // You'll need to create this function in a separate file
  // This should be called after router is initialized
  storeRouterForNotifications(router);
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Smart Task',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        themeMode: ThemeMode.system,
        theme: ThemeData(fontFamily: 'Rubik'),
      ),
    );
  }
}

// Simple function to store router reference for notifications
// This should be defined in your notification navigation file
// But including it here for completeness
void storeRouterForNotifications(GoRouter router) {
  // Implementation would be in your notification navigation file
}