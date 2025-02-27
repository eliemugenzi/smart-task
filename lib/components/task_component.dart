// components/task_component.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Task extends StatefulWidget {
  final String title;
  final String description;
  final DateTime completionDate;
  final TaskStatus status;
  final List<Map<String, dynamic>> assignees; // Updated from List<dynamic> to match TaskData
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
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  String? _currentUserName; // Store the current user's full name

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // Load current user data
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user');
    if (userDataString != null) {
      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      setState(() {
        _currentUserName = '${userData['first_name']} ${userData['last_name']}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(widget.completionDate);
    bool isToday = DateTime.now().day == widget.completionDate.day &&
        DateTime.now().month == widget.completionDate.month &&
        DateTime.now().year == widget.completionDate.year;
    if (isToday) {
      formattedDate = 'Today, ${DateFormat('hh:mm a').format(widget.completionDate)}';
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Dismissible(
        key: Key('${widget.title}_${formattedDate}_${widget.status.name}'), // Unique key including status
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          if (widget.onStatusChanged != null) {
            widget.onStatusChanged!(); // Notify parent to update status
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task ${widget.status == TaskStatus.completed ? "reopened" : "completed"}')),
          );
        },
        background: _buildSwipeBackground(context),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: widget.status == TaskStatus.completed ? Colors.green[50] : Colors.white,
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
                          if (widget.status == TaskStatus.completed)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 16.0),
                            ),
                          Expanded(
                            child: Text(
                              widget.title,
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
                        widget.description,
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
                      if (widget.status == TaskStatus.completed)
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
                  children: widget.assignees.take(2).map((assignee) {
                    final fullName = assignee['name'] ?? 'Unknown';
                    final displayName = _currentUserName == fullName ? '$fullName (You)' : fullName;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Tooltip(
                        message: displayName, // Show full name (with "(You)" if applicable) on hover
                        child: CircleAvatar(
                          radius: 16.0,
                          backgroundColor: Colors.blue,
                          child: Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                            style: TextStyle(color: Colors.white, fontSize: 10.0),
                          ),
                        ),
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
    return widget.status == TaskStatus.pending || widget.status == TaskStatus.inProgress
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