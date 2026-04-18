import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/games_list_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  runApp(const OtakuPlaybookApp());
}

/// Becomes `true` once the splash sequence completes. The splash is shown
/// as an overlay above the routed content, so deep-linked routes (e.g.
/// `/game/<id>`) are preserved across the splash.
final ValueNotifier<bool> splashFinished = ValueNotifier<bool>(false);

/// Currently selected tab in the main shell. Exposed at the top level so
/// deep-linked pages (e.g. `/game/<id>`) can render a bottom nav that
/// jumps to the correct tab when tapped.
final ValueNotifier<int> selectedTabIndex = ValueNotifier<int>(0);

class OtakuPlaybookApp extends StatefulWidget {
  const OtakuPlaybookApp({super.key});

  @override
  State<OtakuPlaybookApp> createState() => _OtakuPlaybookAppState();
}

class _OtakuPlaybookAppState extends State<OtakuPlaybookApp> {
  late final GoRouter _router = buildAppRouter(
    shellBuilder: (_) => const AppShell(),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Otaku Playbook',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: splashFinished,
          builder: (context, done, _) {
            if (done) return child ?? const SizedBox.shrink();
            return SplashScreen(
              onReady: () => splashFinished.value = true,
            );
          },
        );
      },
    );
  }
}

/// Top-level shell: main app with bottom nav.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}

/// Bottom navigation with 4 tabs: Games, Favorites, Collection, Profile.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  @override
  void initState() {
    super.initState();
    selectedTabIndex.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    selectedTabIndex.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData;

        final screens = [
          const GamesListScreen(),
          FavoritesScreen(key: ValueKey(snapshot.data?.uid)),
          CollectionScreen(key: ValueKey(snapshot.data?.uid)),
          isLoggedIn
              ? const ProfileScreen()
              : LoginScreen(
                  onSkip: () => selectedTabIndex.value = 0,
                ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: selectedTabIndex.value,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedTabIndex.value,
            onDestinationSelected: (i) => selectedTabIndex.value = i,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.videogame_asset_outlined),
                selectedIcon: Icon(Icons.videogame_asset),
                label: 'Games',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: Icon(Icons.collections_bookmark_outlined),
                selectedIcon: Icon(Icons.collections_bookmark),
                label: 'Collection',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
