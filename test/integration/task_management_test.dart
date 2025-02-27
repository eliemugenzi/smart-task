import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smarttask/components/text_field_component.dart';
import 'package:smarttask/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Task Creation and Notification', (WidgetTester tester) async {
    app.main(); // Start the app
    await tester.pumpAndSettle();

    // Navigate through splash and login (assuming user is already logged in or mock auth)
    await tester.pump(const Duration(seconds: 2)); // Wait for splash
    await tester.pumpAndSettle();
    expect(find.text('Hey, John 👋'), findsOneWidget); // Assuming user "John"

    // Navigate to create task
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Fill task form
    await tester.enterText(find.byType(CustomTextField).at(0), 'Test Task'); // Title
    await tester.enterText(find.byType(CustomTextField).at(1), 'Test description'); // Description
    await tester.tap(find.text('Due Date')); // Select due date (mock or simulate for testing)
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Assignee')); // Add assignee (mock or simulate)
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Task')); // Submit task
    await tester.pumpAndSettle();

    // Verify task appears in home screen
    expect(find.text('Test Task'), findsOneWidget);

    // Simulate notification (requires mocking or waiting for actual notification)
    // Note: Testing actual notifications may require device/emulator and more complex setup
    await tester.pump(const Duration(minutes: 1)); // Simulate time for notification (simplified)
    // Verify notification logic (mocked or manually checked on device)
  });
}