enum GlyphCategory { directions, motions, buttons, operators }

class GlyphDefinition {
  final String id;
  final GlyphCategory category;
  final String filename;
  final String label;

  const GlyphDefinition(this.id, this.category, this.filename, this.label);
}

class GlyphRegistry {
  GlyphRegistry._();

  static const definitions = <GlyphDefinition>[
    GlyphDefinition('dir_u', GlyphCategory.directions, 'dir_u.svg', 'Up'),
    GlyphDefinition(
      'dir_ub',
      GlyphCategory.directions,
      'dir_ub.svg',
      'Up-back',
    ),
    GlyphDefinition('dir_b', GlyphCategory.directions, 'dir_b.svg', 'Back'),
    GlyphDefinition(
      'dir_db',
      GlyphCategory.directions,
      'dir_db.svg',
      'Down-back',
    ),
    GlyphDefinition('dir_d', GlyphCategory.directions, 'dir_d.svg', 'Down'),
    GlyphDefinition(
      'dir_df',
      GlyphCategory.directions,
      'dir_df.svg',
      'Down-forward',
    ),
    GlyphDefinition('dir_f', GlyphCategory.directions, 'dir_f.svg', 'Forward'),
    GlyphDefinition(
      'dir_uf',
      GlyphCategory.directions,
      'dir_uf.svg',
      'Up-forward',
    ),
    GlyphDefinition(
      'motion_qcf',
      GlyphCategory.motions,
      'motion_qcf.svg',
      'Quarter circle forward',
    ),
    GlyphDefinition(
      'motion_qcb',
      GlyphCategory.motions,
      'motion_qcb.svg',
      'Quarter circle back',
    ),
    GlyphDefinition(
      'motion_hcf',
      GlyphCategory.motions,
      'motion_hcf.svg',
      'Half circle forward',
    ),
    GlyphDefinition(
      'motion_hcb',
      GlyphCategory.motions,
      'motion_hcb.svg',
      'Half circle back',
    ),
    GlyphDefinition(
      'motion_dpf',
      GlyphCategory.motions,
      'motion_dpf.svg',
      'Dragon punch forward',
    ),
    GlyphDefinition(
      'motion_dpb',
      GlyphCategory.motions,
      'motion_dpb.svg',
      'Dragon punch back',
    ),
    GlyphDefinition(
      'motion_rdpf',
      GlyphCategory.motions,
      'motion_rdpf.svg',
      'Reverse dragon punch forward',
    ),
    GlyphDefinition(
      'motion_rdpb',
      GlyphCategory.motions,
      'motion_rdpb.svg',
      'Reverse dragon punch back',
    ),
    GlyphDefinition(
      'motion_360',
      GlyphCategory.motions,
      'motion_360.svg',
      '360 degree rotation',
    ),
    GlyphDefinition(
      'motion_720',
      GlyphCategory.motions,
      'motion_720.svg',
      '720 degree rotation',
    ),
    GlyphDefinition(
      'motion_charge_bf',
      GlyphCategory.motions,
      'motion_charge_bf.svg',
      'Charge back to forward',
    ),
    GlyphDefinition(
      'motion_charge_du',
      GlyphCategory.motions,
      'motion_charge_du.svg',
      'Charge down to up',
    ),
    GlyphDefinition(
      'motion_dqcf',
      GlyphCategory.motions,
      'motion_dqcf.svg',
      'Double quarter circle forward',
    ),
    GlyphDefinition(
      'motion_dqcb',
      GlyphCategory.motions,
      'motion_dqcb.svg',
      'Double quarter circle back',
    ),
    GlyphDefinition(
      'motion_pretzel_f',
      GlyphCategory.motions,
      'motion_pretzel_f.svg',
      'Pretzel forward',
    ),
    GlyphDefinition(
      'motion_pretzel_b',
      GlyphCategory.motions,
      'motion_pretzel_b.svg',
      'Pretzel back',
    ),
    ..._buttonDefinitions,
    GlyphDefinition('op_plus', GlyphCategory.operators, 'op_plus.svg', 'Plus'),
    GlyphDefinition('op_then', GlyphCategory.operators, 'op_then.svg', 'Then'),
    GlyphDefinition('op_hold', GlyphCategory.operators, 'op_hold.svg', 'Hold'),
    GlyphDefinition(
      'op_release',
      GlyphCategory.operators,
      'op_release.svg',
      'Release',
    ),
  ];

  static const _buttonDefinitions = <GlyphDefinition>[
    GlyphDefinition('btn_a', GlyphCategory.buttons, 'btn_a.svg', 'A'),
    GlyphDefinition('btn_b', GlyphCategory.buttons, 'btn_b.svg', 'B'),
    GlyphDefinition('btn_c', GlyphCategory.buttons, 'btn_c.svg', 'C'),
    GlyphDefinition('btn_d', GlyphCategory.buttons, 'btn_d.svg', 'D'),
    GlyphDefinition('btn_p', GlyphCategory.buttons, 'btn_p.svg', 'P'),
    GlyphDefinition('btn_k', GlyphCategory.buttons, 'btn_k.svg', 'K'),
    GlyphDefinition('btn_lp', GlyphCategory.buttons, 'btn_lp.svg', 'LP'),
    GlyphDefinition('btn_mp', GlyphCategory.buttons, 'btn_mp.svg', 'MP'),
    GlyphDefinition('btn_hp', GlyphCategory.buttons, 'btn_hp.svg', 'HP'),
    GlyphDefinition('btn_lk', GlyphCategory.buttons, 'btn_lk.svg', 'LK'),
    GlyphDefinition('btn_mk', GlyphCategory.buttons, 'btn_mk.svg', 'MK'),
    GlyphDefinition('btn_hk', GlyphCategory.buttons, 'btn_hk.svg', 'HK'),
    GlyphDefinition('btn_2p', GlyphCategory.buttons, 'btn_2p.svg', '2P'),
    GlyphDefinition('btn_2k', GlyphCategory.buttons, 'btn_2k.svg', '2K'),
    GlyphDefinition('btn_3p', GlyphCategory.buttons, 'btn_3p.svg', '3P'),
    GlyphDefinition('btn_3k', GlyphCategory.buttons, 'btn_3k.svg', '3K'),
  ];
}
