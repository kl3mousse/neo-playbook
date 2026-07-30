import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'experimental/gold_moves_profile_v1/presentation/debug_harness/gold_moves_harness_screen.dart';
import 'models/game.dart';
import 'screens/game_detail_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/login_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/settings_screen.dart';
import 'services/firestore_service.dart';
import 'services/prefs_service.dart';
import 'theme/app_theme.dart';
import 'widgets/skeleton.dart';

/// Canonical web origin used when sharing a URL to a game page.
const String kCanonicalWebOrigin = 'https://combofox.net';
const String kPrivacyPolicyUrl = '$kCanonicalWebOrigin/privacy.html';
const String kFeedbackFormUrl = '$kCanonicalWebOrigin/feedback.html';
const String kSupportEmail = 'support@combofox.net';

/// Build the canonical share URL for a game.
String canonicalGameUrl(String gameId) => '$kCanonicalWebOrigin/#/game/$gameId';

/// Navigator key for the root navigator. Exposed so widgets that live
/// outside the routed tree (if any) can still trigger navigation.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Builds the [GoRouter] used by the app.
///
/// [shellBuilder] returns the widget rendered for the root path `/`
/// (the bottom-nav shell). It's injected to avoid an import cycle
/// between this file and `main.dart`.
GoRouter buildAppRouter({required WidgetBuilder shellBuilder}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => shellBuilder(context)),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) =>
            _GameRouteLoader(gameId: state.pathParameters['id']!),
      ),
      // Debug-only routes (kDebugMode-guarded inside the helper).
      ...buildGoldHarnessRoutes(),
    ],
  );
}

/// Loads a [Game] by id from Firestore and shows the detail screen.
class _GameRouteLoader extends StatefulWidget {
  final String gameId;
  const _GameRouteLoader({required this.gameId});

  @override
  State<_GameRouteLoader> createState() => _GameRouteLoaderState();
}

class _GameRouteLoaderState extends State<_GameRouteLoader> {
  late Future<Game?> _future;

  @override
  void initState() {
    super.initState();
    _future = FirestoreService.getGame(widget.gameId).then((game) {
      if (game != null) {
        // Fire-and-forget: record this game as recently visited.
        PrefsService.pushRecentGame(widget.gameId);
      }
      return game;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Game?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: GameDetailSkeleton(),
          );
        }
        final game = snapshot.data;
        if (game == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Game not found')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      "We couldn't find a game with id "
                      '"${widget.gameId}".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _future = FirestoreService.getGame(widget.gameId);
                          }),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Back to games'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return GameDetailScreen(game: game);
      },
    );
  }
}
