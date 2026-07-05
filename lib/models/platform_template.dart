import 'collection_item.dart';

/// Type of a free-form platform-specific field.
enum PlatformFieldType { toggle, text, dropdown, date, number }

/// Declarative spec for a single platform-specific collector field.
/// These are stored on the collection item under `platformFields[key]`.
class PlatformFieldSpec {
  final String key;
  final String label;
  final PlatformFieldType type;
  final List<String> options;
  final String? helpText;

  /// When true and the stored value is empty, this contributes a warning
  /// badge (used e.g. for battery service dates).
  final bool warnWhenEmpty;

  const PlatformFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    this.helpText,
    this.warnWhenEmpty = false,
  });
}

/// Declarative spec for an expected collector component.
class ComponentSpec {
  final String key;
  final String label;

  /// Hardware that is required for a playable / authentic setup.
  final bool important;

  const ComponentSpec({
    required this.key,
    required this.label,
    this.important = false,
  });
}

/// A named completeness milestone reached when [requiredKeys] are all present.
class CompletenessTier {
  final String label;
  final Set<String> requiredKeys;
  const CompletenessTier({required this.label, required this.requiredKeys});
}

/// Warning emitted when an important component is missing.
class MissingComponentWarning {
  final String componentKey;
  final String label;
  const MissingComponentWarning({
    required this.componentKey,
    required this.label,
  });
}

/// Visual tone for a computed badge.
enum BadgeTone { positive, info, neutral, warning, danger }

/// A computed badge for display on the collection item detail screen.
class CollectionBadge {
  final String label;
  final BadgeTone tone;
  const CollectionBadge(this.label, this.tone);
}

/// The full collector template for a platform: expected components,
/// platform-specific fields, and completeness milestones.
class PlatformTemplate {
  final String id;
  final String displayName;
  final List<ComponentSpec> components;
  final List<PlatformFieldSpec> fields;

  /// Ordered high → low; the highest fully-satisfied tier wins.
  final List<CompletenessTier> completenessTiers;

  /// If set, an empty value for this platform field raises a battery warning.
  final String? batteryServiceFieldKey;

  final List<MissingComponentWarning> missingComponentWarnings;

  const PlatformTemplate({
    required this.id,
    required this.displayName,
    required this.components,
    this.fields = const [],
    this.completenessTiers = const [],
    this.batteryServiceFieldKey,
    this.missingComponentWarnings = const [],
  });

  ComponentSpec? componentSpec(String key) {
    for (final c in components) {
      if (c.key == key) return c;
    }
    return null;
  }
}

// ── Shared field option lists ────────────────────────────────────────────

const _labelConditionOptions = [
  'Mint',
  'Very Good',
  'Good',
  'Fair',
  'Poor',
  'Missing',
];

// ── Platform templates ───────────────────────────────────────────────────

const _mvs = PlatformTemplate(
  id: 'mvs',
  displayName: 'Neo Geo MVS',
  components: [
    ComponentSpec(key: 'mvs_cartridge', label: 'MVS cartridge', important: true),
    ComponentSpec(key: 'mini_marquee', label: 'Mini marquee'),
    ComponentSpec(key: 'move_strip', label: 'Move strip / instruction card'),
    ComponentSpec(key: 'dip_sheet', label: 'DIP sheet'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'flyer', label: 'Flyer'),
    ComponentSpec(key: 'shockbox', label: 'Shockbox'),
    ComponentSpec(key: 'carton_box', label: 'Carton box'),
    ComponentSpec(key: 'cabinet_sticker', label: 'Cabinet sticker'),
    ComponentSpec(key: 'art_set_bag', label: 'Art set bag / envelope'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'cartridge_shell_color',
      label: 'Cartridge shell color',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'original_cart_label',
      label: 'Original cart label',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'cart_label_condition',
      label: 'Cart label condition',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'serial_number',
      label: 'Serial number',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'pcb_verified',
      label: 'PCB verified',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'bootleg_suspicion',
      label: 'Bootleg suspicion',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'matching_kit',
      label: 'Matching kit',
      type: PlatformFieldType.dropdown,
      options: ['Yes', 'Partial', 'No', 'Unknown'],
    ),
  ],
  completenessTiers: [
    CompletenessTier(
      label: 'Collector complete',
      requiredKeys: {
        'mvs_cartridge',
        'mini_marquee',
        'move_strip',
        'dip_sheet',
        'flyer',
        'manual',
        'shockbox',
        'carton_box',
      },
    ),
    CompletenessTier(
      label: 'Full kit + carton',
      requiredKeys: {
        'mvs_cartridge',
        'mini_marquee',
        'move_strip',
        'dip_sheet',
        'manual',
        'carton_box',
      },
    ),
    CompletenessTier(
      label: 'Full kit',
      requiredKeys: {
        'mvs_cartridge',
        'mini_marquee',
        'move_strip',
        'dip_sheet',
        'manual',
      },
    ),
    CompletenessTier(
      label: 'Partial kit',
      requiredKeys: {'mvs_cartridge', 'mini_marquee', 'move_strip'},
    ),
    CompletenessTier(
      label: 'Cart + mini marquee',
      requiredKeys: {'mvs_cartridge', 'mini_marquee'},
    ),
    CompletenessTier(
      label: 'Loose cart',
      requiredKeys: {'mvs_cartridge'},
    ),
  ],
);

