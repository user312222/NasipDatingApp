import 'package:equatable/equatable.dart';

/// The one prompt everybody answers on a given day. Questions rotate from a
/// fixed list (no backend needed); the day is the **UTC** calendar day, the
/// same one `firestore.rules` uses to cap answers at one per user per day.
class DailyQuestion extends Equatable {
  const DailyQuestion({required this.dayKey, required this.text});

  /// `yyyy-m-d` in UTC, unpadded - matches `string(request.time.year())`
  /// etc. in the security rules.
  final String dayKey;
  final String text;

  static const maxAnswerLength = 280;

  static String dayKeyFor(DateTime moment) {
    final utc = moment.toUtc();
    return '${utc.year}-${utc.month}-${utc.day}';
  }

  /// When the question that is current at [moment] is replaced by the next
  /// one: the start of the following UTC day.
  static DateTime nextChangeAfter(DateTime moment) {
    final utc = moment.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day + 1);
  }

  factory DailyQuestion.forDay(DateTime moment) {
    final utc = moment.toUtc();
    final day = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
    ).difference(DateTime.utc(2026)).inDays;
    return DailyQuestion(
      dayKey: dayKeyFor(moment),
      text: _questions[day % _questions.length],
    );
  }

  static const _questions = [
    'İdeal bir pazar günün nasıl geçer?',
    'Evliliğe dair seni en çok heyecanlandıran şey ne?',
    'Ailenle paylaştığın en güzel gelenek hangisi?',
    'Seni gerçekten dinlendiren şey nedir?',
    'Bir eşte ilk aradığın özellik ne?',
    'Çocukluğundan aklında kalan en sıcak anı ne?',
    'Hafta içi bir akşam evde nasıl vakit geçirmeyi seversin?',
    'Hayatında en çok şükrettiğin şey ne?',
    'Birlikte yapmayı hayal ettiğin ilk yolculuk nereye olurdu?',
    'İyi bir sohbet senin için nasıl başlar?',
    'Zor bir günün sonunda sana ne iyi gelir?',
    'Evinde olmazsa olmaz dediğin şey ne?',
    'Son zamanlarda öğrendiğin ve seni şaşırtan bir şey ne oldu?',
    'Sence bir yuvayı yuva yapan şey nedir?',
    'En son hangi kitap ya da film seni etkiledi?',
    'Kendinde en çok geliştirmek istediğin yön hangisi?',
    'Misafir ağırlamayı mı seversin, misafirliğe gitmeyi mi?',
    'Sabah insanı mısın, gece kuşu mu? Neden?',
    'Bir arkadaşın seni üç kelimeyle nasıl anlatırdı?',
    'Birine güvenmeni sağlayan şey ne olur?',
    'Bayram sabahları senin için nasıl geçer?',
  ];

  @override
  List<Object?> get props => [dayKey, text];
}
