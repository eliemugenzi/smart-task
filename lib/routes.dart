
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/screens/home_screen.dart';
import 'package:smarttask/screens/login_screen.dart';
import 'package:smarttask/screens/task_details_screen.dart';
import 'package:smarttask/screens/welcome_screen.dart';
import 'package:smarttask/utils/constants.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: Routes.welcome, pageBuilder: (context, state) =>  MaterialPage(child: WelcomeScreen())),
    GoRoute(path: Routes.login, pageBuilder: (context, state) =>  MaterialPage(child: LoginScreen())),
    GoRoute(path: Routes.home, pageBuilder: (context, state) =>  MaterialPage(child: HomeScreen())),
GoRoute(
      path: '/task/:taskId',
      builder: (context, state) {
        final taskJson = state.extra as Map<String, dynamic>?;
        if (taskJson == null) {
          throw Exception('Task data is required');
        }
        return TaskDetailsScreen();
      },
    ),  ]
);