const _cps1 = PlatformTemplate(
  id: 'cps1',
  displayName: 'Capcom CPS1',
  components: [
    ComponentSpec(key: 'a_board', label: 'A board', important: true),
    ComponentSpec(key: 'b_board', label: 'B board', important: true),
    ComponentSpec(key: 'c_board', label: 'C board'),
    ComponentSpec(key: 'qsound_board', label: 'QSound board'),
    ComponentSpec(key: 'kick_harness', label: 'Kick harness'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'flyer', label: 'Flyer'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'cpo', label: 'Control panel overlay'),
    ComponentSpec(key: 'move_strip', label: 'Move strip'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'rom_labels_original',
      label: 'ROM labels original',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'security_status',
      label: 'Suicide / security status',
      type: PlatformFieldType.dropdown,
      options: ['OK', 'At risk', 'Suicided', 'N/A', 'Unknown'],
    ),
  ],
);

const _cps2 = PlatformTemplate(
  id: 'cps2',
  displayName: 'Capcom CPS2',
  components: [
    ComponentSpec(
      key: 'b_board',
      label: 'B-board game cartridge',
      important: true,
    ),
    ComponentSpec(key: 'a_board', label: 'A-board', important: true),
    ComponentSpec(key: 'kick_harness', label: 'Kick harness'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'move_strip', label: 'Move strips'),
    ComponentSpec(key: 'side_art', label: 'Side art / cabinet art'),
    ComponentSpec(key: 'shipping_box', label: 'Original shipping box'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'board_color',
      label: 'Board color',
      type: PlatformFieldType.dropdown,
      options: ['Blue', 'Green', 'Gray', 'Orange', 'Yellow', 'Black'],
    ),
    PlatformFieldSpec(
      key: 'ab_compatibility',
      label: 'A/B compatibility',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'battery_status',
      label: 'Battery status',
      type: PlatformFieldType.dropdown,
      options: [
        'Original',
        'Replaced',
        'Suicided',
        'Desuicided',
        'InfiniKey',
        'Phoenix',
        'Unknown',
      ],
    ),
    PlatformFieldSpec(
      key: 'battery_service_date',
      label: 'Battery service date',
      type: PlatformFieldType.date,
      warnWhenEmpty: true,
      helpText: 'Track when the suicide battery was last serviced.',
    ),
    PlatformFieldSpec(
      key: 'shell_condition',
      label: 'Shell condition',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'label_condition',
      label: 'Label condition',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'serial_number',
      label: 'Serial number',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'fan_condition',
      label: 'Fan condition',
      type: PlatformFieldType.text,
    ),
  ],
  batteryServiceFieldKey: 'battery_service_date',
);

