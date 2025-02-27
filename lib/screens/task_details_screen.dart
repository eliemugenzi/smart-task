// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/components/app_bar_compoment.dart';
import 'package:smarttask/components/assignee_initials_component.dart';
import 'package:smarttask/models/task.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/utils/helpers.dart';
import 'package:smarttask/utils/styles.dart'; // Assuming CustomStyles is defined here
import 'package:smarttask/utils/sync_manager.dart';
import 'package:smarttask/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SyncManager _syncManager = SyncManager.instance;
  final UserService _userService = UserService();
  TaskData? _task; // Make nullable to handle loading state
  List<Map<String, dynamic>> _users = []; // List of users from API
  bool _isLoadingUsers = true;
  String? _errorMessage;
  String? _currentUserName; // Store the current user's full name

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _loadCurrentUser(); // Load current user data
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely access context here to get task data
    final taskJson = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (taskJson == null) {
      throw Exception('Task data is required');
    }

    _task = TaskData.fromJson(taskJson);
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      setState(() {
        _currentUserName = '${userData['first_name']} ${userData['last_name']}';
      });
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _errorMessage = null;
    });
    try {
      _users = await _userService.fetchUsers();
      setState(() {
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _updateTask() async {
    if (_task == null || _task!.id == null) return; // Guard against null task or id
    // Navigate to CreateTaskScreen using go_router, passing the task as extra data
    final updatedTaskJson = await context.push<Map<String, dynamic>>(
      '/create-task',
      extra: _task!.toJson(),
    );
    if (updatedTaskJson != null) {
      final updatedTask = TaskData.fromJson(updatedTaskJson);
      await _databaseHelper.updateTask(updatedTask);
      setState(() {
        _task = updatedTask;
      });
      _syncManager.syncTasksToServer(); // Sync updated task to server
      context.goNamed('home'); // Navigate back to HomeScreen, triggering refresh
    }
  }

  Future<void> _deleteTask() async {
    if (_task == null || _task!.id == null) return; // Guard against null task or id
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${_task!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseHelper.deleteTask(_task!.id); // Use id instead of title
      _syncManager.syncTasksToServer(); // Sync deletion to server (if needed)
      context.goNamed('home'); // Navigate back to HomeScreen, triggering refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Center(child: CircularProgressIndicator()); // Show loading while task is not initialized
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: _task!.title,
        onBack: () => context.goNamed('home'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'update') {
                _updateTask();
              } else if (value == 'delete') {
                _deleteTask();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'update',
                child: ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Update'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete'),
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: CustomStyles.textLabelStyle),
                  Row(
                    children: [
                      _task!.status != TaskStatus.completed
                          ? Icon(Icons.event_repeat, color: Colors.red)
                          : Icon(Icons.done, color: Colors.green),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              // Completion Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completion Date',
                    style: CustomStyles.textLabelStyle,
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey, size: 16.0),
                      SizedBox(width: 8.0),
                      Text(
                        formatDueDate(_task!.completionDate),
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              // Priority
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Priority',
                    style: CustomStyles.textLabelStyle,
                  ),
                  Text(
                    _task!.priority.name.capitalize(),
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              // Description
              Text(
                'Description',
                style: CustomStyles.textLabelStyle, // Using CustomStyles for consistency
              ),
              SizedBox(height: 8.0),
              Text(
                _task!.description,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black87,
                  height: 1.5, // Line height for better readability
                ),
              ),
              SizedBox(height: 16.0),
              // Tags
              if (_task!.tags != null && _task!.tags!.isNotEmpty) ...[
                Text(
                  'Tags',
                  style: CustomStyles.textLabelStyle, // Using CustomStyles for consistency
                ),
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: _task!.tags!.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Colors.blue[100],
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.0),
              ],
              // Assigned
              Text(
                'Assigned',
                style: CustomStyles.textLabelStyle, // Using CustomStyles for consistency
              ),
              SizedBox(height: 8.0),
              ..._task!.assignees.map((assignee) {
                final fullName = assignee['name'] ?? 'Unknown';
                final displayName = _currentUserName == fullName ? '$fullName (You)' : fullName;
                return ListTile(
                  contentPadding: EdgeInsets.zero, // Remove default padding for exact match
                  leading: AssigneeInitials(fullName: fullName, currentUserName: _currentUserName),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black87,
                    ),
                  ),
                  dense: true, // Compact spacing to match the image
                );
              }).toList(),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14.0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  
}