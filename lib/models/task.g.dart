// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskData _$TaskDataFromJson(Map<String, dynamic> json) => TaskData(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  completionDate: DateTime.parse(json['completionDate'] as String),
  status: $enumDecode(_$TaskStatusEnumMap, json['status']),
  description: json['description'] as String,
  assignees:
      (json['assignees'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
  subtasks:
      (json['subtasks'] as List<dynamic>?)
          ?.map((e) => Subtask.fromJson(e as Map<String, dynamic>))
          .toList(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  priority: $enumDecode(_$PriorityEnumMap, json['priority']),
);

Map<String, dynamic> _$TaskDataToJson(TaskData instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'completionDate': instance.completionDate.toIso8601String(),
  'status': _$TaskStatusEnumMap[instance.status]!,
  'description': instance.description,
  'assignees': instance.assignees,
  'subtasks': instance.subtasks?.map((e) => e.toJson()).toList(),
  'tags': instance.tags,
  'priority': _$PriorityEnumMap[instance.priority]!,
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.inProgress: 'inProgress',
  TaskStatus.completed: 'completed',
};

const _$PriorityEnumMap = {
  Priority.low: 'low',
  Priority.medium: 'medium',
  Priority.high: 'high',
};
