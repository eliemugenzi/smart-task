// models/task.dart
class TaskData {
  final int? id;
  final String title;
  final DateTime completionDate;
  final TaskStatus status;
  final String description;
  final List<Map<String, dynamic>> assignees; // List of maps with 'name' and 'avatar'
  final List<String>? tags;
  final Priority priority;

  TaskData({
    this.id,
    required this.title,
    required this.completionDate,
    required this.status,
    required this.description,
    required this.assignees,
    this.tags,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completionDate': completionDate.toIso8601String(),
    'status': status.name,
    'description': description,
    'assignees': assignees,
    'tags': tags,
    'priority': priority.name,
  };

  factory TaskData.fromJson(Map<String, dynamic> json) => TaskData(
    id: json['id'] as int?,
    title: json['title'] as String,
    completionDate: DateTime.parse(json['completionDate'] as String),
    status: _parseStatus(json['status'] as String),
    description: json['description'] as String,
    assignees: (json['assignees'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList(),
    tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    priority: _parsePriority(json['priority'] as String),
  );

  static TaskStatus _parseStatus(String statusString) {
    switch (statusString) {
      case 'completed':
        return TaskStatus.completed;
      case 'inProgress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.pending;
    }
  }

  static Priority _parsePriority(String priorityString) {
    switch (priorityString) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        return Priority.medium;
    }
  }

  TaskData copyWith({
    int? id,
    String? title,
    DateTime? completionDate,
    TaskStatus? status,
    String? description,
    List<Map<String, dynamic>>? assignees,
    List<String>? tags,
    Priority? priority,
  }) {
    return TaskData(
      id: id ?? this.id,
      title: title ?? this.title,
      completionDate: completionDate ?? this.completionDate,
      status: status ?? this.status,
      description: description ?? this.description,
      assignees: assignees ?? this.assignees,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
    );
  }
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
}

enum Priority {
  low,
  medium,
  high,
}