import 'dart:convert';
import 'dart:io';

import 'package:combofox/experimental/gold_moves_profile_v1/gold_moves_profile.dart';

/// Absolute path to the shipped Gold bundle folder (test-only). The
/// spike keeps these files out of Flutter's asset system.
String bundlePath(String rel) => 'doc/move profiles/1.0.0/$rel';

/// Read a bundle file as raw bytes (for checksum verification).
List<int> readBundleBytes(String rel) {
  final file = File(bundlePath(rel));
  if (!file.existsSync()) {
    throw StateError(
      'Bundle file not found: ${file.absolute.path}. Tests must be '
      'run from the package root.',
    );
  }
  return file.readAsBytesSync();
}

/// Read a bundle file as a UTF-8 string.
String readBundleString(String rel) =>
    const Utf8Decoder().convert(readBundleBytes(rel));

/// Parse a bundle profile with the default [ProfileParser].
ProfileGold parseBundleProfile(String rel) {
  return ProfileParser().parseString(readBundleString(rel));
}

/// Expected SHA-256 checksums from the bundle manifest (checked into
/// the mission brief).
const Map<String, String> expectedChecksums = {
  'profile.json':
      '5e1b2f8597929502470e4b0b19492142fa5b85d07a8875c95ef4133cdee94b24',
  'schema.json':
      '206dd174689fe4864c911ed2f35c1dc694e375eb72545d678074a6f0466be8fd',
  'CONSUMER_SPEC.md':
      '87c71490afeee6f932525b89ab5168b8722c1156ffaba80908297219de8af9a0',
  'HANDOFF.md':
      'e3d505aa6799e20bd47b332d97e5c7d79020d21ed3c256e875d44491adb5e25a',
  'examples/minimal.profile.json':
      'eec3c1491d3e6debc6d7b71487f7bdc0c9429045664a28c162020f68630c3a3f',
  'examples/activation-automatic.profile.json':
      'f60d274e9dc3820b5d2ee238639f0e627491d3af588130066d332fb26df5d120',
  'rendering-samples.json':
      '1b6c765d40b17579d3022c7bdea3700737c852b8ffde684ba31bfbcb29a986cd',
};
