import 'package:flutter_test/flutter_test.dart';

import 'package:combofox/experimental/glyph_studio/glyph_studio.dart';

void main() {
  test('generates the complete stable inventory', () {
    final generated = SvgGlyphGenerator().generateAll();
    final ids = GlyphRegistry.definitions.map((definition) => definition.id);

    expect(ids.toSet(), hasLength(ids.length));
    expect(generated.keys.toSet(), ids.toSet());
    expect(generated.values.every((svg) => svg.endsWith('\n')), isTrue);
    expect(GeneratedGlyphSet(generated).validate(), isEmpty);
  });

  test('same spec produces byte-identical output', () {
    final spec = GlyphSpec.defaults.copyWith(curveRadius: 18, scale: 0.9);
    expect(
      SvgGlyphGenerator(spec).generateAll(),
      SvgGlyphGenerator(spec).generateAll(),
    );
  });

  test('canonical directions use SVG screen coordinates', () {
    expect(SemanticDirection.u.vector.dy, -1);
    expect(SemanticDirection.d.vector.dy, 1);
    expect(SemanticDirection.b.vector.dx, -1);
    expect(SemanticDirection.f.vector.dx, 1);
    expect(SemanticDirection.df.vector.dx, greaterThan(0));
    expect(SemanticDirection.df.vector.dy, greaterThan(0));
    expect(SemanticDirection.ub.vector.dx, lessThan(0));
    expect(SemanticDirection.ub.vector.dy, lessThan(0));
  });

  test('quarter circles start down and finish toward their side', () {
    final generator = SvgGlyphGenerator();
    final qcf = generator.geometryForMotion('motion_qcf');
    final qcb = generator.geometryForMotion('motion_qcb');

    expect(qcf.sequence, [
      SemanticDirection.d,
      SemanticDirection.df,
      SemanticDirection.f,
    ]);
    expect(qcf.paths.single.start.y, greaterThan(32));
    expect(qcf.paths.single.end.x, greaterThan(32));
    expect(qcf.paths.single.initialTangent.dx, greaterThan(.99));
    expect(qcf.paths.single.initialTangent.dy.abs(), lessThan(.01));
    expect(qcf.paths.single.finalTangent.dx.abs(), lessThan(.01));
    expect(qcf.paths.single.finalTangent.dy, lessThan(-.99));
    expect(qcf.finalDirection, SemanticDirection.f);
    expect(qcf.arrowDirection, isNull);
    final qcfCurve = qcf.paths.single.commands.first as MotionCubic;
    expect(qcfCurve.control1.x, greaterThan(qcf.paths.single.start.x));
    expect(qcfCurve.control1.y, qcf.paths.single.start.y);
    expect(qcfCurve.control2.x, greaterThan(qcf.neutralPoint.x));
    expect(qcfCurve.control2.y, greaterThan(qcf.neutralPoint.y));
    expect(qcf.paths.single.commands, hasLength(1));

    expect(qcb.sequence, [
      SemanticDirection.d,
      SemanticDirection.db,
      SemanticDirection.b,
    ]);
    expect(qcb.paths.single.start.y, greaterThan(32));
    expect(qcb.paths.single.end.x, lessThan(32));
    expect(qcb.paths.single.initialTangent.dx, lessThan(-.99));
    expect(qcb.paths.single.finalTangent.dx.abs(), lessThan(.01));
    expect(qcb.paths.single.finalTangent.dy, lessThan(-.99));
    expect(qcb.finalDirection, SemanticDirection.b);
    expect(qcb.arrowDirection, isNull);
  });

  test('half circles cross the lower half and finish upward', () {
    final generator = SvgGlyphGenerator();
    final hcf = generator.geometryForMotion('motion_hcf');
    final hcb = generator.geometryForMotion('motion_hcb');

    expect(hcf.paths.single.start.x, lessThan(32));
    expect(hcf.paths.single.end.x, greaterThan(32));
    expect(
      hcf.paths.single.significantPoints.any((point) => point.y > 45),
      isTrue,
    );
    expect(hcf.paths.single.finalTangent.dx.abs(), lessThan(.01));
    expect(hcf.paths.single.finalTangent.dy, lessThan(-.99));
    expect(hcf.arrowDirection, isNull);

    expect(hcb.paths.single.start.x, greaterThan(32));
    expect(hcb.paths.single.end.x, lessThan(32));
    expect(
      hcb.paths.single.significantPoints.any((point) => point.y > 45),
      isTrue,
    );
    expect(hcb.paths.single.finalTangent.dx.abs(), lessThan(.01));
    expect(hcb.paths.single.finalTangent.dy, lessThan(-.99));
    expect(hcb.arrowDirection, isNull);
  });

  test('dragon punches preserve F-D-DF progression and mirror', () {
    final generator = SvgGlyphGenerator();
    final dpf = generator.geometryForMotion('motion_dpf');
    final dpb = generator.geometryForMotion('motion_dpb');

    expect(dpf.sequence, [
      SemanticDirection.f,
      SemanticDirection.d,
      SemanticDirection.df,
    ]);
    expect(dpb.sequence, [
      SemanticDirection.b,
      SemanticDirection.d,
      SemanticDirection.db,
    ]);
    expect(dpf.paths.single.start.x, dpf.neutralPoint.x);
    expect(dpf.paths.single.start.y, dpf.neutralPoint.y);
    expect(dpf.paths.single.commands, hasLength(3));
    final dpfPoints = dpf.paths.single.significantPoints.toList();
    expect(dpfPoints[1].x, greaterThan(32));
    expect(dpfPoints[1].y, 32);
    expect(dpfPoints[2].x, 32);
    expect(dpfPoints[2].y, greaterThan(32));
    expect(dpfPoints[3].x, greaterThan(32));
    expect(dpfPoints[3].y, greaterThan(32));
    _expectHorizontalMirror(dpf, dpb);
  });

  test('reverse dragon punches preserve F-DF-D progression and mirror', () {
    final generator = SvgGlyphGenerator();
    final forward = generator.geometryForMotion('motion_rdpf');
    final back = generator.geometryForMotion('motion_rdpb');

    expect(forward.sequence, [
      SemanticDirection.f,
      SemanticDirection.df,
      SemanticDirection.d,
    ]);
    expect(forward.paths.single.start.x, forward.neutralPoint.x);
    expect(forward.paths.single.start.y, forward.neutralPoint.y);
    expect(forward.paths.single.commands, hasLength(3));
    expect(forward.finalDirection, SemanticDirection.d);
    _expectHorizontalMirror(forward, back);
  });

  test('pretzels preserve their seven-direction sequence and mirror', () {
    final generator = SvgGlyphGenerator();
    final forward = generator.geometryForMotion('motion_pretzel_f');
    final back = generator.geometryForMotion('motion_pretzel_b');

    expect(forward.sequence, [
      SemanticDirection.db,
      SemanticDirection.f,
      SemanticDirection.df,
      SemanticDirection.d,
      SemanticDirection.db,
      SemanticDirection.b,
      SemanticDirection.df,
    ]);
    expect(forward.paths.single.commands, hasLength(6));
    expect(forward.finalDirection, SemanticDirection.df);
    _expectHorizontalMirror(forward, back);
  });

  test('double quarter circles finish forward and back', () {
    final generator = SvgGlyphGenerator();
    final dqcf = generator.geometryForMotion('motion_dqcf');
    final dqcb = generator.geometryForMotion('motion_dqcb');

    expect(dqcf.sequence, [
      SemanticDirection.d,
      SemanticDirection.df,
      SemanticDirection.f,
      SemanticDirection.d,
      SemanticDirection.df,
      SemanticDirection.f,
    ]);
    expect(dqcf.finalDirection, SemanticDirection.f);
    expect(dqcf.paths.last.finalTangent.dx.abs(), lessThan(.01));
    expect(dqcf.paths.last.finalTangent.dy, lessThan(-.99));
    expect(dqcb.finalDirection, SemanticDirection.b);
    expect(dqcb.paths.last.finalTangent.dx.abs(), lessThan(.01));
    expect(dqcb.paths.last.finalTangent.dy, lessThan(-.99));
    _expectHorizontalMirror(dqcf, dqcb);
  });

  test('charge glyphs put hold and release on canonical sides', () {
    final generator = SvgGlyphGenerator();
    final backForward = generator.geometryForMotion('motion_charge_bf');
    final downUp = generator.geometryForMotion('motion_charge_du');

    expect(backForward.holdDirection, SemanticDirection.b);
    expect(backForward.holdPoint!.x, lessThan(32));
    expect(backForward.finalDirection, SemanticDirection.f);
    expect(backForward.paths.single.finalTangent.dx, greaterThan(.99));

    expect(downUp.holdDirection, SemanticDirection.d);
    expect(downUp.holdPoint!.y, greaterThan(32));
    expect(downUp.finalDirection, SemanticDirection.u);
    expect(downUp.paths.single.finalTangent.dy, lessThan(-.99));
  });

  test('all intended opposite motions are exact horizontal mirrors', () {
    final generator = SvgGlyphGenerator();
    for (final pair in const [
      ('motion_qcf', 'motion_qcb'),
      ('motion_hcf', 'motion_hcb'),
      ('motion_dpf', 'motion_dpb'),
      ('motion_rdpf', 'motion_rdpb'),
      ('motion_dqcf', 'motion_dqcb'),
      ('motion_pretzel_f', 'motion_pretzel_b'),
    ]) {
      _expectHorizontalMirror(
        generator.geometryForMotion(pair.$1),
        generator.geometryForMotion(pair.$2),
      );
    }
  });

  test('360 and 720 contain one and two complete rotation paths', () {
    final generator = SvgGlyphGenerator();
    expect(generator.geometryForMotion('motion_360').paths, hasLength(1));
    expect(generator.geometryForMotion('motion_720').paths, hasLength(2));
    expect(
      generator.geometryForMotion('motion_360').paths.single.commands,
      hasLength(4),
    );
  });

  test('motion SVGs include the shared joystick neutral marker', () {
    final generator = SvgGlyphGenerator();
    final qcf = generator.geometryForMotion('motion_qcf');
    expect(qcf.neutralPoint.x, 32);
    expect(qcf.neutralPoint.y, 32);
    expect(generator.generate('motion_qcf'), contains('data-role="neutral"'));
  });

  test('all generated assets are SVG without external references', () {
    final generated = SvgGlyphGenerator().generateAll();
    for (final svg in generated.values) {
      expect(svg, startsWith('<svg '));
      expect(svg, contains('xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, isNot(contains('<image')));
      expect(svg, isNot(contains('url(')));
      expect(svg, isNot(contains('xlink:href')));
    }
  });
}

void _expectHorizontalMirror(MotionGeometry source, MotionGeometry mirror) {
  expect(mirror.neutralPoint.x, closeTo(64 - source.neutralPoint.x, .0001));
  expect(mirror.neutralPoint.y, closeTo(source.neutralPoint.y, .0001));
  expect(mirror.paths, hasLength(source.paths.length));
  for (var pathIndex = 0; pathIndex < source.paths.length; pathIndex++) {
    final sourcePoints = source.paths[pathIndex].significantPoints.toList();
    final mirrorPoints = mirror.paths[pathIndex].significantPoints.toList();
    expect(mirrorPoints, hasLength(sourcePoints.length));
    for (var pointIndex = 0; pointIndex < sourcePoints.length; pointIndex++) {
      expect(
        mirrorPoints[pointIndex].x,
        closeTo(64 - sourcePoints[pointIndex].x, .0001),
      );
      expect(
        mirrorPoints[pointIndex].y,
        closeTo(sourcePoints[pointIndex].y, .0001),
      );
    }
  }
  expect(mirror.finalDirection, source.finalDirection.horizontalMirror);
  expect(mirror.arrowDirection, source.arrowDirection?.horizontalMirror);
}
