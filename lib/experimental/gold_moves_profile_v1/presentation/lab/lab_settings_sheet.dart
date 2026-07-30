import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import 'lab_controller.dart';

/// Bottom-sheet control panel used to change rendering options in the
/// Gold Move Lab. Rebuilds on every controller change.
class LabSettingsSheet extends StatelessWidget {
  final LabController controller;
  const LabSettingsSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l.labSettingsTitle,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _sectionTitle(l.labSectionNotation),
              _notationChoice(l),
              const SizedBox(height: 12),
              _sectionTitle(l.labSectionAccessibleLocale),
              _localeChoice(l),
              const SizedBox(height: 12),
              _sectionTitle(l.labSectionTheme),
              _themeChoice(l),
              const SizedBox(height: 12),
              _sectionTitle(l.labSectionDensity),
              _densityChoice(l),
              const SizedBox(height: 12),
              _sectionTitle(l.labSectionTextScale),
              Text(
                l.labTextScaleHint,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 6),
              _textScaleChoice(l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _notationChoice(AppLocalizations l) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(
          l.labNotationPictograms,
          controller.notation == LabNotation.pictograms,
          () => controller.setNotation(LabNotation.pictograms),
        ),
        _chip(
          l.labNotationNumpad,
          controller.notation == LabNotation.numpad,
          () => controller.setNotation(LabNotation.numpad),
        ),
        _chip(
          l.labNotationClassic2d,
          controller.notation == LabNotation.classic2d,
          () => controller.setNotation(LabNotation.classic2d),
        ),
        _chip(
          l.labNotationAccessible,
          controller.notation == LabNotation.accessible,
          () => controller.setNotation(LabNotation.accessible),
        ),
      ],
    );
  }

  Widget _localeChoice(AppLocalizations l) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(
          l.labLocaleEn,
          controller.accessibleLocale == LabAccessibleLocale.en,
          () => controller.setAccessibleLocale(LabAccessibleLocale.en),
        ),
        _chip(
          l.labLocaleFr,
          controller.accessibleLocale == LabAccessibleLocale.fr,
          () => controller.setAccessibleLocale(LabAccessibleLocale.fr),
        ),
      ],
    );
  }

  Widget _themeChoice(AppLocalizations l) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(
          l.labThemeDark,
          controller.themeMode == LabThemeMode.dark,
          () => controller.setThemeMode(LabThemeMode.dark),
        ),
        _chip(
          l.labThemeLight,
          controller.themeMode == LabThemeMode.light,
          () => controller.setThemeMode(LabThemeMode.light),
        ),
        _chip(
          l.labThemeSystem,
          controller.themeMode == LabThemeMode.system,
          () => controller.setThemeMode(LabThemeMode.system),
        ),
      ],
    );
  }

  Widget _densityChoice(AppLocalizations l) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(
          l.labDensityComfortable,
          controller.density == LabDensity.comfortable,
          () => controller.setDensity(LabDensity.comfortable),
        ),
        _chip(
          l.labDensityCompact,
          controller.density == LabDensity.compact,
          () => controller.setDensity(LabDensity.compact),
        ),
      ],
    );
  }

  Widget _textScaleChoice(AppLocalizations l) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in LabTextScale.values)
          _chip(
            l.labTextScalePercent(s.percent),
            controller.textScale == s,
            () => controller.setTextScale(s),
          ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.25),
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : AppColors.textSecondary.withValues(alpha: 0.3),
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }
}
