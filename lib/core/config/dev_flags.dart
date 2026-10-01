/// Toggle for Firebase Phone Auth's reCAPTCHA challenge.
///
/// `true` disables Firebase's bot/abuse check entirely, via
/// `FirebaseAuth.setSettings(appVerificationDisabledForTesting: true)` —
/// Firebase's own documented testing flag. It only has any effect when
/// paired with a number added under Firebase Console → Authentication →
/// Phone → "Phone numbers for testing", so it's safe for our own closed-beta
/// test accounts.
///
/// **Must be flipped back to `false` before real users can sign up with
/// their own phone numbers** — that check is exactly what keeps phone
/// verification from being abused for spam/fake accounts.
const bool kDisableRecaptchaForTesting = true;
