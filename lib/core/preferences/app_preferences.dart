import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, on-device-only display preferences — never synced to Firestore,
/// never shared with the other party or a linked guardian. Backed by
/// `shared_preferences` (the platform's local key-value store; `localStorage`
/// on web), so a choice persists across app restarts but stays on this one
/// device.
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _showMatchMessagePreviewsKey = 'show_match_message_previews';

  /// Whether the matches list shows each row's last message text, or just
  /// the candidate's city/intent instead. Defaults to `true` (current
  /// behavior) — this is purely a "what does MY OWN screen show me" choice,
  /// unrelated to what a linked guardian can see (that's governed
  /// separately and never includes message content, see FR-8.5).
  final ValueNotifier<bool> showMatchMessagePreviews = ValueNotifier(true);

  Future<void> init() async {
    showMatchMessagePreviews.value =
        _prefs.getBool(_showMatchMessagePreviewsKey) ?? true;
  }

  Future<void> setShowMatchMessagePreviews(bool value) async {
    showMatchMessagePreviews.value = value;
    await _prefs.setBool(_showMatchMessagePreviewsKey, value);
  }
}
