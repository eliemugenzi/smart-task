// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:smarttask/components/task_component.dart';
import 'package:smarttask/models/task.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/utils/sync_manager.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _routerDelegate = GoRouter.of(context).routerDelegate; // Store GoRouterDelegate
    _navigationListener = () {
      final currentLocation = _routerDelegate.currentConfiguration.fullPath;
      if (currentLocation == '/') {
        _loadTasks(); // Refresh tasks when returning to HomeScreen
      }
    };
    _routerDelegate.addListener(_navigationListener); // Use stored reference
    _loadTasks();
  }

  @override
  void dispose() {
    _syncManager.dispose(); // Clean up SyncManager
    _routerDelegate.removeListener(_navigationListener); // Use stored reference
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    final loadedTasks = await _databaseHelper.getTasks();
    print('Loaded tasks: ${loadedTasks.map((task)=> task.toJson())}');
    setState(() {
      _tasks = loadedTasks;
      _isLoading = false; // Stop loading
    });
  }

  Future<void> _saveTaskStatus(int id, TaskStatus status) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == id);
    if (taskIndex != -1) {
      final updatedTask = TaskData(
        id: _tasks[taskIndex].id, // Added to preserve ID
        title: _tasks[taskIndex].title,
        completionDate: _tasks[taskIndex].completionDate, // Updated from dueDate
        status: status,
        description: _tasks[taskIndex].description,
        assignees: _tasks[taskIndex].assignees,
        subtasks: _tasks[taskIndex].subtasks, // Handle nullable
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
        _tasks[taskIndex] = TaskData(
          id: _tasks[taskIndex].id, // Added to preserve ID
          title: _tasks[taskIndex].title,
          completionDate: _tasks[taskIndex].completionDate, // Updated from dueDate
          status: _tasks[taskIndex].status == TaskStatus.pending
              ? TaskStatus.completed
              : _tasks[taskIndex].status == TaskStatus.inProgress
                  ? TaskStatus.completed
                  : TaskStatus.pending,
          description: _tasks[taskIndex].description,
          assignees: _tasks[taskIndex].assignees,
          subtasks: _tasks[taskIndex].subtasks, // Handle nullable
        );
        _saveTaskStatus(id, _tasks[taskIndex].status);
      }
    });
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
              'Hey, Elie 👋',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            CircleAvatar(
              radius: 16.0,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=elie'), // Using pravatar.cc
            ),
          ],
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
                      Text(
                        '${_tasks.length} tasks for you Today',
                        style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16.0),
                      // Your Tasks Section (now in a scrollable ListView)
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
                                  '$task.title_${DateFormat('yyyy-MM-dd HH:mm').format(task.completionDate)}_${task.status.name}'), // Updated from dueDate
                              title: task.title,
                              description: task.description,
                              completionDate: task.completionDate, // Updated from dueDate
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
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: Colors.grey),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
            label: '',
          ),
        ],
      ),
    );
  }
}