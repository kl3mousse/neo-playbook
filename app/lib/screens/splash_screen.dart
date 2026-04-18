import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

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
  ];

  static const _minSplashDuration = Duration(milliseconds: 2500);
  static const _messageCycleInterval = Duration(milliseconds: 1500);

  int _messageIndex = 0;
  Timer? _messageTimer;
  late final DateTime _startTime;

  bool _gamesLoaded = false;
  bool _authResolved = false;
  bool _navigated = false;

  StreamSubscription? _gamesSub;
  StreamSubscription? _authSub;

  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    // Logo entrance animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoController.forward();

    // Randomise starting message
    _messageIndex = Random().nextInt(_messages.length);

    // Cycle messages
    _messageTimer = Timer.periodic(_messageCycleInterval, (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });

    // Remove native splash now that Dart UI is rendering
    FlutterNativeSplash.remove();

    // Preload games list (first emission)
    _gamesSub = FirestoreService.gamesStream().listen((_) {
      _gamesLoaded = true;
      _gamesSub?.cancel();
      _tryNavigate();
    });

    // Resolve auth state (first emission)
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
    _gamesSub?.cancel();
    _authSub?.cancel();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo with entrance animation
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/combofox-splash.png',
                width: 280,
              ),
            ),

            const SizedBox(height: 48),

            // Cycling message with fade
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                _messages[_messageIndex],
                key: ValueKey<int>(_messageIndex),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontFamily: 'Doto',
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
