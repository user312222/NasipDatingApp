import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/wizard_widgets.dart';
import '../bloc/auth_cubit.dart';
import '../session_router.dart';

class InviteGateScreen extends StatefulWidget {
  const InviteGateScreen({super.key});

  @override
  State<InviteGateScreen> createState() => _InviteGateScreenState();
}

class _InviteGateScreenState extends State<InviteGateScreen> {
  final _codeController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Session restore (see `AuthCubit.restoreSession`) — runs once, right
    // when the app cold-starts here. A returning, already-verified user
    // gets routed straight past invite/phone/OTP/selfie instead of
    // replaying the whole registration flow.
    context.read<AuthCubit>().restoreSession();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is InviteAccepted) {
            context.push('/account-type');
          } else if (state is InviteRejected) {
            setState(() => _errorText = 'Bu kod tanınmıyor.');
          } else if (state is SessionActive) {
            routeActiveSession(context, state.user);
          }
        },
        builder: (context, state) {
          if (state is SessionRestoring) {
            return const Center(child: CircularProgressIndicator());
          }
          final isChecking = state is InviteCheckInProgress;
          return WizardBackdrop(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'DAVETİYELİ ERKEN ERİŞİM',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.brass,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        const WizardHeader(
                          leading: BrandLogo(),
                          icon: Icons.favorite_rounded,
                          title: 'Bi Nasip’e hoş geldin.',
                          subtitle: 'Şu an kapalı beta aşamasındayız. Devam etmek için davetiye kodunu gir.',
                          centered: true,
                        ),
                        const SizedBox(height: 28),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _codeController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    labelText: 'DAVETİYE KODU',
                                    errorText: _errorText,
                                  ),
                                  onChanged: (_) {
                                    if (_errorText != null) {
                                      setState(() => _errorText = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                GradientButton(
                                  label: 'Devam et',
                                  loading: isChecking,
                                  onPressed: () {
                                    final code = _codeController.text.trim();
                                    if (code.isEmpty) {
                                      setState(() => _errorText = 'Kodu gir');
                                      return;
                                    }
                                    context.read<AuthCubit>().checkInviteCode(
                                      code,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => context.push('/waitlist'),
                          child: Text(
                            'Davetiye kodun yok mu? Bekleme listesine katıl',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
