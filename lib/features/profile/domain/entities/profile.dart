import 'package:equatable/equatable.dart';

/// FR-2.2: exactly these two — deliberately no "casual/flört" option per
/// Bi Nasip's marriage-first positioning.
enum ProfileIntent { marriage, notSureYet }

/// FR-3.1: the three photo-reveal levels, ordered least → most open.
/// FR-3.2: the default MUST be [hiddenUntilIUnlock] — the most
/// restrictive — because visibility is opt-in-to-expand, never
/// opt-out-to-restrict.
enum PhotoVisibility {
  /// Kime ne zaman görüneceği tamamen bana bağlı; kimseye otomatik ya da
  /// istek üzerine açılmaz, sadece ben açarsam görünür. Varsayılan.
  hiddenUntilIUnlock,

  /// Biri istediğinde bildirim alırım, onaylarsam görünür.
  onRequestOnly,

  /// Karşılıklı eşleşme oluşunca otomatik açılır.
  autoOnMatch,
}

/// The madhhab choice that says nothing. Unlike any real value in that
/// field it is not religious data, so it needs no KVKK m.6 consent.
const madhhabNoAnswer = 'Belirtmek istemiyorum';

/// A completed profile, ready to save. `photoRefs` are placeholder
/// filenames for now — see `ProfileRemoteDataSource` — they'll become
/// Firebase Storage download URLs once photo upload is wired.
class Profile extends Equatable {
  const Profile({
    required this.userId,
    required this.name,
    required this.birthDate,
    required this.city,
    required this.intent,
    required this.photoRefs,
    required this.familyInvolvementOptIn,
    this.photoVisibility = PhotoVisibility.hiddenUntilIUnlock,
    this.educationLevel,
    this.occupation,
    this.religiousPracticeNote,
    this.madhhab,
  });

  final String userId;
  final String name;
  final DateTime birthDate;
  final String city;
  final ProfileIntent intent;

  /// FR-2.1: 1 to 6 photos.
  final List<String> photoRefs;

  /// FR-3.1/FR-3.2.
  final PhotoVisibility photoVisibility;

  /// FR-2.4: opsiyonel, varsayılan kapalı.
  final bool familyInvolvementOptIn;

  /// FR-2.3: hepsi opsiyonel.
  final String? educationLevel;
  final String? occupation;
  final String? religiousPracticeNote;
  final String? madhhab;

  int get age {
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    birthDate,
    city,
    intent,
    photoRefs,
    photoVisibility,
    familyInvolvementOptIn,
    educationLevel,
    occupation,
    religiousPracticeNote,
    madhhab,
  ];
}
