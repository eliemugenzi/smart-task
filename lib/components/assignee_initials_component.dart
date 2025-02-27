// components/assignee_initials.dart
import 'package:flutter/material.dart';

class AssigneeInitials extends StatelessWidget {
  final String fullName;
  final String? currentUserName; // For "(You)" check

  const AssigneeInitials({
    super.key,
    required this.fullName,
    this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = currentUserName == fullName ? '$fullName (You)' : fullName;
    return Tooltip(
      message: displayName,
      child: CircleAvatar(
        radius: 16.0,
        backgroundColor: Colors.lightBlueAccent,
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}