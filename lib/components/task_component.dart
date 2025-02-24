import 'package:flutter/material.dart';

enum TaskStatus { pending, completed }

class Task extends StatelessWidget {
  final String title;
  final String description;
  final DateTime completionDate;
  final List<dynamic> assignees;
  final TaskStatus status;
  final double elevation;
  final double borderRadius;
  final Color? backgroundColor;
  const Task({
    super.key,
    required this.title,
    required this.description,
    required this.completionDate,
    required this.status,
    required this.assignees,
    this.elevation = 2.0,
    this.borderRadius = 10.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: backgroundColor ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    completionDate.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(children: assignees.take(2).map((assignee) {
              return CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(assignee['avatar']),
              );
            }).toList(),)
          ],
        ),
      ),
    );
  }
}
