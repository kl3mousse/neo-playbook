import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/scan_recognition_job.dart';
import 'auth_service.dart';

class CollectionScanService {
  static final _db = FirebaseFirestore.instance;
  static const _dbName = 'otakudb';

  static FirebaseFirestore get _namedDb =>
      FirebaseFirestore.instanceFor(app: _db.app, databaseId: _dbName);

  static CollectionReference<Map<String, dynamic>> _jobsRef(String uid) =>
      _namedDb.collection('users').doc(uid).collection('scan_jobs');

  static Future<String> submitScanJob({
    required RecognitionMode mode,
    required Uint8List imageBytes,
    String? fileName,
    String? mimeType,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception('Not authenticated');
    }

    final docRef = _jobsRef(user.uid).doc();
    final effectiveMimeType = mimeType ?? _mimeTypeFromName(fileName);
    final extension = _extensionFromMimeType(effectiveMimeType);
    final imagePath = 'collection_scans/${user.uid}/${docRef.id}.$extension';

    await FirebaseStorage.instance
        .ref()
        .child(imagePath)
        .putData(imageBytes, SettableMetadata(contentType: effectiveMimeType));

    await docRef.set({
      'uid': user.uid,
      'mode': mode.value,
      'status': 'queued',
      'image_path': imagePath,
      'image_name': fileName,
      'mime_type': effectiveMimeType,
      'image_hash': _fastHashHex(imageBytes),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  static Stream<ScanRecognitionJob?> watchJob(String jobId) {
    final user = AuthService.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _jobsRef(user.uid)
        .doc(jobId)
        .snapshots()
        .map(
          (doc) => doc.exists ? ScanRecognitionJob.fromFirestore(doc) : null,
        );
  }

  static Future<ScanRecognitionJob?> getJob(String jobId) async {
    final user = AuthService.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _jobsRef(user.uid).doc(jobId).get();
    if (!doc.exists) {
      return null;
    }
    return ScanRecognitionJob.fromFirestore(doc);
  }

  static String _mimeTypeFromName(String? fileName) {
    final lower = (fileName ?? '').toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  static String _extensionFromMimeType(String mimeType) {
    if (mimeType.contains('png')) {
      return 'png';
    }
    if (mimeType.contains('webp')) {
      return 'webp';
    }
    return 'jpg';
  }

  static String _fastHashHex(Uint8List bytes) {
    // FNV-1a 32-bit hash: enough for request dedupe without extra dependency.
    const int fnvOffset = 0x811c9dc5;
    const int fnvPrime = 0x01000193;
    int hash = fnvOffset;

    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xffffffff;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }
}
