import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../domain/glyph_registry.dart';
import '../domain/glyph_spec.dart';
import '../generation/svg_glyph_generator.dart';
import '../publishing/glyph_publisher.dart';

const kGlyphStudioRoute = '/debug/glyph-studio';

List<GoRoute> buildGlyphStudioRoutes() {
  if (!kDebugMode) return const [];
  return <GoRoute>[
    GoRoute(
      path: kGlyphStudioRoute,
      builder: (_, _) => const GlyphStudioScreen(),
    ),
  ];
}

enum _PreviewSurface { light, dark, neutral, accent }

class GlyphStudioScreen extends StatefulWidget {
  const GlyphStudioScreen({super.key});

  @override
  State<GlyphStudioScreen> createState() => _GlyphStudioScreenState();
}

class _GlyphStudioScreenState extends State<GlyphStudioScreen> {
  GlyphSpec _spec = GlyphSpec.defaults;
  GlyphSpec _savedSpec = GlyphSpec.defaults;
  _PreviewSurface _surface = _PreviewSurface.dark;
  String? _status;

  Map<String, String> get _svgs => SvgGlyphGenerator(_spec).generateAll();

  @override
  void initState() {
    super.initState();
    _loadSavedSpec();
  }

  Future<void> _loadSavedSpec() async {
    final json = await rootBundle.loadString(
      'tool/glyph_studio/glyph_spec.json',
    );
    final savedSpec = GlyphSpec.decode(json);
    if (!mounted) return;
    setState(() {
      _spec = savedSpec;
      _savedSpec = savedSpec;
    });
  }

  void _update(GlyphSpec next) => setState(() {
    _spec = next;
    _status = 'Preview updated';
  });

