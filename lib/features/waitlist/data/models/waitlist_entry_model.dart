import '../../domain/entities/waitlist_entry.dart';

/// Data-layer representation of [WaitlistEntry] — carries the
/// (de)serialization the domain entity deliberately doesn't know about.
/// When the local stub is swapped for Firestore, `toJson`/`fromJson` become
/// `toFirestore`/`fromFirestore` and nothing outside this file changes.
class WaitlistEntryModel extends WaitlistEntry {
  const WaitlistEntryModel({
    required super.name,
    required super.contact,
    super.city,
    this.createdAt,
  });

  final DateTime? createdAt;

  factory WaitlistEntryModel.fromEntity(WaitlistEntry entity) =>
      WaitlistEntryModel(
        name: entity.name,
        contact: entity.contact,
        city: entity.city,
      );

  factory WaitlistEntryModel.fromJson(Map<String, dynamic> json) =>
      WaitlistEntryModel(
        name: json['name'] as String,
        contact: json['contact'] as String,
        city: json['city'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'contact': contact,
    if (city != null) 'city': city,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };
}
