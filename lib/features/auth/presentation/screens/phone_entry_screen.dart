import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/wizard_widgets.dart';
import '../bloc/auth_cubit.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The sign-in door is not a step of the registration wizard, so it has
    // its own wording and no progress bar.
    final signingIn = context.read<AuthCubit>().isSigningIn;
    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: false,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is OtpSent) context.push('/otp');
          if (state is OtpRequestFailed) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isSending = state is OtpRequestInProgress;
            return WizardBackdrop(
              child: WizardBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (signingIn)
                      const WizardHeader(
                        icon: Icons.login_rounded,
                        title: 'Tekrar hoş geldin.',
                        subtitle:
                            'Kayıtlı telefon numaranı gir; sana bir doğrulama '
                            'kodu gönderelim.',
                      )
                    else
                      const WizardHeader(
                        icon: Icons.phone_iphone_rounded,
                        title: 'Sana bir doğrulama kodu göndereceğiz.',
                        subtitle:
                            'Telefon numaran yalnızca doğrulama ve hesabınla '
                            'ilgili önemli bildirimler için kullanılır.',
                        step: 3,
                        totalSteps: 5,
                      ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'TELEFON NUMARASI',
                        prefixText: '+90 ',
                      ),
                    ),
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Kod gönder',
                      loading: isSending,
                      onPressed: () => context.read<AuthCubit>().requestOtp(
                        _phoneController.text.trim(),
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
