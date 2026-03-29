import 'package:flutter/material.dart';

class PlatformSelectScreen extends StatelessWidget {
  final List<String> platforms;
  final void Function(String) onPlatformSelected;

  const PlatformSelectScreen({
    super.key,
    required this.platforms,
    required this.onPlatformSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Platform'),
      ),
      body: ListView.builder(
        itemCount: platforms.length,
        itemBuilder: (context, index) {
          final platform = platforms[index];
          return ListTile(
            title: Text(platform.toUpperCase()),
            onTap: () => onPlatformSelected(platform),
          );
        },
      ),
    );
  }
}