const _cps3 = PlatformTemplate(
  id: 'cps3',
  displayName: 'Capcom CPS3',
  components: [
    ComponentSpec(key: 'motherboard', label: 'Motherboard', important: true),
    ComponentSpec(
      key: 'security_cart',
      label: 'Security cartridge',
      important: true,
    ),
    ComponentSpec(key: 'cd_rom_disc', label: 'CD-ROM game disc', important: true),
    ComponentSpec(key: 'cd_rom_drive', label: 'CD-ROM drive'),
    ComponentSpec(key: 'scsi_cable', label: 'SCSI cable'),
    ComponentSpec(key: 'power_cable', label: 'Power cable'),
    ComponentSpec(key: 'simms', label: 'SIMMs'),
    ComponentSpec(key: 'kick_harness', label: 'Kick harness'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'flyer', label: 'Flyers'),
    ComponentSpec(key: 'instruction_cards', label: 'Instruction cards'),
    ComponentSpec(key: 'casing', label: 'Casing / screws'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'security_cart_battery_status',
      label: 'Security cart battery status',
      type: PlatformFieldType.dropdown,
      options: ['Original', 'Replaced', 'Suicided', 'Phoenix', 'Unknown'],
    ),
    PlatformFieldSpec(
      key: 'battery_service_date',
      label: 'Battery service date',
      type: PlatformFieldType.date,
      warnWhenEmpty: true,
    ),
    PlatformFieldSpec(
      key: 'no_cd_conversion',
      label: 'No-CD conversion',
      type: PlatformFieldType.toggle,
    ),
  ],
  batteryServiceFieldKey: 'battery_service_date',
  missingComponentWarnings: [
    MissingComponentWarning(
      componentKey: 'security_cart',
      label: 'Missing security cart',
    ),
    MissingComponentWarning(
      componentKey: 'cd_rom_disc',
      label: 'Missing game disc',
    ),
  ],
);

const _naomi = PlatformTemplate(
  id: 'naomi',
  displayName: 'Sega NAOMI / NAOMI 2',
  components: [
    ComponentSpec(key: 'rom_cartridge', label: 'ROM cartridge'),
    ComponentSpec(key: 'gd_rom_disc', label: 'GD-ROM disc'),
    ComponentSpec(key: 'key_chip', label: 'Key chip', important: true),
    ComponentSpec(key: 'dimm_board', label: 'DIMM board'),
    ComponentSpec(key: 'netdimm', label: 'NetDIMM'),
    ComponentSpec(key: 'gd_rom_drive', label: 'GD-ROM drive'),
    ComponentSpec(key: 'scsi_cable', label: 'SCSI cable'),
    ComponentSpec(key: 'gd_power_cable', label: 'GD-ROM power cable'),
    ComponentSpec(key: 'jvs_io', label: 'JVS I/O board'),
    ComponentSpec(key: 'jamma_adapter', label: 'JAMMA adapter'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'cpo', label: 'Control panel overlay'),
    ComponentSpec(key: 'card_reader', label: 'Card reader / special device'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'media_type',
      label: 'Media type',
      type: PlatformFieldType.dropdown,
      options: ['Cartridge', 'GD-ROM', 'NetDIMM', 'CompactFlash', 'Netboot'],
    ),
    PlatformFieldSpec(
      key: 'key_chip_paired',
      label: 'Key chip paired with disc',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'dimm_firmware_version',
      label: 'DIMM firmware version',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'bios_region',
      label: 'BIOS region',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'naomi_compatibility',
      label: 'NAOMI 1 / NAOMI 2 compatibility',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'control_panel_type',
      label: 'Control panel type',
      type: PlatformFieldType.dropdown,
      options: ['Standard', 'Analog', 'Driving', 'Gun', 'Trackball'],
    ),
  ],
  missingComponentWarnings: [
    MissingComponentWarning(componentKey: 'key_chip', label: 'Missing key chip'),
  ],
);

const _atomiswave = PlatformTemplate(
  id: 'atomiswave',
  displayName: 'Sammy Atomiswave',
  components: [
    ComponentSpec(key: 'cartridge', label: 'Cartridge', important: true),
    ComponentSpec(key: 'motherboard', label: 'Motherboard', important: true),
    ComponentSpec(key: 'io_board', label: 'I/O board'),
    ComponentSpec(key: 'art_sheet', label: 'Art sheet'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'cabinet_sticker', label: 'Cabinet sticker'),
    ComponentSpec(key: 'flyer', label: 'Flyer'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'shell_condition',
      label: 'Shell condition',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'cart_label',
      label: 'Cart label',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'holographic_sticker',
      label: 'Holographic sticker',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'serial_number',
      label: 'Serial number',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'pcb_verified',
      label: 'PCB verified',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'bootleg_suspicion',
      label: 'Bootleg suspicion',
      type: PlatformFieldType.toggle,
    ),
  ],
);

