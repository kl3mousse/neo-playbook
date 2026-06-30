import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/user_service.dart';

/// A single image source for the full-screen viewer. Exactly one of
/// [storagePath], [url] or [bytes] should be provided.
class PhotoSource {
  final String? storagePath;
  final String? url;
  final Uint8List? bytes;

  const PhotoSource.storage(this.storagePath) : url = null, bytes = null;
  const PhotoSource.url(this.url) : storagePath = null, bytes = null;
  const PhotoSource.bytes(this.bytes) : storagePath = null, url = null;
}

/// Opens a full-screen, swipeable, pinch-to-zoom photo viewer.
void openPhotoViewer(
  BuildContext context, {
  required List<PhotoSource> photos,
  int initialIndex = 0,
}) {
  if (photos.isEmpty) return;
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          _PhotoViewerPage(photos: photos, initialIndex: initialIndex),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _PhotoViewerPage extends StatefulWidget {
  final List<PhotoSource> photos;
  final int initialIndex;

  const _PhotoViewerPage({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiple = widget.photos.length > 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(child: _PhotoImage(source: widget.photos[i])),
              );
            },
          ),
          // Close control.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          // Page indicator.
          if (multiple)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.photos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  final PhotoSource source;
  const _PhotoImage({required this.source});

  @override
  Widget build(BuildContext context) {
    if (source.bytes != null) {
      return Image.memory(source.bytes!, fit: BoxFit.contain);
    }
    if (source.url != null) {
      return CachedNetworkImage(
        imageUrl: source.url!,
        fit: BoxFit.contain,
        placeholder: (_, _) => const _Loading(),
        errorWidget: (_, _, _) => const _Broken(),
      );
    }
    final path = source.storagePath;
    if (path == null) return const _Broken();
    return FutureBuilder<String>(
      future: UserService.resolveCollectionItemPhotoUrl(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _Loading();
        }
        final url = snapshot.data;
        if (url == null) return const _Broken();
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, _) => const _Loading(),
          errorWidget: (_, _, _) => const _Broken(),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _Broken extends StatelessWidget {
  const _Broken();
  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
  );
}
