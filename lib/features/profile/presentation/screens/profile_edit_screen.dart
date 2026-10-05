import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_edit_cubit.dart';
import '../widgets/profile_form_parts.dart';

/// "Profili düzenle", opened from the Hesap tab: the same choices as the
/// registration wizard on one page, starting from what is stored. The birth
/// date is shown but fixed, and photos are not here at all - they are still
/// placeholders until photo storage exists.
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileEditCubit>()..load(userId),
      child: _ProfileEditView(userId: userId),
    );
  }
}

/// Back to where the screen was opened from - or to the Hesap tab when it
/// was opened by address and there is nothing underneath.
void _leave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/account');
  }
}

/// The app bar shows its own back arrow only when there is a page
/// underneath. Opened by address - which is also where the redirect from a
/// wizard step lands (`route_access.dart`) - there is none, and the screen
/// would have no way out; this arrow stands in for it.
Widget? _backWhenOpenedByAddress(BuildContext context, VoidCallback onBack) =>
    context.canPop() ? null : BackButton(onPressed: onBack);

class _ProfileEditView extends StatelessWidget {
  const _ProfileEditView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileEditCubit, ProfileEditState>(
      listenWhen: (previous, current) => current is ProfileEditSaved,
      listener: (context, state) {
        if (state is ProfileEditSaved && state.changed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profilin güncellendi.')),
          );
        }
        _leave(context);
      },
      // The form stays as it is while the screen closes after a save.
      buildWhen: (previous, current) => current is! ProfileEditSaved,
      builder: (context, state) => switch (state) {
        ProfileEditReady() => _ProfileEditForm(state: state),
        ProfileEditUnavailable(:final message) => _Frame(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<ProfileEditCubit>().load(userId),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ProfileEditLoading() || ProfileEditSaved() => const _Frame(
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _backWhenOpenedByAddress(context, () => _leave(context)),
        title: const Text('Profili düzenle'),
      ),
      body: WizardBackdrop(child: SafeArea(child: child)),
    );
  }
}

class _ProfileEditForm extends StatefulWidget {
  const _ProfileEditForm({required this.state});

  final ProfileEditReady state;

  @override
  State<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<_ProfileEditForm> {
  late final Profile _stored = widget.state.profile;

  late final _name = TextEditingController(text: _stored.name);
  late final _city = TextEditingController(text: _stored.city);
  late final _education = TextEditingController(text: _stored.educationLevel);
  late final _occupation = TextEditingController(text: _stored.occupation);
  late final _religiousNote = TextEditingController(
    text: _stored.religiousPracticeNote,
  );
  late final _madhhab = TextEditingController(text: _stored.madhhab);
  late final _fields = [
    _name,
    _city,
    _education,
    _occupation,
    _religiousNote,
    _madhhab,
  ];

  late ProfileIntent _intent = _stored.intent;
  late PhotoVisibility _photoVisibility = _stored.photoVisibility;
  late bool _familyOptIn = _stored.familyInvolvementOptIn;
  bool _sensitiveDataConsent = false;

  ProfileEdits get _edits => ProfileEdits(
    name: _name.text,
    city: _city.text,
    intent: _intent,
    photoVisibility: _photoVisibility,
    familyInvolvementOptIn: _familyOptIn,
    educationLevel: _education.text,
    occupation: _occupation.text,
    religiousPracticeNote: _religiousNote.text,
    madhhab: _madhhab.text,
  );

  bool get _dirty => _edits.changes(_stored);

  @override
  void initState() {
    super.initState();
    // "Kaydet", the consent card and the leave warning all follow what is
    // typed, so every keystroke rebuilds.
    for (final field in _fields) {
      field.addListener(_onTyped);
    }
  }

  void _onTyped() => setState(() {});

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _save() => context.read<ProfileEditCubit>().save(
    _edits,
    sensitiveDataConsent: _sensitiveDataConsent,
  );

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Değişiklikler kaydedilmedi'),
        content: const Text('Çıkarsan yaptığın değişiklikler kaybolur.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Düzenlemeye dön'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaydetmeden çık'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _leave(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final birthDate = _stored.birthDate;
    final dirty = _dirty;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _backWhenOpenedByAddress(
            context,
            () => dirty ? _confirmLeave() : _leave(context),
          ),
          title: const Text('Profili düzenle'),
        ),
        body: WizardBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      const _SectionLabel('Temel bilgiler', first: true),
                      TextField(
                        controller: _name,
                        inputFormatters: [LengthLimitingTextInputFormatter(60)],
                        decoration: const InputDecoration(labelText: 'AD'),
                      ),
                      const SizedBox(height: 14),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'DOĞUM TARİHİ',
                          helperText:
                              'Doğum tarihi kayıttan sonra değiştirilemez.',
                          suffixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: colors.inkSoft,
                          ),
                        ),
                        child: Text(
                          '${birthDate.day}.${birthDate.month}.${birthDate.year}'
                          ' · ${_stored.age} yaş',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _city,
                        decoration: const InputDecoration(labelText: 'ŞEHİR'),
                      ),
                      const _SectionLabel('Niyetin'),
                      IntentOptions(
                        selected: _intent,
                        onChanged: (intent) => setState(() => _intent = intent),
                      ),
                      const _SectionLabel('Hakkında'),
                      TextField(
                        controller: _education,
                        decoration: const InputDecoration(
                          labelText: 'EĞİTİM (OPSİYONEL)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _occupation,
                        decoration: const InputDecoration(
                          labelText: 'MESLEK (OPSİYONEL)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _religiousNote,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'DİNİ PRATİĞİN (OPSİYONEL)',
                          hintText: 'Kendi cümlelerinle, istersen boş bırak',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _madhhab,
                        decoration: const InputDecoration(
                          labelText: 'MEZHEP (OPSİYONEL)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      MadhhabSuggestions(
                        onSelected: (madhhab) => _madhhab.text = madhhab,
                      ),
                      if (_edits.needsSensitiveConsent(_stored)) ...[
                        const SizedBox(height: 16),
                        SensitiveDataConsentCard(
                          value: _sensitiveDataConsent,
                          onChanged: (value) =>
                              setState(() => _sensitiveDataConsent = value),
                        ),
                      ],
                      const _SectionLabel('Fotoğraf görünürlüğü'),
                      PhotoVisibilityOptions(
                        selected: _photoVisibility,
                        onChanged: (level) =>
                            setState(() => _photoVisibility = level),
                      ),
                      const _SectionLabel('Aile'),
                      OptionCard(
                        icon: Icons.family_restroom_outlined,
                        title: 'Ailem/velim bu süreci görsün',
                        subtitle: _familyOptIn
                            ? 'Açık — istediğin zaman kapatabilirsin.'
                            : 'Kapalı — süreci yalnızca sen görürsün.',
                        selected: _familyOptIn,
                        onTap: () =>
                            setState(() => _familyOptIn = !_familyOptIn),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.state.error case final error?) ...[
                        Text(
                          error,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.rose,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      GradientButton(
                        label: 'Kaydet',
                        loading: widget.state.saving,
                        onPressed: dirty ? _save : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.first = false});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 8 : 28, bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: context.colors.plumStrong),
      ),
    );
  }
}
