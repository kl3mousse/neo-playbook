import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

// Wallpaper pool — add more paths here as new loading screen art is created.
const _loadingWallpapers = [
  'assets/foxxy/loadingscreens/foxxy_wp_lee01.png',
  'assets/foxxy/loadingscreens/foxxy_wp_mad01.png',
  'assets/foxxy/loadingscreens/foxxy_wp_motorbike01.png',
  'assets/foxxy/loadingscreens/foxxy_wp_phone01.png',
  'assets/foxxy/loadingscreens/foxxy_wp_playingarcade01.png',
  'assets/foxxy/loadingscreens/foxxy_wp_slug01.png',
];

class SplashScreen extends StatefulWidget {
  /// Called once the splash sequence has finished and the app is
  /// ready to display the main UI.
  final VoidCallback onReady;

  const SplashScreen({super.key, required this.onReady});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    'Inserting coin...',
    'Loading cartridge...',
    'Checking DIP switches...',
    'Calibrating joystick...',
    'Warming up the CRT...',
    'Buffering combos...',
    'Polishing pixels...',
    'Waking up the MVS...',
    'Feeding Foxxy...',
    'Counting quarters...',
  ];

  /// Minimum time the loading screen is visible, giving Firestore a head-start.
  static const _minSplashDuration = Duration(milliseconds: 3000);
  static const _messageCycleInterval = Duration(milliseconds: 1500);

  /// Hard upper-bound: navigate even if games haven't arrived yet.
  static const _maxLoadTimeout = Duration(seconds: 7);

  int _messageIndex = 0;
  Timer? _messageTimer;
  Timer? _maxLoadTimer;
  late final DateTime _startTime;
  late final String _wallpaper;

  bool _gamesLoaded = false;
  bool _authResolved = false;
  bool _navigated = false;

  StreamSubscription? _gamesSub;
  StreamSubscription? _authSub;

  late final AnimationController _uiController;
  late final Animation<double> _uiOpacity;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Pick a random wallpaper for this session.
    final rng = Random();
    _wallpaper = _loadingWallpapers[rng.nextInt(_loadingWallpapers.length)];

    // Fade-in animation for the overlay UI
    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _uiOpacity = CurvedAnimation(parent: _uiController, curve: Curves.easeIn);
    _uiController.forward();

    // Randomise starting message
    _messageIndex = rng.nextInt(_messages.length);

    // Cycle messages
    _messageTimer = Timer.periodic(_messageCycleInterval, (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });

    // Hard-cap: never block the user forever if data is slow/offline.
    _maxLoadTimer = Timer(_maxLoadTimeout, () {
      if (!_navigated) {
        _gamesLoaded = true;
        _tryNavigate();
      }
    });

    // Remove native splash now that Dart UI is rendering.
    FlutterNativeSplash.remove();

    // Wait for first non-empty games snapshot so the list is ready on arrival.
    _gamesSub = FirestoreService.gamesStream().listen((games) {
      if (!_gamesLoaded && games.isNotEmpty) {
        _gamesLoaded = true;
        _gamesSub?.cancel();
        _tryNavigate();
      }
    });

    // Resolve auth state (first emission).
    _authSub = AuthService.authStateChanges.listen((_) {
      _authResolved = true;
      _authSub?.cancel();
      _tryNavigate();
    });
  }

  void _tryNavigate() {
    if (_navigated || !_gamesLoaded || !_authResolved) return;

    final elapsed = DateTime.now().difference(_startTime);
    final remaining = _minSplashDuration - elapsed;

    if (remaining.isNegative || remaining == Duration.zero) {
      _navigate();
    } else {
      Future.delayed(remaining, _navigate);
    }
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    widget.onReady();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _maxLoadTimer?.cancel();
    _gamesSub?.cancel();
    _authSub?.cancel();
    _uiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Wallpaper ────────────────────────────────────────────────────
          Image.asset(_wallpaper, fit: BoxFit.cover),

          // ── Gradient overlay (light top → heavy bottom) ──────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.3, 1.0],
                colors: [Color(0x22000000), Color(0xBB000000)],
              ),
            ),
          ),

          // ── Loading UI (bottom-anchored) ─────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: FadeTransition(
                opacity: _uiOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cycling fun message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _messages[_messageIndex],
                        key: ValueKey<int>(_messageIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'Doto',
                          letterSpacing: 1.2,
                          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Neon pixel loading bar
                    const _NeonLoadingBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Neon arcade loading bar ──────────────────────────────────────────────────

class _NeonLoadingBar extends StatefulWidget {
  const _NeonLoadingBar();

  @override
  State<_NeonLoadingBar> createState() => _NeonLoadingBarState();
}

class _NeonLoadingBarState extends State<_NeonLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) =>
            CustomPaint(painter: _NeonBarPainter(_ctrl.value)),
      ),
    );
  }
}

class _NeonBarPainter extends CustomPainter {
  final double t;
  const _NeonBarPainter(this.t);

  static const _purple = AppColors.primary; // #A855F7
  static const _pink = AppColors.accent; // #FF4FD8
  static const _blue = AppColors.secondary; // #22D3EE

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dim purple background fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _purple.withValues(alpha: 0.12),
    );

    // 2. Moving shimmer band (sweeps left → right, loops)
    const segFrac = 0.45;
    final segW = size.width * segFrac;
    final x = (size.width + segW) * t - segW;
    final segRect = Rect.fromLTWH(x, 0, segW, size.height);
    final visible = segRect.intersect(Offset.zero & size);
    if (!visible.isEmpty) {
      canvas.drawRect(
        visible,
        Paint()
          ..shader = LinearGradient(
            colors: [
              _blue.withValues(alpha: 0.0),
              _blue.withValues(alpha: 0.85),
              _pink.withValues(alpha: 1.0),
              _blue.withValues(alpha: 0.85),
              _blue.withValues(alpha: 0.0),
            ],
          ).createShader(segRect),
      );
    }

    // 3. Pixel scanlines — subtle dark horizontal lines
    final scanPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 1.0;
    for (double y = 3.0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }
  }

  @override
  bool shouldRepaint(_NeonBarPainter old) => old.t != t;
}
