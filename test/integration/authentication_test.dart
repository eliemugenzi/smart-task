import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smarttask/components/text_field_component.dart';
import 'package:smarttask/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login and Signup Flow', (WidgetTester tester) async {
    app.main(); // Start the app
    await tester.pumpAndSettle();

    // Verify splash screen
    expect(find.text('Welcome to SMART TASK'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // Wait for splash navigation
    await tester.pumpAndSettle();

    // Navigate to signup
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Fill signup form
    await tester.enterText(find.byType(CustomTextField).at(0), 'John'); // First Name
    await tester.enterText(find.byType(CustomTextField).at(1), 'Doe'); // Last Name
    await tester.enterText(find.byType(CustomTextField).at(2), 'john.doe@example.com'); // Email
    await tester.enterText(find.byType(CustomTextField).at(3), 'password123'); // Password
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify login screen
    expect(find.text('Welcome Back'), findsOneWidget);

    // Login with new credentials
    await tester.enterText(find.byType(CustomTextField).at(0), 'john.doe@example.com'); // Email
    await tester.enterText(find.byType(CustomTextField).at(1), 'password123'); // Password
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    // Verify home screen
    expect(find.text('Hey, John 👋'), findsOneWidget);
  });
}