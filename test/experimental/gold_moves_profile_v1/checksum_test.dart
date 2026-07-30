import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/fixture_loader.dart';

void main() {
  group('Gold bundle SHA-256 checksums', () {
    for (final entry in expectedChecksums.entries) {
      test('checksum of ${entry.key}', () {
        final bytes = readBundleBytes(entry.key);
        expect(GoldChecksum.sha256Hex(bytes), equals(entry.value));
      });
    }
  });
}
