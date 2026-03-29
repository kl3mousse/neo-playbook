import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/move_list.dart';
import '../services/firestore_service.dart';
import '../widgets/move_list_widget.dart';

class GameDetailScreen extends StatelessWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final wallpaper = game.images['wallpaper']?.displayUrl;
    final cover = game.images['cover3d']?.displayUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          game.title,
          style: const TextStyle(
            fontFamily: 'Doto',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            if (wallpaper != null)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  wallpaper,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image
                      if (cover != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cover,
                              width: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (game.altTitle != null)
                              Text(
                                game.altTitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                            const SizedBox(height: 8),
                            _InfoChip(label: game.year),
                            _InfoChip(label: game.publisher),
                            _InfoChip(label: game.genre),
                            _InfoChip(label: game.type),
                            _InfoChip(label: game.nbPlayers),
                            if (game.megs != null)
                              _InfoChip(label: '${game.megs} MEGs'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (game.description != null && game.description!.isNotEmpty)
                    Text(game.description!),

                  const SizedBox(height: 24),

                  // Screenshots
                  _ScreenshotRow(game: game),

                  const SizedBox(height: 24),

                  // Move List
                  if (game.roms.isNotEmpty)
                    _MoveListLoader(romNames: game.roms.map((r) => r.romName).toList()),

                  const SizedBox(height: 24),

                  // ROMs table
                  if (game.roms.isNotEmpty) ...[
                    Text('ROM Versions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...game.roms.map((rom) => Card(
                          child: ListTile(
                            title: Text(rom.romName),
                            subtitle: Text(
                              [
                                rom.description,
                                if (rom.serial.isNotEmpty) rom.serial,
                                if (rom.platformTag.isNotEmpty)
                                  'Platform: ${rom.platformTag}',
                              ].join('\n'),
                            ),
                            isThreeLine: true,
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ScreenshotRow extends StatelessWidget {
  final Game game;
  const _ScreenshotRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final keys = ['screenshot_title', 'screenshot_main', 'screenshot_alt'];
    final urls = keys
        .map((key) => game.images[key]?.displayUrl)
        .where((u) => u != null)
        .cast<String>()
        .toList();

    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Screenshots', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                urls[i],
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Async loader that fetches command data from Firestore for a game's rom names.
class _MoveListLoader extends StatelessWidget {
  final List<String> romNames;

  const _MoveListLoader({required this.romNames});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CommandData?>(
      future: FirestoreService.getCommandData(romNames),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final commandData = snapshot.data;
        if (commandData == null || commandData.sections.isEmpty) {
          return const SizedBox.shrink();
        }

        return MoveListView(commandData: commandData);
      },
    );
  }
}
