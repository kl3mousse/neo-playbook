import 'dart:math' as math;

import '../domain/glyph_registry.dart';
import '../domain/glyph_spec.dart';
import 'glyph_geometry.dart';

class SvgGlyphGenerator {
  final GlyphSpec spec;
  const SvgGlyphGenerator([this.spec = GlyphSpec.defaults]);

  Map<String, String> generateAll() => {
    for (final definition in GlyphRegistry.definitions)
      definition.id: generate(definition.id),
  };

  String generate(String id) {
    final definition = GlyphRegistry.definitions.firstWhere(
      (entry) => entry.id == id,
      orElse: () => throw ArgumentError('Unknown glyph id: $id'),
    );
    final body = switch (definition.category) {
      GlyphCategory.directions => _direction(id),
      GlyphCategory.motions => _motion(id),
      GlyphCategory.buttons => _button(),
      GlyphCategory.operators => _operator(id),
    };
    final content = spec.scale == 1
        ? body
        : '<g transform="translate(32 32) scale(${_f(spec.scale)}) translate(-32 -32)">$body</g>';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${spec.canvasSize} ${spec.canvasSize}" fill="none" stroke="currentColor" stroke-width="${_f(spec.strokeWidth)}" stroke-linecap="${spec.lineCap}" stroke-linejoin="${spec.lineJoin}">$content</svg>\n';
  }

  String _direction(String id) {
    const directions = <String, SemanticDirection>{
      'dir_u': SemanticDirection.u,
      'dir_ub': SemanticDirection.ub,
      'dir_b': SemanticDirection.b,
      'dir_db': SemanticDirection.db,
      'dir_d': SemanticDirection.d,
      'dir_df': SemanticDirection.df,
      'dir_f': SemanticDirection.f,
      'dir_uf': SemanticDirection.uf,
    };
    final vector = directions[id]!.vector;
    final center = spec.canvasSize / 2;
    final x1 = center - vector.dx * 13;
    final y1 = center - vector.dy * 13;
    final x2 = center + vector.dx * 20;
    final y2 = center + vector.dy * 20;
    return '<path d="M${_f(x1)} ${_f(y1)}L${_f(x2)} ${_f(y2)}"/>${_arrow(x2, y2, vector.dx, vector.dy)}';
  }

  MotionGeometry geometryForMotion(String id) =>
      MotionGeometryBuilder(spec).build(id);

  String _motion(String id) {
    final geometry = geometryForMotion(id);
    final neutral =
        '<circle data-role="neutral" cx="${_f(geometry.neutralPoint.x)}" cy="${_f(geometry.neutralPoint.y)}" r="${_f(spec.neutralRadius)}" fill="currentColor" stroke="none"/>';
    final paths = geometry.paths.map(_serializePath).join();
    final lastPath = geometry.paths.last;
    final arrowVector =
        geometry.arrowDirection?.vector ?? lastPath.finalTangent;
    final arrow = _arrow(
      lastPath.end.x,
      lastPath.end.y,
      arrowVector.dx,
      arrowVector.dy,
    );
    final hold = geometry.holdPoint == null
        ? ''
        : _hold(geometry.holdPoint!.x, geometry.holdPoint!.y);
    return '$neutral$paths$hold$arrow';
  }

  String _serializePath(MotionPathGeometry path) {
    final buffer = StringBuffer('<path d="M${_point(path.start)}');
    for (final command in path.commands) {
      switch (command) {
        case MotionLine():
          buffer.write('L${_point(command.end)}');
        case MotionCubic():
          buffer.write(
            'C${_point(command.control1)} ${_point(command.control2)} ${_point(command.end)}',
          );
      }
    }
    return '${buffer.toString()}"/>';
  }

  String _point(SvgPoint point) => '${_f(point.x)} ${_f(point.y)}';

  String _button() =>
      '<circle cx="32" cy="32" r="${_f(spec.buttonRadius)}" stroke-width="${_f(spec.buttonBorderWidth)}"/>';

  String _operator(String id) {
    if (id == 'op_plus') return '<path d="M22 32H42M32 22V42"/>';
    if (id == 'op_then') return '<path d="M16 32H44M35 23L44 32L35 41"/>';
    if (id == 'op_hold') return '<path d="M22 18V46M32 18V46M42 18V46"/>';
    if (id == 'op_release') return '<path d="M18 32H46M37 23L46 32L37 41"/>';
    throw ArgumentError('Unknown operator id: $id');
  }

  String _hold(double x, double y) {
    final size = spec.holdSize;
    return '<circle cx="${_f(x)}" cy="${_f(y)}" r="${_f(size / 2)}" stroke-dasharray="2 3"/>';
  }

  String _arrow(double x, double y, double dx, double dy) {
    final length = math.sqrt(dx * dx + dy * dy);
    final ux = dx / length;
    final uy = dy / length;
    final nx = -uy;
    final ny = ux;
    final baseX = x - ux * spec.arrowHeadLength;
    final baseY = y - uy * spec.arrowHeadLength;
    final half = spec.arrowHeadWidth / 2;
    return '<path d="M${_f(x)} ${_f(y)}L${_f(baseX + nx * half)} ${_f(baseY + ny * half)}M${_f(x)} ${_f(y)}L${_f(baseX - nx * half)} ${_f(baseY - ny * half)}"/>';
  }

  String _f(double value) => value.toStringAsFixed(2);
}

class GeneratedGlyphSet {
  final Map<String, String> svgs;
  const GeneratedGlyphSet(this.svgs);

  List<String> validate() {
    final errors = <String>[];
    for (final definition in GlyphRegistry.definitions) {
      final svg = svgs[definition.id];
      if (svg == null) {
        errors.add('Missing ${definition.id}');
        continue;
      }
      if (!svg.startsWith('<svg ') || !svg.contains('viewBox="0 0 64 64"')) {
        errors.add('Invalid SVG header for ${definition.id}');
      }
      if (svg.contains('<image') || svg.contains('href="http')) {
        errors.add('External or raster content in ${definition.id}');
      }
    }
    return errors;
  }
}
