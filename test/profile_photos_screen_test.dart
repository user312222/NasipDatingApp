import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/features/profile/presentation/screens/profile_photos_screen.dart';
import 'package:binasip/theme/app_theme.dart';
import 'package:binasip/theme/wizard_widgets.dart';

void main() {
  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const ProfilePhotosScreen()),
    );
    await tester.pumpAndSettle();
  }

  // Regression: the photo grid used a shrink-wrapped GridView inside
  // WizardBody, whose SliverFillRemaining measures intrinsic height - that
  // threw during layout and the whole step rendered blank.
  testWidgets('the first profile step lays out and shows its content', (
    tester,
  ) async {
    await pump(tester, const Size(400, 800));

    expect(tester.takeException(), isNull);
    expect(find.text('En az 1, en fazla 6 fotoğraf ekle.'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
  });

  testWidgets('it still lays out on a short screen', (tester) async {
    await pump(tester, const Size(360, 420));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('continuing without a photo shows the validation message', (
    tester,
  ) async {
    await pump(tester, const Size(400, 800));

    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();

    expect(find.text('En az 1 fotoğraf ekle.'), findsOneWidget);
  });
}
