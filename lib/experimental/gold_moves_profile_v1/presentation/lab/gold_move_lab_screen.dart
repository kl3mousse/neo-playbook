import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/move.dart';
import '../../domain/profile.dart';
import '../../domain/provenance.dart';
import '../../parsing/asset_loader.dart';
import 'lab_controller.dart';
import 'lab_diagnostics_panel.dart';
import 'lab_gallery.dart';
import 'lab_move_card.dart';
import 'lab_settings_sheet.dart';

/// Route path for the Gold Move Lab. Available only in debug builds
/// via [buildGoldMoveLabRoutes] (guarded by [kDebugMode]).
const String kGoldMoveLabRoute = '/debug/gold-move-lab';

/// Returns the debug [GoRoute] list registered by the app router.
/// The list is intentionally empty in release builds so the route is
/// unreachable, and the entry point in Settings is hidden as well.
List<GoRoute> buildGoldMoveLabRoutes() {
  if (!kDebugMode) return const [];
  return <GoRoute>[
    GoRoute(
      path: kGoldMoveLabRoute,
      builder: (_, _) => const GoldMoveLabScreen(),
    ),
  ];
}

/// Root screen of the Gold Move Lab. Loads the bundled KOF R-2 profile
/// via the asset bundle so it works identically on Android, iOS,
/// macOS and web.
class GoldMoveLabScreen extends StatefulWidget {
  final Future<ProfileGold> Function()? loader;
  const GoldMoveLabScreen({super.key, this.loader});

  @override
  State<GoldMoveLabScreen> createState() => _GoldMoveLabScreenState();
}

class _GoldMoveLabScreenState extends State<GoldMoveLabScreen> {
  late Future<ProfileGold> _future = _load();

  Future<ProfileGold> _load() {
    return (widget.loader ?? loadBundledKofR2Profile).call();
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileGold>(
      future: _future,
      builder: (context, snap) {
        final l = AppLocalizations.of(context);
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text(l.labTitle)),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l.labLoading),
                ],
              ),
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return _ErrorScreen(error: snap.error, onRetry: _retry);
        }
        return _LabLoadedScreen(profile: snap.data!);
      },
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const _ErrorScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.labTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.accent,
              ),
              const SizedBox(height: 12),
              Text(
                l.labLoadErrorTitle,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.labLoadErrorHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                SelectableText(
                  '$error',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l.labRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabLoadedScreen extends StatefulWidget {
  final ProfileGold profile;
  const _LabLoadedScreen({required this.profile});

  @override
  State<_LabLoadedScreen> createState() => _LabLoadedScreenState();
}

class _LabLoadedScreenState extends State<_LabLoadedScreen>
    with SingleTickerProviderStateMixin {
  late final LabController _controller;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _controller = LabController(widget.profile);
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => LabSettingsSheet(controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scaffold = Scaffold(
          appBar: AppBar(
            title: Text(l.labTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: l.labSettingsTitle,
                onPressed: _openSettings,
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: [
                Tab(text: l.labTabCharacters),
                Tab(text: l.labTabGallery),
                Tab(text: l.labTabProvenance),
                Tab(text: l.labTabDiagnostics),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _CharactersTab(controller: _controller),
              LabGalleryView(controller: _controller),
              _ProvenanceTab(controller: _controller),
              LabDiagnosticsPanel(controller: _controller),
            ],
          ),
        );

        Widget content = scaffold;
        // Simulated text scaling remains local to the Lab.
        content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(_controller.textScale.factor),
          ),
          child: content,
        );
        // Local theme override without touching global preferences.
        if (_controller.themeMode == LabThemeMode.light) {
          content = Theme(
            data: ThemeData(useMaterial3: true, brightness: Brightness.light),
            child: content,
          );
        }
        return content;
      },
    );
  }
}

// ── Characters tab ────────────────────────────────────────────

class _CharactersTab extends StatelessWidget {
  final LabController controller;
  const _CharactersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 720;
    if (wide) {
      return Row(
        children: [
          SizedBox(width: 260, child: _CharactersList(controller: controller)),
          const VerticalDivider(width: 1),
          Expanded(child: _MovesPane(controller: controller)),
        ],
      );
    }
    // Narrow: list, then push detail.
    if (controller.selectedCharacterId == null) {
      return _CharactersList(controller: controller);
    }
    return _MovesPane(
      controller: controller,
      onBack: () => controller.selectCharacter(null),
    );
  }
}

