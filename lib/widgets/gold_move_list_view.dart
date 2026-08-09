import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../experimental/gold_moves_profile_v1/domain/character.dart';
import '../experimental/gold_moves_profile_v1/domain/move.dart';
import '../experimental/gold_moves_profile_v1/domain/profile.dart';
import '../experimental/gold_moves_profile_v1/presentation/gold_profile_move_card.dart';
import '../experimental/gold_moves_profile_v1/presentation/gold_rendering_options.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/prefs_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'arcade_panel.dart';

/// Production renderer for a bundled Gold profile. It stays in the surrounding
/// page's scroll view, so character sections do not create nested scrollables.
class GoldMoveListView extends StatefulWidget {
  final ProfileGold profile;
  final String gameId;
  final String gameTitle;
  final String? onlyCharacterName;
  final bool showFavorites;

  const GoldMoveListView({
    super.key,
    required this.profile,
    required this.gameId,
    required this.gameTitle,
    this.onlyCharacterName,
    this.showFavorites = true,
  });

  @override
  State<GoldMoveListView> createState() => _GoldMoveListViewState();
}

class _GoldMoveListViewState extends State<GoldMoveListView> {
  late GoldNotation _notation;
  late GoldDensity _density;
  String _query = '';
  String? _parentMoveId;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _notation = PrefsService.getGoldMoveNotation();
    _density = PrefsService.getGoldMoveDensity();
  }

  List<CharacterSpec> get _characters {
    final requested = widget.onlyCharacterName;
    if (requested == null) return widget.profile.characters;
    return widget.profile.characters
        .where((character) => character.name == requested)
        .toList();
  }

  bool _matches(MoveGold move, CharacterSpec character) {
    if (_parentMoveId != null) return move.id == _parentMoveId;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return character.name.toLowerCase().contains(q) ||
        move.name.toLowerCase().contains(q) ||
        move.aliases.any((alias) => alias.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final visible = _characters;
    final queryActive = _query.trim().isNotEmpty || _parentMoveId != null;
    final matchedCount = visible
        .expand((character) => widget.profile.movesForCharacter(character.id))
        .where((move) {
          final character = widget.profile.character(move.characterId ?? '');
          return character != null && _matches(move, character);
        })
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              const Icon(Icons.sports_martial_arts, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.goldMoveListTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              _optionsMenu(l),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _label(l.goldProfileLabel),
              Text(
                l.goldCharactersMoves(
                  widget.profile.characters.length,
                  widget.profile.moves.length,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            onChanged: (value) => setState(() {
              _query = value;
              _parentMoveId = null;
            }),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l.goldSearchHint,
              suffixIcon: queryActive
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l.labSearchClear,
                      onPressed: () => setState(() {
                        _query = '';
                        _parentMoveId = null;
                      }),
                    )
                  : null,
            ),
          ),
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.goldCharacterMissing),
          )
        else ...[
          const SizedBox(height: 8),
          for (final character in visible)
            _characterSection(character, l, queryActive),
          if (queryActive && matchedCount == 0)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.goldNoResults),
            ),
          _provenance(l),
        ],
      ],
    );
  }

  Widget _characterSection(
    CharacterSpec character,
    AppLocalizations l,
    bool queryActive,
  ) {
    final moves = widget.profile
        .movesForCharacter(character.id)
        .where((move) => _matches(move, character))
        .toList();
    if (queryActive && moves.isEmpty) return const SizedBox.shrink();
    final open =
        widget.onlyCharacterName != null ||
        queryActive ||
        _expanded.contains(character.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ArcadePanel(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          key: ValueKey('${character.id}-$open-${moves.length}'),
          initiallyExpanded: open,
          onExpansionChanged: (expanded) => setState(() {
            if (expanded) {
              _expanded.add(character.id);
            } else {
              _expanded.remove(character.id);
            }
          }),
          title: Text(
            character.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(l.goldMovesCount(moves.length)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _favoriteButton(character, l),
              const Icon(Icons.expand_more),
            ],
          ),
          children: open
              ? [
                  for (final move in moves)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                      child: GoldProfileMoveCard(
                        move: move,
                        character: character,
                        buttons: widget.profile.buttons,
                        notation: _notation,
                        locale:
                            Localizations.localeOf(context).languageCode == 'fr'
                            ? GoldAccessibleLocale.fr
                            : GoldAccessibleLocale.en,
                        density: _density,
                        automaticParentName: _parentName(move),
                        onParentMoveTap:
                            move.activation.trigger?.parentMoveId == null
                            ? null
                            : () => _showParent(
                                move.activation.trigger!.parentMoveId!,
                              ),
                      ),
                    ),
                ]
              : const [],
        ),
      ),
    );
  }

  String? _parentName(MoveGold move) {
    final parentId = move.activation.trigger?.parentMoveId;
    return parentId == null ? null : widget.profile.move(parentId)?.name;
  }

  void _showParent(String parentId) {
    final parent = widget.profile.move(parentId);
    if (parent == null) return;
    setState(() {
      _parentMoveId = parentId;
      if (parent.characterId != null) {
        _expanded.add(parent.characterId!);
      }
    });
  }

  Widget _favoriteButton(CharacterSpec character, AppLocalizations l) {
    if (!widget.showFavorites) return const SizedBox.shrink();
    if (!AuthService.isLoggedIn) {
      return IconButton(
        icon: const Icon(Icons.bookmark_border, size: 20),
        tooltip: l.goldBookmark,
        onPressed: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.goldSignInBookmark))),
      );
    }
    return StreamBuilder<bool>(
      stream: UserService.isFaveMoveStream(widget.gameId, character.name),
      builder: (context, snapshot) {
        final saved = snapshot.data ?? false;
        return IconButton(
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, size: 20),
          color: saved ? Colors.amber : null,
          tooltip: saved ? l.goldRemoveBookmark : l.goldBookmark,
          onPressed: () => UserService.toggleFaveMove(
            gameId: widget.gameId,
            gameTitle: widget.gameTitle,
            romName: widget.gameId,
            sectionTitle: character.name,
          ),
        );
      },
    );
  }

  Widget _optionsMenu(AppLocalizations l) {
    return PopupMenuButton<String>(
      tooltip: l.goldNotation,
      onSelected: _selectOption,
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text(l.goldNotation)),
        PopupMenuItem(value: 'pictograms', child: Text(l.goldPictograms)),
        PopupMenuItem(value: 'motionGlyphs', child: Text(l.goldMotionGlyphs)),
        PopupMenuItem(value: 'numpad', child: Text(l.goldNumpad)),
        PopupMenuItem(value: 'classic', child: Text(l.goldClassic2d)),
        PopupMenuItem(value: 'accessible', child: Text(l.goldAccessible)),
        PopupMenuItem(enabled: false, child: Text(l.goldDensity)),
        PopupMenuItem(value: 'compact', child: Text(l.goldCompact)),
        PopupMenuItem(value: 'comfortable', child: Text(l.goldComfortable)),
      ],
      icon: const Icon(Icons.tune),
    );
  }

  Future<void> _selectOption(String value) async {
    setState(() {
      switch (value) {
        case 'pictograms':
          _notation = GoldNotation.pictograms;
        case 'motionGlyphs':
          _notation = GoldNotation.motionGlyphs;
        case 'numpad':
          _notation = GoldNotation.numpad;
        case 'classic':
          _notation = GoldNotation.classic2d;
        case 'accessible':
          _notation = GoldNotation.accessible;
        case 'compact':
          _density = GoldDensity.compact;
        case 'comfortable':
          _density = GoldDensity.comfortable;
      }
    });
    await UserService.updateGoldMovePreferences(
      notation: _notation,
      density: _density,
    );
  }

  Widget _label(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.secondary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );

  Widget _provenance(AppLocalizations l) {
    final attribution = widget.profile.attribution;
    final primary = attribution.primarySource;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: ExpansionTile(
        title: Text(l.goldSourcesAttribution),
        subtitle: Text('${primary.name} · ${primary.license ?? ''}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (primary.url != null)
            TextButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(primary.url!);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: Text(l.goldOpenSource),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.goldAttributionText,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(attribution.displayText),
          for (final source in attribution.additionalSources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(source.name),
              subtitle: Text(source.notes ?? ''),
            ),
        ],
      ),
    );
  }
}
