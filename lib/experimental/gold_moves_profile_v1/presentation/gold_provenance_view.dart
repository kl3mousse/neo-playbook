import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/arcade_panel.dart';
import '../domain/provenance.dart';

/// Renders the profile's [Attribution] block in a way that satisfies
/// CONSUMER_SPEC §5: `displayText` is shown verbatim, and every listed
/// source is exposed with title/role/license/URL.
class GoldProvenanceView extends StatelessWidget {
  final Attribution attribution;
  const GoldProvenanceView({super.key, required this.attribution});

  @override
  Widget build(BuildContext context) {
    final primary = attribution.primarySource;
    return ArcadePanel(
      accentColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'Attribution & Sources',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _sourceTile(
            primary,
            role: 'primary_source',
            license: primary.license,
          ),
          for (final add in attribution.additionalSources) ...[
            const SizedBox(height: 6),
            _sourceTile(
              Source(name: add.name, url: add.url, notes: add.notes),
              role: add.rawRole,
              license: null,
            ),
          ],
          const SizedBox(height: 10),
          Divider(color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 6),
          // §5 mandates verbatim display of the credit line.
          SelectableText(
            attribution.displayText,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceTile(
    Source src, {
    required String role,
    required String? license,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 32,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                src.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  _pill('role: $role', AppColors.secondary),
                  if (license != null) _pill('license: $license', Colors.amber),
                  if (src.version != null)
                    _pill('v${src.version}', AppColors.textSecondary),
                ],
              ),
              if (src.url != null)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(src.url!);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Text(
                    src.url!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (src.notes != null && src.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    src.notes!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    margin: const EdgeInsets.only(top: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
    ),
  );
}
