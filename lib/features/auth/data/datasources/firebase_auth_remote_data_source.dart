import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/error_log.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/account_type.dart';
import '../../domain/entities/auth_user.dart';
import 'auth_remote_data_source.dart';

/// FR-1.1 on real Firebase Phone Auth, and FR-1.3 invite codes on
/// Firestore. Selfie liveness (FR-1.2) is still handled by [fallback]
/// until a real provider exists.
///
/// Invite codes are `inviteCodes/{CODE}` docs (`active: true`), created by
/// hand in the Firebase Console - the check runs before login, so rules
/// allow a single-doc `get` for anyone but no listing and no client
/// writes. Codes are reusable on purpose: a returning user logs back in
/// through the same gate, and per-use tracking would need Cloud Functions.
///
/// Session state lives in one small `users/{uid}` doc — `accountType`
/// (written the moment OTP succeeds, FR-8.1) and `verifiedAt` (added once
/// selfie verification succeeds). [getCurrentSession] reads it back so a
/// returning, already-verified user can skip straight past invite/phone/
/// OTP/selfie on their next app open — see `AuthCubit.restoreSession` and
/// `InviteGateScreen`, which is what actually decides where to send them.
class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({required this.fallback});

  final AuthRemoteDataSource fallback;

  // Resolved lazily so constructing the graph (e.g. in widget tests) never
  // touches Firebase until an OTP is actually requested.
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  ConfirmationResult? _confirmation;

  @override
  Future<void> checkInviteCode(String code) async {
    final id = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{4,32}$').hasMatch(id)) {
      throw const ServerException('Bu davetiye kodu tanınmıyor.');
    }
    try {
      final doc = await _db.collection('inviteCodes').doc(id).get();
      if (doc.data()?['active'] != true) {
        throw const ServerException('Bu davetiye kodu tanınmıyor.');
      }
    } on FirebaseException catch (e) {
      logFailure('auth', e, needsSession: false);
      throw const ServerException('Kod doğrulanamadı.');
    }
  }

  @override
  Future<void> requestOtp(String phone) async {
    final e164 = _toE164(phone);
    if (e164 == null) {
      throw const ServerException('Geçerli bir telefon numarası gir.');
    }
    try {
      _confirmation = await _auth.signInWithPhoneNumber(e164);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_message(e));
    }
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
    required AccountType accountType,
  }) async {
    final confirmation = _confirmation;
    if (confirmation == null) {
      throw const ServerException('Önce kod iste.');
    }
    try {
      final credential = await confirmation.confirm(code.trim());
      final user = credential.user;
      if (user == null) {
        throw const ServerException('Giriş yapılamadı. Tekrar dener misin?');
      }
      return await _resolveVerifiedUser(user.uid, phone, accountType);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_message(e));
    }
  }

  /// A phone number Firebase has seen before signs back into the SAME
  /// uid — so this "registration" attempt can actually be a login for an
  /// already fully-onboarded account. When that's the case, this returns
  /// the account's own persisted `accountType`/`verifiedAt` (never the
  /// freshly-picked [freshAccountType], which would otherwise silently
  /// overwrite it) so `AuthCubit.verifyOtp` can short-circuit straight
  /// past selfie/profile-wizard instead of making the user redo them.
  /// Best effort: any Firestore failure here falls through to the normal
  /// fresh-registration path rather than blocking sign-in.
  Future<AuthUser> _resolveVerifiedUser(
    String uid,
    String phone,
    AccountType freshAccountType,
  ) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      final verifiedAt = (data?['verifiedAt'] as Timestamp?)?.toDate();
      if (verifiedAt != null) {
        final accountType = data?['accountType'] == 'guardian'
            ? AccountType.guardian
            : AccountType.single;
        return AuthUser(
          id: uid,
          phone: phone,
          accountType: accountType,
          verifiedAt: verifiedAt,
        );
      }
      await _db.collection('users').doc(uid).set({
        'accountType': freshAccountType.name,
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Ignored — see doc comment above.
    }
    return AuthUser(id: uid, phone: phone, accountType: freshAccountType);
  }

  @override
  Future<AuthUser> submitSelfieVerification(AuthUser user) async {
    final verified = await fallback.submitSelfieVerification(user);
    try {
      await _db.collection('users').doc(user.id).set({
        'accountType': verified.accountType.name,
        if (verified.verifiedAt != null)
          'verifiedAt': Timestamp.fromDate(verified.verifiedAt!),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Best effort, same reasoning as verifyOtp above.
    }
    return verified;
  }

  @override
  Future<AuthUser?> getCurrentSession() async {
    // Broad catch is deliberate here (not just FirebaseException): this
    // runs on every cold start, including in widget tests where
    // `Firebase.initializeApp` never ran — any failure just means "show
    // the invite gate," never a crash.
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _db.collection('users').doc(user.uid).get();
      final data = doc.data();
      final accountType = data?['accountType'] == 'guardian'
          ? AccountType.guardian
          : AccountType.single;
      final verifiedAt = (data?['verifiedAt'] as Timestamp?)?.toDate();
      return AuthUser(
        id: user.uid,
        // Firebase reports E.164 ("+905550000000"); everywhere else in the
        // app `AuthUser.phone` is the local number and screens prepend
        // "+90 " themselves, so strip it here or it renders twice.
        phone: (user.phoneNumber ?? '').replaceFirst(RegExp(r'^\+90'), ''),
        accountType: accountType,
        verifiedAt: verifiedAt,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logOut() async {
    _confirmation = null;
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      logFailure('auth', e, needsSession: false);
      throw const ServerException('Çıkış yapılamadı.');
    }
  }

  /// Accepts "05xx…", "5xx…", "90 5xx…" or "+905xx…" (spaces ignored);
  /// returns null when it cannot be a Turkish mobile number.
  String? _toE164(String input) {
    var digits = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) {
      return RegExp(r'^\+\d{11,14}$').hasMatch(digits) ? digits : null;
    }
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.length == 10 ? '+90$digits' : null;
  }

  String _message(FirebaseAuthException e) {
    logFailure('auth', e, needsSession: false);
    return switch (e.code) {
      'invalid-phone-number' => 'Geçerli bir telefon numarası gir.',
      'invalid-verification-code' => 'Kod hatalı. Tekrar dener misin?',
      'code-expired' ||
      'session-expired' => 'Kodun süresi doldu. Yeni kod iste.',
      'too-many-requests' =>
        'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
      'network-request-failed' => 'Bağlantı sorunu. İnternetini kontrol et.',
      _ => 'Bir sorun oluştu. Tekrar dener misin?',
    };
  }
}
