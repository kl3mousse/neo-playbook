import 'package:flutter/material.dart';
import '../models/dip_settings.dart';

// ═══════════════════════════════════════════════════════════════
// DIP Settings widget
//
// Renders Neo Geo soft DIP switches and debug DIPs with:
// - Region tabs (EU / US / JP)
// - Special settings (time/count values)
// - Simple settings with default value highlighted
// - Collapsible debug DIPs section
// ═══════════════════════════════════════════════════════════════

/// Preferred region display order.
const _regionOrder = ['EU', 'US', 'JP'];

class DipSettingsView extends StatelessWidget {
  final DipSettingsData dipData;

  const DipSettingsView({super.key, required this.dipData});

  @override
  Widget build(BuildContext context) {
    final availableRegions = _regionOrder
        .where((r) => dipData.regions.containsKey(r))
        .toList();
    // Include any regions not in the standard order
    for (final r in dipData.regions.keys) {
      if (!availableRegions.contains(r)) availableRegions.add(r);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          initiallyExpanded: false,
          title: Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Soft DIP Settings',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: 'What are Soft DIPs?',
                onPressed: () => _showInfoDialog(
                  context,
                  'Soft DIP Settings',
                  'Soft DIPs are software-configurable game settings stored in '
                  'battery-backed SRAM on MVS arcade boards, or in backup RAM '
                  'on AES home consoles.\n\n'
                  'They control gameplay options such as difficulty, round time, '
                  'number of lives, and other game-specific parameters.\n\n'
                  'On Neo Geo CD, these settings are stored on the memory card '
                  'or internal storage. Each region (EU / US / JP) can have '
                  'different default values.',
                ),
              ),
            ],
          ),
          children: [
            // Region tabs + settings
            if (availableRegions.isNotEmpty)
              _RegionTabView(
                regions: availableRegions,
                dipData: dipData,
              ),
          ],
        ),

        // Debug DIPs (separate section)
        if (dipData.hasDebugDips) ...[
          const SizedBox(height: 12),
          _DebugDipsSection(debugDips: dipData.debugDips),
        ],
      ],
    );
  }
}

// ── Region tab view ──────────────────────────────────────────

class _RegionTabView extends StatefulWidget {
  final List<String> regions;
  final DipSettingsData dipData;

  const _RegionTabView({required this.regions, required this.dipData});

  @override
  State<_RegionTabView> createState() => _RegionTabViewState();
}

class _RegionTabViewState extends State<_RegionTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.regions.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only show tab bar if more than one region
        if (widget.regions.length > 1)
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: widget.regions
                .map((r) => Tab(text: _regionLabel(r)))
                .toList(),
          ),
        SizedBox(
          // Let content size itself; use a builder to avoid fixed height
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final region = widget.regions[_tabController.index];
              final settings = widget.dipData.regions[region];
              if (settings == null || settings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No settings available for this region.',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                );
              }
              return _RegionSettingsBody(
                key: ValueKey(region),
                settings: settings,
                regionCode: region,
              );
            },
          ),
        ),
      ],
    );
  }

  String _regionLabel(String code) {
    switch (code) {
      case 'EU':
        return 'Europe';
      case 'US':
        return 'USA';
      case 'JP':
        return 'Japan';
      default:
        return code;
    }
  }
}

// ── Settings body for a single region ────────────────────────

class _RegionSettingsBody extends StatelessWidget {
  final RegionDipSettings settings;
  final String regionCode;

  const _RegionSettingsBody({
    super.key,
    required this.settings,
    required this.regionCode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Special settings
          if (settings.specialSettings.isNotEmpty) ...[
            _SectionLabel(label: 'System Settings'),
            const SizedBox(height: 4),
            ...settings.specialSettings.map(_buildSpecialRow),
            const SizedBox(height: 12),
          ],

          // Simple settings
          if (settings.simpleSettings.isNotEmpty) ...[
            _SectionLabel(label: 'Game Settings'),
            const SizedBox(height: 4),
            ...settings.simpleSettings.map(
              (s) => _SimpleSettingTile(setting: s),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialRow(DipSpecialSetting setting) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              setting.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _ValueChip(label: setting.value, isDefault: true),
        ],
      ),
    );
  }
}

// ── Simple setting with all values shown ─────────────────────

class _SimpleSettingTile extends StatelessWidget {
  final DipSimpleSetting setting;

  const _SimpleSettingTile({required this.setting});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setting.description,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (var i = 0; i < setting.valueDescriptions.length; i++)
                _ValueChip(
                  label: setting.valueDescriptions[i],
                  isDefault: i == setting.defaultValue,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Debug DIPs section ───────────────────────────────────────

class _DebugDipsSection extends StatelessWidget {
  final Map<String, Map<String, String>> debugDips;

  const _DebugDipsSection({required this.debugDips});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: false,
      title: Row(
        children: [
          const Icon(Icons.bug_report, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Debug DIP Switches',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            tooltip: 'What are Debug DIPs?',
            onPressed: () => _showInfoDialog(
              context,
              'Debug DIP Switches',
              'Debug DIP switches correspond to the physical hardware '
              'DIP switches found on MVS arcade boards.\n\n'
              'They are typically used for diagnostic and test modes, '
              'such as entering the service menu, enabling free play, '
              'or activating debug features built into the game.\n\n'
              'Most players will never need to change these settings.',
            ),
          ),
        ],
      ),
      children: [
        for (final entry in debugDips.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text(
              'DIP Group ${entry.key}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          ...entry.value.entries.map((bit) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 1, bottom: 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${bit.key}.',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        bit.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

// ── Shared components ────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

void _showInfoDialog(BuildContext context, String title, String body) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _ValueChip extends StatelessWidget {
  final String label;
  final bool isDefault;

  const _ValueChip({required this.label, this.isDefault = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDefault
            ? cs.primaryContainer
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: isDefault
            ? Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isDefault ? FontWeight.w600 : FontWeight.normal,
          color: isDefault ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
