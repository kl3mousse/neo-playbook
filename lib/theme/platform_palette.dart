import 'package:flutter/material.dart';

/// Hand-picked palettes for known arcade/console platforms. Each palette
/// is a 2-stop gradient used as a typographic hero background on the
/// game detail screen, and as a subtle accent elsewhere.
///
/// Falls back to a deterministic hash-based palette for unknown keys
/// so new platforms still get a stable, distinctive colour.
class PlatformPalette {
  final Color start;
  final Color end;
  final String label;

  const PlatformPalette({
    required this.start,
    required this.end,
    required this.label,
  });

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      );

  /// Mid-blend colour — useful for chips and accents.
  Color get accent => Color.lerp(start, end, 0.5)!;
}

const _kPlatformPalettes = <String, PlatformPalette>{
  'neogeo': PlatformPalette(
    label: 'Neo Geo',
    start: Color(0xFFB8001F), // MVS red
    end: Color(0xFF1A1A2E),
  ),
  'neo geo': PlatformPalette(
    label: 'Neo Geo',
    start: Color(0xFFB8001F),
    end: Color(0xFF1A1A2E),
  ),
  // Explicit entries for each Neo Geo format so they get distinct colours
  // instead of falling back to the hash-based palette.
  'mvs': PlatformPalette(
    label: 'Neo Geo MVS',
    start: Color(0xFFB8001F), // SNK arcade red
    end: Color(0xFF1A1A2E),
  ),
  'aes': PlatformPalette(
    label: 'Neo Geo AES',
    start: Color(0xFFD4A017), // AES gold/cream
    end: Color(0xFF1A140A),
  ),
  'ngcd': PlatformPalette(
    label: 'Neo Geo CD',
    start: Color(0xFF0B5EA8), // CD blue
    end: Color(0xFF0E1A33),
  ),
  'neogeocd': PlatformPalette(
    label: 'Neo Geo CD',
    start: Color(0xFF0B5EA8), // AES-CD blue
    end: Color(0xFF0E1A33),
  ),
  'neojamma': PlatformPalette(
    label: 'Neo Geo Jamma',
    start: Color(0xFF8B0000), // dark arcade red
    end: Color(0xFF1A0A0A),
  ),
  'cps1': PlatformPalette(
    label: 'CPS-1',
    start: Color(0xFFE8A317),
    end: Color(0xFF3A1F05),
  ),
  'cps2': PlatformPalette(
    label: 'CPS-2',
    start: Color(0xFF4B2A82), // violet arcade board
    end: Color(0xFF0F0A1F),
  ),
  'cps3': PlatformPalette(
    label: 'CPS-3',
    start: Color(0xFF2B8A7A),
    end: Color(0xFF0A1A1A),
  ),
  'atomiswave': PlatformPalette(
    label: 'Atomiswave',
    start: Color(0xFF00A3A3),
    end: Color(0xFF081F26),
  ),
  'taitof3': PlatformPalette(
    label: 'Taito F3',
    start: Color(0xFFC83C6E),
    end: Color(0xFF1A0A16),
  ),
  'hng64': PlatformPalette(
    label: 'Hyper Neo Geo 64',
    start: Color(0xFFD64949),
    end: Color(0xFF171A26),
  ),
  'stv': PlatformPalette(
    label: 'ST-V',
    start: Color(0xFF3A5FBE),
    end: Color(0xFF0A1024),
  ),
  'zn': PlatformPalette(
    label: 'ZN',
    start: Color(0xFF707070),
    end: Color(0xFF14161C),
  ),
};

PlatformPalette _fallbackPalette(String key) {
  // Deterministic HSL from key hash — keeps each unknown platform
  // consistent across builds.
  final hash = key.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0xFFFFFF);
  final hue = (hash % 360).toDouble();
  final start = HSLColor.fromAHSL(1, hue, 0.55, 0.38).toColor();
  final end = HSLColor.fromAHSL(1, (hue + 12) % 360, 0.35, 0.10).toColor();
  return PlatformPalette(
    label: key.isEmpty ? 'Unknown' : key,
    start: start,
    end: end,
  );
}

/// Resolve a [PlatformPalette] for the given platform key. Case-insensitive.
PlatformPalette platformPalette(String key) {
  final normalized = key.trim().toLowerCase();
  if (normalized.isEmpty) return _fallbackPalette('');
  return _kPlatformPalettes[normalized] ?? _fallbackPalette(normalized);
}
