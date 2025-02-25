import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/components/task_component.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smarttask/models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<TaskData> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = [
      TaskData(
        title: 'Research competitors',
        description: 'Analyze competitor products and strategies',
        completionDate: DateTime.now().subtract(Duration(minutes: 30)),
        status: TaskStatus.completed,
        assignees: [
          {'avatar': 'https://i.pravatar.cc/150?u=user7', 'name': 'Arrkid'},
          {'avatar': 'https://i.pravatar.cc/150?u=user8', 'name': 'Skengman'},
        ],
        subtasks: [
          Subtask(
            title: "Trip",
            isCompleted: true,
          ),
          Subtask(
            title: "Pitch",
            isCompleted: false,
          ),
        ]
      ),
      TaskData(
        title: 'Sitemap & User Flow',
        description: 'Design the site structure and user navigation',
        completionDate: DateTime.now().subtract(Duration(minutes: 10)),
        status: TaskStatus.pending,
        assignees: [
          {'avatar': 'https://i.pravatar.cc/150?u=user9', 'name': 'Jenny'},
          {'avatar': 'https://i.pravatar.cc/150?u=user10', 'name': 'John'},
        ],
      ),
      TaskData(
        title: 'Wireframing',
        description: 'Create wireframes for key screens',
        completionDate: DateTime.now().add(Duration(hours: 1, minutes: 10)),
        status: TaskStatus.pending,
        assignees: [
          {'avatar': 'https://i.pravatar.cc/150?u=user11', 'name': 'Jane'},
          {'avatar': 'https://i.pravatar.cc/150?u=user12', 'name': 'Doe'},
        ],
      ),
      TaskData(
        title: 'Moodboard',
        description: 'Compile inspiration images for design',
        completionDate: DateTime.now().add(Duration(hours: 10, minutes: 50)),
        status: TaskStatus.pending,
        assignees: [
          {'avatar': 'https://i.pravatar.cc/150?u=user13', 'name': 'Elie'},
          {'avatar': 'https://i.pravatar.cc/150?u=user14', 'name': 'Doe'},
        ],
      ),
    ];
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = _tasks.map((task) {
        final statusString = prefs.getString('task_${task.title}_status') ?? task.status.name;
        return TaskData(
          title: task.title,
          description: task.description,
          completionDate: task.completionDate,
          status: statusString == 'completed' ? TaskStatus.completed : TaskStatus.pending,
          assignees: task.assignees,
          subtasks: task.subtasks,
        );
      }).toList();
    });
  }

  Future<void> _saveTaskStatus(String title, TaskStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('task_${title}_status', status.name);
  }

  void _toggleTaskStatus(String title) {
    setState(() {
      final taskIndex = _tasks.indexWhere((task) => task.title == title);
      if (taskIndex != -1) {
        _tasks[taskIndex] = TaskData(
          title: _tasks[taskIndex].title,
          description: _tasks[taskIndex].description,
          completionDate: _tasks[taskIndex].completionDate,
          status: _tasks[taskIndex].status == TaskStatus.pending ? TaskStatus.completed : TaskStatus.pending,
          assignees: _tasks[taskIndex].assignees,
        );
        _saveTaskStatus(title, _tasks[taskIndex].status);
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '4 tasks for you Today',
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
                shrinkWrap: true, // Prevents infinite height issues
                physics: AlwaysScrollableScrollPhysics(), // Ensures scrollability even with few items
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return Task(
                    key: ValueKey('$task.title_${DateFormat('yyyy-MM-dd HH:mm').format(task.completionDate)}_${task.status.name}'),
                    title: task.title,
                    description: task.description,
                    completionDate: task.completionDate,
                    status: task.status,
                    assignees: task.assignees,
                    onStatusChanged: () => _toggleTaskStatus(task.title),
                    onTap: () => {
                      // Navigate to task details screen
                      context.go('/task/${task.title}', extra: task.toJson()),
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
          // Add task logic here
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
