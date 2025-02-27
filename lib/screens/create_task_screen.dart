// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/components/app_bar_compoment.dart';
import 'package:smarttask/components/assignee_initials_component.dart';
import 'package:smarttask/components/button_component.dart';
import 'package:smarttask/components/text_field_component.dart';
import 'package:smarttask/models/task.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/utils/helpers.dart';
import 'package:smarttask/utils/sync_manager.dart';
import 'package:smarttask/utils/styles.dart'; // Assuming CustomStyles is defined here
import 'package:smarttask/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateTaskScreen extends StatefulWidget {
  final TaskData? task; // Optional task for editing

  const CreateTaskScreen({super.key, this.task});

  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagController = TextEditingController(); // New controller for tags
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now(); // Updated from completionDate for consistency
  TaskStatus _status = TaskStatus.pending;
  Priority _priority = Priority.medium; // Default to medium
  List<Map<String, dynamic>> _assignees = []; // Start with empty list, requiring at least one assignee
  List<String> _tags = []; // New field for tags
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SyncManager _syncManager = SyncManager.instance;
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _users = []; // List of users from API
  bool _isLoadingUsers = true;
  String? _errorMessage;
  String? _currentUserName; // Store the current user's full name

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _loadCurrentUser(); // Load current user data
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.completionDate; // Updated from completionDate for consistency
      _status = widget.task!.status;
      _priority = widget.task!.priority; // Initialize priority
      _assignees = widget.task!.assignees.isEmpty ? [] : widget.task!.assignees; // Initialize with existing assignees
      _tags = widget.task!.tags ?? []; // Initialize tags
    }
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

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (timePicked != null) {
        setState(() {
          _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  void _addTag(String tag) {
    setState(() {
      if (!_tags.contains(tag) && tag.isNotEmpty) {
        _tags.add(tag);
      }
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showAssigneeSelector() async {
    if (_isLoadingUsers) return;

    final selectedUsers = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) {
        List<Map<String, dynamic>> tempSelectedAssignees = [..._assignees];
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Assignees'),
              content: _users.isEmpty
                  ? _isLoadingUsers
                      ? Center(child: CircularProgressIndicator())
                      : Center(child: Text('No users found'))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _users.map((user) {
                          final userId = user['id'] as int;
                          final fullName = '${user['first_name']} ${user['last_name']}';
                          final displayName = _currentUserName == fullName ? '$fullName (You)' : fullName;
                          final isSelected = tempSelectedAssignees.any((a) => a['name'] == fullName);
                          return CheckboxListTile(
                            title: Row(
                              mainAxisSize: MainAxisSize.min, // Limit row width
                              children: [
                                AssigneeInitials(fullName: fullName, currentUserName: _currentUserName),
                                SizedBox(width: 8.0),
                                Expanded( // Allow text to wrap or truncate
                                  child: Text(
                                    displayName,
                                    style: TextStyle(fontSize: 14.0),
                                    overflow: TextOverflow.ellipsis, // Truncate with ellipsis if too long
                                    maxLines: 1, // Limit to one line
                                  ),
                                ),
                              ],
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  tempSelectedAssignees.add({
                                    'name': fullName,
                                    'avatar': 'https://i.pravatar.cc/150?u=$fullName', // Keep avatar for DB, but not displayed
                                  });
                                } else {
                                  tempSelectedAssignees.removeWhere((a) => a['name'] == fullName);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, tempSelectedAssignees),
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      setState(() {
        _assignees = selectedUsers;
      });
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate() && _assignees.isNotEmpty) {
      final task = TaskData(
        id: widget.task?.id, // Preserve the original id for updates
        title: _titleController.text,
        completionDate: _dueDate, // Updated from dueDate for consistency
        status: _status,
        description: _descriptionController.text,
        assignees: _assignees.isEmpty ? [] : _assignees, // Handle empty assignees (now validated)
        tags: _tags.isEmpty ? null : _tags, // Handle nullable tags
        priority: _priority, // Include priority
      ).copyWith(); // Use copyWith to create the final instance (optional, for consistency)

      if (widget.task == null) {
        // Create new task
        await _databaseHelper.insertTask(task);
      } else {
        // Update existing task
        await _databaseHelper.updateTask(task); // Uses task.id
      }
      _syncManager.syncTasksToServer(); // Sync to server
      context.goNamed('home'); // Return to HomeScreen, which will refresh automatically
    } else if (_assignees.isEmpty) {
      setState(() {
        _errorMessage = 'At least one assignee is required';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.task == null ? 'Create Task' : 'Update Task',
        onBack: () => context.goNamed('home'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title', style: CustomStyles.textLabelStyle),
              CustomTextField(
                labelText: 'Title',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Description', style: CustomStyles.textLabelStyle),
              CustomTextField(
                labelText: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ListTile(
                title: Text('Due Date', style: CustomStyles.textLabelStyle),
                subtitle: Text(_formatDueDate(_dueDate)),
                trailing: Icon(Icons.calendar_today, color: Colors.grey),
                onTap: () => _selectDueDate(context),
              ),
              SizedBox(height: 16.0),
              Text('Status', style: CustomStyles.textLabelStyle),
              DropdownButtonFormField<TaskStatus>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                items: TaskStatus.values.map((status) {
                  return DropdownMenuItem<TaskStatus>(
                    value: status,
                    child: Text(status.name.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value ?? TaskStatus.pending;
                  });
                },
              ),
              SizedBox(height: 16.0),
              Text('Priority', style: CustomStyles.textLabelStyle),
              DropdownButtonFormField<Priority>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                items: Priority.values.map((priority) {
                  return DropdownMenuItem<Priority>(
                    value: priority,
                    child: Text(priority.name.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value ?? Priority.medium;
                  });
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Tags',
                style: CustomStyles.textLabelStyle,
              ),
              SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: Icon(Icons.close, size: 16.0),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
              CustomTextField(
                labelText: 'Add tag...',
                controller: _tagController,
                onSubmitted: (value) {
                  _addTag(value!);
                  _tagController.clear();
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Assignees',
                style: CustomStyles.textLabelStyle,
              ),
              SizedBox(height: 8.0),
              ..._assignees.map((assignee) {
                final fullName = assignee['name'] ?? 'Unknown';
                final displayName = _currentUserName == fullName ? '$fullName (You)' : fullName;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AssigneeInitials(fullName: fullName, currentUserName: _currentUserName),
                  title: Text(
                    displayName,
                    style: TextStyle(fontSize: 14.0, color: Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _assignees.remove(assignee);
                      });
                    },
                  ),
                );
              }).toList(),
              SizedBox(height: 8.0),
              CustomButton(
                text: 'Add Assignee',
                onPressed: _showAssigneeSelector,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14.0),
                  ),
                ),
              SizedBox(height: 16.0),
              CustomButton(
                text: widget.task == null ? 'Create Task' : 'Update Task',
                onPressed: _saveTask,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    bool isToday = DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;
    if (isToday) {
      return 'Today, ${DateFormat('hh:mm a').format(date)}';
    }
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }
}
