import 'dart:convert';

class GlyphSpec {
  final int canvasSize;
  final double padding;
  final double strokeWidth;
  final String lineCap;
  final String lineJoin;
  final double scale;
  final double arrowHeadLength;
  final double arrowHeadWidth;
  final double curveRadius;
  final double curveExtent;
  final double repeatSeparation;
  final double neutralRadius;
  final double buttonRadius;
  final double buttonBorderWidth;
  final double labelSize;
  final double holdSize;
  final double chargeSpacing;

  const GlyphSpec({
    this.canvasSize = 64,
    this.padding = 6,
    this.strokeWidth = 5,
    this.lineCap = 'round',
    this.lineJoin = 'round',
    this.scale = 1,
    this.arrowHeadLength = 9,
    this.arrowHeadWidth = 8,
    this.curveRadius = 20,
    this.curveExtent = 1.57,
    this.repeatSeparation = 7,
    this.neutralRadius = 3,
    this.buttonRadius = 21,
    this.buttonBorderWidth = 4,
    this.labelSize = 18,
    this.holdSize = 13,
    this.chargeSpacing = 8,
  });

  static const defaults = GlyphSpec();

  GlyphSpec copyWith({
    double? padding,
    double? strokeWidth,
    double? scale,
    double? arrowHeadLength,
    double? arrowHeadWidth,
    double? curveRadius,
    double? curveExtent,
    double? repeatSeparation,
    double? neutralRadius,
    double? buttonRadius,
    double? buttonBorderWidth,
    double? labelSize,
    double? holdSize,
    double? chargeSpacing,
  }) => GlyphSpec(
    padding: padding ?? this.padding,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    scale: scale ?? this.scale,
    arrowHeadLength: arrowHeadLength ?? this.arrowHeadLength,
    arrowHeadWidth: arrowHeadWidth ?? this.arrowHeadWidth,
    curveRadius: curveRadius ?? this.curveRadius,
    curveExtent: curveExtent ?? this.curveExtent,
    repeatSeparation: repeatSeparation ?? this.repeatSeparation,
    neutralRadius: neutralRadius ?? this.neutralRadius,
    buttonRadius: buttonRadius ?? this.buttonRadius,
    buttonBorderWidth: buttonBorderWidth ?? this.buttonBorderWidth,
    labelSize: labelSize ?? this.labelSize,
    holdSize: holdSize ?? this.holdSize,
    chargeSpacing: chargeSpacing ?? this.chargeSpacing,
  );

  Map<String, Object> toJson() => {
    'version': 1,
    'canvas': {'size': canvasSize, 'padding': padding, 'scale': scale},
    'stroke': {'width': strokeWidth, 'lineCap': lineCap, 'lineJoin': lineJoin},
    'arrow': {'headLength': arrowHeadLength, 'headWidth': arrowHeadWidth},
    'motion': {
      'curveRadius': curveRadius,
      'curveExtent': curveExtent,
      'repeatSeparation': repeatSeparation,
      'neutralRadius': neutralRadius,
    },
    'button': {
      'radius': buttonRadius,
      'borderWidth': buttonBorderWidth,
      'labelSize': labelSize,
    },
    'charge': {'holdSize': holdSize, 'spacing': chargeSpacing},
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory GlyphSpec.decode(String source) => GlyphSpec.fromJson(
    Map<String, dynamic>.from(const JsonDecoder().convert(source) as Map),
  );

  factory GlyphSpec.fromJson(Map<String, dynamic> json) {
    final canvas = json['canvas'] as Map<String, dynamic>? ?? {};
    final stroke = json['stroke'] as Map<String, dynamic>? ?? {};
    final arrow = json['arrow'] as Map<String, dynamic>? ?? {};
    final motion = json['motion'] as Map<String, dynamic>? ?? {};
    final button = json['button'] as Map<String, dynamic>? ?? {};
    final charge = json['charge'] as Map<String, dynamic>? ?? {};
    double number(Map<String, dynamic> map, String key, double fallback) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    return GlyphSpec(
      padding: number(canvas, 'padding', defaults.padding),
      scale: number(canvas, 'scale', defaults.scale),
      strokeWidth: number(stroke, 'width', defaults.strokeWidth),
      arrowHeadLength: number(arrow, 'headLength', defaults.arrowHeadLength),
      arrowHeadWidth: number(arrow, 'headWidth', defaults.arrowHeadWidth),
      curveRadius: number(motion, 'curveRadius', defaults.curveRadius),
      curveExtent: number(motion, 'curveExtent', defaults.curveExtent),
      repeatSeparation: number(
        motion,
        'repeatSeparation',
        defaults.repeatSeparation,
      ),
      neutralRadius: number(motion, 'neutralRadius', defaults.neutralRadius),
      buttonRadius: number(button, 'radius', defaults.buttonRadius),
      buttonBorderWidth: number(
        button,
        'borderWidth',
        defaults.buttonBorderWidth,
      ),
      labelSize: number(button, 'labelSize', defaults.labelSize),
      holdSize: number(charge, 'holdSize', defaults.holdSize),
      chargeSpacing: number(charge, 'spacing', defaults.chargeSpacing),
      lineCap: stroke['lineCap'] as String? ?? defaults.lineCap,
      lineJoin: stroke['lineJoin'] as String? ?? defaults.lineJoin,
    );
  }
}
