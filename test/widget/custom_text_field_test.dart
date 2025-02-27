import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttask/components/text_field_component.dart';

void main() {
  testWidgets('CustomTextField accepts input and validates', (WidgetTester tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            labelText: 'Test Field',
            controller: controller,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Cannot be empty';
              return null;
            },
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Test Field'), findsOneWidget);

    // Enter text
    await tester.enterText(find.byType(TextFormField), 'Hello');
    await tester.pump();
    expect(controller.text, 'Hello');

    // Test validation
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pump();
    final formField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(formField.validator!(null), 'Cannot be empty');
  });
}