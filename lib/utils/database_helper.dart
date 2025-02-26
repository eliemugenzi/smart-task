import 'dart:convert';

import 'package:smarttask/models/task.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final db = await openDatabase(filePath, version: 1, onCreate: _createDB);
    return db;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  completionDate TEXT NOT NULL,
  status TEXT NOT NULL,
  description TEXT NOT NULL,
  assignees TEXT NOT NULL,
  subtasks TEXT
)
''');
  }

  Future<int> insertTask(TaskData task) async {
    final db = await database;
    final id = await db.insert('tasks', {
      'title': task.title,
      'completionDate': task.completionDate.toIso8601String(),
      'status': task.status.name,
      'description': task.description,
      'assignees': _encodeAssignees(task.assignees),
      'subtasks': _encodeSubTasks(task.subtasks ?? []),
    });
    return id;
  }

  Future<List<TaskData>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks');
    print('Maps:____$maps');
    return List.generate(maps.length, (i) {
      return TaskData(
        title: maps[i]['title'] as String,
        completionDate: DateTime.parse(maps[i]['completionDate'] as String),
        status: _parseStatus(maps[i]['status'] as String),
        description: maps[i]['description'] as String,
        assignees: _decodeAssignees(maps[i]['assignees'] as String),
        subtasks:
            _decodeSubTasks(maps[i]['subtasks'] as String),
      );
    });
  }

  Future<int> updateTask(TaskData task) async {
    final db = await database;
    return await db.update('tasks', {
      'completionDate': task.completionDate.toIso8601String(),
      'status': task.status.name,
      'description': task.description,
      'assignees': _encodeAssignees(task.assignees),
      'subtasks': _encodeSubTasks(task.subtasks ?? []),
    }, where: 'title = ?', whereArgs: [task.title]);
  }

  Future<int> deleteTask(String title) async {
    final db = await database;
    return await db.delete('tasks', where: 'title = ?', whereArgs: [title]);
  }

  String _encodeAssignees(List<Map<String, dynamic>> assignees) {
   return jsonEncode(assignees); // Use JSON encoding for reliability
  }

  List<Map<String, dynamic>> _decodeAssignees(String encoded) {
        print('Decoded: $encoded');

    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.cast<Map<String, dynamic>>();
  }
  String _encodeSubTasks(List<Subtask> subtasks) {
    return jsonEncode(subtasks.map((subtask) => subtask.toJson()).toList()); // Use JSON encoding
  }

  List<Subtask> _decodeSubTasks(String encoded) {
   final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Subtask.fromJson(e as Map<String, dynamic>)).toList();
  }

  TaskStatus _parseStatus(String statusString) {
    switch (statusString) {
      case 'completed':
        return TaskStatus.completed;
      case 'inProgress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.pending;
    }
  }


}
