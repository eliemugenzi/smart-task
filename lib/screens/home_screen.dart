import 'package:flutter/material.dart';
import 'package:smarttask/components/project_card_component.dart';
import 'package:smarttask/components/task_component.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
              'Hey, Adam 👋',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            CircleAvatar(
              radius: 16.0,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=adam'), // Using pravatar.cc for Adam
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '4 tasks for you Today',
                style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
              ),
              SizedBox(height: 16.0),
                // Your Tasks Section
              Text(
                'Your Tasks',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              Task(
                title: 'Research competitors',
                description: 'Analyze competitor products and strategies',
                completionDate: DateTime.now().subtract(Duration(minutes: 30)), // Example: 01:00 PM today
                status: TaskStatus.completed,
                assignees: [
                  {'avatar': 'https://i.pravatar.cc/150?u=user7'},
                  {'avatar': 'https://i.pravatar.cc/150?u=user8'},
                ],
              ),
              Task(
                title: 'Sitemap & User Flow',
                description: 'Design the site structure and user navigation',
                completionDate: DateTime.now().subtract(Duration(minutes: 10)), // Example: 01:30 PM today
                status: TaskStatus.pending,
                assignees: [
                  {'avatar': 'https://i.pravatar.cc/150?u=user9'},
                  {'avatar': 'https://i.pravatar.cc/150?u=user10'},
                ],
              ),
              Task(
                title: 'Wireframing',
                description: 'Create wireframes for key screens',
                completionDate: DateTime.now().add(Duration(hours: 1, minutes: 10)), // Example: 02:50 PM today
                status: TaskStatus.pending,
                assignees: [
                  {'avatar': 'https://i.pravatar.cc/150?u=user11'},
                  {'avatar': 'https://i.pravatar.cc/150?u=user12'},
                ],
              ),
              Task(
                title: 'Moodboard',
                description: 'Compile inspiration images for design',
                completionDate: DateTime.now().add(Duration(hours: 10, minutes: 50)), // Example: 11:30 PM today
                status: TaskStatus.pending,
                assignees: [
                  {'avatar': 'https://i.pravatar.cc/150?u=user13'},
                  {'avatar': 'https://i.pravatar.cc/150?u=user14'},
                ],
              ),
            ],
          ),
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