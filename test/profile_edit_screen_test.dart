import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:binasip/core/di/injection_container.dart';
import 'package:binasip/core/error/failures.dart';
import 'package:binasip/core/result/result.dart';
import 'package:binasip/features/profile/data/models/profile_model.dart';
import 'package:binasip/features/profile/domain/entities/profile.dart';
import 'package:binasip/features/profile/domain/usecases/get_profile.dart';
import 'package:binasip/features/profile/domain/usecases/save_profile.dart';
import 'package:binasip/features/profile/presentation/bloc/profile_edit_cubit.dart';
import 'package:binasip/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:binasip/features/profile/presentation/widgets/profile_form_parts.dart';
import 'package:binasip/theme/app_theme.dart';
import 'package:binasip/theme/wizard_widgets.dart';

import 'support/fakes.dart';

void main() {
  late FakeProfileRepository repo;

  /// Opens the edit screen the way the Hesap tab does: pushed on top of
  /// another page, so going back has somewhere to land.
  Future<void> pumpEdit(WidgetTester tester, {Profile? profile}) async {
    // Tall enough for the whole form, so nothing needs scrolling into view.
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    sl.registerFactory(
      () => ProfileEditCubit(
        getProfile: GetProfile(repo),
        saveProfile: SaveProfile(repo),
      ),
    );
    // As the real repository hands it out: the data layer's model, which
    // is a `Profile` but never equal to a plain one.
    if (profile != null) repo.stored = Ok(ProfileModel.fromEntity(profile));

    final router = GoRouter(
      initialLocation: '/account',
      routes: [
        GoRoute(
          path: '/account',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/profile/edit'),
                child: const Text('hesap sekmesi'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => const ProfileEditScreen(userId: 'me'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.tap(find.text('hesap sekmesi'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  String textOf(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label)).controller!.text;

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<GradientButton>(find.byType(GradientButton)).onPressed !=
      null;

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
  }

  bool onEditScreen() => find.text('Profili düzenle').evaluate().isNotEmpty;

  setUp(() async {
    await sl.reset();
    repo = FakeProfileRepository();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('starts from the stored profile', (tester) async {
    await pumpEdit(tester, profile: testProfile(madhhab: 'Sünni'));

    expect(textOf(tester, 'AD'), 'Zeynep');
    expect(textOf(tester, 'ŞEHİR'), 'İstanbul');
    expect(textOf(tester, 'EĞİTİM (OPSİYONEL)'), 'Lisans');
    expect(textOf(tester, 'MESLEK (OPSİYONEL)'), 'Mimar');
    expect(textOf(tester, 'MEZHEP (OPSİYONEL)'), 'Sünni');
    expect(
      tester.widget<IntentOptions>(find.byType(IntentOptions)).selected,
      ProfileIntent.marriage,
    );
    expect(
      tester
          .widget<PhotoVisibilityOptions>(find.byType(PhotoVisibilityOptions))
          .selected,
      PhotoVisibility.hiddenUntilIUnlock,
    );
  });

  testWidgets('the birth date is shown but cannot be changed', (tester) async {
    await pumpEdit(tester, profile: testProfile());

    expect(find.textContaining('27 yaş'), findsOneWidget);
    expect(
      find.text('Doğum tarihi kayıttan sonra değiştirilemez.'),
      findsOneWidget,
    );

    await tester.tap(find.textContaining('27 yaş'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('"Kaydet" stays off until something really changes', (
    tester,
  ) async {
    await pumpEdit(tester, profile: testProfile());
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(field('ŞEHİR'), 'Ankara');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);

    // Typing the old value back - or only adding spaces - is no change.
    await tester.enterText(field('ŞEHİR'), ' İstanbul ');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('saves the edits, confirms and goes back', (tester) async {
    final stored = testProfile();
    await pumpEdit(tester, profile: stored);

    await tester.enterText(field('ŞEHİR'), 'Ankara');
    await tester.enterText(field('MESLEK (OPSİYONEL)'), '');
    await tester.tap(find.text('Henüz emin değilim'));
    await tester.tap(find.text('Eşleşince otomatik'));
    await tester.tap(find.text('Ailem/velim bu süreci görsün'));
    await tester.pump();
    await save(tester);

    final saved = repo.saved.single;
    expect(saved.city, 'Ankara');
    expect(saved.occupation, isNull);
    expect(saved.intent, ProfileIntent.notSureYet);
    expect(saved.photoVisibility, PhotoVisibility.autoOnMatch);
    expect(saved.familyInvolvementOptIn, isTrue);
    // Not on the screen, so never touched.
    expect(saved.birthDate, stored.birthDate);
    expect(saved.photoRefs, stored.photoRefs);

    expect(find.text('hesap sekmesi'), findsOneWidget);
    expect(find.text('Profilin güncellendi.'), findsOneWidget);
  });

  testWidgets('shows a spinner on the button while saving', (tester) async {
    await pumpEdit(tester, profile: testProfile());
    repo.pendingSave = Completer<void>();

    await tester.enterText(field('ŞEHİR'), 'Ankara');
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Kaydet'), findsNothing);

    repo.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(find.text('hesap sekmesi'), findsOneWidget);
  });

  testWidgets('a failed save says why and keeps what was typed', (
    tester,
  ) async {
    await pumpEdit(tester, profile: testProfile());
    repo.saveResult = const Err(ServerFailure('Profil kaydedilemedi.'));

    await tester.enterText(field('ŞEHİR'), 'Ankara');
    await tester.pump();
    await save(tester);

    expect(find.text('Profil kaydedilemedi.'), findsOneWidget);
    expect(textOf(tester, 'ŞEHİR'), 'Ankara');
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('an emptied name is refused with a reason', (tester) async {
    await pumpEdit(tester, profile: testProfile());

    await tester.enterText(field('AD'), '');
    await tester.pump();
    await save(tester);

    expect(find.text('Ad ve şehir boş bırakılamaz.'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  // KVKK m.6.
  group('religious data', () {
    testWidgets('new data asks for consent before it can be saved', (
      tester,
    ) async {
      await pumpEdit(tester, profile: testProfile());
      expect(find.byType(SensitiveDataConsentCard), findsNothing);

      await tester.enterText(
        field('DİNİ PRATİĞİN (OPSİYONEL)'),
        'Namazlarımı kılarım.',
      );
      await tester.pump();
      expect(find.byType(SensitiveDataConsentCard), findsOneWidget);

      await save(tester);
      expect(find.textContaining('onayı işaretlemelisin'), findsOneWidget);
      expect(repo.saved, isEmpty);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await save(tester);

      expect(repo.saved.single.religiousPracticeNote, 'Namazlarımı kılarım.');
    });

    testWidgets('what is already stored does not ask again', (tester) async {
      await pumpEdit(
        tester,
        profile: testProfile(
          religiousPracticeNote: 'Oruç tutarım.',
          madhhab: 'Sünni',
        ),
      );
      expect(find.byType(SensitiveDataConsentCard), findsNothing);

      await tester.enterText(field('ŞEHİR'), 'Ankara');
      await tester.pump();
      await save(tester);

      expect(repo.saved.single.city, 'Ankara');
      expect(repo.saved.single.madhhab, 'Sünni');
    });

    testWidgets('the non-answer chip fills the field and needs no consent', (
      tester,
    ) async {
      await pumpEdit(tester, profile: testProfile());

      await tester.tap(find.text('Alevi'));
      await tester.pump();
      expect(textOf(tester, 'MEZHEP (OPSİYONEL)'), 'Alevi');
      expect(find.byType(SensitiveDataConsentCard), findsOneWidget);

      await tester.tap(find.text(madhhabNoAnswer));
      await tester.pump();
      expect(textOf(tester, 'MEZHEP (OPSİYONEL)'), madhhabNoAnswer);
      expect(find.byType(SensitiveDataConsentCard), findsNothing);

      await save(tester);
      expect(repo.saved.single.madhhab, madhhabNoAnswer);
    });
  });

  group('leaving', () {
    testWidgets('an untouched form just closes', (tester) async {
      await pumpEdit(tester, profile: testProfile());

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('hesap sekmesi'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('unsaved changes ask first, and can be kept', (tester) async {
      await pumpEdit(tester, profile: testProfile());
      await tester.enterText(field('ŞEHİR'), 'Ankara');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Değişiklikler kaydedilmedi'), findsOneWidget);

      await tester.tap(find.text('Düzenlemeye dön'));
      await tester.pumpAndSettle();

      expect(onEditScreen(), isTrue);
      expect(textOf(tester, 'ŞEHİR'), 'Ankara');
    });

    testWidgets('unsaved changes can be thrown away', (tester) async {
      await pumpEdit(tester, profile: testProfile());
      await tester.enterText(field('ŞEHİR'), 'Ankara');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydetmeden çık'));
      await tester.pumpAndSettle();

      expect(find.text('hesap sekmesi'), findsOneWidget);
      expect(repo.saved, isEmpty);
    });
  });

  testWidgets('a profile that cannot be loaded can be retried', (tester) async {
    repo.stored = const Err(ServerFailure('Profilin yüklenemedi.'));
    await pumpEdit(tester);
    expect(find.text('Profilin yüklenemedi.'), findsOneWidget);

    repo.stored = Ok(testProfile());
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'AD'), 'Zeynep');
  });
}
