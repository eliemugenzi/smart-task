import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/models/task.dart';


class Task extends StatelessWidget {
  final String title;
  final String description;
  final DateTime completionDate;
  final TaskStatus status;
  final List<dynamic> assignees;
  final VoidCallback? onStatusChanged; // Callback for status changes
  final VoidCallback? onTap; // Callback for tapping to view details

  const Task({
    super.key,
    required this.title,
    required this.description,
    required this.completionDate,
    required this.status,
    required this.assignees,
    this.onStatusChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(completionDate);
    bool isToday = DateTime.now().day == completionDate.day &&
        DateTime.now().month == completionDate.month &&
        DateTime.now().year == completionDate.year;
    if (isToday) {
      formattedDate = 'Today, ${DateFormat('hh:mm a').format(completionDate)}';
    }

    return GestureDetector(
      onTap: onTap,
      child: Dismissible(
        key: Key('${title}_${formattedDate}_${status.name}'), // Unique key including status
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          if (onStatusChanged != null) {
            onStatusChanged!(); // Notify parent to update status
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task ${status == TaskStatus.completed ? "reopened" : "completed"}')),
          );
        },
        background: _buildSwipeBackground(context),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: status == TaskStatus.completed ? Colors.green[50] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (status == TaskStatus.completed)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 16.0),
                            ),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (status == TaskStatus.completed)
                        Row(
                          children: List.generate(3, (index) => Icon(Icons.star, color: Colors.grey, size: 12.0))
                              .map((icon) => Padding(
                                    padding: const EdgeInsets.only(left: 2.0),
                                    child: icon,
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: assignees.take(2).map((assignee) {
                    String? avatarUrl;
                    if (assignee is Map) {
                      avatarUrl = assignee['avatar'] as String?;
                    } else if (assignee is String) {
                      avatarUrl = assignee; // Fallback for plain strings
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: CircleAvatar(
                        radius: 16.0,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? Icon(Icons.person, color: Colors.grey) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context) {
    return status == TaskStatus.pending || status == TaskStatus.inProgress
        ? Container(
            color: Colors.green, // Green for completing (pending/inProgress -> completed)
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.check, color: Colors.white),
          )
        : Container(
            color: Colors.red, // Red for re-opening (completed -> pending/inProgress)
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.undo, color: Colors.white), // Undo icon for re-opening
          );
  }
}