class _CharactersList extends StatelessWidget {
  final LabController controller;
  const _CharactersList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = controller.profile;
    return Column(
      children: [
        _HeaderStrip(controller: controller),
        Expanded(
          child: ListView.builder(
            itemCount: p.characters.length,
            itemBuilder: (context, i) {
              final c = p.characters[i];
              final selected = c.id == controller.selectedCharacterId;
              final count = controller.movesForCharacter(c.id).length;
              return ListTile(
                selected: selected,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.12),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: selected
                      ? AppColors.primary
                      : AppColors.surfaceLight,
                  child: Text(
                    (i + 1).toString(),
                    style: TextStyle(
                      color: selected
                          ? AppColors.background
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  c.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  l.labResultsCount(count),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                onTap: () => controller.selectCharacter(c.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderStrip extends StatelessWidget {
  final LabController controller;
  const _HeaderStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = controller.profile;
    final autoCount =
        controller.activationCounts()[ActivationKind.automaticAfterMove] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.attribution.primarySource.name,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            p.appliesTo.romIds.isEmpty ? p.id : p.appliesTo.romIds.join(', '),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _statPill('${l.labHeaderGoldVersion}: ${p.goldSchemaVersion}'),
              _statPill('${l.labHeaderCharacters}: ${p.characters.length}'),
              _statPill('${l.labHeaderMoves}: ${p.moves.length}'),
              _statPill('${l.labHeaderAutomatic}: $autoCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MovesPane extends StatelessWidget {
  final LabController controller;
  final VoidCallback? onBack;
  const _MovesPane({required this.controller, this.onBack});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final charId = controller.selectedCharacterId;
    if (charId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l.labSelectCharacter,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final p = controller.profile;
    final character = p.character(charId);
    final moves = controller.filteredMovesForCharacter(charId);
    return Column(
      children: [
        _MoveListToolbar(
          controller: controller,
          onBack: onBack,
          characterName: character?.name ?? charId,
        ),
        if (moves.isEmpty)
          Expanded(child: _EmptyState())
        else
          Expanded(
            child: ListView.builder(
              itemCount: moves.length,
              itemBuilder: (context, i) {
                final m = moves[i];
                final selected = m.id == controller.selectedMoveId;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: _SafeMoveCard(
                    move: m,
                    character: character,
                    controller: controller,
                    selected: selected,
                    onTap: () => controller.selectMove(m.id),
                    onJumpToParent: (parentId) {
                      final parent = p.move(parentId);
                      if (parent == null) return;
                      controller.selectCharacter(parent.characterId);
                      controller.selectMove(parent.id);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Wraps [LabMoveCard] in a small try/catch: a rendering error on one
/// move must not prevent inspecting the other moves.
class _SafeMoveCard extends StatelessWidget {
  final MoveGold move;
  final dynamic character;
  final LabController controller;
  final bool selected;
  final VoidCallback? onTap;
  final void Function(String parentMoveId)? onJumpToParent;

  const _SafeMoveCard({
    required this.move,
    required this.character,
    required this.controller,
    required this.selected,
    this.onTap,
    this.onJumpToParent,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return LabMoveCard(
        move: move,
        character: character,
        buttons: controller.profile.buttons,
        notation: controller.notation,
        locale: controller.accessibleLocale,
        density: controller.density,
        onTap: onTap,
        selected: selected,
        onParentMoveTap:
            move.activation.trigger?.parentMoveId == null ||
                onJumpToParent == null
            ? null
            : () => onJumpToParent!(move.activation.trigger!.parentMoveId!),
      );
    } catch (e) {
      return _MoveErrorTile(move: move, error: e);
    }
  }
}

class _MoveErrorTile extends StatelessWidget {
  final MoveGold move;
  final Object error;
  const _MoveErrorTile({required this.move, required this.error});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.labErrorMoveTitle,
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${move.name}  ·  ${move.id}',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.labErrorMoveHint,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoveListToolbar extends StatefulWidget {
  final LabController controller;
  final String characterName;
  final VoidCallback? onBack;
  const _MoveListToolbar({
    required this.controller,
    required this.characterName,
    this.onBack,
  });

  @override
  State<_MoveListToolbar> createState() => _MoveListToolbarState();
}

class _MoveListToolbarState extends State<_MoveListToolbar> {
  late final TextEditingController _search = TextEditingController(
    text: widget.controller.search,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final count = widget.controller
        .filteredMovesForCharacter(widget.controller.selectedCharacterId!)
        .length;
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
              Expanded(
                child: Text(
                  widget.characterName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                l.labResultsCount(count),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: l.labSearchHint,
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: widget.controller.search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: l.labSearchClear,
                      onPressed: () {
                        _search.clear();
                        widget.controller.setSearch('');
                      },
                    ),
            ),
            onChanged: widget.controller.setSearch,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: Text(l.labFilterAllMoves),
                selected: widget.controller.moveFilter == LabMoveFilter.all,
                onSelected: (_) =>
                    widget.controller.setMoveFilter(LabMoveFilter.all),
              ),
              ChoiceChip(
                avatar: const Icon(
                  Icons.autorenew,
                  size: 14,
                  color: AppColors.secondary,
                ),
                label: Text(l.labFilterAutomatic),
                selected:
                    widget.controller.moveFilter == LabMoveFilter.automaticOnly,
                onSelected: (_) => widget.controller.setMoveFilter(
                  LabMoveFilter.automaticOnly,
                ),
              ),
              FilterChip(
                label: Text(l.labFilterGroupByCategory),
                selected: widget.controller.groupByCategory,
                onSelected: widget.controller.setGroupByCategory,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              l.labEmptyStateTitle,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.labEmptyStateHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Provenance tab ────────────────────────────────────────────

class _ProvenanceTab extends StatelessWidget {
  final LabController controller;
  const _ProvenanceTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = controller.profile.attribution;
    final composedCredit = l.labProvenanceComposedCredit(
      a.primarySource.name,
      a.primarySource.license ?? '—',
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.labProvenanceTitle,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        // Composed one-line credit — the *canonical* human summary
        // built from structured fields. Avoids repeating the license
        // string a second time via the raw display_text below.
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondary),
          ),
          child: SelectableText(
            composedCredit,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.labProvenanceStructured.toUpperCase(),
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _SourceTile(source: a.primarySource, isPrimary: true),
        if (a.additionalSources.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l.labProvenanceAdditional.toUpperCase(),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final s in a.additionalSources) _AdditionalSourceTile(source: s),
        ],
        const SizedBox(height: 16),
        // Verbatim attribution is preserved behind an explicit
        // expansion so CONSUMER_SPEC §5 stays honored (the raw
        // display_text is exposed on user demand) without the
        // license line being displayed twice in the default view.
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              l.labProvenanceVerbatim,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textSecondary,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: SelectableText(
                  a.displayText,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final Source source;
  final bool isPrimary;
  const _SourceTile({required this.source, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              // The license is intentionally NOT displayed here — it
              // is already surfaced by the composed credit above the
              // tile (mission §14: no duplicate "CC BY-SA 4.0").
              if (source.version != null)
                _pill('${l.labProvenanceVersion}: ${source.version}'),
              if (isPrimary) _pill('primary'),
            ],
          ),
          if (source.url != null) ...[
            const SizedBox(height: 6),
            _UrlLine(url: source.url!, label: l.labProvenanceOpenUrl),
          ],
          if (source.notes != null && source.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              source.notes!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AdditionalSourceTile extends StatelessWidget {
  final AdditionalSource source;
  const _AdditionalSourceTile({required this.source});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [_pill('${l.labProvenanceRole}: ${source.rawRole}')],
          ),
          if (source.url != null) ...[
            const SizedBox(height: 4),
            _UrlLine(url: source.url!, label: l.labProvenanceOpenUrl),
          ],
          if (source.notes != null && source.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              source.notes!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UrlLine extends StatelessWidget {
  final String url;
  final String label;
  const _UrlLine({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Row(
        children: [
          const Icon(Icons.open_in_new, size: 14, color: AppColors.secondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              url,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
              semanticsLabel: label,
            ),
          ),
        ],
      ),
    );
  }
}
