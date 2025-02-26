// router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/models/task.dart';
import 'package:smarttask/screens/create_task_screen.dart';
import 'package:smarttask/screens/home_screen.dart';
import 'package:smarttask/screens/login_screen.dart';
import 'package:smarttask/screens/task_details_screen.dart';
import 'package:smarttask/screens/welcome_screen.dart';
import 'package:smarttask/utils/constants.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: Routes.welcome,
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(), // Simplified to builder
    ),
    GoRoute(
      path: Routes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(), // Simplified to builder
    ),
    GoRoute(
      path: Routes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(), // Simplified to builder
    ),
    GoRoute(
      path: Routes.createTask,
      name: 'createTask',
      builder: (context, state) {
        final taskJson = state.extra as Map<String, dynamic>?;
        return CreateTaskScreen(
          task: taskJson != null ? TaskData.fromJson(taskJson) : null,
        );
      },
    ),
    GoRoute(
      path: '/task/:taskId',
      name: 'task', // Added name for consistency
      builder: (context, state) {
        final taskJson = state.extra as Map<String, dynamic>?;
        if (taskJson == null) {
          throw Exception('Task data is required');
        }
        // final task = TaskData.fromJson(taskJson);
        return TaskDetailsScreen(); // Pass task to TaskDetailsScreen
      },
    ),
  ],
);