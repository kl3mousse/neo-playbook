import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Utility around the SHA-256 verification required by CONSUMER_SPEC §14.
class GoldChecksum {
  /// Hex-encoded lowercase SHA-256 of the raw bytes.
  static String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

  /// Convenience: hash a UTF-8 string.
  static String sha256HexString(String s) =>
      sha256Hex(const Utf8Encoder().convert(s));

  /// Hash raw bytes buffered as a [Uint8List].
  static String sha256HexBytes(Uint8List bytes) => sha256Hex(bytes);
}
