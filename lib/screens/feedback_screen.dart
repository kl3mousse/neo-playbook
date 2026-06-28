import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../router.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final TextEditingController _emailController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: AuthService.currentUser?.email ?? '',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a bit more detail.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await UserService.submitFeedback(
        message: message,
        contactEmail: _emailController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks! Your feedback was sent.')),
      );
      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send feedback: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openEmailClient() async {
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      queryParameters: {'subject': 'ComboFox feedback'},
    );
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your email app.')),
      );
    }
  }

  Future<void> _openWebForm() async {
    final uri = Uri.parse(kFeedbackFormUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open feedback page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feedback',
          style: TextStyle(fontFamily: 'Doto', fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Help us improve ComboFox by sharing bugs, ideas, or feature requests.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Your feedback',
              border: OutlineInputBorder(),
              hintText: 'What happened? What would you like to see improved?',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Contact email (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Submit feedback'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _openEmailClient,
            icon: const Icon(Icons.alternate_email),
            label: const Text('Contact support by email'),
          ),
          TextButton.icon(
            onPressed: _openWebForm,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open web feedback page'),
          ),
        ],
      ),
    );
  }
}
