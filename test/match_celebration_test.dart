import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/features/matching/presentation/widgets/match_celebration.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

void main() {
  final candidate = testMatch('a', DateTime(2026, 1, 1)).candidate;

  // The heart pulses forever, so these tests pump single frames instead of
  // settling.
  Future<void> pump(
    WidgetTester tester, {
    Future<bool> Function(bool visible)? onShowFamilyChanged,
    VoidCallback? onChat,
    VoidCallback? onLater,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MatchCelebration(
            candidate: candidate,
            onChat: onChat ?? () {},
            onLater: onLater ?? () {},
            onShowFamilyChanged: onShowFamilyChanged ?? (_) async => true,
          ),
        ),
      ),
    );
  }

  Switch familySwitch(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch));

  testWidgets('"aileme göster" is off until the user turns it on', (
    tester,
  ) async {
    final saved = <bool>[];
    await pump(
      tester,
      onShowFamilyChanged: (v) async {
        saved.add(v);
        return true;
      },
    );

    expect(find.text('Aileme göster'), findsOneWidget);
    expect(familySwitch(tester).value, isFalse);
    expect(saved, isEmpty);
  });

  testWidgets('turning it on saves the choice and keeps it on', (tester) async {
    final saved = <bool>[];
    await pump(
      tester,
      onShowFamilyChanged: (v) async {
        saved.add(v);
        return true;
      },
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();

    expect(saved, [true]);
    expect(familySwitch(tester).value, isTrue);
    expect(find.text('Kaydedilemedi, tekrar dene.'), findsNothing);
  });

  testWidgets('a failed save puts the switch back and says so', (tester) async {
    await pump(tester, onShowFamilyChanged: (_) async => false);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();

    expect(familySwitch(tester).value, isFalse);
    expect(find.text('Kaydedilemedi, tekrar dene.'), findsOneWidget);
  });

  testWidgets('the switch is locked while the choice is being saved', (
    tester,
  ) async {
    final pending = Completer<bool>();
    await pump(tester, onShowFamilyChanged: (_) => pending.future);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(familySwitch(tester).value, isTrue);
    expect(familySwitch(tester).onChanged, isNull);

    pending.complete(true);
    await tester.pump();
    await tester.pump();
    expect(familySwitch(tester).onChanged, isNotNull);
  });

  testWidgets('the two buttons still report back', (tester) async {
    var chats = 0;
    var laters = 0;
    await pump(tester, onChat: () => chats++, onLater: () => laters++);

    await tester.tap(find.text('Sohbete başla'));
    // On the short test surface the last button starts below the fold.
    await tester.ensureVisible(find.text('Şimdi değil'));
    await tester.pump();
    await tester.tap(find.text('Şimdi değil'));

    expect(chats, 1);
    expect(laters, 1);
  });

  testWidgets('the chat button keeps white text in the dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: MatchCelebration(
            candidate: candidate,
            onChat: () {},
            onLater: () {},
            onShowFamilyChanged: (_) async => true,
          ),
        ),
      ),
    );

    final label = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(RichText),
      ),
    );
    expect(label.text.style?.color, Colors.white);
  });
}
