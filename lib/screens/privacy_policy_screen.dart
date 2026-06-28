import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _openPolicy(BuildContext context) async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the privacy policy URL.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ComboFox collects only the data needed to provide your account and app features. '
            'This includes account identity, profile information, and your in-app content such as '
            'favorites and collection entries.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Your data is stored using Firebase services (Authentication, Firestore, Storage). '
            'You can request full account deletion from the profile screen.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _openPolicy(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open full privacy policy'),
          ),
          const SizedBox(height: 8),
          SelectableText(
            kPrivacyPolicyUrl,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
