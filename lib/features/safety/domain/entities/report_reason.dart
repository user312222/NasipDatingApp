/// FR-6.1: why a user is being reported.
enum ReportReason {
  fakeProfile,
  harassment,
  inappropriateContent,
  scam,
  casualIntent,
  other,
}

extension ReportReasonLabel on ReportReason {
  String get label => switch (this) {
    ReportReason.fakeProfile => 'Sahte profil',
    ReportReason.harassment => 'Taciz / rahatsız edici davranış',
    ReportReason.inappropriateContent => 'Uygunsuz fotoğraf ya da mesaj',
    ReportReason.scam => 'Dolandırıcılık şüphesi',
    ReportReason.casualIntent => 'Niyeti evlilik değil, flört',
    ReportReason.other => 'Diğer',
  };
}
