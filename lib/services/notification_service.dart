import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:smarttask/models/task.dart' as task_model;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Track scheduled notifications to avoid duplicates
  final Map<int, int> _scheduledTaskNotifications = {};

  NotificationService._internal();

  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Request permission for Firebase Messaging
    await _requestPermissions();
    
    // Set up Firebase message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Check for initial message (app opened from terminated state)
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
    
    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // TODO: Send token to your backend server to associate with the user
  }
  
  Future<void> _requestPermissions() async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('User notification permission status: ${settings.authorizationStatus}');
    
    // Additional iOS/macOS permissions
    if (Platform.isIOS || Platform.isMacOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    
    // Additional Android permissions (for Android 13+)
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final String? payload = response.payload;
    if (payload != null) {
      // Parse the payload and navigate to the relevant task
      try {
        final int taskId = int.parse(payload);
        // TODO: Add navigation to task details
        // navigatorKey.currentState?.pushNamed('/task/$taskId');
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }
  
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.messageId}');
    
    // Show a local notification when app is in foreground
    await _showLocalNotification(
      id: message.messageId.hashCode,
      title: message.notification?.title ?? 'Task Reminder',
      body: message.notification?.body ?? 'You have an upcoming task!',
      payload: message.data['taskId']?.toString(),
    );
  }
  
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    
    // Handle navigation when app is opened from notification
    if (message.data.containsKey('taskId')) {
      final String taskId = message.data['taskId'];
      // TODO: Add navigation to task details
      // Example: navigatorKey.currentState?.pushNamed('/task/$taskId');
    }
  }
  
  void _handleInitialMessage(RemoteMessage message) {
    print('Initial message: ${message.messageId}');
    
    // Handle navigation when app is launched from notification
    if (message.data.containsKey('taskId')) {
      final String taskId = message.data['taskId'];
      // TODO: Add navigation to task details
      // Example: navigatorKey.currentState?.pushNamed('/task/$taskId', arguments: {'initialTaskId': taskId});
    }
  }
  
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming task reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  // Schedule a local notification for the task reminder (2 minutes before completion)
  Future<void> scheduleTaskReminder(task_model.TaskData task) async {
    if (task.id == null) return;
    
    // Cancel any existing notification for this task
    cancelTaskReminder(task.id!);
    
    // Calculate notification time (2 minutes before completion)
    final DateTime notificationTime = task.completionDate.subtract(const Duration(minutes: 2));
    print('Notification time: $notificationTime');
    
    // Skip if the notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      print('Skipping notification for past task: ${task.title}');
      return;
    }
    
    final int notificationId = task.id!;
    
    // Schedule the notification
    await _localNotifications.zonedSchedule(
      notificationId,
      'Task Reminder: ${task.title}',
      'This task is due in 2 minutes',
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for upcoming task reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id.toString(),
    );
    
    // Track the scheduled notification
    _scheduledTaskNotifications[task.id!] = notificationId;
    
    print('Scheduled notification for task ${task.id} at $notificationTime');
  }
  
  // Cancel a previously scheduled task reminder
  Future<void> cancelTaskReminder(int taskId) async {
    if (_scheduledTaskNotifications.containsKey(taskId)) {
      await _localNotifications.cancel(_scheduledTaskNotifications[taskId]!);
      _scheduledTaskNotifications.remove(taskId);
      print('Cancelled notification for task $taskId');
    }
  }
  
  // Reschedule all task reminders (call this when app starts)
  Future<void> rescheduleAllTaskReminders(List<task_model.TaskData> tasks) async {
    // Clear existing scheduled notifications
    await _localNotifications.cancelAll();
    _scheduledTaskNotifications.clear();
    
    // Schedule notifications for tasks that haven't been completed
    for (final task in tasks) {
      if (task.status != task_model.TaskStatus.completed && 
          task.completionDate.isAfter(DateTime.now())) {
        await scheduleTaskReminder(task);
      }
    }
  }
  
  // Subscribe to a topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }
  
  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}

// This function must be outside of any class and declared as top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  
  print('Background message received: ${message.messageId}');
  
  // Handle background message (no UI operations)
  // You can still process data and schedule local notifications
}