import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.hour = 19, this.minute = 0});

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

abstract class ReminderStore {
  Future<ReminderSettings> load(String uid);
  Future<void> save(String uid, ReminderSettings settings);
}

/// Disimpan di users/{uid}/settings/reminder.
class FirestoreReminderStore implements ReminderStore {
  FirestoreReminderStore({FirebaseFirestore? firestore}) : _override = firestore;

  final FirebaseFirestore? _override;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      (_override ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('reminder');

  @override
  Future<ReminderSettings> load(String uid) async {
    final data = (await _doc(uid).get()).data();
    if (data == null) return const ReminderSettings();
    return ReminderSettings(
      enabled: data['enabled'] as bool? ?? false,
      hour: (data['hour'] as num?)?.toInt() ?? 19,
      minute: (data['minute'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> save(String uid, ReminderSettings s) => _doc(uid).set({
        'enabled': s.enabled,
        'hour': s.hour,
        'minute': s.minute,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
