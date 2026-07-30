import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Slim, persistent offline indicator shown above the body of the main
/// shell whenever the device has no usable network. Non-dismissible
/// by design — Firestore serves cached data silently, so users deserve
/// a visible hint that what they see may be stale.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Seed current state.
    final current = await _connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() => _offline = _isOffline(current));
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _offline = _isOffline(results));
    });
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((r) => r == ConnectivityResult.none);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: _offline
          ? Container(
              width: double.infinity,
              color: AppColors.accent.withValues(alpha: 0.92),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 14, color: AppColors.textPrimary),
                  SizedBox(width: 8),
                  Text(
                    "You're offline — showing cached data",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
