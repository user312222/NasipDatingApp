import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/features/profile/domain/entities/profile.dart';
import 'package:binasip/features/profile/domain/usecases/save_profile.dart';
import 'package:binasip/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:binasip/features/profile/presentation/screens/profile_details_screen.dart';
import 'package:binasip/features/profile/presentation/screens/profile_intent_screen.dart';
import 'package:binasip/features/profile/presentation/screens/profile_privacy_screen.dart';
import 'package:binasip/features/profile/presentation/widgets/profile_form_parts.dart';
import 'package:binasip/theme/app_theme.dart';

import 'support/fakes.dart';

/// The wizard steps whose choices are shared with "Profili düzenle"
/// (`profile_form_parts.dart`): each still feeds the wizard's own draft.
void main() {
  late ProfileCubit cubit;

  Future<void> pumpStep(WidgetTester tester, Widget step) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(theme: AppTheme.light(), home: step),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    cubit = ProfileCubit(saveProfile: SaveProfile(FakeProfileRepository()));
  });

  tearDown(() => cubit.close());

  testWidgets('intent step: nothing is chosen until the user chooses', (
    tester,
  ) async {
    await pumpStep(tester, const ProfileIntentScreen());
    expect(cubit.state.draft.intent, isNull);

    await tester.tap(find.text('Henüz emin değilim'));
    await tester.pump();
    expect(cubit.state.draft.intent, ProfileIntent.notSureYet);

    await tester.tap(find.text('Evlilik'));
    await tester.pump();
    expect(cubit.state.draft.intent, ProfileIntent.marriage);
  });

  // FR-3.2.
  testWidgets('privacy step: starts at the most restrictive level', (
    tester,
  ) async {
    await pumpStep(tester, const ProfilePrivacyScreen());
    expect(
      tester
          .widget<PhotoVisibilityOptions>(find.byType(PhotoVisibilityOptions))
          .selected,
      PhotoVisibility.hiddenUntilIUnlock,
    );

    await tester.tap(find.text('Sadece istek üzerine'));
    await tester.pump();
    expect(cubit.state.draft.photoVisibility, PhotoVisibility.onRequestOnly);

    await tester.tap(find.text('Eşleşince otomatik'));
    await tester.pump();
    expect(cubit.state.draft.photoVisibility, PhotoVisibility.autoOnMatch);
  });

  // KVKK m.6.
  testWidgets('details step: a real madhhab asks for consent, the '
      'non-answer does not', (tester) async {
    await pumpStep(tester, const ProfileDetailsScreen());
    expect(find.byType(SensitiveDataConsentCard), findsNothing);

    await tester.tap(find.text('Caferi'));
    await tester.pump();
    expect(find.byType(SensitiveDataConsentCard), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.text(madhhabNoAnswer));
    await tester.pump();
    expect(find.byType(SensitiveDataConsentCard), findsNothing);
  });
}
