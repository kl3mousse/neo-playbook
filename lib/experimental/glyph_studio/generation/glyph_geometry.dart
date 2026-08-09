import 'dart:math' as math;

import '../domain/glyph_spec.dart';

enum SemanticDirection { u, uf, f, df, d, db, b, ub }

extension SemanticDirectionGeometry on SemanticDirection {
  SvgVector get vector => switch (this) {
    SemanticDirection.u => const SvgVector(0, -1),
    SemanticDirection.uf => const SvgVector(1, -1).normalized,
    SemanticDirection.f => const SvgVector(1, 0),
    SemanticDirection.df => const SvgVector(1, 1).normalized,
    SemanticDirection.d => const SvgVector(0, 1),
    SemanticDirection.db => const SvgVector(-1, 1).normalized,
    SemanticDirection.b => const SvgVector(-1, 0),
    SemanticDirection.ub => const SvgVector(-1, -1).normalized,
  };

  SemanticDirection get horizontalMirror => switch (this) {
    SemanticDirection.u => SemanticDirection.u,
    SemanticDirection.uf => SemanticDirection.ub,
    SemanticDirection.f => SemanticDirection.b,
    SemanticDirection.df => SemanticDirection.db,
    SemanticDirection.d => SemanticDirection.d,
    SemanticDirection.db => SemanticDirection.df,
    SemanticDirection.b => SemanticDirection.f,
    SemanticDirection.ub => SemanticDirection.uf,
  };
}

class SvgVector {
  final double dx;
  final double dy;
  const SvgVector(this.dx, this.dy);

  SvgVector get normalized {
    final length = math.sqrt(dx * dx + dy * dy);
    return SvgVector(dx / length, dy / length);
  }

  SvgVector get horizontalMirror => SvgVector(-dx, dy);
}

class SvgPoint {
  final double x;
  final double y;
  const SvgPoint(this.x, this.y);

  SvgPoint horizontalMirror(double canvasSize) => SvgPoint(canvasSize - x, y);
  SvgPoint translate(double dx, double dy) => SvgPoint(x + dx, y + dy);
}

sealed class MotionCommand {
  const MotionCommand();
  SvgPoint get end;
  SvgVector finalTangentFrom(SvgPoint previous);
  MotionCommand horizontalMirror(double canvasSize);
  MotionCommand translate(double dx, double dy);
}

class MotionLine extends MotionCommand {
  @override
  final SvgPoint end;
  const MotionLine(this.end);

  @override
  SvgVector finalTangentFrom(SvgPoint previous) =>
      SvgVector(end.x - previous.x, end.y - previous.y).normalized;

  @override
  MotionLine horizontalMirror(double canvasSize) =>
      MotionLine(end.horizontalMirror(canvasSize));

  @override
  MotionLine translate(double dx, double dy) =>
      MotionLine(end.translate(dx, dy));
}

class MotionCubic extends MotionCommand {
  final SvgPoint control1;
  final SvgPoint control2;
  @override
  final SvgPoint end;
  const MotionCubic(this.control1, this.control2, this.end);

  @override
  SvgVector finalTangentFrom(SvgPoint previous) =>
      SvgVector(end.x - control2.x, end.y - control2.y).normalized;

  @override
  MotionCubic horizontalMirror(double canvasSize) => MotionCubic(
    control1.horizontalMirror(canvasSize),
    control2.horizontalMirror(canvasSize),
    end.horizontalMirror(canvasSize),
  );

  @override
  MotionCubic translate(double dx, double dy) => MotionCubic(
    control1.translate(dx, dy),
    control2.translate(dx, dy),
    end.translate(dx, dy),
  );
}

class MotionPathGeometry {
  final SvgPoint start;
  final List<MotionCommand> commands;
  const MotionPathGeometry(this.start, this.commands);

  SvgPoint get end => commands.last.end;
  SvgVector get initialTangent => switch (commands.first) {
    MotionLine(:final end) => SvgVector(
      end.x - start.x,
      end.y - start.y,
    ).normalized,
    MotionCubic(:final control1) => SvgVector(
      control1.x - start.x,
      control1.y - start.y,
    ).normalized,
  };
  SvgVector get finalTangent {
    final previous = commands.length == 1
        ? start
        : commands[commands.length - 2].end;
    return commands.last.finalTangentFrom(previous);
  }

  Iterable<SvgPoint> get significantPoints sync* {
    yield start;
    for (final command in commands) {
      if (command is MotionCubic) {
        yield command.control1;
        yield command.control2;
      }
      yield command.end;
    }
  }

  MotionPathGeometry horizontalMirror(double canvasSize) => MotionPathGeometry(
    start.horizontalMirror(canvasSize),
    commands.map((command) => command.horizontalMirror(canvasSize)).toList(),
  );

  MotionPathGeometry translate(double dx, double dy) => MotionPathGeometry(
    start.translate(dx, dy),
    commands.map((command) => command.translate(dx, dy)).toList(),
  );
}

