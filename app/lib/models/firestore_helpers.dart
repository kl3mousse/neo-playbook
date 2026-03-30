import 'package:cloud_firestore/cloud_firestore.dart';

/// Parse a Firestore field that may be either a [Timestamp] or an ISO 8601
/// string (e.g. when data was uploaded from a Python script).
Timestamp? parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value;
  if (value is String) {
    final dt = DateTime.tryParse(value);
    if (dt != null) return Timestamp.fromDate(dt);
  }
  return null;
}
