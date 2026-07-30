import 'package:flutter/services.dart';

import '../domain/profile.dart';
import 'profile_parser.dart';

/// Path to the bundled KOF R-2 Gold profile fixture used by the debug
/// Gold Move Lab. This is a byte-identical copy of
/// `doc/move profiles/1.0.0/profile.json` (checksums are asserted in
/// `test/experimental/gold_moves_profile_v1/checksum_test.dart`).
const String kBundledKofR2ProfileAsset =
    'assets/experimental/gold_moves_profile_v1/kof_r2_profile.json';

/// Loads the bundled KOF R-2 Gold profile via [rootBundle] so the
/// same code path works on Android, iOS, macOS and web.
Future<ProfileGold> loadBundledKofR2Profile({AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  final raw = await b.loadString(kBundledKofR2ProfileAsset);
  return ProfileParser().parseString(raw);
}
