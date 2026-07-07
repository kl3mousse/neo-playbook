import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/prefs_service.dart';
import '../services/user_service.dart';

/// App settings: about, caches, recent history, offline status.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _info;
  int _recentCount = 0;
  bool _deletingAccount = false;
  String _defaultCurrency = PrefsService.getDefaultCurrency() ?? 'USD';

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Image cache cleared')));
  }

  Future<void> _clearRecent() async {
    await PrefsService.clearRecentGames();
    if (!mounted) return;
    setState(() => _recentCount = 0);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recent games cleared')));
  }

  Future<bool> _confirmDeleteAccount() async {
    final typed = TextEditingController();
    var loading = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = typed.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              title: const Text('Delete account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will permanently remove your profile and user data. '
                    'Type DELETE to confirm.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typed,
                    enabled: !loading,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: (!canDelete || loading)
                      ? null
                      : () async {
                          setDialogState(() => loading = true);
                          Navigator.pop(context, true);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    typed.dispose();
    return result ?? false;
  }

  Future<void> _deleteAccount() async {
    if (_deletingAccount) return;
    setState(() => _deletingAccount = true);
    try {
      await UserService.deleteCurrentAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Account deletion failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _deletingAccount = false);
      }
    }
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
          // ── Preferences ─────────────────────────────────────────────
          if (AuthService.isLoggedIn) ...[
            const _SectionHeader('Preferences'),
            ListTile(
              leading: const Icon(Icons.attach_money_outlined),
              title: const Text('Default Currency'),
              subtitle: Text(_defaultCurrency),
              onTap: () async {
                const options = ['USD', 'EUR', 'JPY', 'GBP'];
                final picked = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Default currency'),
                    children: [
                      for (final c in options)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, c),
                          child: Text(c),
                        ),
                    ],
                  ),
                );
                if (picked == null || !mounted) return;
                await UserService.updateDefaultCurrency(picked);
                setState(() => _defaultCurrency = picked);
              },
            ),
          ],

          // ── Network ─────────────────────────────────────────────────
          const _SectionHeader('Network'),
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              final results = snapshot.data;
              final online =
                  results != null &&
                  results.any((r) => r != ConnectivityResult.none);
              return ListTile(
                leading: Icon(
                  online ? Icons.wifi : Icons.wifi_off,
                  color: online
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
                title: Text(online ? 'Online' : 'Offline'),
                subtitle: Text(
                  online ? 'Connected' : 'Showing cached data where available',
                ),
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
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Legal terms and data handling'),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            subtitle: const Text('Contact support or report an issue'),
            onTap: () => context.push('/feedback'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(
              info == null ? '…' : '${info.version}+${info.buildNumber}',
            ),
            onLongPress: info == null
                ? null
                : () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '${info.version}+${info.buildNumber}',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Version copied')),
                    );
                  },
          ),

          // ── Account ─────────────────────────────────────────────────
          if (AuthService.isLoggedIn) ...[
            const _SectionHeader('Account'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilledButton.tonal(
                onPressed: () async {
                  await AuthService.signOut();
                  if (!context.mounted) return;
                  context.pop();
                },
                child: const Text('Sign Out'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: _deletingAccount
                    ? null
                    : () async {
                        final confirmed = await _confirmDeleteAccount();
                        if (!confirmed) return;
                        await _deleteAccount();
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: _deletingAccount
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete Account'),
              ),
            ),
          ],
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
