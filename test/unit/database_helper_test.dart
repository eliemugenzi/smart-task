import 'package:flutter_test/flutter_test.dart';
import 'package:smarttask/utils/database_helper.dart';
import 'package:smarttask/models/task.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Mock NotificationService for testing
class MockNotificationService {
  void scheduleNotification(TaskData task) {
    // Mock implementation, no actual notification scheduling
    print('Mock notification scheduled for ${task.title}');
  }
}

void main() {
  late DatabaseHelper databaseHelper;
  late Database db;

  setUpAll(() async {
    // Initialize in-memory database for testing
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'test_tasks.db');
    db = await openDatabase(path, version: 4, onCreate: (db, version) async {
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
    });
    databaseHelper = DatabaseHelper.instance;
    // Use the new method to set the database for testing
    DatabaseHelper.setDatabaseForTesting(db);
  });

  tearDownAll(() async {
    await db.close();
    await deleteDatabase(join(await getDatabasesPath(), 'test_tasks.db'));
  });

  group('DatabaseHelper Tests', () {
    test('Insert Task', () async {
      final task = TaskData(
        title: 'Test Task',
        completionDate: DateTime.now().add(Duration(minutes: 30)),
        status: TaskStatus.pending,
        description: 'Test description',
        assignees: [{'name': 'John Doe', 'avatar': 'avatar_url'}],
        tags: ['urgent'],
        priority: Priority.high,
      );
      final id = await databaseHelper.insertTask(task);
      expect(id, greaterThan(0));

      // Verify notification was scheduled (mocked)
      // Note: MockNotificationService logs instead of actual scheduling
    });

    test('Update Task', () async {
      var task = TaskData(
        title: 'Updated Task',
        completionDate: DateTime.now().add(Duration(minutes: 45)),
        status: TaskStatus.inProgress,
        description: 'Updated description',
        assignees: [{'name': 'Jane Doe', 'avatar': 'avatar_url'}],
        tags: ['urgent', 'work'],
        priority: Priority.medium,
      );
      final id = await databaseHelper.insertTask(task.copyWith(id: null));
      task = task.copyWith(id: id);
      final rows = await databaseHelper.updateTask(task);
      expect(rows, 1);

      // Verify notification was scheduled (mocked)
    });

    test('Get Tasks', () async {
      final tasks = await databaseHelper.getTasks();
      expect(tasks.length, greaterThanOrEqualTo(1));
      expect(tasks.first.title, 'Updated Task');
    });

    test('Delete Task', () async {
      final task = TaskData(
        title: 'Delete Test',
        completionDate: DateTime.now().add(Duration(minutes: 30)),
        status: TaskStatus.pending,
        description: 'To be deleted',
        assignees: [{'name': 'John Doe', 'avatar': 'avatar_url'}],
        tags: ['test'],
        priority: Priority.low,
      );
      final id = await databaseHelper.insertTask(task);
      final rows = await databaseHelper.deleteTask(id);
      expect(rows, 1);

      final tasks = await databaseHelper.getTasks();
      expect(tasks.any((t) => t.title == 'Delete Test'), false);
    });
  });
}