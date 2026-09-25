import 'package:flutter_test/flutter_test.dart';

import 'package:binasip/core/format/chat_time.dart';

void main() {
  // Wednesday, 14:30.
  final now = DateTime(2026, 9, 23, 14, 30);

  test('same day shows the zero-padded time', () {
    expect(formatChatTimestamp(DateTime(2026, 9, 23, 9, 5), now: now), '09:05');
    expect(
      formatChatTimestamp(DateTime(2026, 9, 23, 23, 59), now: now),
      '23:59',
    );
  });

  test('yesterday shows "Dün", even across midnight by minutes', () {
    expect(formatChatTimestamp(DateTime(2026, 9, 22, 23, 59), now: now), 'Dün');
    expect(formatChatTimestamp(DateTime(2026, 9, 22, 0, 1), now: now), 'Dün');
  });

  test('within the last week shows the weekday', () {
    // 2026-09-20 is a Sunday, 2026-09-18 a Friday.
    expect(formatChatTimestamp(DateTime(2026, 9, 20, 10), now: now), 'Paz');
    expect(formatChatTimestamp(DateTime(2026, 9, 18, 10), now: now), 'Cum');
  });

  test('a week or more ago shows the date', () {
    expect(
      formatChatTimestamp(DateTime(2026, 9, 16, 10), now: now),
      '16.09.2026',
    );
    expect(
      formatChatTimestamp(DateTime(2025, 1, 5, 10), now: now),
      '05.01.2025',
    );
  });

  test('a timestamp slightly in the future still shows the time', () {
    expect(formatChatTimestamp(DateTime(2026, 9, 23, 14, 31), now: now), '14:31');
  });
}
