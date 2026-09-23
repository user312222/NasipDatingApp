import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    _phone = state is OtpSent ? state.phone : '';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Doğrulama Kodu')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is PhoneVerified) context.push('/selfie-verification');
          if (state is OtpVerifyFailed) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
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
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '+90 $_phone numarasına gönderilen 6 haneli kodu gir.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'DOĞRULAMA KODU',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isVerifying
                          ? null
                          : () => context.read<AuthCubit>().verifyOtp(
                              phone: _phone,
                              code: _codeController.text.trim(),
                            ),
                      child: isVerifying
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Doğrula'),
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
