import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/move_list.dart';
import '../theme/app_theme.dart';
import '../widgets/input_token.dart';

// ═══════════════════════════════════════════════════════════════
// Execution Mode — Full-screen move visualization
//
// Animated step-through of the input sequence.
// ═══════════════════════════════════════════════════════════════

class ExecutionModeScreen extends StatefulWidget {
  final MoveEntry move;
  final String? moveCategoryLabel;

  const ExecutionModeScreen({
    super.key,
    required this.move,
    this.moveCategoryLabel,
  });

  @override
  State<ExecutionModeScreen> createState() => _ExecutionModeScreenState();
}

class _ExecutionModeScreenState extends State<ExecutionModeScreen>
    with TickerProviderStateMixin {
  late final List<ParsedToken> _tokens;

  int _highlightIndex = -1;
  bool _sequenceComplete = false;

  // View mode animation
  AnimationController? _stepController;
  // Success glow
  AnimationController? _glowController;

  @override
  void initState() {
    super.initState();
    _tokens = parseInputTokens(widget.move.input);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _stepController?.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  void _startViewAnimation() {
    _stepController?.dispose();
    setState(() {
      _highlightIndex = -1;
      _sequenceComplete = false;
    });

    final totalSteps = _tokens.length;
    _stepController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 * totalSteps),
    );

    _stepController!.addListener(() {
      final progress = _stepController!.value;
      final newIndex = (progress * totalSteps).floor();
      if (newIndex != _highlightIndex && newIndex < totalSteps) {
        setState(() => _highlightIndex = newIndex);
        HapticFeedback.selectionClick();
      }
    });

    _stepController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _highlightIndex = totalSteps;
          _sequenceComplete = true;
        });
        HapticFeedback.mediumImpact();
        _glowController!.forward(from: 0);
      }
    });

    _stepController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColorForExec(widget.move.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.background,
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Move name + category
              _buildMoveHeader(catColor),

              const SizedBox(height: 40),

              // Main sequence display
              AnimatedBuilder(
                animation: _glowController!,
                builder: (context, child) {
                  final glowOpacity =
                      _sequenceComplete ? (1 - _glowController!.value) * 0.6 : 0.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _sequenceComplete
                            ? AppColors.secondary.withValues(alpha: 0.5)
                            : AppColors.textSecondary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: _sequenceComplete
                          ? [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: glowOpacity),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: _buildSequenceDisplay(),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Play / replay button
              _buildViewControls(),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoveHeader(Color catColor) {
    return Column(
      children: [
        // Category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: catColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            _categoryLabel(widget.move.category),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: catColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Move name
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.move.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Doto',
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSequenceDisplay() {
    final widgets = <Widget>[];
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      final isHighlighted = i <= _highlightIndex;

      widgets.add(
        _AnimatedToken(
          token: token,
          size: InputTokenSize.large,
          isHighlighted: isHighlighted,
          isDimmed: _highlightIndex >= 0 && i > _highlightIndex,
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 12,
      children: widgets,
    );
  }

  Widget _buildViewControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _startViewAnimation,
          icon: Icon(
            _sequenceComplete ? Icons.replay : Icons.play_arrow,
            size: 20,
          ),
          label: Text(_sequenceComplete ? 'Replay' : 'Play Sequence'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryColorForExec(String category) {
    return switch (category) {
      'throw'   => AppColors.catThrow,
      'command' => AppColors.catCommand,
      'special' => AppColors.catSpecial,
      'super'   => AppColors.catDM,
      'ultra'   => AppColors.catSDM,
      'other'   => Colors.amber,
      _         => AppColors.textSecondary,
    };
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'throw'   => 'THROW',
      'command' => 'COMMAND',
      'special' => 'SPECIAL',
      'super'   => 'DM',
      'ultra'   => 'SDM',
      'other'   => 'OTHER',
      _         => 'MOVE',
    };
  }
}

// ── Animated single token ───────────────────────────────────

class _AnimatedToken extends StatelessWidget {
  final ParsedToken token;
  final InputTokenSize size;
  final bool isHighlighted;
  final bool isDimmed;

  const _AnimatedToken({
    required this.token,
    required this.size,
    this.isHighlighted = false,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = _buildToken();
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      opacity: isDimmed ? 0.25 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: AnimatedScale(
          scale: isHighlighted ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: widget,
        ),
      ),
    );
  }

  Widget _buildToken() {
    return switch (token) {
      DirectionParsed(:final glyph, :final icon) => DirectionToken(glyph, icon: icon, size: size),
      ChargeParsed(:final glyph, :final icon) => ChargeToken(glyph, icon: icon, size: size),
      ButtonParsed(:final label, :final color) =>
        ButtonToken(label, color, size: size),
      OperatorParsed(:final op) => OperatorToken(op, size: size),
      ModifierParsed(:final text) => ModifierToken(text, size: size),
      TextParsed(:final text) => Text(
          text,
          style: TextStyle(
            fontSize: size == InputTokenSize.large ? 18.0 : 13.0,
            color: AppColors.textPrimary,
          ),
        ),
      SeparatorParsed() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '/',
            style: TextStyle(
              fontSize: size == InputTokenSize.large ? 22.0 : 13.0,
              color: AppColors.textSecondary,
            ),
          ),
        ),
    };
  }
}