class MotionGeometry {
  final List<MotionPathGeometry> paths;
  final List<SemanticDirection> sequence;
  final SemanticDirection finalDirection;
  final SemanticDirection? arrowDirection;
  final SvgPoint neutralPoint;
  final SemanticDirection? holdDirection;
  final SvgPoint? holdPoint;

  const MotionGeometry({
    required this.paths,
    required this.sequence,
    required this.finalDirection,
    required this.neutralPoint,
    this.arrowDirection,
    this.holdDirection,
    this.holdPoint,
  });

  MotionGeometry horizontalMirror(double canvasSize) => MotionGeometry(
    paths: paths.map((path) => path.horizontalMirror(canvasSize)).toList(),
    sequence: sequence.map((direction) => direction.horizontalMirror).toList(),
    finalDirection: finalDirection.horizontalMirror,
    arrowDirection: arrowDirection?.horizontalMirror,
    neutralPoint: neutralPoint.horizontalMirror(canvasSize),
    holdDirection: holdDirection?.horizontalMirror,
    holdPoint: holdPoint?.horizontalMirror(canvasSize),
  );
}

class MotionGeometryBuilder {
  final GlyphSpec spec;
  const MotionGeometryBuilder(this.spec);

  double get _center => spec.canvasSize / 2;
  double get _radius => _center - spec.padding - 9;
  SvgPoint _point(SemanticDirection direction, [double? radius]) {
    final distance = radius ?? _radius;
    final (dx, dy) = switch (direction) {
      SemanticDirection.u => (0.0, -1.0),
      SemanticDirection.uf => (1.0, -1.0),
      SemanticDirection.f => (1.0, 0.0),
      SemanticDirection.df => (1.0, 1.0),
      SemanticDirection.d => (0.0, 1.0),
      SemanticDirection.db => (-1.0, 1.0),
      SemanticDirection.b => (-1.0, 0.0),
      SemanticDirection.ub => (-1.0, -1.0),
    };
    return SvgPoint(_center + dx * distance, _center + dy * distance);
  }

  SvgPoint get _centerPoint => SvgPoint(_center, _center);

  MotionGeometry build(String id) => switch (id) {
    'motion_qcf' => _qcf(),
    'motion_qcb' => _qcf().horizontalMirror(spec.canvasSize.toDouble()),
    'motion_hcf' => _hcf(),
    'motion_hcb' => _hcf().horizontalMirror(spec.canvasSize.toDouble()),
    'motion_dpf' => _dpf(),
    'motion_dpb' => _dpf().horizontalMirror(spec.canvasSize.toDouble()),
    'motion_rdpf' => _rdpf(),
    'motion_rdpb' => _rdpf().horizontalMirror(spec.canvasSize.toDouble()),
    'motion_dqcf' => _dqcf(),
    'motion_dqcb' => _dqcf().horizontalMirror(spec.canvasSize.toDouble()),
    'motion_charge_bf' => _chargeBf(),
    'motion_charge_du' => _chargeDu(),
    'motion_360' => _rotation(1),
    'motion_720' => _rotation(2),
    'motion_pretzel_f' => _pretzelForward(),
    'motion_pretzel_b' => _pretzelForward().horizontalMirror(
      spec.canvasSize.toDouble(),
    ),
    _ => throw ArgumentError('Unknown motion id: $id'),
  };

  MotionGeometry _qcf() {
    return MotionGeometry(
      paths: [_quarterForwardPath(_radius)],
      sequence: const [
        SemanticDirection.d,
        SemanticDirection.df,
        SemanticDirection.f,
      ],
      finalDirection: SemanticDirection.f,
      neutralPoint: _centerPoint,
    );
  }

  MotionGeometry _hcf() {
    final back = _point(SemanticDirection.b);
    final down = _point(SemanticDirection.d);
    final forward = _point(SemanticDirection.f);
    final tangent = _radius * .55228475 * (spec.curveExtent / 1.57);
    return MotionGeometry(
      paths: [
        MotionPathGeometry(back, [
          MotionCubic(
            SvgPoint(back.x, back.y + tangent),
            SvgPoint(down.x - tangent, down.y),
            down,
          ),
          MotionCubic(
            SvgPoint(down.x + tangent, down.y),
            SvgPoint(forward.x, forward.y + tangent),
            forward,
          ),
        ]),
      ],
      sequence: const [
        SemanticDirection.b,
        SemanticDirection.db,
        SemanticDirection.d,
        SemanticDirection.df,
        SemanticDirection.f,
      ],
      finalDirection: SemanticDirection.f,
      neutralPoint: _centerPoint,
    );
  }

  MotionGeometry _dpf() => MotionGeometry(
    paths: [
      MotionPathGeometry(_centerPoint, [
        MotionLine(_point(SemanticDirection.f)),
        MotionLine(_point(SemanticDirection.d)),
        MotionLine(_point(SemanticDirection.df)),
      ]),
    ],
    sequence: const [
      SemanticDirection.f,
      SemanticDirection.d,
      SemanticDirection.df,
    ],
    finalDirection: SemanticDirection.df,
    neutralPoint: _centerPoint,
  );