const _stv = PlatformTemplate(
  id: 'stv',
  displayName: 'Sega ST-V',
  components: [
    ComponentSpec(key: 'cartridge', label: 'Cartridge', important: true),
    ComponentSpec(key: 'motherboard', label: 'Motherboard', important: true),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'flyer', label: 'Flyer'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'cpo', label: 'Control panel overlay'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'cartridge_label',
      label: 'Cartridge label',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'shell_condition',
      label: 'Cartridge shell condition',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'bios_version',
      label: 'BIOS version',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'backup_ram_status',
      label: 'Backup RAM status',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'battery_status',
      label: 'Battery status',
      type: PlatformFieldType.dropdown,
      options: ['Original', 'Replaced', 'Dead', 'Unknown'],
    ),
    PlatformFieldSpec(
      key: 'battery_service_date',
      label: 'Battery service date',
      type: PlatformFieldType.date,
      warnWhenEmpty: true,
    ),
  ],
  batteryServiceFieldKey: 'battery_service_date',
);

const _taitof3 = PlatformTemplate(
  id: 'taitof3',
  displayName: 'Taito F3',
  components: [
    ComponentSpec(key: 'cartridge', label: 'Cartridge', important: true),
    ComponentSpec(key: 'motherboard', label: 'Motherboard', important: true),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'flyer', label: 'Flyer'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'instruction_card', label: 'Instruction card'),
    ComponentSpec(key: 'cpo', label: 'Control panel overlay'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'cart_label',
      label: 'Cart label',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'pcb_verified',
      label: 'PCB verified',
      type: PlatformFieldType.toggle,
    ),
  ],
);

const _pgm = PlatformTemplate(
  id: 'pgm',
  displayName: 'IGS PGM',
  components: [
    ComponentSpec(key: 'cartridge', label: 'Cartridge', important: true),
    ComponentSpec(key: 'motherboard', label: 'Motherboard', important: true),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'flyer', label: 'Flyer'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'move_strip', label: 'Move strip'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'cart_label',
      label: 'Cart label',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'shell_color',
      label: 'Shell color',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'serial_number',
      label: 'Serial number',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'pcb_verified',
      label: 'PCB verified',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'cave_pgm_variant',
      label: 'Cave PGM variant',
      type: PlatformFieldType.dropdown,
      options: [
        'Original PCB',
        'Conversion',
        'Bootleg cart',
        'Unknown',
      ],
    ),
  ],
);

const _typex = PlatformTemplate(
  id: 'typex',
  displayName: 'Taito Type X',
  components: [
    ComponentSpec(key: 'game_drive', label: 'Game HDD / SSD', important: true),
    ComponentSpec(
      key: 'security_dongle',
      label: 'USB security dongle',
      important: true,
    ),
    ComponentSpec(key: 'motherboard', label: 'Motherboard / PC', important: true),
    ComponentSpec(key: 'jvs_io', label: 'JVS I/O'),
    ComponentSpec(key: 'restore_media', label: 'Restore media'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'cpo', label: 'Control panel overlay'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'system_type',
      label: 'System type',
      type: PlatformFieldType.dropdown,
      options: ['Type X', 'Type X+', 'Type X2', 'Type X3', 'Type X4'],
    ),
    PlatformFieldSpec(
      key: 'dongle_serial',
      label: 'Dongle serial',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'gpu_model',
      label: 'GPU model',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'os_image_original',
      label: 'OS image original',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'network_requirement',
      label: 'Network requirement',
      type: PlatformFieldType.text,
    ),
  ],
  missingComponentWarnings: [
    MissingComponentWarning(
      componentKey: 'security_dongle',
      label: 'Missing dongle',
    ),
  ],
);

const _system246 = PlatformTemplate(
  id: 'system246',
  displayName: 'Namco System 246 / 256 / 357',
  components: [
    ComponentSpec(key: 'motherboard', label: 'Motherboard', important: true),
    ComponentSpec(key: 'game_media', label: 'Game disc / HDD', important: true),
    ComponentSpec(
      key: 'security_dongle',
      label: 'Security dongle / key',
      important: true,
    ),
    ComponentSpec(key: 'dvd_drive', label: 'DVD drive'),
    ComponentSpec(key: 'io_board', label: 'I/O board'),
    ComponentSpec(key: 'memory_card_reader', label: 'Memory card reader'),
    ComponentSpec(key: 'special_controls', label: 'Special controls'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'art_set', label: 'Art set'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'dongle_serial',
      label: 'Dongle serial',
      type: PlatformFieldType.text,
    ),
  ],
  missingComponentWarnings: [
    MissingComponentWarning(
      componentKey: 'security_dongle',
      label: 'Missing dongle',
    ),
  ],
);

