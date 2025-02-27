// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttask/components/task_component.dart';
import 'package:smarttask/models/task.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/utils/helpers.dart';
import 'package:smarttask/utils/sync_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<TaskData> _tasks;
  bool _isLoading = true; // Track loading state
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SyncManager _syncManager = SyncManager.instance;
  late VoidCallback _navigationListener; // Store the listener function
  late GoRouterDelegate _routerDelegate; // Store the GoRouterDelegate reference
  String _searchQuery = ''; // Search query for task names
  DateTime? _selectedDate; // Filter by completion date
  Priority? _selectedPriority; // Filter by priority (low, medium, high)
  List<String> _selectedTags = []; // Filter by tags
  String _userFirstName = ''; // Initialize as empty string

  @override
  void initState() {
    super.initState();
    _routerDelegate = GoRouter.of(context).routerDelegate; // Store GoRouterDelegate
    _navigationListener = () {
      final currentLocation = _routerDelegate.currentConfiguration.fullPath;
      if (currentLocation == '/home') {
        _loadFilteredTasks(); // Refresh filtered tasks when returning to HomeScreen
        _loadUserData(); // Load user data on navigation
      }
    };
    _routerDelegate.addListener(_navigationListener); // Use stored reference
    _checkAuthState(); // Check authentication state and load user data
  }

  @override
  void dispose() {
    _syncManager.dispose(); // Clean up SyncManager
    _routerDelegate.removeListener(_navigationListener); // Use stored reference
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userDataString = prefs.getString('user');

    if (token == null || token.isEmpty) {
      context.goNamed('login'); // Redirect to login if no token
    } else {
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        setState(() {
          _userFirstName = userData['first_name'] ?? 'User'; // Set from SharedPreferences
        });
      }
      _loadFilteredTasks();
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      setState(() {
        _userFirstName = userData['first_name'] ?? 'User'; // Update if changed
      });
    }
  }

  Future<void> _loadFilteredTasks() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    _tasks = await _databaseHelper.getFilteredTasks(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      completionDate: _selectedDate,
      priority: _selectedPriority,
      tags: _selectedTags.isNotEmpty ? _selectedTags : null,
    );
    print('Loaded filtered tasks: ${_tasks.map((task) => task.toJson())}');
    setState(() {
      _isLoading = false; // Stop loading
    });
  }

  Future<void> _saveTaskStatus(int id, TaskStatus status) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      final updatedTask = _tasks[taskIndex].copyWith(
        status: status,
      );
      await _databaseHelper.updateTask(updatedTask);
      setState(() {
        _tasks[taskIndex] = updatedTask;
      });
      _syncManager.syncTasksToServer(); // Updated to public method
    }
  }

  void _toggleTaskStatus(int id) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.id == id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(
          status: _tasks[taskIndex].status == TaskStatus.pending
              ? TaskStatus.completed
              : _tasks[taskIndex].status == TaskStatus.inProgress
                  ? TaskStatus.completed
                  : TaskStatus.pending,
        );
        _saveTaskStatus(id, _tasks[taskIndex].status);
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadFilteredTasks();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadFilteredTasks();
    }
  }

  void _filterByPriority(Priority? priority) {
    setState(() {
      _selectedPriority = priority;
    });
    _loadFilteredTasks();
  }

  void _filterByTags(List<String> tags) {
    setState(() {
      _selectedTags = tags;
    });
    _loadFilteredTasks();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDate = null;
      _selectedPriority = null;
      _selectedTags = [];
    });
    _loadFilteredTasks();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('email');
    setState(() {
      _userFirstName = ''; // Reset username
    });
    context.go('/welcome'); // Redirect to login screen
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setState) {
            return AlertDialog(
              title: Text('Filter Tasks'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Completion Date'),
                      subtitle: Text(_selectedDate == null
                          ? 'None selected'
                          : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                          _loadFilteredTasks();
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Priority'),
                      subtitle: Text(_selectedPriority?.name.capitalize() ?? 'None selected'),
                      onTap: () => _showPriorityFilter(dialogContext, setState),
                    ),
                    ListTile(
                      title: Text('Tags'),
                      subtitle: Text(_selectedTags.isEmpty ? 'None selected' : _selectedTags.join(', ')),
                      onTap: () => _showTagsFilter(dialogContext, setState),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _clearFilters,
                      child: Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _loadFilteredTasks();
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPriorityFilter(BuildContext dialogContext, StateSetter setState) {
    showDialog(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Priority'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Priority.values.map((priority) {
              return RadioListTile<Priority>(
                title: Text(priority.name.capitalize()),
                value: priority,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                  _loadFilteredTasks();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showTagsFilter(BuildContext dialogContext, StateSetter setState) {
    final TextEditingController _tagController = TextEditingController();
    List<String> availableTags = ['urgent', 'personal', 'work', 'meeting']; // Example tags; customize as needed
    List<String> selectedTags = [..._selectedTags]; // Copy current tags

    showDialog(
      context: dialogContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Tags'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...availableTags.map((tag) {
                    return CheckboxListTile(
                      title: Text(tag),
                      value: selectedTags.contains(tag),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                  TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add custom tag...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && !availableTags.contains(value)) {
                        setState(() {
                          availableTags.add(value);
                          selectedTags.add(value);
                        });
                        _tagController.clear();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTags = selectedTags;
                    });
                    _loadFilteredTasks();
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hey, $_userFirstName 👋',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16.0,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$_userFirstName'), // Dynamic avatar
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks by name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: Icon(Icons.search),
                prefixIcon: _searchQuery.isNotEmpty || _selectedDate != null || _selectedPriority != null || _selectedTags.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: _clearFilters, // Clear filters with a single tap
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching
          : _tasks.isEmpty
              ? Center(child: Text('No tasks available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_tasks.length} tasks for you Today',
                            style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                          ),
                          IconButton(
                            icon: Icon(Icons.filter_list),
                            onPressed: () => _showFilterDialog(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Your Tasks',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16.0),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Task(
                              key: ValueKey(
                                  '${task.id}_${DateFormat('yyyy-MM-dd HH:mm').format(task.completionDate)}_${task.status.name}'), // Use id for uniqueness
                              title: task.title,
                              description: task.description,
                              completionDate: task.completionDate,
                              status: task.status,
                              assignees: task.assignees,
                              onStatusChanged: () {
                                if (task.id != null) {
                                  _toggleTaskStatus(task.id!);
                                }
                              },
                              onTap: () {
                                context.go('/task/${task.title}', extra: task.toJson());
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/create-task'); // Navigate to CreateTaskScreen
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
