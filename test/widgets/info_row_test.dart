import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/info_row.dart';

void main() {
  group('InfoRow - Display and Styling', () {
    testWidgets('displays label and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Order ID',
              value: 'order_123',
            ),
          ),
        ),
      );

      expect(find.text('Order ID'), findsOneWidget);
      expect(find.text('order_123'), findsOneWidget);
    });

    testWidgets('uses non-selectable text by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Amount',
              value: '₹100.00',
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsWidgets);
      expect(find.byType(SelectableText), findsNothing);
    });

    testWidgets('uses selectable text when selectable is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Order ID',
              value: 'order_123',
              selectable: true,
            ),
          ),
        ),
      );

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('label has grey color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Test Label',
              value: 'Test Value',
            ),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('Test Label'));
      expect(labelText.style?.color, isNotNull);
      // Grey color should be present
      expect(labelText.style?.color?.value, isNot(Colors.black.value));
    });

    testWidgets('value has black color and medium weight',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Test Label',
              value: 'Test Value',
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('Test Value'));
      expect(valueText.style?.color, Colors.black);
      expect(valueText.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('displays in row layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Label',
              value: 'Value',
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('handles empty strings', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: '',
              value: '',
            ),
          ),
        ),
      );

      expect(find.byType(InfoRow), findsOneWidget);
    });

    testWidgets('handles long text values', (WidgetTester tester) async {
      const longValue = 'This is a very long value that might wrap to multiple lines in the UI';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoRow(
              label: 'Description',
              value: longValue,
            ),
          ),
        ),
      );

      expect(find.text(longValue), findsOneWidget);
    });
  });
}
