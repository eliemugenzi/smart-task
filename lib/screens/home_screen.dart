import 'package:flutter/material.dart';
import 'package:smarttask/components/app_bar_compoment.dart';
import 'package:smarttask/components/assignee_initials_component.dart';
import 'package:smarttask/components/filter_dialog_component.dart';
import 'package:smarttask/components/task_component.dart';
import 'package:smarttask/components/text_field_component.dart';
import 'package:smarttask/models/task.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/services/notification_service.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/utils/sync_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<TaskData> _tasks = [];
  bool _isLoading = true; // Track loading state
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SyncManager _syncManager = SyncManager.instance;
  late VoidCallback _navigationListener; // Store the listener function
  late GoRouterDelegate _routerDelegate; // Store the GoRouterDelegate reference
  String _searchQuery = ''; // Search query for task names
  TextEditingController _searchController = TextEditingController(); // Controller for search field
  DateTime? _selectedDate; // Filter by completion date
  Priority? _selectedPriority; // Filter by priority (low, medium, high)
  List<String> _selectedTags = []; // Filter by tags
  String _userFirstName = ''; // Initialize as empty string

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery; // Initialize search controller with current query
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
    _searchController.dispose(); // Dispose of the text controller
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
      _searchController.clear(); // Clear the search field
      _selectedDate = null;
      _selectedPriority = null;
      _selectedTags = [];
    });
    _loadFilteredTasks();
  }

  // Method to check if any filters are active
  bool _areFiltersActive() {
    return _searchQuery.isNotEmpty || 
           _selectedDate != null || 
           _selectedPriority != null || 
           _selectedTags.isNotEmpty;
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('email');
    setState(() {
      _userFirstName = ''; // Reset username
    });
    context.goNamed('login'); // Redirect to login screen
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        selectedDate: _selectedDate,
        selectedPriority: _selectedPriority,
        selectedTags: _selectedTags,
        onApply: (date, priority, tags) {
          setState(() {
            _selectedDate = date;
            _selectedPriority = priority;
            _selectedTags = tags;
          });
          _loadFilteredTasks(); // Load tasks with the new filters
        },
        onClear: _clearFilters,
      ),
    );
  }

  Future<void> _scheduleTaskReminders() async {
    final tasks = await _databaseHelper.getTasks();
    await NotificationService.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hey, $_userFirstName 👋',
        actions: [
          PopupMenuButton<String>(
            icon: AssigneeInitials(fullName: _userFirstName, currentUserName: _userFirstName),
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar at the top
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          labelText: 'Search tasks by name...',
                          controller: _searchController,
                          onSubmitted: (value) => _onSearchChanged(value!),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: _searchQuery.isNotEmpty 
                          ? () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                              _loadFilteredTasks();
                            } 
                          : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  
                  // Tasks count and filter row - always visible
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _areFiltersActive()
                          ? RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                                children: [
                                  TextSpan(text: '${_tasks.length} filtered '),
                                  TextSpan(
                                    text: 'tasks',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              '${_tasks.length} tasks for you Today',
                              style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                            ),
                      Row(
                        children: [
                          // Only show clear filters button if filters are active
                          if (_areFiltersActive())
                            TextButton.icon(
                              icon: Icon(Icons.clear_all, size: 18),
                              label: Text('Clear'),
                              onPressed: _clearFilters,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size(0, 36),
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.filter_list),
                            onPressed: () => _showFilterDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  
                  // Your Tasks header
                  Text(
                    'Your Tasks',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),
                  
                  // Task list or empty state
                  Expanded(
                    child: _tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No tasks found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _areFiltersActive()
                                      ? 'Try adjusting your filters'
                                      : 'Add a new task to get started',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return Task(
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
          context.go('/create-task');
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}