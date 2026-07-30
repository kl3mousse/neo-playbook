import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A recognised social/community site, resolved from a URL.
class SocialSite {
  final String label;
  final IconData icon;
  final Color? brandColor;

  const SocialSite({required this.label, required this.icon, this.brandColor});
}

/// Fallback used when the URL cannot be recognised.
const SocialSite _genericLink = SocialSite(
  label: 'Website',
  icon: PhosphorIconsRegular.link,
);

/// Recognise a website from a URL. Match is done against the (sub)domain,
/// so `https://twitter.com/foo` and `https://x.com/foo` both resolve.
///
/// Returns a generic "Website" descriptor if the URL is empty or unknown.
SocialSite recognizeSocialSite(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return _genericLink;

  Uri? uri;
  try {
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    uri = Uri.parse(withScheme);
  } catch (_) {
    return _genericLink;
  }

  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  if (host.isEmpty) return _genericLink;

  for (final entry in _knownSites.entries) {
    for (final pattern in entry.value.hosts) {
      if (host == pattern || host.endsWith('.$pattern')) {
        return entry.value.site;
      }
    }
  }
  return _genericLink;
}

class _KnownSite {
  final List<String> hosts;
  final SocialSite site;
  const _KnownSite(this.hosts, this.site);
}

// Ordered map so more-specific matches (e.g. `forums.neo-geo.com`) win
// over generic ones. Iteration is insertion order for `Map` literals.
final Map<String, _KnownSite> _knownSites = {
  // ── Arcade / fighting-game community ─────────────────────────────
  'neogeo': _KnownSite(
    const ['neo-geo.com', 'neogeo.com'],
    const SocialSite(
      label: 'Neo-Geo Forum',
      icon: PhosphorIconsRegular.gameController,
    ),
  ),
  'hfsplay': _KnownSite(const [
    'hfsplay.fr',
  ], const SocialSite(label: 'HFS Play', icon: PhosphorIconsRegular.trophy)),
  'shmups': _KnownSite(
    const ['shmups.system11.org', 'system11.org'],
    const SocialSite(label: 'Shmups Forum', icon: PhosphorIconsRegular.rocket),
  ),
  'srk': _KnownSite(
    const ['shoryuken.com', 'forums.shoryuken.com'],
    const SocialSite(
      label: 'Shoryuken',
      icon: PhosphorIconsRegular.boxingGlove,
    ),
  ),
  'atomiswave': _KnownSite(
    const ['atomiswave.net'],
    const SocialSite(
      label: 'Atomiswave',
      icon: PhosphorIconsRegular.gameController,
    ),
  ),
  'arcade-projects': _KnownSite(
    const ['arcade-projects.com'],
    const SocialSite(
      label: 'Arcade Projects',
      icon: PhosphorIconsRegular.gameController,
    ),
  ),

  // ── Social networks ──────────────────────────────────────────────
  'x': _KnownSite(const [
    'x.com',
    'twitter.com',
  ], const SocialSite(label: 'X', icon: PhosphorIconsRegular.xLogo)),
  'github': _KnownSite(const [
    'github.com',
  ], const SocialSite(label: 'GitHub', icon: PhosphorIconsRegular.githubLogo)),
  'youtube': _KnownSite(
    const ['youtube.com', 'youtu.be'],
    const SocialSite(
      label: 'YouTube',
      icon: PhosphorIconsRegular.youtubeLogo,
      brandColor: Color(0xFFFF0000),
    ),
  ),
  'twitch': _KnownSite(
    const ['twitch.tv'],
    const SocialSite(
      label: 'Twitch',
      icon: PhosphorIconsRegular.twitchLogo,
      brandColor: Color(0xFF9146FF),
    ),
  ),
  'discord': _KnownSite(
    const ['discord.com', 'discord.gg'],
    const SocialSite(
      label: 'Discord',
      icon: PhosphorIconsRegular.discordLogo,
      brandColor: Color(0xFF5865F2),
    ),
  ),
  'instagram': _KnownSite(
    const ['instagram.com'],
    const SocialSite(
      label: 'Instagram',
      icon: PhosphorIconsRegular.instagramLogo,
      brandColor: Color(0xFFE1306C),
    ),
  ),
  'facebook': _KnownSite(
    const ['facebook.com', 'fb.com'],
    const SocialSite(
      label: 'Facebook',
      icon: PhosphorIconsRegular.facebookLogo,
      brandColor: Color(0xFF1877F2),
    ),
  ),
  'reddit': _KnownSite(
    const ['reddit.com'],
    const SocialSite(
      label: 'Reddit',
      icon: PhosphorIconsRegular.redditLogo,
      brandColor: Color(0xFFFF4500),
    ),
  ),
  'linkedin': _KnownSite(
    const ['linkedin.com'],
    const SocialSite(
      label: 'LinkedIn',
      icon: PhosphorIconsRegular.linkedinLogo,
      brandColor: Color(0xFF0A66C2),
    ),
  ),
  'tiktok': _KnownSite(const [
    'tiktok.com',
  ], const SocialSite(label: 'TikTok', icon: PhosphorIconsRegular.tiktokLogo)),
  'telegram': _KnownSite(
    const ['t.me', 'telegram.me', 'telegram.org'],
    const SocialSite(
      label: 'Telegram',
      icon: PhosphorIconsRegular.telegramLogo,
      brandColor: Color(0xFF26A5E4),
    ),
  ),
  'mastodon': _KnownSite(
    const ['mastodon.social', 'mastodon.online', 'mstdn.social'],
    const SocialSite(
      label: 'Mastodon',
      icon: PhosphorIconsRegular.mastodonLogo,
    ),
  ),
  'bluesky': _KnownSite(const [
    'bsky.app',
  ], const SocialSite(label: 'Bluesky', icon: PhosphorIconsRegular.butterfly)),
};
