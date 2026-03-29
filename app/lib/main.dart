import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/games_list_screen.dart';
import 'screens/platform_select_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const AuthGate(),
    );
  }
}

/// Routes to login or games list based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _selectedPlatform;

  // List of supported platforms (could be dynamic or from config)
  final List<String> _platforms = const ['neogeo', 'cps1', 'cps2'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          if (_selectedPlatform == null) {
            return PlatformSelectScreen(
              platforms: _platforms,
              onPlatformSelected: (platform) {
                setState(() {
                  _selectedPlatform = platform;
                });
              },
            );
          } else {
            return GamesListScreen(
              selectedPlatform: _selectedPlatform!,
              onBack: () => setState(() => _selectedPlatform = null),
            );
          }
        }
        return const LoginScreen();
      },
    );
  }
}
