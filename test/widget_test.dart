// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fieldnotes/fieldnotes_app.dart';

void main() {
  testWidgets('saved stories stay available in the library', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const FieldnotesApp());
    await tester.pumpAndSettle();

    expect(find.text('The community journal'), findsOneWidget);
    expect(
      find.text('The long way home is still the way home'),
      findsOneWidget,
    );

    final saveButton = find.byTooltip('Save story').first;
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(
      find.text('The long way home is still the way home'),
      findsOneWidget,
    );
  });
}
