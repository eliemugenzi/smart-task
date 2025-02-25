import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/models/task.dart';
import 'package:smarttask/utils/styles.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskJson = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (taskJson == null) {
      throw Exception('Task data is required');
    }
    final task = TaskData.fromJson(taskJson);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700], // Exact blue from the image
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            context.go('/home');
          },
        ),
        title: Text(
          'Task details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text(
              task.status.name.toUpperCase(),
              style: TextStyle(color: Colors.white70, fontSize: 14.0),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // color: Colors.grey[50], // Light grey background for the body
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.0),
          ), // Rounded top corners
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Task title', style: CustomStyles.textLabelStyle),
              const SizedBox(height: 10),
              Text(task.title),
              const SizedBox(height: 10),
              // Description
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.black87,
                  height: 1.5, // Line height for better readability
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: CustomStyles.textLabelStyle),
                  Row(children: [
                    task.status != TaskStatus.completed
                        ? Icon(Icons.event_repeat, color: Colors.red)
                        : Icon(Icons.done, color: Colors.green)
                  ],)
                ],
              ),
                            SizedBox(height: 16.0),

              // Due Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Due Date', style: CustomStyles.textLabelStyle),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey,
                        size: 16.0,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        _formatDueDate(task.completionDate),
                        style: TextStyle(fontSize: 14.0, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              // Assigned
              Text(
                'Assigned',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.0),
              ...task.assignees.map((assignee) {
                return ListTile(
                  contentPadding:
                      EdgeInsets.zero, // Remove default padding for exact match
                  leading: CircleAvatar(
                    radius: 16.0,
                    backgroundImage: NetworkImage(
                      assignee['avatar'] ??
                          'https://i.pravatar.cc/150?u=default',
                    ),
                  ),
                  title: Text(
                    assignee['name'] ?? 'Unknown',
                    style: TextStyle(fontSize: 14.0, color: Colors.black87),
                  ),
                  dense: true, // Compact spacing to match the image
                );
              }),
              SizedBox(height: 16.0),

              task.subtasks != null
                  ? Column(
                    children: [
                      // Subtasks
                      Text(
                        'Subtasks',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.0),
                      ...task.subtasks!.map((subtask) {
                        return CheckboxListTile(
                          contentPadding:
                              EdgeInsets.zero, // Remove default padding
                          title: Text(
                            subtask.title,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.black87,
                            ),
                          ),
                          value: subtask.isCompleted,
                          onChanged: (bool? value) {
                            // Add logic to update subtask status (e.g., state management)
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.green,
                          checkColor:
                              Colors.white, // Match checkbox check color
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              4.0,
                            ), // Rounded checkbox
                          ),
                          dense: true, // Compact spacing
                        );
                      }),
                    ],
                  )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    bool isToday =
        DateTime.now().day == date.day &&
        DateTime.now().month == date.month &&
        DateTime.now().year == date.year;
    if (isToday) {
      return 'Today, ${DateFormat('hh:mm a').format(date)}';
    }
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }
}
