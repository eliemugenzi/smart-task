import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarttask/components/button_component.dart';

void main() {
  testWidgets('CustomButton displays text and responds to tap', (WidgetTester tester) async {
    bool wasTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CustomButton(
          text: 'Tap Me',
          onPressed: () => wasTapped = true,
        ),
      ),
    );

    expect(find.text('Tap Me'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Trigger frame after tap
    expect(wasTapped, true);

    // Verify styling (e.g., background color)
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.style?.backgroundColor?.resolve({}), Colors.blue);
  });

  testWidgets('CustomButton shows loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomButton(
          text: 'Loading',
          isLoading: true,
        ),
      ),
    );

    expect(find.text('Loading'), findsNothing); // Text hidden during loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}