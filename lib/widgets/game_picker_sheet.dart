import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/platform_template.dart';
import '../services/firestore_service.dart';
import '../theme/combofox_theme.dart';
import '../theme/platform_palette.dart';

// ── Result types ──────────────────────────────────────────────────────────────

/// Describes a game title for an item not present in the Firestore catalog
/// (bootleg, homebrew, or any unknown-system copy).
class CustomGameDraft {
  final String title;

  /// Normalised platform id (slug). Matches an existing [PlatformTemplate.id]
  /// for known systems, otherwise a user-typed slug.
  final String platformId;

  /// Human-readable label supplied by the user when they chose "Other…".
  /// `null` when the platform is one of the known templates.
  final String? customPlatformLabel;

  const CustomGameDraft({
    required this.title,
    required this.platformId,
    this.customPlatformLabel,
  });
}

/// Returned by [showGamePicker]. Exactly one of [game] or [custom] is non-null.
class GamePickerResult {
  final Game? game;
  final CustomGameDraft? custom;

  const GamePickerResult.fromGame(this.game) : custom = null;
  const GamePickerResult.fromCustom(this.custom) : game = null;
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Opens a full-screen game picker.
///
/// Returns a [GamePickerResult] where [GamePickerResult.game] is set when the
/// user chose a catalog title, or [GamePickerResult.custom] is set when they
/// created an off-catalog entry. Returns `null` when dismissed.
Future<GamePickerResult?> showGamePicker(
  BuildContext context, {
  String? initialQuery,
}) {
  return Navigator.of(context).push<GamePickerResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _GamePickerScreen(initialQuery: initialQuery),
    ),
  );
}

// ── Picker screen ─────────────────────────────────────────────────────────────

class _GamePickerScreen extends StatefulWidget {
  final String? initialQuery;
  const _GamePickerScreen({this.initialQuery});

  @override
  State<_GamePickerScreen> createState() => _GamePickerScreenState();
}

class _GamePickerScreenState extends State<_GamePickerScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _query = widget.initialQuery?.trim() ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _openCustomDialog() async {
    final draft = await showDialog<CustomGameDraft>(
      context: context,
      builder: (_) => _CustomTitleDialog(initialTitle: _query),
    );
    if (draft != null && mounted) {
      Navigator.pop(context, GamePickerResult.fromCustom(draft));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change game',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search the catalog…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: _query.length < 2
                ? _idleState()
                : StreamBuilder<List<Game>>(
                    stream: FirestoreService.searchGames(_query),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _resultList(snapshot.data!);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Shown before the user types enough characters.
  Widget _idleState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Type at least 2 characters to search',
            style: TextStyle(color: ComboFoxColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _offCatalogTile(prominent: false),
        ],
      ),
    );
  }

  Widget _resultList(List<Game> games) {
    // The off-catalog tile always appears at the end of the list.
    return ListView.builder(
      itemCount: games.length + 1,
      itemBuilder: (context, i) {
        if (i < games.length) {
          final game = games[i];
          final palette = platformPalette(game.platform);
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: palette.gradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.videogame_asset_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(game.title),
            subtitle: Text(
              [
                palette.label,
                if (game.yearLabel.isNotEmpty) game.yearLabel,
              ].join(' · '),
            ),
            onTap: () =>
                Navigator.pop(context, GamePickerResult.fromGame(game)),
          );
        }
        // Off-catalog tile — prominent when no catalog results were found.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (games.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  'No results for "$_query" in the catalog.',
                  style: const TextStyle(color: ComboFoxColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else
              const Divider(height: 24),
            _offCatalogTile(prominent: games.isEmpty),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _offCatalogTile({required bool prominent}) {
    final label = _query.isNotEmpty
        ? 'Use "$_query" as an off-catalog title…'
        : 'Add an off-catalog title (bootleg, homebrew…)';

    if (prominent) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: OutlinedButton.icon(
          onPressed: _openCustomDialog,
          icon: const Icon(Icons.extension_outlined),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      );
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ComboFoxColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ComboFoxColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: const Icon(
          Icons.extension_outlined,
          color: ComboFoxColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(color: ComboFoxColors.textSecondary),
      ),
      subtitle: const Text(
        'Bootleg, homebrew, or any game not in the catalog',
        style: TextStyle(color: ComboFoxColors.textSecondary, fontSize: 12),
      ),
      onTap: _openCustomDialog,
    );
  }
}

// ── Custom-title dialog ───────────────────────────────────────────────────────

/// A dialog that collects a custom game title and platform for an off-catalog
/// collection entry.
class _CustomTitleDialog extends StatefulWidget {
  final String initialTitle;
  const _CustomTitleDialog({required this.initialTitle});

  @override
  State<_CustomTitleDialog> createState() => _CustomTitleDialogState();
}

class _CustomTitleDialogState extends State<_CustomTitleDialog> {
  late final TextEditingController _titleController;
  final TextEditingController _customPlatformController =
      TextEditingController();

  PlatformTemplate? _selectedTemplate;
  bool _isCustomPlatform = false;

  final _templates = allPlatformTemplates;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customPlatformController.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    if (_titleController.text.trim().isEmpty) return false;
    if (_isCustomPlatform) {
      return _customPlatformController.text.trim().isNotEmpty;
    }
    return _selectedTemplate != null;
  }

  void _confirm() {
    if (!_canConfirm) return;

    final String platformId;
    final String? customLabel;

    if (_isCustomPlatform) {
      final raw = _customPlatformController.text.trim();
      customLabel = raw;
      // Slugify: lowercase, collapse non-alphanum runs to hyphens, trim edges.
      final slug = raw
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      platformId = slug.isEmpty ? 'other' : slug;
    } else {
      platformId = _selectedTemplate!.id;
      customLabel = null;
    }

    Navigator.pop(
      context,
      CustomGameDraft(
        title: _titleController.text.trim(),
        platformId: platformId,
        customPlatformLabel: customLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Off-catalog entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Game title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Object?>(
              key: ValueKey('dialog-platform-$_isCustomPlatform'),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Platform',
                border: OutlineInputBorder(),
              ),
              initialValue: _isCustomPlatform
                  ? const _OtherSentinel()
                  : _selectedTemplate,
              items: [
                ..._templates.map(
                  (t) => DropdownMenuItem<Object?>(
                    value: t,
                    child: Text(t.displayName),
                  ),
                ),
                const DropdownMenuItem<Object?>(
                  value: _OtherSentinel(),
                  child: Text('Other (type below)…'),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  if (v is _OtherSentinel) {
                    _isCustomPlatform = true;
                    _selectedTemplate = null;
                  } else {
                    _isCustomPlatform = false;
                    _selectedTemplate = v as PlatformTemplate?;
                  }
                });
              },
            ),
            if (_isCustomPlatform) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customPlatformController,
                decoration: const InputDecoration(
                  labelText: 'Platform name',
                  hintText: 'e.g. Sega Titan Video',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canConfirm ? _confirm : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

/// Sentinel value used to represent the "Other…" option in the platform
/// dropdown without conflicting with nullable [PlatformTemplate] items.
class _OtherSentinel {
  const _OtherSentinel();
  @override
  bool operator ==(Object other) => other is _OtherSentinel;
  @override
  int get hashCode => runtimeType.hashCode;
}