const _jamma = PlatformTemplate(
  id: 'jamma',
  displayName: 'Generic JAMMA PCB',
  components: [
    ComponentSpec(key: 'pcb', label: 'PCB', important: true),
    ComponentSpec(key: 'daughterboards', label: 'Daughterboards'),
    ComponentSpec(key: 'kick_harness', label: 'Kick harness'),
    ComponentSpec(key: 'sound_amp', label: 'Sound amp board'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'flyer', label: 'Flyer'),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'bezel', label: 'Bezel'),
    ComponentSpec(key: 'cpo', label: 'Control panel overlay'),
    ComponentSpec(key: 'wiring_adapter', label: 'Wiring adapter'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'original_pcb',
      label: 'Original PCB',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'rom_labels',
      label: 'ROM labels',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'edge_connector_condition',
      label: 'Edge connector condition',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'suicide_battery',
      label: 'Suicide battery',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'battery_service_date',
      label: 'Battery service date',
      type: PlatformFieldType.date,
    ),
  ],
);

/// Dedicated Neo Geo Jamma board (a specific game PCB mounted in a cabinet).
const _neoJamma = PlatformTemplate(
  id: 'neojamma',
  displayName: 'Neo Geo Jamma',
  components: [
    ComponentSpec(key: 'pcb', label: 'PCB', important: true),
    ComponentSpec(key: 'marquee', label: 'Marquee'),
    ComponentSpec(key: 'side_art', label: 'Side art'),
    ComponentSpec(key: 'bezel', label: 'Bezel'),
  ],
  fields: [
    PlatformFieldSpec(
      key: 'original_pcb',
      label: 'Original PCB',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'rom_labels',
      label: 'ROM labels',
      type: PlatformFieldType.text,
    ),
    PlatformFieldSpec(
      key: 'edge_connector_condition',
      label: 'Edge connector condition',
      type: PlatformFieldType.dropdown,
      options: _labelConditionOptions,
    ),
    PlatformFieldSpec(
      key: 'suicide_battery',
      label: 'Suicide battery',
      type: PlatformFieldType.toggle,
    ),
    PlatformFieldSpec(
      key: 'battery_service_date',
      label: 'Battery service date',
      type: PlatformFieldType.date,
      warnWhenEmpty: true,
    ),
  ],
  batteryServiceFieldKey: 'battery_service_date',
);

/// Simple home-console / CD templates so AES & Neo Geo CD copies still work.
const _aes = PlatformTemplate(
  id: 'aes',
  displayName: 'Neo Geo AES',
  components: [
    ComponentSpec(key: 'cartridge', label: 'Cartridge', important: true),
    ComponentSpec(key: 'box', label: 'Box'),
    ComponentSpec(key: 'manual', label: 'Manual / insert'),
    ComponentSpec(key: 'snk_insert', label: 'SNK insert / poster'),
  ],
);

const _ngcd = PlatformTemplate(
  id: 'ngcd',
  displayName: 'Neo Geo CD',
  components: [
    ComponentSpec(key: 'disc', label: 'Game disc', important: true),
    ComponentSpec(key: 'case', label: 'Jewel case'),
    ComponentSpec(key: 'manual', label: 'Manual'),
    ComponentSpec(key: 'spine_card', label: 'Spine / obi card'),
  ],
);

const Map<String, PlatformTemplate> _templates = {
  'mvs': _mvs,
  'neogeo': _mvs,
  'aes': _aes,
  'ngcd': _ngcd,
  'neogeocd': _ngcd,
  'neojamma': _neoJamma,
  'cps1': _cps1,
  'cps2': _cps2,
  'cps3': _cps3,
  'naomi': _naomi,
  'naomi2': _naomi,
  'atomiswave': _atomiswave,
  'stv': _stv,
  'taitof3': _taitof3,
  'pgm': _pgm,
  'typex': _typex,
  'system246': _system246,
  'jamma': _jamma,
};

/// Platform IDs that belong to the Neo Geo hardware family.
const Set<String> neoGeoFamilyPlatformIds = {
  'mvs', 'neogeo', 'aes', 'ngcd', 'neogeocd', 'neojamma',
};

/// The four selectable Neo Geo formats, in display order.
const List<String> neoGeoFormatIds = ['mvs', 'aes', 'ngcd', 'neojamma'];

/// Returns true when [platformId] belongs to the Neo Geo family.
bool isNeoGeoFamily(String platformId) {
  final key = platformId.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  return neoGeoFamilyPlatformIds.contains(key);
}

