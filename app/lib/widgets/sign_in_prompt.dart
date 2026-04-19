import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared empty-state prompt shown on screens that require authentication
/// (Favorites, Collection, etc.). Renders an icon, message, and a CTA
/// button that navigates to `/login`.
class SignInPrompt extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;

  const SignInPrompt({
    super.key,
    required this.icon,
    required this.message,
    this.buttonLabel = 'Sign In',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
