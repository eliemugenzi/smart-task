import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:smarttask/models/task.dart';
import 'dart:convert'; // For jsonEncode/jsonDecode

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  // Add a public method for testing to set the database instance
  @visibleForTesting
  static void setDatabaseForTesting(Database? db) {
    _database = db; // Allow direct setting for tests
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'test_tasks.db');

    return await openDatabase(path, version: 4, onCreate: _createDB, onUpgrade: _upgradeDB);
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
      tags TEXT NOT NULL DEFAULT '[]',
      priority TEXT NOT NULL DEFAULT 'medium'
    )
    ''');
    await db.execute('CREATE INDEX idx_title ON tasks(title)');
    await db.execute('CREATE INDEX idx_completion_date ON tasks(completionDate)');
    await db.execute('CREATE INDEX idx_status ON tasks(status)');
    await db.execute('CREATE INDEX idx_priority ON tasks(priority)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      // Ensure all columns and indexes exist (using assignees)
      await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        completionDate TEXT NOT NULL,
        status TEXT NOT NULL,
        description TEXT NOT NULL,
        assignees TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        priority TEXT NOT NULL DEFAULT 'medium'
      )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_title ON tasks(title)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_completion_date ON tasks(completionDate)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_status ON tasks(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_priority ON tasks(priority)');
      await db.execute('PRAGMA user_version = 4');
    }
  }

  Future<int> insertTask(TaskData task) async {
    final db = await database;
    final id = await db.insert('tasks', {
      'title': task.title,
      'completionDate': task.completionDate.toIso8601String(),
      'status': task.status.name,
      'description': task.description,
      'assignees': jsonEncode(task.assignees),
      'tags': jsonEncode(task.tags ?? []),
      'priority': task.priority.name,
    });
  
    return id;
  }

  Future<int> updateTask(TaskData task) async {
    final db = await database;
    final rowsAffected = await db.update(
      'tasks',
      {
        'title': task.title,
        'completionDate': task.completionDate.toIso8601String(),
        'status': task.status.name,
        'description': task.description,
        'assignees': jsonEncode(task.assignees),
        'tags': jsonEncode(task.tags ?? []),
        'priority': task.priority.name,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
   
    return rowsAffected;
  }

  Future<List<TaskData>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks');
    final tasks = List.generate(maps.length, (i) {
      final task = TaskData(
        id: maps[i]['id'] as int?,
        title: maps[i]['title'] as String,
        completionDate: DateTime.parse(maps[i]['completionDate'] as String),
        status: _parseStatus(maps[i]['status'] as String),
        description: maps[i]['description'] as String,
        assignees: _decodeAssignees(maps[i]['assignees'] as String),
        tags: _decodeTags(maps[i]['tags'] as String),
        priority: _parsePriority(maps[i]['priority'] as String),
      );
      return task;
    });
    return tasks;
  }

  Future<List<TaskData>> getFilteredTasks({
    String? searchQuery,
    DateTime? completionDate,
    Priority? priority,
    List<String>? tags,
  }) async {
    final db = await database;

    print('Wegfgf: $priority, $completionDate');
    
    // Start with getting all tasks
    final List<Map<String, dynamic>> allTasks = await db.query('tasks');
    
    // Convert to TaskData objects
    List<TaskData> tasks = allTasks.map((map) {
      return TaskData(
        id: map['id'] as int?,
        title: map['title'] as String,
        completionDate: DateTime.parse(map['completionDate'] as String),
        status: _parseStatus(map['status'] as String),
        description: map['description'] as String,
        assignees: _decodeAssignees(map['assignees'] as String),
        tags: _decodeTags(map['tags'] as String),
        priority: _parsePriority(map['priority'] as String),
      );
    }).toList();
    
    // Apply filters in memory for more accurate matching
    if (searchQuery != null && searchQuery.isNotEmpty) {
      tasks = tasks.where((task) => 
        task.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    
    if (completionDate != null) {
      final startOfDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
      final endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));
      tasks = tasks.where((task) => 
        task.completionDate.isAfter(startOfDay.subtract(Duration(seconds: 1))) && 
        task.completionDate.isBefore(endOfDay.add(Duration(seconds: 1)))).toList();
    }
    
    if (priority != null) {
      tasks = tasks.where((task) => task.priority == priority).toList();
    }
    
    if (tags != null && tags.isNotEmpty) {
      tasks = tasks.where((task) {
        // Check if any of the selected tags exist in the task tags
        final taskTags = task.tags ?? [];
        return tags.any((tag) => taskTags.contains(tag));
      }).toList();
    }
    
    return tasks;
  }

  Future<int> deleteTask(int? id) async {
    if (id == null) return 0; // Guard against null id
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  List<Map<String, dynamic>> _decodeAssignees(String encoded) {
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _encodeTags(List<String>? tags) {
    return jsonEncode(tags ?? []);
  }

  List<String> _decodeTags(String encoded) {
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.cast<String>().toList();
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

  Priority _parsePriority(String priorityString) {
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
}