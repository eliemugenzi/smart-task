// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/models/task.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/utils/helpers.dart';
import 'package:smarttask/utils/sync_manager.dart';
import 'package:smarttask/utils/styles.dart'; // Assuming CustomStyles is defined here

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
  DateTime _dueDate = DateTime.now(); // Updated from completionDate for consistency with your file
  TaskStatus _status = TaskStatus.pending;
  Priority _priority = Priority.medium; // Default to medium
  List<Map<String, dynamic>> _assignees = [
    {'name': 'Leroy Jenkins', 'avatar': 'https://i.pravatar.cc/150?u=leroy'},
    {'name': 'Janna Dark', 'avatar': 'https://i.pravatar.cc/150?u=janna'},
  ];
  List<Subtask> _subtasks = [Subtask(title: '')];
  List<String> _tags = []; // New field for tags
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SyncManager _syncManager = SyncManager.instance;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.completionDate; // Updated from completionDate for consistency
      _status = widget.task!.status;
      _priority = widget.task!.priority; // Initialize priority
      _assignees = widget.task!.assignees;
      _subtasks = widget.task!.subtasks ?? [Subtask(title: '')]; // Handle nullable subtasks
      _tags = widget.task!.tags ?? []; // Initialize tags
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

  void _addSubtask() {
    setState(() {
      _subtasks.add(Subtask(title: ''));
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      if (_subtasks.length > 1) {
        _subtasks.removeAt(index);
      }
    });
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

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final task = TaskData(
        id: widget.task?.id, // Preserve the original id for updates
        title: _titleController.text,
        completionDate: _dueDate, // Updated from dueDate for consistency
        status: _status,
        description: _descriptionController.text,
        assignees: _assignees,
        subtasks: _subtasks.where((subtask) => subtask.title.isNotEmpty).map((subtask) => Subtask(
          title: subtask.title,
          isCompleted: subtask.isCompleted, // Preserve completion status for updates
        )).toList().isEmpty ? null : _subtasks.where((subtask) => subtask.title.isNotEmpty).map((subtask) => Subtask(
          title: subtask.title,
          isCompleted: subtask.isCompleted, // Preserve completion status for updates
        )).toList(), // Handle nullable subtasks
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
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: Text(
          widget.task == null ? 'Create Task' : 'Update Task',
          style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.goNamed('home'), // Use named route for back navigation
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title', style: CustomStyles.textLabelStyle),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              Text('Description', style: CustomStyles.textLabelStyle),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
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
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add tag...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add, color: Colors.blue),
                    onPressed: () {
                      _addTag(_tagController.text);
                      _tagController.clear();
                    },
                  ),
                ),
                controller: _tagController, // Reusing title controller for simplicity; consider a new one for tags
                onSubmitted: (value) {
                  _addTag(value);
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
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16.0,
                    backgroundImage: NetworkImage(assignee['avatar'] ?? 'https://i.pravatar.cc/150?u=default'),
                  ),
                  title: Text(
                    assignee['name'] ?? 'Unknown',
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
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _assignees.add({
                      'name': 'New Assignee',
                      'avatar': 'https://i.pravatar.cc/150?u=new${_assignees.length}',
                    });
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: Text('Add Assignee', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 16.0),
              Text(
                'Subtasks',
                style: CustomStyles.textLabelStyle,
              ),
              SizedBox(height: 8.0),
              ..._subtasks.asMap().entries.map((entry) {
                final index = entry.key;
                final subtask = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: subtask.title,
                          decoration: InputDecoration(
                            hintText: 'Enter subtask',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _subtasks[index] = subtask.copyWith(title: value); // Use copyWith for Subtask
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeSubtask(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
              SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: _addSubtask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: Text('Add Subtask', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                ),
                child: Text(widget.task == null ? 'Create Task' : 'Update Task',
                    style: TextStyle(color: Colors.white, fontSize: 16.0)),
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
