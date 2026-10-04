import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/features/family/domain/entities/family_visible_match.dart';
import 'package:binasip/features/family/presentation/screens/guardian_home_screen.dart';
import 'package:binasip/theme/app_theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required ThemeData theme}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: VisibleMatchCard(
              match: FamilyVisibleMatch(
                candidateName: 'Zeynep',
                candidateAge: 27,
                candidateCity: 'İstanbul',
                intentLabel: 'Evlilik',
                statusLabel: 'Yeni eşleşme',
                matchedAt: DateTime(2026, 9, 1),
              ),
            ),
          ),
        ),
      );

  // FR-8.5: name, age, city, intent and a coarse status - nothing else.
  testWidgets('shows exactly what a guardian may see', (tester) async {
    await pump(tester, theme: AppTheme.light());

    expect(find.text('Zeynep, 27'), findsOneWidget);
    expect(find.text('İstanbul'), findsOneWidget);
    expect(find.text('Evlilik'), findsOneWidget);
    expect(find.text('Yeni eşleşme'), findsOneWidget);
  });

  testWidgets('is not tappable - the guardian view is read-only', (
    tester,
  ) async {
    await pump(tester, theme: AppTheme.light());

    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('renders in the dark theme too', (tester) async {
    await pump(tester, theme: AppTheme.dark());

    expect(tester.takeException(), isNull);
    expect(find.text('Evlilik'), findsOneWidget);
  });
}
