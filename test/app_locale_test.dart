import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/config/app_locale.dart';
import 'package:binasip/theme/app_theme.dart';

void main() {
  testWidgets('framework dialogs speak Turkish, like the rest of the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: kAppLocale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDatePicker(
                context: context,
                initialDate: DateTime(2001),
                firstDate: DateTime(1940),
                lastDate: DateTime(2008),
              ),
              child: const Text('tarih seç'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('tarih seç'));
    await tester.pumpAndSettle();

    expect(find.text('İptal'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Select date'), findsNothing);
    expect(find.textContaining('Ocak'), findsWidgets);
  });
}
