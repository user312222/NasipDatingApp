import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/theme/app_theme.dart';
import 'package:binasip/theme/avatar_palette.dart';
import 'package:binasip/theme/wizard_widgets.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('GradientButton', () {
    testWidgets('calls onPressed when enabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(GradientButton(label: 'Devam et', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Devam et'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('ignores taps when onPressed is null', (tester) async {
      await tester.pumpWidget(
        _host(const GradientButton(label: 'Devam et', onPressed: null)),
      );

      // No handler to assert against — tapping must simply not throw.
      await tester.tap(find.text('Devam et'));
      await tester.pump();

      expect(find.text('Devam et'), findsOneWidget);
    });

    testWidgets('shows a spinner and blocks taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          GradientButton(
            label: 'Devam et',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Devam et'), findsNothing);

      await tester.tap(find.byType(GradientButton));
      await tester.pump();

      expect(taps, 0);
    });
  });

  group('OptionCard', () {
    testWidgets('reports taps and shows the check when selected', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          OptionCard(
            title: 'Evlilik',
            subtitle: 'Ciddi bir ilişki',
            selected: true,
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Evlilik'));
      expect(taps, 1);
    });

    testWidgets('hides the check when not selected', (tester) async {
      await tester.pumpWidget(
        _host(
          OptionCard(
            title: 'Evlilik',
            subtitle: 'Ciddi bir ilişki',
            selected: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNothing);
    });
  });

  group('WizardProgress', () {
    testWidgets('renders one segment per step', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: WizardProgress(current: 2, total: 5),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsNWidgets(5));
    });
  });

  group('WizardHeader', () {
    testWidgets('shows title, subtitle and progress when given a step', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 320,
            child: WizardHeader(
              icon: Icons.lock_rounded,
              title: 'Başlık',
              subtitle: 'Alt başlık',
              step: 1,
              totalSteps: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Başlık'), findsOneWidget);
      expect(find.text('Alt başlık'), findsOneWidget);
      expect(find.byType(WizardProgress), findsOneWidget);
    });

    testWidgets('omits progress without a step', (tester) async {
      await tester.pumpWidget(
        _host(const WizardHeader(icon: Icons.lock_rounded, title: 'Başlık')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WizardProgress), findsNothing);
    });
  });

  group('WizardBody', () {
    testWidgets('scrolls instead of overflowing on a short screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: WizardBody(
              child: Column(
                children: const [
                  SizedBox(height: 400, child: Text('içerik')),
                  Spacer(),
                  Text('alt'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('içerik'), findsOneWidget);
    });
  });

  group('AvatarPalette', () {
    test('is stable for a seed and wraps around', () {
      expect(AvatarPalette.forSeed(1), AvatarPalette.forSeed(1));
      expect(AvatarPalette.forSeed(0), AvatarPalette.forSeed(4));
      expect(AvatarPalette.forSeed(2), hasLength(2));
    });

    test('different seeds within a cycle give different pairs', () {
      expect(AvatarPalette.forSeed(0), isNot(AvatarPalette.forSeed(1)));
    });
  });
}