  Future<void> _publish({required bool specOnly}) async {
    final generated = _svgs;
    final errors = GeneratedGlyphSet(generated).validate();
    if (errors.isNotEmpty) {
      setState(() => _status = errors.join(', '));
      return;
    }
    final result = await publishGlyphSet(
      GlyphPublishInput(
        specJson: _spec.encode(),
        svgs: generated,
        publishAssets: !specOnly,
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result.persisted) _savedSpec = _spec;
      _status = result.persisted
          ? '${specOnly ? 'Design spec saved' : 'Published SVG set'}\n'
                '${result.message}'
          : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final background = switch (_surface) {
      _PreviewSurface.light => Colors.white,
      _PreviewSurface.dark => const Color(0xFF11131A),
      _PreviewSurface.neutral => const Color(0xFF747982),
      _PreviewSurface.accent => const Color(0xFF24183F),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glyph Studio'),
        actions: [
          IconButton(
            tooltip: 'Reset preview',
            onPressed: () => _update(GlyphSpec.defaults),
            icon: const Icon(Icons.restart_alt),
          ),
          FilledButton.icon(
            onPressed: () => _publish(specOnly: true),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save spec'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _publish(specOnly: false),
            icon: const Icon(Icons.publish),
            label: const Text('Publish set'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_status != null)
                _StatusBanner(message: _status!, saved: _savedSpec == _spec),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 300, child: _parameterPanel()),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: background,
                      child: _sizePreview(background: background),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('Glyph gallery'),
              for (final category in GlyphCategory.values) ...[
                _categoryTitle(category),
                _Gallery(
                  category: category,
                  svgs: _svgs,
                  labelSize: _spec.labelSize,
                ),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Command composition preview'),
              _CompositionPreview(svgs: _svgs, labelSize: _spec.labelSize),
              const SizedBox(height: 16),
              SegmentedButton<_PreviewSurface>(
                segments: const [
                  ButtonSegment(
                    value: _PreviewSurface.light,
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: _PreviewSurface.dark,
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: _PreviewSurface.neutral,
                    label: Text('Neutral'),
                  ),
                  ButtonSegment(
                    value: _PreviewSurface.accent,
                    label: Text('Accent'),
                  ),
                ],
                selected: {_surface},
                onSelectionChanged: (value) =>
                    setState(() => _surface = value.first),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
  );

  Widget _categoryTitle(GlyphCategory category) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(
      category.name.toUpperCase(),
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(1)),
        ],
      ),
      Slider(value: value, min: min, max: max, onChanged: onChanged),
    ],
  );

  Widget _parameterPanel() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Design parameters',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _slider(
            'Stroke width',
            _spec.strokeWidth,
            1,
            9,
            (v) => _update(_spec.copyWith(strokeWidth: v)),
          ),
          _slider(
            'Padding',
            _spec.padding,
            2,
            12,
            (v) => _update(_spec.copyWith(padding: v)),
          ),
          _slider(
            'Overall scale',
            _spec.scale,
            .7,
            1.3,
            (v) => _update(_spec.copyWith(scale: v)),
          ),
          _slider(
            'Arrow head length',
            _spec.arrowHeadLength,
            5,
            14,
            (v) => _update(_spec.copyWith(arrowHeadLength: v)),
          ),
          _slider(
            'Arrow head width',
            _spec.arrowHeadWidth,
            4,
            12,
            (v) => _update(_spec.copyWith(arrowHeadWidth: v)),
          ),
          _slider(
            'Curve radius',
            _spec.curveRadius,
            12,
            26,
            (v) => _update(_spec.copyWith(curveRadius: v)),
          ),
          _slider(
            'Repeat separation',
            _spec.repeatSeparation,
            3,
            12,
            (v) => _update(_spec.copyWith(repeatSeparation: v)),
          ),
          _slider(
            'Curve extent',
            _spec.curveExtent,
            .8,
            2.4,
            (v) => _update(_spec.copyWith(curveExtent: v)),
          ),
          _slider(
            'Neutral point radius',
            _spec.neutralRadius,
            1.5,
            5,
            (v) => _update(_spec.copyWith(neutralRadius: v)),
          ),
          _slider(
            'Button radius',
            _spec.buttonRadius,
            15,
            26,
            (v) => _update(_spec.copyWith(buttonRadius: v)),
          ),
          _slider(
            'Button border',
            _spec.buttonBorderWidth,
            2,
            7,
            (v) => _update(_spec.copyWith(buttonBorderWidth: v)),
          ),
          _slider(
            'Charge hold size',
            _spec.holdSize,
            8,
            18,
            (v) => _update(_spec.copyWith(holdSize: v)),
          ),
          _slider(
            'Charge spacing',
            _spec.chargeSpacing,
            3,
            14,
            (v) => _update(_spec.copyWith(chargeSpacing: v)),
          ),
          _slider(
            'Label size',
            _spec.labelSize,
            10,
            24,
            (v) => _update(_spec.copyWith(labelSize: v)),
          ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => _update(_savedSpec),
            icon: const Icon(Icons.history),
            label: const Text('Restore saved spec'),
          ),
        ],
      ),
    ),
  );

  Widget _sizePreview({required Color background}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Size validation',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 22,
        runSpacing: 18,
        children: [16, 20, 24, 32, 48, 64]
            .map(
              (size) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GlyphMark(
                    svg: _svgs['motion_qcf']!,
                    size: size.toDouble(),
                    color: _surface == _PreviewSurface.light
                        ? Colors.black
                        : Colors.white,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${size}px',
                    style: TextStyle(
                      color: background == Colors.white
                          ? Colors.black54
                          : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
      Text(
        'All motions at 24px',
        style: TextStyle(
          color: background == Colors.white ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: GlyphRegistry.definitions
            .where((definition) => definition.category == GlyphCategory.motions)
            .map(
              (definition) => Tooltip(
                message: definition.id,
                child: _GlyphMark(
                  svg: _svgs[definition.id]!,
                  size: 24,
                  color: background == Colors.white
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool saved;
  const _StatusBanner({required this.message, required this.saved});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    color: saved ? AppColors.buttonB.withValues(alpha: .16) : AppColors.surface,
    child: Text(
      message,
      style: TextStyle(
        color: saved ? AppColors.buttonB : AppColors.textSecondary,
      ),
    ),
  );
}

class _Gallery extends StatelessWidget {
  final GlyphCategory category;
  final Map<String, String> svgs;
  final double labelSize;
  const _Gallery({
    required this.category,
    required this.svgs,
    required this.labelSize,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: GlyphRegistry.definitions
        .where((d) => d.category == category)
        .map(
          (definition) => Card(
            child: SizedBox(
              width: 118,
              height: 104,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GlyphMark(
                    svg: svgs[definition.id]!,
                    size: 42,
                    color: AppColors.textPrimary,
                    label: definition.label,
                    button: category == GlyphCategory.buttons,
                    labelSize: labelSize,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    definition.id,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    definition.filename,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _CompositionPreview extends StatelessWidget {
  final Map<String, String> svgs;
  final double labelSize;
  const _CompositionPreview({required this.svgs, required this.labelSize});
  static const commands = <List<String>>[
    ['motion_qcf', 'op_plus', 'btn_a'],
    ['motion_qcb', 'op_plus', 'btn_b'],
    ['motion_dpf', 'op_plus', 'btn_hp'],
    ['motion_hcf', 'op_plus', 'btn_p'],
    ['motion_charge_bf', 'op_plus', 'btn_p'],
    ['motion_charge_du', 'op_plus', 'btn_k'],
    ['motion_dqcf', 'op_plus', 'btn_p'],
    ['motion_360', 'op_plus', 'btn_p'],
  ];
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: commands
        .map(
          (command) => Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: command.map((id) {
                  final definition = GlyphRegistry.definitions.firstWhere(
                    (d) => d.id == id,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _GlyphMark(
                      svg: svgs[id]!,
                      size: 26,
                      color: AppColors.textPrimary,
                      label: definition.label,
                      button: definition.category == GlyphCategory.buttons,
                      labelSize: labelSize,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _GlyphMark extends StatelessWidget {
  final String svg;
  final double size;
  final Color color;
  final String? label;
  final bool button;
  final double? labelSize;
  const _GlyphMark({
    required this.svg,
    required this.size,
    required this.color,
    this.label,
    this.button = false,
    this.labelSize,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.string(
          svg,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        if (button && label != null)
          Text(
            label!,
            style: TextStyle(
              color: color,
              fontSize: labelSize ?? size * .28,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    ),
  );
}
