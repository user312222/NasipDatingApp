import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/waitlist_entry.dart';

/// Data-layer representation of [WaitlistEntry] - carries the
/// serialization the domain entity deliberately doesn't know about.
class WaitlistEntryModel extends WaitlistEntry {
  const WaitlistEntryModel({
    required super.name,
    required super.contact,
    super.city,
  });

  factory WaitlistEntryModel.fromEntity(WaitlistEntry entity) =>
      WaitlistEntryModel(
        name: entity.name,
        contact: entity.contact,
        city: entity.city,
      );

  Map<String, dynamic> toFirestore() => {
    'name': name.trim(),
    'contact': contact.trim(),
    if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  };
}
