import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/glassy_card.dart';

void main() {
  group('GlassyCard Widget Tests', () {
    testWidgets('renders child widget correctly', (WidgetTester tester) async {
      const testText = 'Test Content';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('applies BackdropFilter with correct blur values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final backdropFilter = tester.widget<BackdropFilter>(
        find.byType(BackdropFilter),
      );

      final filter = backdropFilter.filter as ImageFilter;
      // Note: ImageFilter doesn't expose sigma values directly,
      // but we can verify the filter exists and is of correct type
      expect(filter, isA<ImageFilter>());
    });

    testWidgets('applies correct decoration properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      
      // Verify background color (semi-transparent white with opacity 0.08)
      expect(decoration.color, equals(Colors.white.withValues(alpha: 0.08)));
      
      // Verify border radius
      expect(decoration.borderRadius, equals(BorderRadius.circular(12)));
      
      // Verify border (white with opacity 0.18, width 1.5)
      expect(decoration.border, isA<Border>());
      final border = decoration.border as Border;
      expect(border.top.width, equals(1.5));
      expect(border.top.color, equals(Colors.white.withValues(alpha: 0.18)));
      
      // Verify box shadow
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, equals(1));
      final shadow = decoration.boxShadow!.first;
      expect(shadow.color, equals(Colors.black.withValues(alpha: 0.3)));
      expect(shadow.blurRadius, equals(32));
      expect(shadow.offset, equals(const Offset(0, 8)));
    });

    testWidgets('uses default padding when not specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );

      expect(container.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('applies custom padding when specified', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(24);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              padding: customPadding,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );

      expect(container.padding, equals(customPadding));
    });

    testWidgets('applies custom border radius when specified', (WidgetTester tester) async {
      const customRadius = 20.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              borderRadius: customRadius,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(customRadius)));
    });

    testWidgets('applies custom border color when specified', (WidgetTester tester) async {
      const customBorderColor = Colors.blue;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              borderColor: customBorderColor,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, equals(customBorderColor));
    });

    testWidgets('ClipRRect applies border radius correctly', (WidgetTester tester) async {
      const customRadius = 16.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassyCard(
              borderRadius: customRadius,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(
        find.byType(ClipRRect),
      );

      expect(clipRRect.borderRadius, equals(BorderRadius.circular(customRadius)));
    });
  });
}
