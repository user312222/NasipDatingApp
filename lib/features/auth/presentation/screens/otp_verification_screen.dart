import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
import '../bloc/auth_cubit.dart';
import '../session_router.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  late final String _phone;
  late final bool _signingIn;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuthCubit>();
    final state = cubit.state;
    _phone = state is OtpSent ? state.phone : '';
    _signingIn = cubit.isSigningIn;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is PhoneVerified) context.push('/selfie-verification');
          if (state is OtpVerifyFailed) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is SignInAccountNotFound) {
            // The sign-in door, but nobody registered with this number:
            // back to the entry screen, which explains and offers the
            // invite code instead.
            context.go('/');
          }
          if (state is SessionActive) {
            // This phone number already belonged to a fully-onboarded
            // account — Firebase just signed back into that same uid, so
            // treat this as a login rather than continuing the
            // registration flow (no re-selfie, no re-uploading photos).
            routeActiveSession(context, state.user);
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isVerifying = state is OtpVerifyInProgress;
            return WizardBackdrop(
              child: WizardBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WizardHeader(
                      icon: Icons.sms_rounded,
                      title: 'Kodu gir.',
                      subtitle:
                          '+90 $_phone numarasına gönderilen 6 haneli kodu gir.',
                      step: _signingIn ? null : 4,
                      totalSteps: _signingIn ? null : 5,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'DOĞRULAMA KODU',
                      ),
                    ),
                    const SizedBox(height: 6),
                    GradientButton(
                      label: 'Doğrula',
                      loading: isVerifying,
                      onPressed: () => context.read<AuthCubit>().verifyOtp(
                        phone: _phone,
                        code: _codeController.text.trim(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
