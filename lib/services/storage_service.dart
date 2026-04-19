import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Get a download URL for a storage path.
  static Future<String?> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } catch (_) {
      return null;
    }
  }
}
