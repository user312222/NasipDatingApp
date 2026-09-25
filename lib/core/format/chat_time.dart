const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Short, chat-list style timestamp: "14:05" for today, "Dün" for
/// yesterday, a weekday ("Sal") within the last week, otherwise "12.03.2026".
/// [now] is injectable so it can be tested without a clock.
String formatChatTimestamp(DateTime when, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(when.year, when.month, when.day);
  final daysAgo = today.difference(day).inDays;

  if (daysAgo <= 0) {
    return '${when.hour.toString().padLeft(2, '0')}:'
        '${when.minute.toString().padLeft(2, '0')}';
  }
  if (daysAgo == 1) return 'Dün';
  if (daysAgo < 7) return _weekdays[when.weekday - 1];
  return '${when.day.toString().padLeft(2, '0')}.'
      '${when.month.toString().padLeft(2, '0')}.${when.year}';
}
