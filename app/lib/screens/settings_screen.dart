import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/prefs_service.dart';

/// App settings: about, caches, recent history, offline status.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _info;
  int _recentCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _info = info;
      _recentCount = PrefsService.getRecentGameIds().length;
    });
  }

  Future<void> _clearImageCache() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image cache cleared')),
    );
  }

  Future<void> _clearRecent() async {
    await PrefsService.clearRecentGames();
    if (!mounted) return;
    setState(() => _recentCount = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recent games cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        children: [
          // ── Network ─────────────────────────────────────────────────
          const _SectionHeader('Network'),
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              final results = snapshot.data;
              final online = results != null &&
                  results.any((r) => r != ConnectivityResult.none);
              return ListTile(
                leading: Icon(
                  online ? Icons.wifi : Icons.wifi_off,
                  color: online ? Colors.green : Theme.of(context).colorScheme.error,
                ),
                title: Text(online ? 'Online' : 'Offline'),
                subtitle: Text(online
                    ? 'Connected'
                    : 'Showing cached data where available'),
              );
            },
          ),

          // ── Storage ─────────────────────────────────────────────────
          const _SectionHeader('Storage'),
          ListTile(
            leading: const Icon(Icons.image_not_supported_outlined),
            title: const Text('Clear image cache'),
            subtitle: const Text('Removes cached avatars and images'),
            onTap: _clearImageCache,
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Clear recent games'),
            subtitle: Text('$_recentCount saved'),
            enabled: _recentCount > 0,
            onTap: _recentCount > 0 ? _clearRecent : null,
          ),

          // ── About ───────────────────────────────────────────────────
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(info == null
                ? '…'
                : '${info.version}+${info.buildNumber}'),
            onLongPress: info == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(
                      text: '${info.version}+${info.buildNumber}',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Version copied')),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
