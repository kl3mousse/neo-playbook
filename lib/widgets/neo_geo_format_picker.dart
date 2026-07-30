import 'package:flutter/material.dart';
import '../models/platform_template.dart';
import '../theme/platform_palette.dart';

/// A compact format selector that surfaces the four Neo Geo physical formats
/// (MVS, AES, CD, Jamma board) as tappable chips.
///
/// Used in both [AddToCollectionSheet] and [CollectionItemEditScreen] whenever
/// the current game belongs to the Neo Geo family.
class NeoGeoFormatPicker extends StatelessWidget {
  final String selectedFormatId;
  final ValueChanged<String> onChanged;

  const NeoGeoFormatPicker({
    super.key,
    required this.selectedFormatId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Format',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: neoGeoFormatIds.map((id) {
            final template = platformTemplate(id);
            final palette = platformPalette(id);
            final isSelected = id == selectedFormatId;
            return _FormatChip(
              label: template.displayName,
              accentColor: palette.start,
              isSelected: isSelected,
              onTap: () => onChanged(id),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? accentColor
                : colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? accentColor : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