/// All distinct templates available for selection.
List<PlatformTemplate> get allPlatformTemplates => const [
  _mvs,
  _aes,
  _ngcd,
  _neoJamma,
  _cps1,
  _cps2,
  _cps3,
  _naomi,
  _atomiswave,
  _stv,
  _taitof3,
  _pgm,
  _typex,
  _system246,
  _jamma,
];

/// Resolve a [PlatformTemplate] for the given platform key, falling back to
/// the generic JAMMA template so any platform stays usable.
PlatformTemplate platformTemplate(String platformId) {
  final key = platformId.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  return _templates[key] ?? _jamma;
}

/// True when an explicit template (not the JAMMA fallback) exists.
bool hasPlatformTemplate(String platformId) {
  final key = platformId.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  return _templates.containsKey(key);
}

// ── Completeness & badges ────────────────────────────────────────────────

Set<String> _presentComponentKeys(CollectionItem item) {
  return item.components.entries
      .where((e) => e.value.present)
      .map((e) => e.key)
      .toSet();
}

/// Computes the completeness milestone label for an item, or null.
String? computeCompleteness(CollectionItem item, PlatformTemplate template) {
  final present = _presentComponentKeys(item);
  if (present.isEmpty) return null;

  if (template.completenessTiers.isNotEmpty) {
    for (final tier in template.completenessTiers) {
      if (tier.requiredKeys.every(present.contains)) {
        return tier.label;
      }
    }
    return null;
  }

  // Generic ratio-based completeness for templates without explicit tiers.
  final total = template.components.length;
  if (total == 0) return null;
  final ratio = present.length / total;
  if (ratio >= 0.95) return 'Collector complete';
  if (ratio >= 0.6) return 'Full kit';
  if (ratio >= 0.3) return 'Partial kit';
  return 'Loose';
}

/// Computes display badges for an item using its platform template.
List<CollectionBadge> computeBadges(
  CollectionItem item,
  PlatformTemplate template,
) {
  final badges = <CollectionBadge>[];

  // Draft / unverified status — surface first so users can act on it.
  if (item.isUnverified) {
    badges.add(const CollectionBadge('Draft · Unverified', BadgeTone.warning));
  }

  // Off-catalog entries: not linked to a catalog game.
  if (item.isCustomEntry) {
    badges.add(const CollectionBadge('Off-catalog', BadgeTone.info));
  }

  final completeness = computeCompleteness(item, template);
  if (completeness != null) {
    badges.add(CollectionBadge(completeness, BadgeTone.info));
  }

  // Working status.
  switch (item.workingStatus) {
    case WorkingStatus.working:
      badges.add(const CollectionBadge('Working', BadgeTone.positive));
      break;
    case WorkingStatus.untested:
      badges.add(const CollectionBadge('Untested', BadgeTone.warning));
      break;
    case WorkingStatus.partial:
      badges.add(const CollectionBadge('Partial', BadgeTone.warning));
      break;
    case WorkingStatus.faulty:
      badges.add(const CollectionBadge('Faulty', BadgeTone.danger));
      break;
    case WorkingStatus.dead:
      badges.add(const CollectionBadge('Dead', BadgeTone.danger));
      break;
  }

  // Authenticity.
  switch (item.authenticityConfidence) {
    case AuthenticityConfidence.originalConfirmed:
      badges.add(const CollectionBadge('Original confirmed', BadgeTone.positive));
      break;
    case AuthenticityConfidence.likelyOriginal:
      badges.add(const CollectionBadge('Likely original', BadgeTone.positive));
      break;
    case AuthenticityConfidence.likelyBootleg:
      badges.add(const CollectionBadge('Bootleg suspected', BadgeTone.danger));
      break;
    case AuthenticityConfidence.uncertain:
    case null:
      break;
  }
  if (item.copyType == CopyType.bootleg &&
      item.authenticityConfidence != AuthenticityConfidence.likelyBootleg) {
    badges.add(const CollectionBadge('Bootleg', BadgeTone.danger));
  }

  // Battery attention.
  if (template.batteryServiceFieldKey != null) {
    final v = item.platformFields[template.batteryServiceFieldKey];
    final empty = v == null || (v is String && v.trim().isEmpty);
    if (empty) {
      badges.add(const CollectionBadge('Battery attention', BadgeTone.warning));
    }
  }

  // Missing important components.
  for (final w in template.missingComponentWarnings) {
    final c = item.components[w.componentKey];
    if (c == null || !c.present) {
      badges.add(CollectionBadge(w.label, BadgeTone.warning));
    }
  }

  return badges;
}