  MotionGeometry _rdpf() => MotionGeometry(
    paths: [
      MotionPathGeometry(_centerPoint, [
        MotionLine(_point(SemanticDirection.f)),
        MotionLine(_point(SemanticDirection.df)),
        MotionLine(_point(SemanticDirection.d)),
      ]),
    ],
    sequence: const [
      SemanticDirection.f,
      SemanticDirection.df,
      SemanticDirection.d,
    ],
    finalDirection: SemanticDirection.d,
    neutralPoint: _centerPoint,
  );

  MotionGeometry _pretzelForward() => MotionGeometry(
    paths: [
      MotionPathGeometry(_point(SemanticDirection.db), [
        MotionLine(_point(SemanticDirection.f)),
        MotionLine(_point(SemanticDirection.df)),
        MotionLine(_point(SemanticDirection.d)),
        MotionLine(_point(SemanticDirection.db)),
        MotionLine(_point(SemanticDirection.b)),
        MotionLine(_point(SemanticDirection.df)),
      ]),
    ],
    sequence: const [
      SemanticDirection.db,
      SemanticDirection.f,
      SemanticDirection.df,
      SemanticDirection.d,
      SemanticDirection.db,
      SemanticDirection.b,
      SemanticDirection.df,
    ],
    finalDirection: SemanticDirection.df,
    neutralPoint: _centerPoint,
  );

  MotionGeometry _dqcf() {
    final innerRadius = math.max(7.0, _radius - spec.repeatSeparation);
    return MotionGeometry(
      paths: [_quarterForwardPath(innerRadius), _quarterForwardPath(_radius)],
      sequence: const [
        SemanticDirection.d,
        SemanticDirection.df,
        SemanticDirection.f,
        SemanticDirection.d,
        SemanticDirection.df,
        SemanticDirection.f,
      ],
      finalDirection: SemanticDirection.f,
      neutralPoint: _centerPoint,
    );
  }

  MotionPathGeometry _quarterForwardPath(double radius) {
    final down = _point(SemanticDirection.d, radius);
    final forward = _point(SemanticDirection.f, radius);
    final tangent = radius * .55228475 * (spec.curveExtent / 1.57);
    return MotionPathGeometry(down, [
      MotionCubic(
        SvgPoint(down.x + tangent, down.y),
        SvgPoint(forward.x, forward.y + tangent),
        forward,
      ),
    ]);
  }

  MotionGeometry _chargeBf() {
    final back = _point(SemanticDirection.b);
    final forward = _point(SemanticDirection.f);
    return MotionGeometry(
      paths: [
        MotionPathGeometry(back, [MotionLine(forward)]),
      ],
      sequence: const [SemanticDirection.b, SemanticDirection.f],
      finalDirection: SemanticDirection.f,
      neutralPoint: _centerPoint,
      holdDirection: SemanticDirection.b,
      holdPoint: back,
    );
  }

  MotionGeometry _chargeDu() {
    final down = _point(SemanticDirection.d);
    final up = _point(SemanticDirection.u);
    return MotionGeometry(
      paths: [
        MotionPathGeometry(down, [MotionLine(up)]),
      ],
      sequence: const [SemanticDirection.d, SemanticDirection.u],
      finalDirection: SemanticDirection.u,
      neutralPoint: _centerPoint,
      holdDirection: SemanticDirection.d,
      holdPoint: down,
    );
  }

  MotionGeometry _rotation(int loops) {
    final paths = <MotionPathGeometry>[];
    for (var index = 0; index < loops; index++) {
      final radius =
          spec.curveRadius - (loops - 1 - index) * spec.repeatSeparation;
      final center = _centerPoint;
      final k = radius * .55228475;
      final right = SvgPoint(center.x + radius, center.y);
      paths.add(
        MotionPathGeometry(right, [
          MotionCubic(
            SvgPoint(center.x + radius, center.y + k),
            SvgPoint(center.x + k, center.y + radius),
            SvgPoint(center.x, center.y + radius),
          ),
          MotionCubic(
            SvgPoint(center.x - k, center.y + radius),
            SvgPoint(center.x - radius, center.y + k),
            SvgPoint(center.x - radius, center.y),
          ),
          MotionCubic(
            SvgPoint(center.x - radius, center.y - k),
            SvgPoint(center.x - k, center.y - radius),
            SvgPoint(center.x, center.y - radius),
          ),
          MotionCubic(
            SvgPoint(center.x + k, center.y - radius),
            SvgPoint(center.x + radius, center.y - k),
            right,
          ),
        ]),
      );
    }
    return MotionGeometry(
      paths: paths,
      sequence: const [],
      finalDirection: SemanticDirection.f,
      neutralPoint: _centerPoint,
    );
  }
}
