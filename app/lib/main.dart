import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/games_list_screen.dart';
import 'screens/platform_select_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/collection_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  runApp(const OtakuPlaybookApp());
}

class OtakuPlaybookApp extends StatelessWidget {
  const OtakuPlaybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otaku Playbook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}

/// Top-level shell: platform selection → main app with bottom nav.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? _selectedPlatform;
  final List<String> _platforms = const ['neogeo', 'cps1', 'cps2'];

  @override
  Widget build(BuildContext context) {
    if (_selectedPlatform == null) {
      return PlatformSelectScreen(
        platforms: _platforms,
        onPlatformSelected: (platform) {
          setState(() => _selectedPlatform = platform);
        },
      );
    }

    return MainNavigation(
      selectedPlatform: _selectedPlatform!,
      onBackToPlatforms: () => setState(() => _selectedPlatform = null),
    );
  }
}

/// Bottom navigation with 4 tabs: Games, Favorites, Collection, Profile.
class MainNavigation extends StatefulWidget {
  final String selectedPlatform;
  final VoidCallback onBackToPlatforms;

  const MainNavigation({
    super.key,
    required this.selectedPlatform,
    required this.onBackToPlatforms,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = snapshot.hasData;

        final screens = [
          GamesListScreen(
            selectedPlatform: widget.selectedPlatform,
            onBack: widget.onBackToPlatforms,
          ),
          const FavoritesScreen(),
          const CollectionScreen(),
          isLoggedIn
              ? const ProfileScreen()
              : LoginScreen(
                  onSkip: () => setState(() => _currentIndex = 0),
                ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
