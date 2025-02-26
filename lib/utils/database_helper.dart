// utils/database_helper.dart
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

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
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
      subtasks TEXT NOT NULL,
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
    if (oldVersion < 3) {
      await db.execute('DELETE FROM tasks');
      await db.execute('DELETE FROM sqlite_sequence WHERE name = "tasks"');
      await db.execute('ALTER TABLE tasks ADD COLUMN tags TEXT NOT NULL DEFAULT \'[]\'');
      await db.execute('ALTER TABLE tasks ADD COLUMN priority TEXT NOT NULL DEFAULT \'medium\'');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_title ON tasks(title)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_completion_date ON tasks(completionDate)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_status ON tasks(status)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_priority ON tasks(priority)');
      await db.execute('PRAGMA user_version = 3');
    }
  }

  Future<int> insertTask(TaskData task) async {
    final db = await database;
    return await db.insert('tasks', {
      'title': task.title,
      'completionDate': task.completionDate.toIso8601String(),
      'status': task.status.name,
      'description': task.description,
      'assignees': _encodeAssignees(task.assignees),
      'subtasks': _encodeSubtasks(task.subtasks ?? []),
      'tags': _encodeTags(task.tags ?? []),
      'priority': task.priority.name,
    });
  }

  Future<List<TaskData>> getTasks() async {
    final db = await database;
    final maps = await db.query('tasks');
    return List.generate(maps.length, (i) {
      return TaskData(
        id: maps[i]['id'] as int?,
        title: maps[i]['title'] as String,
        completionDate: DateTime.parse(maps[i]['completionDate'] as String),
        status: _parseStatus(maps[i]['status'] as String),
        description: maps[i]['description'] as String,
        assignees: _decodeAssignees(maps[i]['assignees'] as String),
        subtasks: _decodeSubtasks(maps[i]['subtasks'] as String),
        tags: _decodeTags(maps[i]['tags'] as String),
        priority: _parsePriority(maps[i]['priority'] as String),
      );
    });
  }

  Future<List<TaskData>> getFilteredTasks({
    String? searchQuery, // For fuzzy search on title
    DateTime? completionDate, // For filtering by completion date
    Priority? priority, // For filtering by priority
    List<String>? tags, // For filtering by tags
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += 'title LIKE ?';
      whereArgs.add('%$searchQuery%'); // Fuzzy search using LIKE
    }

    if (completionDate != null) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      // Filter by date range (start of day to end of day)
      final startOfDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
      final endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));
      whereClause += 'completionDate BETWEEN ? AND ?';
      whereArgs.add(startOfDay.toIso8601String());
      whereArgs.add(endOfDay.toIso8601String());
    }

    if (priority != null) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause += 'priority = ?';
      whereArgs.add(priority.name);
    }

    if (tags != null && tags.isNotEmpty) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause += 'tags LIKE ?';
      whereArgs.add('%${jsonEncode(tags)}%'); // Fuzzy match for tags (JSON array)
    }

    print('Filter query: WHERE $whereClause, Args: $whereArgs'); // Debug log
    final maps = await db.query(
      'tasks',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return List.generate(maps.length, (i) {
      return TaskData(
        id: maps[i]['id'] as int?,
        title: maps[i]['title'] as String,
        completionDate: DateTime.parse(maps[i]['completionDate'] as String),
        status: _parseStatus(maps[i]['status'] as String),
        description: maps[i]['description'] as String,
        assignees: _decodeAssignees(maps[i]['assignees'] as String),
        subtasks: _decodeSubtasks(maps[i]['subtasks'] as String),
        tags: _decodeTags(maps[i]['tags'] as String),
        priority: _parsePriority(maps[i]['priority'] as String),
      );
    });
  }

  Future<int> updateTask(TaskData task) async {
    final db = await database;
    return await db.update(
      'tasks',
      {
        'title': task.title,
        'completionDate': task.completionDate.toIso8601String(),
        'status': task.status.name,
        'description': task.description,
        'assignees': _encodeAssignees(task.assignees),
        'subtasks': _encodeSubtasks(task.subtasks ?? []),
        'tags': _encodeTags(task.tags ?? []),
        'priority': task.priority.name,
      },
      where: 'id = ?', // Use id instead of title
      whereArgs: [task.id], // Use task.id for unique identification
    );
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

  String _encodeAssignees(List<Map<String, dynamic>> assignees) {
    return jsonEncode(assignees);
  }

  List<Map<String, dynamic>> _decodeAssignees(String encoded) {
    return (jsonDecode(encoded) as List).cast<Map<String, dynamic>>();
  }

  String _encodeSubtasks(List<Subtask>? subtasks) {
    return jsonEncode(subtasks?.map((subtask) => subtask.toJson()).toList() ?? []);
  }

  List<Subtask> _decodeSubtasks(String encoded) {
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((e) => Subtask.fromJson(e as Map<String, dynamic>)).toList();
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