import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

enum TaskStatus { pending, inProgress, completed }

class Subtask {
  final String title;
  final bool isCompleted;

  Subtask({required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool,
  );
}

@JsonSerializable(explicitToJson: true)
class TaskData {
  final String title;
  final DateTime completionDate;
  final TaskStatus status;
  final String description;
  final List<Map<String, dynamic>> assignees;
  final List<Subtask>? subtasks;

  TaskData({
    required this.title,
    required this.completionDate,
    required this.status,
    required this.description,
    required this.assignees,
     this.subtasks,
  });

  factory TaskData.fromJson(Map<String, dynamic> json) => _$TaskDataFromJson(json);

  Map<String, dynamic> toJson() => _$TaskDataToJson(this);
}

generateJson() {
  // Run this command in your terminal to generate the JSON serialization code:
  // flutter pub run build_runner build --delete-conflicting-outputs
}