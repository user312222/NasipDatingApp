import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/features/family/presentation/screens/guardian_home_screen.dart';
import 'package:binasip/features/safety/domain/usecases/block_user.dart';
import 'package:binasip/features/safety/domain/usecases/report_user.dart';
import 'package:binasip/features/safety/presentation/bloc/safety_cubit.dart';
import 'package:binasip/screens/design_preview_screen.dart';
import 'package:binasip/theme/app_theme.dart';
import 'package:binasip/theme/wizard_widgets.dart';

import 'support/fakes.dart';

// The gallery shows a loading button (endless spinner), so
// `pumpAndSettle` would never return — advance a fixed time instead.
Future<void> _settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 700));

void main() {
  // The gallery's discovery card carries the report/block menu, which
  // resolves its cubit from the service locator.
  setUp(() async {
    await sl.reset();
    final safety = FakeSafetyRepository();
    sl.registerFactory(
      () => SafetyCubit(
        reportUser: ReportUser(safety),
        blockUser: BlockUser(safety),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const DesignPreviewScreen()),
    );
    await _settle(tester);
  }

  testWidgets('renders every shared component without errors', (tester) async {
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(GradientButton), findsWidgets);
    expect(find.byType(OptionCard), findsNWidgets(3));
    expect(find.byType(SectionCard), findsNWidgets(2));
    expect(find.byType(WizardHeader), findsOneWidget);
    expect(find.byType(VisibleMatchCard), findsNWidgets(2));
    expect(find.text('Aktif yazışıyorlar'), findsOneWidget);
  });

  testWidgets('switches to the dark theme via the app bar switch', (
    tester,
  ) async {
    await pump(tester);
    final before = Theme.of(tester.element(find.byType(Scaffold))).brightness;

    await tester.tap(find.byType(Switch));
    await _settle(tester);

    final after = Theme.of(tester.element(find.byType(Scaffold))).brightness;
    expect(tester.takeException(), isNull);
    expect(before, Brightness.light);
    expect(after, Brightness.dark);
  });

  testWidgets('selecting an option card moves the selection', (tester) async {
    await pump(tester);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('İstek üzerine'));
    await _settle(tester);

    final cards = tester.widgetList<OptionCard>(find.byType(OptionCard));
    expect(cards.map((c) => c.selected), [false, true, false]);
  });
}
