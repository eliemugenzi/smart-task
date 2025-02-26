// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/models/task.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/utils/styles.dart';
import 'package:smarttask/utils/sync_manager.dart';


class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key});

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SyncManager _syncManager = SyncManager.instance;
  TaskData? _task; // Make nullable to handle loading state

  @override
  void initState() {
    super.initState();
    // Do not access context here; initialize _task later
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

  Future<void> _updateTask() async {
    if (_task == null) return; // Guard against null task
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
    if (_task == null) return; // Guard against null task
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
      await _databaseHelper.deleteTask(_task!.title);
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
      appBar: AppBar(
        backgroundColor: Colors.blue[700], // Exact blue from the image
        elevation: 0,
        title: Text(
          _task!.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goNamed('home'), // Back button to navigate to HomeScreen
        ),
        actions: [
          // Removed status row from here; moved to body
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
          color: Colors.grey[50], // Light grey background for the body
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)), // Rounded top corners
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Row (moved from app bar to body)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: CustomStyles.textLabelStyle), // Assuming CustomStyles is defined
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
                    style: CustomStyles.textLabelStyle, // Using CustomStyles for consistency
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey, size: 16.0),
                      SizedBox(width: 8.0),
                      Text(
                        _formatCompletionDate(_task!.completionDate),
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
              // Assigned
              Text(
                'Assigned',
                style: CustomStyles.textLabelStyle, // Using CustomStyles for consistency
              ),
              SizedBox(height: 8.0),
              ..._task!.assignees.map((assignee) {
                return ListTile(
                  contentPadding: EdgeInsets.zero, // Remove default padding for exact match
                  leading: CircleAvatar(
                    radius: 16.0,
                    backgroundImage: NetworkImage(assignee['avatar'] ?? 'https://i.pravatar.cc/150?u=default'),
                  ),
                  title: Text(
                    assignee['name'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.black87,
                    ),
                  ),
                  dense: true, // Compact spacing to match the image
                );
              }).toList(),
              SizedBox(height: 16.0),
              // Subtasks (show label only if subtasks exist)
              if (_task!.subtasks != null && _task!.subtasks!.isNotEmpty) ...[
                Text(
                  'Subtasks',
                  style: CustomStyles.textLabelStyle, // Using CustomStyles for consistency
                ),
                SizedBox(height: 8.0),
                ..._task!.subtasks!.map((subtask) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero, // Remove default padding
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black87,
                      ),
                    ),
                    value: subtask.isCompleted,
                    onChanged: (bool? value) async {
                      if (value != null && _task != null) {
                        final updatedSubtasks = _task!.subtasks!.map((s) => s.title == subtask.title
                            ? Subtask(title: s.title, isCompleted: value)
                            : s).toList();
                        final updatedTask = TaskData(
                          title: _task!.title,
                          completionDate: _task!.completionDate,
                          status: _task!.status,
                          description: _task!.description,
                          assignees: _task!.assignees,
                          subtasks: updatedSubtasks,
                        );
                        await _databaseHelper.updateTask(updatedTask);
                        setState(() {
                          _task = updatedTask;
                        });
                        _syncManager.syncTasksToServer(); // Sync updated task to server
                        // No need for _refreshHomeScreen; navigation will handle it
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.green,
                    checkColor: Colors.white, // Match checkbox check color
                    checkboxShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0), // Rounded checkbox
                    ),
                    dense: true, // Compact spacing
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatCompletionDate(DateTime date) {
    bool isToday = DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;
    if (isToday) {
      return 'Today, ${DateFormat('hh:mm a').format(date)}';
    }
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }
}