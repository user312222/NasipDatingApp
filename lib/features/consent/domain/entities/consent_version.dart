/// Bumped whenever the wording in `ConsentScreen`'s notice text changes in
/// a way that would require asking users again (not for typo fixes).
/// A real backend would use this to know which accounts need re-consent
/// after a policy update — not implemented yet, just recorded.
const String kConsentVersion = '2026-09-22-v1';
