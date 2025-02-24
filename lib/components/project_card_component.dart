import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final int taskCount;
  final double progress;
  final List<dynamic> assignees;
  final IconData icon;
  final Color backgroundColor;

  const ProjectCard({
    Key? key,
    required this.title,
    required this.taskCount,
    required this.progress,
    required this.assignees,
    required this.icon,
    this.backgroundColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 24.0),
                    SizedBox(width: 8.0),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$taskCount TASKS',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            // Use ConstrainedBox to ensure finite constraints for LinearProgressIndicator
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 0, // Minimum width to prevent infinite constraints
                maxWidth: double.infinity, // Take full available width
                minHeight: 8.0, // Match progress bar height
                maxHeight: 8.0, // Ensure fixed height
              ),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: assignees.take(3).map((assignee) {
                String? avatarUrl;
                if (assignee is Map) {
                  avatarUrl = assignee['avatar'] as String?;
                } else if (assignee is String) {
                  avatarUrl = assignee; // Fallback for plain strings
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: CircleAvatar(
                    radius: 12.0,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Icon(Icons.person, color: Colors.grey) : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}